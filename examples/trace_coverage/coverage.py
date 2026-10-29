"""Function coverage from a Renode PC trace: which functions of an ELF ran at least once.

Usage: python coverage.py <fw.elf> <trace.txt> [--expect-hit f1,f2] [--expect-miss f3]
The trace is Renode's `cpu CreateExecutionTracing "t" @file PC` output (one hex PC per line).
Exit 1 when an expectation fails."""
import argparse
import sys

from elftools.elf.elffile import ELFFile


def functions(path):
    with open(path, "rb") as f:
        elf = ELFFile(f)
        syms = elf.get_section_by_name(".symtab")
        out = []
        for s in syms.iter_symbols():
            if s["st_info"]["type"] == "STT_FUNC" and s["st_size"] > 0:
                start = s["st_value"] & ~1  # Thumb bit
                out.append((start, start + s["st_size"], s.name))
        return sorted(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("elf")
    ap.add_argument("trace")
    ap.add_argument("--expect-hit", default="")
    ap.add_argument("--expect-miss", default="")
    a = ap.parse_args()
    funcs = functions(a.elf)
    pcs = set()
    n = 0
    with open(a.trace) as f:
        for line in f:
            line = line.strip()
            if line.startswith("0x"):
                pcs.add(int(line, 16))
                n += 1
    hit = {name for lo, hi, name in funcs if any(lo <= pc < hi for pc in pcs)}
    for lo, hi, name in funcs:
        print(f"{'HIT ' if name in hit else 'miss'}  {lo:#010x} {hi - lo:5d} B  {name}")
    print(f"coverage: {len(hit)}/{len(funcs)} functions, {len(pcs)} distinct PCs, {n} trace lines")
    bad = [f for f in filter(None, a.expect_hit.split(",")) if f not in hit]
    bad += [f for f in filter(None, a.expect_miss.split(",")) if f in hit]
    if bad:
        print("FAIL: unexpected coverage for " + ", ".join(bad))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
