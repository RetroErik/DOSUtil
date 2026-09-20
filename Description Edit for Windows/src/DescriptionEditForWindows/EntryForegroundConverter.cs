using DescriptionEditForWindows.Core;
using Microsoft.UI.Xaml.Data;

namespace DescriptionEditForWindows;

public sealed class EntryForegroundConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, string language)
    {
        return ColorPreferences.Current.BrushFor(value as FileEntry);
    }

    public object ConvertBack(object value, Type targetType, object parameter, string language)
    {
        throw new NotSupportedException();
    }
}
