using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Linq;

namespace DescriptionEditForWindows.Core
{
    public static class DescriptIonParser
    {
        public static IDictionary<string, string> ParseFile(string path)
        {
            byte[] bytes = File.ReadAllBytes(path);
            string text = Decode(bytes);
            return Parse(text);
        }

        public static IDictionary<string, string> Parse(string text)
        {
            Dictionary<string, string> entries = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            if (String.IsNullOrEmpty(text))
                return entries;

            using (StringReader reader = new StringReader(text))
            {
                string line;
                while ((line = reader.ReadLine()) != null)
                {
                    string name;
                    string description;
                    if (TryParseLine(line, out name, out description))
                        entries[name] = description;
                }
            }

            return entries;
        }

        public static bool TryParseLine(string line, out string name, out string description)
        {
            name = null;
            description = null;

            if (String.IsNullOrWhiteSpace(line))
                return false;

            int position = 0;
            while (position < line.Length && Char.IsWhiteSpace(line[position]))
                position++;

            if (position == line.Length)
                return false;

            if (line[position] == '"')
            {
                StringBuilder fileName = new StringBuilder();
                position++;
                bool closed = false;
                while (position < line.Length)
                {
                    char current = line[position++];
                    if (current == '"')
                    {
                        if (position < line.Length && line[position] == '"')
                        {
                            fileName.Append('"');
                            position++;
                            continue;
                        }

                        closed = true;
                        break;
                    }
                    fileName.Append(current);
                }

                if (!closed || fileName.Length == 0)
                    return false;

                name = fileName.ToString();
            }
            else
            {
                int start = position;
                while (position < line.Length && !Char.IsWhiteSpace(line[position]))
                    position++;
                name = line.Substring(start, position - start);
            }

            while (position < line.Length && Char.IsWhiteSpace(line[position]))
                position++;

            if (position >= line.Length)
                description = String.Empty;
            else
                description = line.Substring(position).TrimEnd();

            // 4DOS may append metadata fields separated by Ctrl-D. The first field is
            // the user-visible description.
            int metadata = description.IndexOf('\x04');
            if (metadata >= 0)
                description = description.Substring(0, metadata).TrimEnd();

            return true;
        }

        public static string Serialize(IEnumerable<KeyValuePair<string, string>> entries)
        {
            StringBuilder result = new StringBuilder();
            foreach (KeyValuePair<string, string> entry in entries)
            {
                if (String.IsNullOrWhiteSpace(entry.Key) || String.IsNullOrWhiteSpace(entry.Value))
                    continue;
                result.Append(FormatName(entry.Key));
                result.Append(' ');
                result.Append(entry.Value.Replace("\r", " ").Replace("\n", " ").Trim());
                result.Append("\r\n");
            }
            return result.ToString();
        }

        private static string FormatName(string name)
        {
            bool quote = name.Any(Char.IsWhiteSpace) || name.IndexOf('"') >= 0;
            if (!quote) return name;
            return "\"" + name.Replace("\"", "\"\"") + "\"";
        }

        private static string Decode(byte[] bytes)
        {
            if (bytes.Length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF)
                return new UTF8Encoding(false, true).GetString(bytes, 3, bytes.Length - 3);

            if (bytes.Length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE)
                return Encoding.Unicode.GetString(bytes, 2, bytes.Length - 2);

            if (bytes.Length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF)
                return Encoding.BigEndianUnicode.GetString(bytes, 2, bytes.Length - 2);

            try
            {
                return new UTF8Encoding(false, true).GetString(bytes);
            }
            catch (DecoderFallbackException)
            {
                // Keeps classic DOS/Windows DESCRIPT.ION files usable. On .NET
                // Framework, Encoding.Default is the active Windows ANSI code page.
                return Encoding.Default.GetString(bytes);
            }
        }
    }
}
