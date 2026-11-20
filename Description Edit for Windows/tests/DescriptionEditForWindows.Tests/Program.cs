using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using DescriptionEditForWindows.Core;

namespace DescriptionEditForWindows.Tests
{
    internal static class Program
    {
        private static int failures;

        private static int Main()
        {
            ParseUnquotedName();
            ParseQuotedUnicodeName();
            ParseEscapedQuote();
            ParseCtrlDMetadata();
            MatchWithoutCase();
            SerializeQuotedUnicodeName();
            ParseFileEncodings();
            DescriptionNotifiesStatus();
            MergeFoldersFilesAndMissingEntries();
            SaveCreatesBackupAndUtf8File();
            RemovingMissingEntryDeletesSavedLine();
            DetectExternalChange();
            AcceptUncSyntax();

            Console.WriteLine(failures == 0 ? "All tests passed." : failures + " test(s) failed.");
            return failures == 0 ? 0 : 1;
        }

        private static void ParseUnquotedName()
        {
            IDictionary<string, string> result = DescriptIonParser.Parse("MONKEY.EXE Monkey Island  1990 EGA/VGA/ADLIB\r\n");
            Equal("Monkey Island  1990 EGA/VGA/ADLIB", result["MONKEY.EXE"], "unquoted entry");
        }

        private static void ParseQuotedUnicodeName()
        {
            IDictionary<string, string> result = DescriptIonParser.Parse("\"Blå mappe\" Beskrivelse på norsk\n");
            Equal("Beskrivelse på norsk", result["Blå mappe"], "quoted Unicode entry");
        }

        private static void ParseEscapedQuote()
        {
            IDictionary<string, string> result = DescriptIonParser.Parse("\"say \"\"hello\"\".txt\" Greeting\n");
            Equal("Greeting", result["say \"hello\".txt"], "escaped quote");
        }

        private static void ParseCtrlDMetadata()
        {
            IDictionary<string, string> result = DescriptIonParser.Parse("README.TXT Visible text\x04ignored metadata\n");
            Equal("Visible text", result["README.TXT"], "Ctrl-D metadata");
        }

        private static void MatchWithoutCase()
        {
            IDictionary<string, string> result = DescriptIonParser.Parse("ReadMe.txt Case insensitive\n");
            Equal("Case insensitive", result["README.TXT"], "case-insensitive match");
        }

        private static void SerializeQuotedUnicodeName()
        {
            string text = DescriptIonParser.Serialize(new[] {
                new KeyValuePair<string, string>("Blå mappe", "Norsk beskrivelse")
            });
            Equal("\"Blå mappe\" Norsk beskrivelse\r\n", text, "quoted serialization");
        }

        private static void ParseFileEncodings()
        {
            WithTemporaryDirectory(root =>
            {
                string path = Path.Combine(root, "DESCRIPT.ION");
                const string name = "Blå mappe";
                const string description = "Ærlig beskrivelse med æ, ø og å";
                string content = "\"" + name + "\" " + description + "\r\n";
                Encoding[] unicodeEncodings = {
                    new UTF8Encoding(true), new UTF8Encoding(false),
                    new UnicodeEncoding(false, true), new UnicodeEncoding(true, true)
                };
                foreach (Encoding encoding in unicodeEncodings)
                {
                    File.WriteAllText(path, content, encoding);
                    Equal(description, DescriptIonParser.ParseFile(path)[name],
                        "Unicode input " + encoding.WebName + " BOM=" + encoding.GetPreamble().Length);
                }

                Encoding ansi = CodePagesEncodingProvider.Instance.GetEncoding(0);
                if (ansi == null) throw new InvalidOperationException("Windows ANSI encoding unavailable.");
                // Use characters representable in the machine's active ANSI page.
                byte[] ansiBytes = ansi.GetBytes(content);
                string expectedText = ansi.GetString(ansiBytes);
                IDictionary<string, string> expected = DescriptIonParser.Parse(expectedText);
                File.WriteAllBytes(path, ansiBytes);
                IDictionary<string, string> actual = DescriptIonParser.ParseFile(path);
                foreach (KeyValuePair<string, string> pair in expected)
                    Equal(pair.Value, actual[pair.Key], "active Windows ANSI input " + ansi.CodePage);
                Console.WriteLine("Encoding coverage: UTF-8 BOM/no BOM, UTF-16 LE/BE, ANSI code page " + ansi.CodePage + ".");
            });
        }

        private static void DescriptionNotifiesStatus()
        {
            FileEntry entry = new FileEntry { Name = "demo.txt", Description = String.Empty };
            List<string> changed = new List<string>();
            entry.PropertyChanged += (_, args) => changed.Add(args.PropertyName);
            entry.Description = "New description";
            Equal("Described", entry.Status, "description updates status");
            True(changed.Contains(nameof(FileEntry.Description)) && changed.Contains(nameof(FileEntry.Status)),
                "description and dependent status notify bindings");
            changed.Clear();
            entry.Description = "New description";
            True(changed.Count == 0, "unchanged description does not notify");
            entry.Description = String.Empty;
            Equal(String.Empty, entry.Status, "clearing description clears status");
        }

        private static void MergeFoldersFilesAndMissingEntries()
        {
            WithTemporaryDirectory(delegate(string root)
            {
                Directory.CreateDirectory(Path.Combine(root, "Games"));
                File.WriteAllText(Path.Combine(root, "README.TXT"), String.Empty);
                File.WriteAllText(Path.Combine(root, "DESCRIPT.ION"),
                    "Games DOS games\nREADME.TXT Notes\nGONE.ZIP Stale entry\n", new UTF8Encoding(true));

                DescriptionDocument document = DescriptionDocument.LoadDirectory(root);
                Equal("DOS games", document.Entries.Single(entry => entry.Name == "Games").Description, "folder description");
                Equal("Notes", document.Entries.Single(entry => entry.Name == "README.TXT").Description, "file description");
                True(document.Entries.Single(entry => entry.Name == "GONE.ZIP").IsMissing, "stale entry retained");
                True(document.Entries[0].IsDirectory, "directories sort first");
            });
        }

        private static void SaveCreatesBackupAndUtf8File()
        {
            WithTemporaryDirectory(delegate(string root)
            {
                string descriptionPath = Path.Combine(root, "DESCRIPT.ION");
                File.WriteAllText(Path.Combine(root, "demo.txt"), String.Empty);
                File.WriteAllText(descriptionPath, "demo.txt Old\n", new UTF8Encoding(true));
                DescriptionDocument document = DescriptionDocument.LoadDirectory(root);
                document.Entries.Single(entry => entry.Name == "demo.txt").Description = "Ny beskrivelse";
                document.Save(document.Entries);

                Equal("Ny beskrivelse", DescriptIonParser.ParseFile(descriptionPath)["demo.txt"], "saved Unicode description");
                Equal("Old", DescriptIonParser.ParseFile(Path.Combine(root, "DESCRIPT.BAK"))["demo.txt"], "backup preserved");
                byte[] bytes = File.ReadAllBytes(descriptionPath);
                True(bytes.Length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF, "UTF-8 BOM written");
                True((File.GetAttributes(descriptionPath) & FileAttributes.Hidden) != 0, "saved description file is hidden");
                True((File.GetAttributes(Path.Combine(root, "DESCRIPT.BAK")) & FileAttributes.Hidden) != 0, "backup file is hidden");
            });
        }

        private static void DetectExternalChange()
        {
            WithTemporaryDirectory(delegate(string root)
            {
                string descriptionPath = Path.Combine(root, "DESCRIPT.ION");
                File.WriteAllText(descriptionPath, "one.txt One\n", new UTF8Encoding(true));
                DescriptionDocument document = DescriptionDocument.LoadDirectory(root);
                File.WriteAllText(descriptionPath, "one.txt Changed outside\n", new UTF8Encoding(true));
                File.SetLastWriteTimeUtc(descriptionPath, DateTime.UtcNow.AddSeconds(2));
                True(document.HasChangedOnDisk(), "external modification detected");
            });
        }

        private static void RemovingMissingEntryDeletesSavedLine()
        {
            WithTemporaryDirectory(delegate(string root)
            {
                string descriptionPath = Path.Combine(root, "DESCRIPT.ION");
                File.WriteAllText(Path.Combine(root, "present.txt"), String.Empty);
                File.WriteAllText(descriptionPath, "present.txt Present\nGONE.ZIP Remove me\n", new UTF8Encoding(true));
                DescriptionDocument document = DescriptionDocument.LoadDirectory(root);
                List<FileEntry> retained = document.Entries.Where(entry => !entry.IsMissing).ToList();
                document.Save(retained);

                IDictionary<string, string> saved = DescriptIonParser.ParseFile(descriptionPath);
                True(saved.ContainsKey("present.txt"), "present entry retained after deleting missing line");
                True(!saved.ContainsKey("GONE.ZIP"), "missing line deleted from saved file");
            });
        }

        private static void AcceptUncSyntax()
        {
            string path = Path.GetFullPath(@"\\server\share\games");
            True(path.StartsWith(@"\\server\share", StringComparison.OrdinalIgnoreCase), "UNC syntax accepted");
        }

        private static void WithTemporaryDirectory(Action<string> action)
        {
            string root = Path.Combine(Path.GetTempPath(), "DescriptionEditForWindowsTests-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(root);
            try { action(root); }
            finally { Directory.Delete(root, true); }
        }

        private static void Equal(string expected, string actual, string name)
        {
            if (String.Equals(expected, actual, StringComparison.Ordinal)) return;
            failures++;
            Console.Error.WriteLine("FAIL " + name + ": expected <" + expected + ">, got <" + actual + ">");
        }

        private static void True(bool value, string name)
        {
            if (value) return;
            failures++;
            Console.Error.WriteLine("FAIL " + name);
        }
    }
}
