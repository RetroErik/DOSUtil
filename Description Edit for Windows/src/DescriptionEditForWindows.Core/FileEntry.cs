using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace DescriptionEditForWindows.Core
{
    public sealed class FileEntry : INotifyPropertyChanged
    {
        private string description;

        public string Name { get; set; }
        public string FullPath { get; set; }
        public bool IsDirectory { get; set; }
        public bool IsMissing { get; set; }
        public long? Size { get; set; }
        public DateTime? Modified { get; set; }
        public string Attributes { get; set; }

        public string Description
        {
            get { return description; }
            set
            {
                if (String.Equals(description, value, StringComparison.Ordinal))
                    return;
                description = value ?? String.Empty;
                OnPropertyChanged();
            }
        }

        public string Type
        {
            get
            {
                if (IsMissing) return "Missing";
                if (IsDirectory) return "Folder";
                string extension = System.IO.Path.GetExtension(Name);
                return String.IsNullOrEmpty(extension) ? "File" : extension.TrimStart('.').ToUpperInvariant() + " file";
            }
        }

        public string SizeDisplay
        {
            get
            {
                if (!Size.HasValue) return String.Empty;
                return Size.Value.ToString("N0");
            }
        }

        public string ModifiedDisplay
        {
            get { return Modified.HasValue ? Modified.Value.ToString("yyyy-MM-dd HH:mm") : String.Empty; }
        }

        public string Status
        {
            get
            {
                if (IsMissing) return "MISSING";
                return String.IsNullOrWhiteSpace(Description) ? String.Empty : "Described";
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;

        private void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChangedEventHandler handler = PropertyChanged;
            if (handler != null)
                handler(this, new PropertyChangedEventArgs(propertyName));
            if (propertyName == "Description" && handler != null)
                handler(this, new PropertyChangedEventArgs("Status"));
        }
    }
}
