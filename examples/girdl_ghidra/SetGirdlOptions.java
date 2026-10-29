// SetGirdlOptions.java: Ghidra pre-script for the girdl_ghidra example (headless, analyzeHeadless -preScript).
// Points girdl's "Peripheral Registers" analyzer at local files, so the analysis needs no network:
//   Data Source 1 = a folder of Renode RDL files (or an SVD), Data Source 2 = Renode's `peripherals export` map.
// Usage: -preScript SetGirdlOptions.java <source 1> [<source 2>]
// @category Analysis
import ghidra.app.script.GhidraScript;

public class SetGirdlOptions extends GhidraScript {
    @Override
    protected void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length < 1) {
            throw new IllegalArgumentException("usage: SetGirdlOptions.java <source 1> [<source 2>]");
        }
        setAnalysisOption(currentProgram, "Peripheral Registers", "true");
        setAnalysisOption(currentProgram, "Peripheral Registers.Data Source 1", args[0]);
        setAnalysisOption(currentProgram, "Peripheral Registers.Data Source 2", args.length > 1 ? args[1] : "");
        setAnalysisOption(currentProgram, "Peripheral Registers.Use Renode RDL", "false");
        println("SetGirdlOptions: source 1 = " + args[0] + (args.length > 1 ? ", source 2 = " + args[1] : ""));
    }
}
