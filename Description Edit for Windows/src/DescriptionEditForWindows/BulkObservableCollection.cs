using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.ComponentModel;

namespace DescriptionEditForWindows;

internal sealed class BulkObservableCollection<T> : ObservableCollection<T>
{
    public void ReplaceAll(IEnumerable<T> replacement)
    {
        ArgumentNullException.ThrowIfNull(replacement);
        List<T> items = replacement.ToList();

        CheckReentrancy();
        Items.Clear();
        foreach (T item in items)
            Items.Add(item);

        OnPropertyChanged(new PropertyChangedEventArgs(nameof(Count)));
        OnPropertyChanged(new PropertyChangedEventArgs("Item[]"));
        OnCollectionChanged(new NotifyCollectionChangedEventArgs(
            NotifyCollectionChangedAction.Reset));
    }
}
