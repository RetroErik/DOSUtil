using Microsoft.UI.Xaml;

namespace DescriptionEditForWindows;

public partial class App : Application
{
    private Window window;

    public App()
    {
        InitializeComponent();
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        string[] commandLine = Environment.GetCommandLineArgs();
        string initialPath = commandLine.Length > 1 && !String.IsNullOrWhiteSpace(commandLine[1])
            ? commandLine[1]
            : Environment.CurrentDirectory;

        window = new MainWindow(initialPath);
        window.Activate();
    }
}
