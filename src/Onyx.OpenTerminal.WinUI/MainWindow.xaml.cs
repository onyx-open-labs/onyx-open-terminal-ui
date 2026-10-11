using Microsoft.UI.Xaml;

namespace Onyx.OpenTerminal.WinUI;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        var version = typeof(MainWindow).Assembly
            .GetCustomAttributes(typeof(System.Reflection.AssemblyInformationalVersionAttribute), false)
            .OfType<System.Reflection.AssemblyInformationalVersionAttribute>()
            .Single().InformationalVersion.Split('+')[0];
        Title = $"Onyx Open Terminal {version}";
    }
}
