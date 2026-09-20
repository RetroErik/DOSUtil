using DescriptionEditForWindows.Core;
using Microsoft.UI;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using System.ComponentModel;
using System.Diagnostics;
using Windows.Graphics;
using Windows.Storage.Pickers;
using Windows.System;
using WinRT.Interop;

namespace DescriptionEditForWindows;

public sealed partial class MainWindow : Window, INotifyPropertyChanged
{
    private readonly string initialPath;
    private readonly Stack<string> backHistory = new();
    private readonly BulkObservableCollection<FileEntry> entries = new();
    private DescriptionDocument document;
    private bool dirty;
    private bool isLoading;
    private bool allowClose;
    private int loadGeneration;
    private string sortProperty = "Name";
    private bool sortAscending = true;
    private FileEntry editingEntry;
    private string descriptionBeforeEdit;
    private bool dirtyBeforeEdit;

    public MainWindow(string initialPath)
    {
        this.initialPath = initialPath;
        InitializeComponent();
        EntriesList.ItemsSource = entries;
        EntriesList.AddHandler(UIElement.KeyDownEvent,
            new KeyEventHandler(EntriesList_KeyDown), true);
        RootGrid.AddHandler(UIElement.PointerPressedEvent,
            new PointerEventHandler(RootGrid_PointerPressed), true);

        IntPtr windowHandle = WindowNative.GetWindowHandle(this);
        WindowId windowId = Win32Interop.GetWindowIdFromWindow(windowHandle);
        AppWindow appWindow = AppWindow.GetFromWindowId(windowId);
        appWindow.Resize(new SizeInt32(1280, 780));
        string iconPath = Path.Combine(AppContext.BaseDirectory,
            "Assets", "DescriptionEditForWindows.ico");
        if (File.Exists(iconPath)) appWindow.SetIcon(iconPath);
        appWindow.Closing += AppWindow_Closing;

        RootGrid.Loaded += async delegate
        {
            await OpenInitialPathAsync();
        };
    }

    public bool IsLoading
    {
        get => isLoading;
        private set
        {
            if (isLoading == value) return;
            isLoading = value;
            if (LoadingOverlay != null) LoadingOverlay.Visibility = value ? Visibility.Visible : Visibility.Collapsed;
            if (LoadingRing != null) LoadingRing.IsActive = value;
            OnPropertyChanged(nameof(IsLoading));
            OnPropertyChanged(nameof(IsLoadingVisibility));
        }
    }

    public Visibility IsLoadingVisibility => IsLoading ? Visibility.Visible : Visibility.Collapsed;

    public event PropertyChangedEventHandler PropertyChanged;

    private async Task OpenInitialPathAsync()
    {
        if (File.Exists(initialPath))
            await LoadFileAsync(initialPath, false, false);
        else if (Directory.Exists(initialPath))
            await LoadDirectoryAsync(initialPath, false, false);
        else
        {
            await ShowMessageAsync("Path not found", initialPath);
            string documents = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
            await LoadDirectoryAsync(documents, false, false);
        }
    }

    private async Task<bool> LoadDirectoryAsync(string path, bool addHistory, bool confirmLeave = true)
    {
        if (confirmLeave && !await CanLeaveDocumentAsync()) return false;
        return await LoadAsync(() => DescriptionDocument.LoadDirectory(path.Trim()), addHistory);
    }

    private async Task<bool> LoadFileAsync(string path, bool addHistory, bool confirmLeave = true)
    {
        if (confirmLeave && !await CanLeaveDocumentAsync()) return false;
        return await LoadAsync(() => DescriptionDocument.LoadFile(path.Trim()), addHistory);
    }

    private async Task<bool> LoadAsync(Func<DescriptionDocument> loader, bool addHistory)
    {
        int generation = ++loadGeneration;
        string previous = document?.DirectoryPath;
        IsLoading = true;
        StatusText.Text = "Reading folder…";
        try
        {
            DescriptionDocument loaded = await Task.Run(loader);
            if (generation != loadGeneration) return false;
            if (addHistory && !String.IsNullOrEmpty(previous) &&
                !String.Equals(previous, loaded.DirectoryPath, StringComparison.OrdinalIgnoreCase))
                backHistory.Push(previous);
            BindDocument(loaded);
            return true;
        }
        catch (Exception ex)
        {
            if (generation == loadGeneration)
                await ShowErrorAsync("Could not read the folder or description file.", ex);
            return false;
        }
        finally
        {
            if (generation == loadGeneration)
            {
                IsLoading = false;
                if (document != null) StatusText.Text = EntrySummary();
            }
        }
    }

    private void BindDocument(DescriptionDocument loaded)
    {
        foreach (FileEntry oldEntry in entries)
            oldEntry.PropertyChanged -= Entry_PropertyChanged;
        document = loaded;
        foreach (FileEntry entry in loaded.Entries)
            entry.PropertyChanged += Entry_PropertyChanged;
        entries.ReplaceAll(loaded.Entries);
        PathBox.Text = loaded.DirectoryPath;
        DocumentText.Text = Path.GetFileName(loaded.FilePath);
        dirty = false;
        UpdateTitle();
        UpdateNavigationButtons();
    }

    private void Entry_PropertyChanged(object sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName != nameof(FileEntry.Description)) return;
        dirty = true;
        UpdateTitle();
    }

    private async Task<bool> CanLeaveDocumentAsync()
    {
        if (!dirty || document == null) return true;
        ContentDialog dialog = CreateDialog(
            "Unsaved descriptions",
            "Do you want to save the changes to " + document.FilePath + "?",
            "Save", "Discard", "Cancel");
        ContentDialogResult result = await dialog.ShowAsync();
        if (result == ContentDialogResult.Primary) return await SaveDocumentAsync();
        return result == ContentDialogResult.Secondary;
    }

    private async Task<bool> SaveDocumentAsync()
    {
        if (document == null) return false;
        try
        {
            if (document.HasChangedOnDisk())
            {
                ContentDialog conflict = CreateDialog(
                    "File changed",
                    "DESCRIPT.ION changed after it was opened. Overwrite it and keep the current file as a backup?",
                    "Overwrite", null, "Cancel");
                if (await conflict.ShowAsync() != ContentDialogResult.Primary) return false;
            }

            await Task.Run(() => document.Save(entries.ToList()));
            dirty = false;
            UpdateTitle();
            StatusText.Text = "Saved safely. The previous file was kept as " + BackupName() + ".";
            return true;
        }
        catch (Exception ex)
        {
            await ShowErrorAsync("Could not save. The original file was preserved when possible.", ex);
            return false;
        }
    }

    private string BackupName()
    {
        return Path.GetFileName(document.FilePath).Equals("DESCRIPT.ION", StringComparison.OrdinalIgnoreCase)
            ? "DESCRIPT.BAK"
            : Path.GetFileName(document.FilePath) + ".bak";
    }

    private async void BackButton_Click(object sender, RoutedEventArgs e)
    {
        await NavigateBackAsync();
    }

    private async Task NavigateBackAsync()
    {
        if (backHistory.Count == 0) return;
        string target = backHistory.Peek();
        if (await LoadDirectoryAsync(target, false)) backHistory.Pop();
        UpdateNavigationButtons();
    }

    private async void RootGrid_PointerPressed(object sender, PointerRoutedEventArgs e)
    {
        if (!e.GetCurrentPoint(RootGrid).Properties.IsXButton1Pressed) return;
        e.Handled = true;
        await NavigateBackAsync();
    }

    private async void UpButton_Click(object sender, RoutedEventArgs e)
    {
        if (document == null) return;
        DirectoryInfo parent = Directory.GetParent(document.DirectoryPath);
        if (parent != null) await LoadDirectoryAsync(parent.FullName, true);
    }

    private async void BrowseFolderButton_Click(object sender, RoutedEventArgs e)
    {
        FolderPicker picker = new();
        picker.FileTypeFilter.Add("*");
        InitializeWithWindow.Initialize(picker, WindowNative.GetWindowHandle(this));
        Windows.Storage.StorageFolder folder = await picker.PickSingleFolderAsync();
        if (folder != null) await LoadDirectoryAsync(folder.Path, true);
    }

    private async void OpenFileButton_Click(object sender, RoutedEventArgs e)
    {
        FileOpenPicker picker = new();
        picker.FileTypeFilter.Add(".ion");
        picker.FileTypeFilter.Add("*");
        InitializeWithWindow.Initialize(picker, WindowNative.GetWindowHandle(this));
        Windows.Storage.StorageFile file = await picker.PickSingleFileAsync();
        if (file != null) await LoadFileAsync(file.Path, true);
    }

    private async void RefreshButton_Click(object sender, RoutedEventArgs e)
    {
        await RefreshDocumentAsync();
    }

    private async void RefreshKeyboardAccelerator_Invoked(
        KeyboardAccelerator sender, KeyboardAcceleratorInvokedEventArgs args)
    {
        args.Handled = true;
        await RefreshDocumentAsync();
    }

    private async Task RefreshDocumentAsync()
    {
        if (document != null) await LoadFileAsync(document.FilePath, false);
    }

    private async void SaveButton_Click(object sender, RoutedEventArgs e) => await SaveDocumentAsync();

    private async void GoButton_Click(object sender, RoutedEventArgs e) => await NavigateFromPathBoxAsync();

    private async void PathBox_KeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key != VirtualKey.Enter) return;
        e.Handled = true;
        await NavigateFromPathBoxAsync();
    }

    private async Task NavigateFromPathBoxAsync()
    {
        string path = PathBox.Text.Trim();
        if (File.Exists(path)) await LoadFileAsync(path, true);
        else await LoadDirectoryAsync(path, true);
    }

    private async void EntriesList_DoubleTapped(object sender, DoubleTappedRoutedEventArgs e)
    {
        if (FindAncestor<TextBox>(e.OriginalSource as DependencyObject) != null ||
            FindAncestor<Button>(e.OriginalSource as DependencyObject) != null)
            return;

        ListViewItem container = FindAncestor<ListViewItem>(e.OriginalSource as DependencyObject);
        if (container?.Content is not FileEntry entry || entry.IsMissing) return;
        if (entry.IsDirectory)
            await LoadDirectoryAsync(entry.FullPath, true);
        else
        {
            try
            {
                Process.Start(new ProcessStartInfo(entry.FullPath) { UseShellExecute = true });
            }
            catch (Exception ex)
            {
                await ShowErrorAsync("Windows could not open the file.", ex);
            }
        }
    }

    private void DeleteMissingRowButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: FileEntry entry } && entry.IsMissing)
            RemoveMissingEntries(new[] { entry });
    }

    private void DeleteSelectedMissingButton_Click(object sender, RoutedEventArgs e)
    {
        List<FileEntry> selected = EntriesList.SelectedItems
            .OfType<FileEntry>()
            .Where(entry => entry.IsMissing)
            .ToList();
        RemoveMissingEntries(selected);
    }

    private void EntriesList_KeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (FindAncestor<TextBox>(e.OriginalSource as DependencyObject) != null) return;

        if (e.Key == VirtualKey.Enter && EntriesList.SelectedItem is FileEntry selectedEntry)
        {
            e.Handled = true;
            BeginDescriptionEdit(selectedEntry);
            return;
        }

        if (e.Key != VirtualKey.Delete) return;
        List<FileEntry> selected = EntriesList.SelectedItems
            .OfType<FileEntry>()
            .Where(entry => entry.IsMissing)
            .ToList();
        if (selected.Count == 0) return;
        e.Handled = true;
        RemoveMissingEntries(selected);
    }

    private void BeginDescriptionEdit(FileEntry entry)
    {
        EntriesList.ScrollIntoView(entry);
        DispatcherQueue.TryEnqueue(() =>
        {
            if (EntriesList.ContainerFromItem(entry) is not ListViewItem container) return;
            TextBox descriptionBox = FindDescendant<TextBox>(container);
            if (descriptionBox == null) return;
            descriptionBox.Focus(FocusState.Keyboard);
            descriptionBox.SelectAll();
        });
    }

    private void RemoveMissingEntries(IEnumerable<FileEntry> items)
    {
        List<FileEntry> removable = items.Where(entry => entry.IsMissing).Distinct().ToList();
        if (removable.Count == 0)
        {
            StatusText.Text = "Select one or more MISSING rows first.";
            return;
        }
        foreach (FileEntry entry in removable)
        {
            entry.PropertyChanged -= Entry_PropertyChanged;
            entries.Remove(entry);
        }
        dirty = true;
        UpdateTitle();
        StatusText.Text = removable.Count == 1
            ? "The MISSING line was removed. Save to update DESCRIPT.ION."
            : removable.Count + " MISSING lines were removed. Save to update DESCRIPT.ION.";
    }

    private void SortButton_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button { Tag: string property }) return;
        if (sortProperty == property) sortAscending = !sortAscending;
        else
        {
            sortProperty = property;
            sortAscending = true;
        }

        IEnumerable<FileEntry> sorted = entries
            .OrderBy(entry => entry.IsMissing ? 2 : entry.IsDirectory ? 0 : 1)
            .ThenBy(entry => SortValue(entry, property), StringComparer.CurrentCultureIgnoreCase);
        if (!sortAscending)
        {
            sorted = entries
                .OrderBy(entry => entry.IsMissing ? 2 : entry.IsDirectory ? 0 : 1)
                .ThenByDescending(entry => SortValue(entry, property), StringComparer.CurrentCultureIgnoreCase);
        }
        ReplaceEntries(sorted.ToList());
        StatusText.Text = "Sorted by " + property + (sortAscending ? " ascending." : " descending.");
    }

    private static string SortValue(FileEntry entry, string property)
    {
        return property switch
        {
            "Type" => entry.Type,
            "Size" => entry.Size.HasValue ? entry.Size.Value.ToString("D20") : String.Empty,
            "Modified" => entry.Modified.HasValue ? entry.Modified.Value.Ticks.ToString("D20") : String.Empty,
            "Description" => entry.Description,
            "Status" => entry.Status,
            _ => entry.Name
        };
    }

    private void ReplaceEntries(IList<FileEntry> sorted)
    {
        entries.ReplaceAll(sorted);
    }

    private void DescriptionBox_GotFocus(object sender, RoutedEventArgs e)
    {
        if (sender is not TextBox { Tag: FileEntry entry }) return;
        if (ReferenceEquals(editingEntry, entry)) return;
        editingEntry = entry;
        descriptionBeforeEdit = entry.Description;
        dirtyBeforeEdit = dirty;
    }

    private void DescriptionBox_LostFocus(object sender, RoutedEventArgs e)
    {
        if (sender is TextBox { Tag: FileEntry entry } && ReferenceEquals(editingEntry, entry))
            EndDescriptionEdit();
    }

    private void DescriptionBox_KeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (sender is not TextBox { Tag: FileEntry entry } box) return;

        if (e.Key == VirtualKey.Escape)
        {
            e.Handled = true;
            if (ReferenceEquals(editingEntry, entry))
            {
                entry.Description = descriptionBeforeEdit;
                dirty = dirtyBeforeEdit;
                UpdateTitle();
            }
            EndDescriptionEdit();
            EntriesList.Focus(FocusState.Programmatic);
            StatusText.Text = "Edit cancelled; the previous description was restored.";
        }
        else if (e.Key == VirtualKey.Enter)
        {
            e.Handled = true;
            // The TwoWay binding has already copied the current text to FileEntry.
            EndDescriptionEdit();
            EntriesList.Focus(FocusState.Programmatic);
            StatusText.Text = "Description updated in memory. Press Save to write DESCRIPT.ION.";
        }
    }

    private void EndDescriptionEdit()
    {
        editingEntry = null;
        descriptionBeforeEdit = null;
    }

    private async void ColorSettingsButton_Click(object sender, RoutedEventArgs e)
    {
        TextBox rulesBox = new()
        {
            Text = ColorPreferences.Current.Rules,
            MinWidth = 620,
            TextWrapping = TextWrapping.Wrap,
            AcceptsReturn = false
        };
        StackPanel content = new() { Spacing = 10 };
        content.Children.Add(new TextBlock
        {
            Text = "Use the same ColorDir format as 4DOS and DES. Separate rules with semicolons.",
            TextWrapping = TextWrapping.Wrap
        });
        content.Children.Add(rulesBox);
        content.Children.Add(new TextBlock
        {
            Text = "dirs:bri mag; zip arj:bri blu; com exe:bri gre; bat:bri red; gif jpg png:yel; txt me now:gre",
            Opacity = 0.7,
            TextWrapping = TextWrapping.Wrap
        });

        ContentDialog dialog = CreateDialog(
            "Colors", content, "Apply", "Defaults", "Cancel");
        ContentDialogResult result = await dialog.ShowAsync();
        if (result == ContentDialogResult.None) return;

        ColorPreferences.Current.SetRules(result == ContentDialogResult.Secondary
            ? ColorPreferences.DefaultRules
            : rulesBox.Text);
        DataTemplate template = EntriesList.ItemTemplate;
        EntriesList.ItemTemplate = null;
        EntriesList.ItemTemplate = template;
        StatusText.Text = "Colors updated.";
    }

    private async void AssociateButton_Click(object sender, RoutedEventArgs e)
    {
        try
        {
            FileAssociation.Register(Environment.ProcessPath);
            await ShowMessageAsync("File association registered",
                ".ION files now open with Description Edit for Windows for the current user. Windows may ask you to confirm the default application.");
        }
        catch (Exception ex) { await ShowErrorAsync("Could not register the .ION association.", ex); }
    }

    private async void UnassociateButton_Click(object sender, RoutedEventArgs e)
    {
        try
        {
            FileAssociation.Unregister();
            await ShowMessageAsync("File association removed",
                "The program's .ION association was removed for the current user.");
        }
        catch (Exception ex) { await ShowErrorAsync("Could not remove the .ION association.", ex); }
    }

    private async void AboutButton_Click(object sender, RoutedEventArgs e)
    {
        await ShowMessageAsync("Description Edit for Windows",
            "Version 1.0.5\nModern WinUI 3 editor for Norton/4DOS DESCRIPT.ION files." +
            "\n\nBy Dag Erik Hagesæter / Retro Erik using Codex in VS Code\nhttps://www.youtube.com/@RetroErik");
    }

    private async void AppWindow_Closing(AppWindow sender, AppWindowClosingEventArgs args)
    {
        if (allowClose || !dirty) return;
        args.Cancel = true;
        if (await CanLeaveDocumentAsync())
        {
            allowClose = true;
            Close();
        }
    }

    private ContentDialog CreateDialog(string title, object content, string primary, string secondary, string close)
    {
        return new ContentDialog
        {
            XamlRoot = RootGrid.XamlRoot,
            Title = title,
            Content = content,
            PrimaryButtonText = primary ?? String.Empty,
            SecondaryButtonText = secondary ?? String.Empty,
            CloseButtonText = close ?? String.Empty,
            DefaultButton = ContentDialogButton.Primary
        };
    }

    private async Task ShowMessageAsync(string title, string message)
    {
        ContentDialog dialog = CreateDialog(title, message, "OK", null, null);
        await dialog.ShowAsync();
    }

    private async Task ShowErrorAsync(string message, Exception exception)
    {
        StatusText.Text = exception.Message;
        await ShowMessageAsync("Description Edit for Windows", message + "\n\n" + exception.Message);
    }

    private string EntrySummary()
    {
        int folders = entries.Count(entry => entry.IsDirectory && !entry.IsMissing);
        int files = entries.Count(entry => !entry.IsDirectory && !entry.IsMissing);
        int missing = entries.Count(entry => entry.IsMissing);
        return $"{folders} folders, {files} files, {missing} MISSING lines";
    }

    private void UpdateTitle()
    {
        Title = (dirty ? "● " : String.Empty) + "Description Edit for Windows" +
            (document == null ? String.Empty : " — " + document.DirectoryPath);
    }

    private void UpdateNavigationButtons()
    {
        BackButton.IsEnabled = backHistory.Count > 0;
        UpButton.IsEnabled = document != null && Directory.GetParent(document.DirectoryPath) != null;
    }

    private static T FindAncestor<T>(DependencyObject current) where T : DependencyObject
    {
        while (current != null)
        {
            if (current is T match) return match;
            current = VisualTreeHelper.GetParent(current);
        }
        return null;
    }

    private static T FindDescendant<T>(DependencyObject current) where T : DependencyObject
    {
        if (current == null) return null;
        int count = VisualTreeHelper.GetChildrenCount(current);
        for (int index = 0; index < count; index++)
        {
            DependencyObject child = VisualTreeHelper.GetChild(current, index);
            if (child is T match) return match;
            T nested = FindDescendant<T>(child);
            if (nested != null) return nested;
        }
        return null;
    }

    private void OnPropertyChanged(string propertyName)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }

}
