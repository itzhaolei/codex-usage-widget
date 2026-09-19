using System.IO;
using System.Runtime.InteropServices;

namespace QuotaBubble.Services;

public sealed record SystemCapacity(ulong Available, ulong Total);

public static class SystemCapacityService
{
    public static SystemCapacity? SystemDrive()
    {
        try
        {
            var drive = new DriveInfo(@"C:\");
            return drive.IsReady
                ? new SystemCapacity((ulong)Math.Max(0, drive.AvailableFreeSpace), (ulong)Math.Max(0, drive.TotalSize))
                : null;
        }
        catch { return null; }
    }

    public static SystemCapacity? PhysicalMemory()
    {
        var status = new MemoryStatusEx();
        return GlobalMemoryStatusEx(status)
            ? new SystemCapacity(status.AvailablePhysical, status.TotalPhysical)
            : null;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    private sealed class MemoryStatusEx
    {
        public uint Length = (uint)Marshal.SizeOf<MemoryStatusEx>();
        public uint MemoryLoad;
        public ulong TotalPhysical;
        public ulong AvailablePhysical;
        public ulong TotalPageFile;
        public ulong AvailablePageFile;
        public ulong TotalVirtual;
        public ulong AvailableVirtual;
        public ulong AvailableExtendedVirtual;
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GlobalMemoryStatusEx([In, Out] MemoryStatusEx buffer);
}
