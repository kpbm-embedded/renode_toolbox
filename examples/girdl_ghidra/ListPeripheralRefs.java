// ListPeripheralRefs.java: Ghidra post-script for the girdl_ghidra example (headless, analyzeHeadless -postScript).
// Writes one line per reference from code into peripheral space (0x40000000-0x5FFFFFFF):
//   <function>\t<from address>\t<to address>\t<peripheral>+0x<offset> or -\t<peripheral data type or ->
// The peripheral is the label girdl puts on the binding address (from the Renode map), the type is its RDL struct.
// Usage: -postScript ListPeripheralRefs.java <output file>
// @category Analysis
import java.io.PrintWriter;

import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.Instruction;
import ghidra.program.model.listing.InstructionIterator;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.Symbol;

public class ListPeripheralRefs extends GhidraScript {
    private static final long LO = 0x40000000L, HI = 0x60000000L;

    @Override
    protected void run() throws Exception {
        String[] args = getScriptArgs();
        String out = args.length > 0 ? args[0] : "peripheral_refs.tsv";
        int n = 0;
        try (PrintWriter w = new PrintWriter(out)) {
            InstructionIterator it = currentProgram.getListing().getInstructions(true);
            while (it.hasNext() && !monitor.isCancelled()) {
                Instruction ins = it.next();
                for (Reference r : ins.getReferencesFrom()) {
                    Address to = r.getToAddress();
                    if (!to.isMemoryAddress()) {
                        continue;
                    }
                    long off = to.getOffset();
                    if (off < LO || off >= HI) {
                        continue;
                    }
                    Function f = getFunctionContaining(ins.getAddress());
                    Data d = getDataContaining(to);
                    String per = "-", type = "-";
                    if (d != null) {
                        Symbol s = getSymbolAt(d.getAddress());
                        per = (s == null ? d.getAddress().toString() : s.getName(true)) + "+0x"
                            + Long.toHexString(to.subtract(d.getAddress()));
                        type = d.getDataType().getName();
                    }
                    w.printf("%s\t%s\t%s\t%s\t%s%n", f == null ? "-" : f.getName(), ins.getAddress(), to, per, type);
                    n++;
                }
            }
        }
        println("ListPeripheralRefs: " + n + " references into peripheral space -> " + out);
    }
}
