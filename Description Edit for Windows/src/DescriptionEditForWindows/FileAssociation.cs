using Microsoft.Win32;
using System.Runtime.InteropServices;

namespace DescriptionEditForWindows;

internal static class FileAssociation
{
    private const string ProgId = "RetroErik.DescriptionEditForWindows.DescriptIon";
    private const uint ShcneAssocChanged = 0x08000000;

    internal static void Register(string executablePath)
    {
        using RegistryKey classes = Registry.CurrentUser.CreateSubKey(@"Software\Classes");
        using RegistryKey extension = classes.CreateSubKey(".ion");
        using RegistryKey openWith = extension.CreateSubKey("OpenWithProgids");
        using RegistryKey progId = classes.CreateSubKey(ProgId);
        extension.SetValue(String.Empty, ProgId);
        openWith.SetValue(ProgId, Array.Empty<byte>(), RegistryValueKind.None);
        progId.SetValue(String.Empty, "DESCRIPT.ION description file");
        using (RegistryKey icon = progId.CreateSubKey("DefaultIcon"))
            icon.SetValue(String.Empty, Quote(executablePath) + ",0");
        using (RegistryKey command = progId.CreateSubKey(@"shell\open\command"))
            command.SetValue(String.Empty, Quote(executablePath) + " \"%1\"");
        SHChangeNotify(ShcneAssocChanged, 0, IntPtr.Zero, IntPtr.Zero);
    }

    internal static void Unregister()
    {
        using RegistryKey classes = Registry.CurrentUser.OpenSubKey(@"Software\Classes", true);
        if (classes == null) return;
        using (RegistryKey extension = classes.OpenSubKey(".ion", true))
        {
            if (extension != null)
            {
                if (String.Equals(extension.GetValue(String.Empty) as string, ProgId, StringComparison.OrdinalIgnoreCase))
                    extension.DeleteValue(String.Empty, false);
                using RegistryKey openWith = extension.OpenSubKey("OpenWithProgids", true);
                openWith?.DeleteValue(ProgId, false);
            }
        }
        classes.DeleteSubKeyTree(ProgId, false);
        SHChangeNotify(ShcneAssocChanged, 0, IntPtr.Zero, IntPtr.Zero);
    }

    private static string Quote(string value) => "\"" + value + "\"";

    [DllImport("shell32.dll")]
    private static extern void SHChangeNotify(uint eventId, uint flags, IntPtr item1, IntPtr item2);
}
