// @NAME@.cs: a Renode peripheral in C#, compiled by Renode at run time (`include @@NAME@.cs`).
// A register file with a ready flag, an interrupt line and a self-clearing start bit:
//   0x00 CTRL   (W)  bit0 START: VALUE = INPUT * 2, STATUS.DONE = 1, IRQ raised if CTRL.IE (bit1)
//   0x04 STATUS (R)  bit0 DONE; (W1C) write 1 to clear DONE and the IRQ
//   0x08 INPUT  (RW)
//   0x0C VALUE  (R)
using Antmicro.Renode.Core;
using Antmicro.Renode.Core.Structure.Registers;
using Antmicro.Renode.Logging;
using Antmicro.Renode.Peripherals.Bus;

namespace Antmicro.Renode.Peripherals.Miscellaneous
{
    public class @NAME@ : BasicDoubleWordPeripheral, IKnownSize
    {
        public @NAME@(IMachine machine) : base(machine)
        {
            IRQ = new GPIO();
            Registers.Ctrl.Define(this)
                .WithFlag(0, FieldMode.Write, writeCallback: (_, v) => { if(v) Start(); }, name: "START")
                .WithFlag(1, out irqEnabled, name: "IE")
                .WithReservedBits(2, 30);
            Registers.Status.Define(this)
                .WithFlag(0, out done, FieldMode.Read | FieldMode.WriteOneToClear, name: "DONE",
                    writeCallback: (_, __) => UpdateIrq())
                .WithReservedBits(1, 31);
            Registers.Input.Define(this).WithValueField(0, 32, out input, name: "INPUT");
            Registers.Value.Define(this).WithValueField(0, 32, out value, FieldMode.Read, name: "VALUE");
        }

        public override void Reset()
        {
            base.Reset();
            UpdateIrq();
        }

        public long Size => 0x100;
        public GPIO IRQ { get; }

        private void Start()
        {
            value.Value = (input.Value * 2) & 0xFFFFFFFF;
            done.Value = true;
            this.Log(LogLevel.Debug, "computed 0x{0:X}", value.Value);
            UpdateIrq();
        }

        private void UpdateIrq()
        {
            IRQ.Set(done.Value && irqEnabled.Value);
        }

        private IFlagRegisterField irqEnabled;
        private IFlagRegisterField done;
        private IValueRegisterField input;
        private IValueRegisterField value;

        private enum Registers
        {
            Ctrl = 0x0,
            Status = 0x4,
            Input = 0x8,
            Value = 0xC,
        }
    }
}
