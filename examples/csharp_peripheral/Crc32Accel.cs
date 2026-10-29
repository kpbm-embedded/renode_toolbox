// Crc32Accel.cs: a CRC-32 (IEEE 802.3) accelerator as a Renode peripheral, compiled by Renode at
// run time (`include @Crc32Accel.cs`). Registers: 0x0 DATA (write a 32-bit word, little endian
// bytes), 0x4 RESULT (read: final CRC), 0x8 CTRL (write 1: reset), 0xC COUNT (bytes fed).
using Antmicro.Renode.Core;
using Antmicro.Renode.Logging;
using Antmicro.Renode.Peripherals.Bus;

namespace Antmicro.Renode.Peripherals.Miscellaneous
{
    public class Crc32Accel : IDoubleWordPeripheral, IKnownSize
    {
        public Crc32Accel()
        {
            Reset();
        }

        public long Size => 0x100;

        public void Reset()
        {
            crc = 0xFFFFFFFF;
            count = 0;
        }

        public uint ReadDoubleWord(long offset)
        {
            switch(offset)
            {
                case 0x4: return ~crc;
                case 0xC: return count;
                default:
                    this.Log(LogLevel.Warning, "read from unknown offset 0x{0:X}", offset);
                    return 0;
            }
        }

        public void WriteDoubleWord(long offset, uint value)
        {
            switch(offset)
            {
                case 0x0:
                    for(var i = 0; i < 4; i++)
                    {
                        Feed((byte)(value >> (8 * i)));
                    }
                    break;
                case 0x8:
                    if(value == 1)
                    {
                        Reset();
                    }
                    break;
                default:
                    this.Log(LogLevel.Warning, "write 0x{0:X} to unknown offset 0x{1:X}", value, offset);
                    break;
            }
        }

        private void Feed(byte b)
        {
            crc ^= b;
            for(var k = 0; k < 8; k++)
            {
                crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
            }
            count++;
        }

        private uint crc;
        private uint count;
    }
}
