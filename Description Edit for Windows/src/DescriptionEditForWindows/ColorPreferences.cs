using DescriptionEditForWindows.Core;
using Microsoft.UI.Xaml.Media;
using System.Text;
using Windows.UI;

namespace DescriptionEditForWindows;

internal sealed class ColorPreferences
{
    public const string DefaultRules =
        "dirs:bri mag; zip arj:bri blu; com exe:bri gre; bat:bri red; gif jpg png:yel; txt me now:gre";

    private static readonly Dictionary<string, Color> DosColors = new(StringComparer.OrdinalIgnoreCase)
    {
        ["bla"] = Color.FromArgb(255, 0, 0, 0),
        ["blu"] = Color.FromArgb(255, 0, 0, 170),
        ["gre"] = Color.FromArgb(255, 0, 170, 0),
        ["cya"] = Color.FromArgb(255, 0, 170, 170),
        ["red"] = Color.FromArgb(255, 170, 0, 0),
        ["mag"] = Color.FromArgb(255, 170, 0, 170),
        ["bro"] = Color.FromArgb(255, 170, 85, 0),
        ["whi"] = Color.FromArgb(255, 170, 170, 170),
        ["yel"] = Color.FromArgb(255, 255, 255, 85)
    };

    private static readonly Dictionary<string, Color> BrightDosColors = new(StringComparer.OrdinalIgnoreCase)
    {
        ["bla"] = Color.FromArgb(255, 85, 85, 85),
        ["blu"] = Color.FromArgb(255, 85, 85, 255),
        ["gre"] = Color.FromArgb(255, 85, 255, 85),
        ["cya"] = Color.FromArgb(255, 85, 255, 255),
        ["red"] = Color.FromArgb(255, 255, 85, 85),
        ["mag"] = Color.FromArgb(255, 255, 85, 255),
        ["bro"] = Color.FromArgb(255, 255, 255, 85),
        ["whi"] = Color.FromArgb(255, 255, 255, 255),
        ["yel"] = Color.FromArgb(255, 255, 255, 85)
    };

    private readonly Dictionary<string, SolidColorBrush> extensionBrushes = new(StringComparer.OrdinalIgnoreCase);
    private SolidColorBrush directoryBrush;

    public static ColorPreferences Current { get; } = new();

    public string Rules { get; private set; } = DefaultRules;

    private ColorPreferences()
    {
        Load();
    }

    public void SetRules(string rules)
    {
        Rules = String.IsNullOrWhiteSpace(rules) ? DefaultRules : rules.Trim();
        Parse();
        Save();
    }

    public Brush BrushFor(FileEntry entry)
    {
        if (entry == null || entry.IsMissing) return null;
        if (entry.IsDirectory) return directoryBrush;
        string extension = Path.GetExtension(entry.Name).TrimStart('.');
        return extensionBrushes.TryGetValue(extension, out SolidColorBrush brush) ? brush : null;
    }

    private void Load()
    {
        try
        {
            string path = SettingsPath();
            if (File.Exists(path))
                Rules = File.ReadAllText(path, Encoding.UTF8).Trim();
        }
        catch
        {
            Rules = DefaultRules;
        }
        if (String.IsNullOrWhiteSpace(Rules)) Rules = DefaultRules;
        Parse();
    }

    private void Save()
    {
        try
        {
            string path = SettingsPath();
            Directory.CreateDirectory(Path.GetDirectoryName(path)!);
            File.WriteAllText(path, Rules, new UTF8Encoding(false));
        }
        catch
        {
            // A read-only profile must not prevent the editor from working.
        }
    }

    private void Parse()
    {
        directoryBrush = null;
        extensionBrushes.Clear();

        foreach (string rawRule in Rules.Split(';', StringSplitOptions.RemoveEmptyEntries))
        {
            int colon = rawRule.IndexOf(':');
            if (colon < 1) continue;
            string[] keys = rawRule[..colon].Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
            string[] colorWords = rawRule[(colon + 1)..].Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
            bool bright = colorWords.Any(word => word.Equals("bri", StringComparison.OrdinalIgnoreCase));
            string colorName = colorWords.FirstOrDefault(word => DosColors.ContainsKey(word));
            if (colorName == null) continue;
            Color color = (bright ? BrightDosColors : DosColors)[colorName];
            SolidColorBrush brush = new(color);

            foreach (string key in keys)
            {
                if (key.Equals("dirs", StringComparison.OrdinalIgnoreCase))
                    directoryBrush = brush;
                else
                    extensionBrushes[key.TrimStart('.')] = brush;
            }
        }
    }

    private static string SettingsPath()
    {
        return Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Retro Erik", "Description Edit for Windows", "ColorDir.txt");
    }
}
