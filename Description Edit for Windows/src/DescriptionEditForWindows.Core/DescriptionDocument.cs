using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace DescriptionEditForWindows.Core
{
    public sealed class DescriptionDocument
    {
        private static readonly string[] HiddenSidecars = { "DESCRIPT.ION", "DESCRIPT.BAK", "DESCRIPT.$$$" };

        public string DirectoryPath { get; private set; }
        public string FilePath { get; private set; }
        public DateTime? LoadedWriteTimeUtc { get; private set; }
        public long? LoadedLength { get; private set; }
        public IList<FileEntry> Entries { get; private set; }

        public static DescriptionDocument LoadDirectory(string directoryPath)
        {
            string directory = Path.GetFullPath(directoryPath);
            return Load(directory, Path.Combine(directory, "DESCRIPT.ION"));
        }

        public static DescriptionDocument LoadFile(string filePath)
        {
            string fullPath = Path.GetFullPath(filePath);
            string directory = Path.GetDirectoryName(fullPath);
            if (String.IsNullOrEmpty(directory))
                throw new ArgumentException("The description file must have a parent directory.", "filePath");
            return Load(directory, fullPath);
        }

        private static DescriptionDocument Load(string directory, string filePath)
        {
            if (!System.IO.Directory.Exists(directory))
                throw new DirectoryNotFoundException("Directory not found: " + directory);

            IDictionary<string, string> descriptions = File.Exists(filePath)
                ? DescriptIonParser.ParseFile(filePath)
                : new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

            Dictionary<string, string> remaining = new Dictionary<string, string>(descriptions, StringComparer.OrdinalIgnoreCase);
            List<FileEntry> entries = new List<FileEntry>();

            foreach (string path in System.IO.Directory.EnumerateFileSystemEntries(directory))
            {
                string name = Path.GetFileName(path.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar));
                if (HiddenSidecars.Any(sidecar => sidecar.Equals(name, StringComparison.OrdinalIgnoreCase)))
                    continue;

                FileAttributes attributes;
                try { attributes = File.GetAttributes(path); }
                catch (IOException) { attributes = 0; }
                catch (UnauthorizedAccessException) { attributes = 0; }

                bool isDirectory = (attributes & FileAttributes.Directory) != 0 || System.IO.Directory.Exists(path);
                string description;
                remaining.TryGetValue(name, out description);
                remaining.Remove(name);

                FileEntry entry = new FileEntry
                {
                    Name = name,
                    FullPath = path,
                    IsDirectory = isDirectory,
                    IsMissing = false,
                    Attributes = FormatAttributes(attributes),
                    Description = description ?? String.Empty
                };

                try { entry.Modified = File.GetLastWriteTime(path); }
                catch (IOException) { entry.Modified = null; }
                catch (UnauthorizedAccessException) { entry.Modified = null; }

                if (!isDirectory)
                {
                    try { entry.Size = new FileInfo(path).Length; }
                    catch (IOException) { entry.Size = null; }
                    catch (UnauthorizedAccessException) { entry.Size = null; }
                }

                entries.Add(entry);
            }

            foreach (KeyValuePair<string, string> stale in remaining)
            {
                entries.Add(new FileEntry
                {
                    Name = stale.Key,
                    FullPath = null,
                    IsDirectory = false,
                    IsMissing = true,
                    Attributes = String.Empty,
                    Description = stale.Value
                });
            }

            entries = entries
                .OrderBy(entry => entry.IsMissing ? 2 : entry.IsDirectory ? 0 : 1)
                .ThenBy(entry => entry.Name, StringComparer.CurrentCultureIgnoreCase)
                .ToList();

            return new DescriptionDocument
            {
                DirectoryPath = directory,
                FilePath = filePath,
                LoadedWriteTimeUtc = File.Exists(filePath) ? (DateTime?)File.GetLastWriteTimeUtc(filePath) : null,
                LoadedLength = File.Exists(filePath) ? (long?)new FileInfo(filePath).Length : null,
                Entries = entries
            };
        }

        public bool HasChangedOnDisk()
        {
            if (!File.Exists(FilePath))
                return LoadedWriteTimeUtc.HasValue;
            FileInfo info = new FileInfo(FilePath);
            return !LoadedWriteTimeUtc.HasValue || !LoadedLength.HasValue ||
                info.LastWriteTimeUtc != LoadedWriteTimeUtc.Value || info.Length != LoadedLength.Value;
        }

        public void Save(IEnumerable<FileEntry> entries)
        {
            string temporaryPath;
            string backupPath;
            if (Path.GetFileName(FilePath).Equals("DESCRIPT.ION", StringComparison.OrdinalIgnoreCase))
            {
                temporaryPath = Path.Combine(DirectoryPath, "DESCRIPT.$$$");
                backupPath = Path.Combine(DirectoryPath, "DESCRIPT.BAK");
            }
            else
            {
                temporaryPath = FilePath + ".tmp";
                backupPath = FilePath + ".bak";
            }

            string content = DescriptIonParser.Serialize(entries
                .Where(entry => !String.IsNullOrWhiteSpace(entry.Description))
                .Select(entry => new KeyValuePair<string, string>(entry.Name, entry.Description)));

            WriteThrough(temporaryPath, content);
            FileAttributes? originalAttributes = File.Exists(FilePath)
                ? (FileAttributes?)File.GetAttributes(FilePath)
                : null;
            try
            {
                if (File.Exists(FilePath))
                {
                    if ((originalAttributes.Value & FileAttributes.ReadOnly) != 0)
                        File.SetAttributes(FilePath, originalAttributes.Value & ~FileAttributes.ReadOnly);
                    DeleteIfPresent(backupPath);
                    try
                    {
                        File.Replace(temporaryPath, FilePath, backupPath, true);
                    }
                    catch (PlatformNotSupportedException)
                    {
                        ReplaceByRename(temporaryPath, backupPath);
                    }
                    catch (IOException)
                    {
                        ReplaceByRename(temporaryPath, backupPath);
                    }
                }
                else
                {
                    File.Move(temporaryPath, FilePath);
                }

                FileAttributes savedAttributes = originalAttributes ?? File.GetAttributes(FilePath);
                File.SetAttributes(FilePath, savedAttributes | FileAttributes.Hidden);
                if (File.Exists(backupPath))
                    File.SetAttributes(backupPath, File.GetAttributes(backupPath) | FileAttributes.Hidden);
            }
            catch
            {
                DeleteIfPresent(temporaryPath);
                if (originalAttributes.HasValue && File.Exists(FilePath))
                {
                    try { File.SetAttributes(FilePath, originalAttributes.Value); }
                    catch (IOException) { }
                    catch (UnauthorizedAccessException) { }
                }
                throw;
            }

            LoadedWriteTimeUtc = File.GetLastWriteTimeUtc(FilePath);
            LoadedLength = new FileInfo(FilePath).Length;
        }

        private void ReplaceByRename(string temporaryPath, string backupPath)
        {
            File.Move(FilePath, backupPath);
            try
            {
                File.Move(temporaryPath, FilePath);
            }
            catch
            {
                if (!File.Exists(FilePath) && File.Exists(backupPath))
                    File.Move(backupPath, FilePath);
                throw;
            }
        }

        private static void WriteThrough(string path, string content)
        {
            using (FileStream stream = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None, 4096, FileOptions.WriteThrough))
            using (StreamWriter writer = new StreamWriter(stream, new UTF8Encoding(true)))
            {
                writer.Write(content);
                writer.Flush();
                stream.Flush(true);
            }
        }

        private static void DeleteIfPresent(string path)
        {
            if (!File.Exists(path)) return;
            FileAttributes attributes = File.GetAttributes(path);
            if ((attributes & FileAttributes.ReadOnly) != 0)
                File.SetAttributes(path, attributes & ~FileAttributes.ReadOnly);
            File.Delete(path);
        }

        private static string FormatAttributes(FileAttributes attributes)
        {
            StringBuilder result = new StringBuilder(4);
            if ((attributes & FileAttributes.Hidden) != 0) result.Append('H');
            if ((attributes & FileAttributes.System) != 0) result.Append('S');
            if ((attributes & FileAttributes.ReadOnly) != 0) result.Append('R');
            if ((attributes & FileAttributes.Archive) != 0) result.Append('A');
            return result.ToString();
        }
    }
}
