using System.Reflection;
using System.Threading;
using System.Windows;

namespace QuotaBubble;

public partial class App : Application
{
    private Mutex? _mutex;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        _mutex = new Mutex(true, "Local\\QuotaBubble.Windows.App", out var created);
        if (!created)
        {
            Shutdown();
            return;
        }

        var window = new MainWindow();
        MainWindow = window;
        window.Show();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        try { _mutex?.ReleaseMutex(); } catch (ApplicationException) { }
        _mutex?.Dispose();
        base.OnExit(e);
    }

    public static string Version =>
        Assembly.GetExecutingAssembly()
            .GetCustomAttribute<AssemblyInformationalVersionAttribute>()?
            .InformationalVersion.Split('+')[0] ?? "0.0.0";
}
