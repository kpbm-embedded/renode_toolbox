#!/usr/bin/env python3
"""covflow.py: one coverage flow for bare-metal C and Zephyr images in Renode (no gcov, no instrumentation).

  Renode trace  ->  renode-retracer  ->  LCOV .info per run  ->  info-process merge  ->  summary / checks
                                                                           |-> info-process pack -> Coverview .zip
                                                                           |-> Coverview standalone .html (pinned)
Trace in Renode (binary + compressed is fastest):
  cpu CreateExecutionTracing "t" @run1.bin.gz PCAndOpcode true true     # PC is enough for line coverage

Commands (run through ./renode-box covflow ..., which provides Renode's tools and the pixi env):
  info    --elf E --name N -o run.info TRACE...      retracer: trace(s) -> LCOV .info (DA lines)
  merge   -o merged.info A.info B.info ...           info-process merge (+ tests.desc: which run hit each line)
  summary INFO [--only SUBSTR] [--hit F:TEXT] [--miss F:TEXT] [--min F:PERCENT] [--json OUT]
          per-file line coverage; --hit/--miss check the lines of source file F (suffix) containing TEXT;
          --min checks a file's line coverage; exit 1 when a check fails
  pack    -o report.zip --title T INFO... [--desc D]  Coverview archive (sources, config.json) via info-process pack
  html    ZIP -o report.html                         standalone Coverview page with the archive embedded
Lines that hold no code have no DA entry; "lines" below are executable lines (DA entries), as gcovr counts them.
"""
import argparse
import base64
import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def renode_dir():
    return Path(os.environ.get("RENODE_DIR") or ROOT / "install" / "renode")


def read_info(path):
    """LCOV .info -> {source file: {line: hits}} (DA entries; several records of one file are added up)."""
    files, cur = {}, None
    for line in Path(path).read_text().splitlines():
        if line.startswith("SF:"):
            cur = files.setdefault(line[3:], {})
        elif line.startswith("DA:") and cur is not None:
            ln, hits = line[3:].split(",")[:2]
            cur[int(ln)] = cur.get(int(ln), 0) + int(float(hits))
        elif line == "end_of_record":
            cur = None
    return files


def find_file(files, suffix):
    hits = [f for f in files if f == suffix or f.endswith("/" + suffix)]
    if len(hits) != 1:
        raise SystemExit(f"covflow: {suffix!r} matches {len(hits)} files in the report: {hits[:5]}")
    return hits[0]


def source_text(path, roots):
    for r in [Path("")] + [Path(x) for x in roots]:
        p = r / path if not os.path.isabs(path) else Path(path)
        if p.is_file():
            return p.read_text(errors="replace").splitlines()
    raise SystemExit(f"covflow: source {path} not found (pass --src-root)")


def cmd_info(a):
    tracer = renode_dir() / "tools" / "execution_tracer" / "execution_tracer_reader.py"
    cmd = [sys.executable, str(tracer), "coverage", *a.traces, "--binary", a.elf, "--output", a.output]
    if a.name:
        cmd += ["--name", a.name]
    for s in a.sub_source_path or []:
        cmd += ["--sub-source-path", s]
    for s in a.ignore or []:
        cmd += ["--ignore-paths", s]
    subprocess.run(cmd, check=True)
    files = read_info(a.output)
    print(f"covflow: {a.output}: {len(files)} source files, "
          f"{sum(1 for f in files.values() for h in f.values() if h)} lines hit")


def cmd_merge(a):
    desc = a.tests or str(Path(a.output).with_suffix(".desc"))
    subprocess.run(["info-process", "merge", "--output", a.output, "--test-list", desc, *a.inputs], check=True)
    print(f"covflow: merged {len(a.inputs)} runs -> {a.output} (+ {desc})")


def cmd_summary(a):
    files = read_info(a.info)
    rows, total, hit = [], 0, 0
    for f in sorted(files):
        if a.only and not any(o in f for o in a.only):
            continue
        n, h = len(files[f]), sum(1 for v in files[f].values() if v)
        total, hit = total + n, hit + h
        rows.append((f, n, h, 100.0 * h / n if n else 0.0))
    w = max([len(r[0]) for r in rows] + [4])
    print(f"{'File':<{w}} {'Lines':>6} {'Exec':>6} {'Cover':>7}")
    for f, n, h, pc in rows:
        print(f"{f:<{w}} {n:>6} {h:>6} {pc:>6.1f}%")
    print(f"{'TOTAL':<{w}} {total:>6} {hit:>6} {100.0 * hit / total if total else 0:>6.1f}%")
    if a.json:
        Path(a.json).write_text(json.dumps({f: {"lines": n, "hit": h, "percent": round(pc, 2)} for f, n, h, pc in rows}, indent=1))
    bad = 0
    for kind, specs in (("hit", a.hit or []), ("miss", a.miss or [])):
        for spec in specs:
            suffix, text = spec.split(":", 1)
            f = find_file(files, suffix)
            src = source_text(f, a.src_root or [])
            lines = [i + 1 for i, t in enumerate(src) if text in t and (i + 1) in files[f]]
            if not lines:
                print(f"FAIL  {kind} {spec}: no executable line contains the text"); bad += 1; continue
            counts = [files[f][ln] for ln in lines]
            ok = all(c > 0 for c in counts) if kind == "hit" else all(c == 0 for c in counts)
            print(f"{'ok  ' if ok else 'FAIL'}  {kind:<4} {spec}  (lines {lines}, hits {counts})")
            bad += not ok
    for spec in a.min or []:
        suffix, pc = spec.rsplit(":", 1)
        f = find_file(files, suffix)
        n = len(files[f]); h = sum(1 for v in files[f].values() if v)
        got = 100.0 * h / n if n else 0.0
        ok = got + 1e-9 >= float(pc)
        print(f"{'ok  ' if ok else 'FAIL'}  min  {suffix} >= {pc}%  (got {got:.1f}%, {h}/{n})")
        bad += not ok
    sys.exit(1 if bad else 0)


def cmd_pack(a):
    out = Path(a.output).resolve()
    work = out.parent / (out.stem + ".pack")
    work.mkdir(parents=True, exist_ok=True)
    # info-process pack derives Coverview datasets from coverage_<type>_<dataset>.info names
    infos = []
    for i, src in enumerate(a.infos):
        name = Path(src).stem if len(a.infos) > 1 else a.dataset
        dst = work / f"coverage_line_{name}.info"
        dst.write_text(Path(src).read_text())
        infos.append(str(dst))
    descs = []
    for d in a.desc or []:
        dst = work / f"tests_line_{a.dataset}.desc"
        dst.write_text(Path(d).read_text())
        descs.append(str(dst))
    cfg = work / "config.json"
    cfg.write_text(json.dumps({"title": a.title, "repo": a.repo, "branch": "-", "commit": "-",
                               "timestamp": a.timestamp or "", "additional": {"source": "Renode execution trace"}}))
    cmd = ["info-process", "pack", "--output", str(out), "--config", str(cfg), "--coverage-files", *infos]
    if descs:
        cmd += ["--description-files", *descs]
    if a.sources_root:
        cmd += ["--sources-root", a.sources_root]
    subprocess.run(cmd, check=True)
    print(f"covflow: Coverview archive {out} (open it in the page from `covflow html`, or antmicro.github.io/coverview)")


def coverview_dir():
    d = ROOT / "install" / "coverview"
    if not (d / "index.html").is_file():
        raise SystemExit("covflow: Coverview is optional: ./renode-box extras install coverview")
    return d


def cmd_html(a):
    d = coverview_dir()
    page = (d / "index.html").read_text()
    snippet = "let originalFiles = {}"
    if snippet not in page:
        raise SystemExit("covflow: unexpected Coverview index.html (pinned build changed?)")
    data = base64.b64encode(Path(a.zip).read_bytes()).decode("ascii")
    page = page.replace(snippet, f'{snippet}; let embeddedZipArchive = "{data}"', 1)
    # inline the module script(s) so the page works from file:// without a server
    for tag, src in re.findall(r'(<script type="module" crossorigin src="/?(assets/[\w.\-]+\.js)"></script>)', page):
        page = page.replace(tag, '<script type="module">' + (d / src).read_text() + "</script>")
    Path(a.output).write_text(page)
    print(f"covflow: {a.output} ({len(page) // 1024} KiB, Coverview {os.path.basename(os.path.realpath(d))}, data embedded)")


def main():
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0], formatter_class=argparse.RawDescriptionHelpFormatter,
                                epilog=__doc__.split("\n", 1)[1])
    sp = p.add_subparsers(dest="cmd", required=True)
    s = sp.add_parser("info"); s.add_argument("--elf", required=True); s.add_argument("--name")
    s.add_argument("-o", "--output", required=True); s.add_argument("--sub-source-path", action="append")
    s.add_argument("--ignore", action="append"); s.add_argument("traces", nargs="+"); s.set_defaults(f=cmd_info)
    s = sp.add_parser("merge"); s.add_argument("-o", "--output", required=True); s.add_argument("--tests")
    s.add_argument("inputs", nargs="+"); s.set_defaults(f=cmd_merge)
    s = sp.add_parser("summary"); s.add_argument("info"); s.add_argument("--only", action="append")
    s.add_argument("--hit", action="append"); s.add_argument("--miss", action="append"); s.add_argument("--min", action="append")
    s.add_argument("--src-root", action="append"); s.add_argument("--json"); s.set_defaults(f=cmd_summary)
    s = sp.add_parser("pack"); s.add_argument("-o", "--output", required=True); s.add_argument("--title", default="Renode coverage")
    s.add_argument("--repo", default="-"); s.add_argument("--dataset", default="renode"); s.add_argument("--timestamp")
    s.add_argument("--desc", action="append"); s.add_argument("--sources-root"); s.add_argument("infos", nargs="+")
    s.set_defaults(f=cmd_pack)
    s = sp.add_parser("html"); s.add_argument("zip"); s.add_argument("-o", "--output", required=True); s.set_defaults(f=cmd_html)
    a = p.parse_args()
    a.f(a)


if __name__ == "__main__":
    main()
