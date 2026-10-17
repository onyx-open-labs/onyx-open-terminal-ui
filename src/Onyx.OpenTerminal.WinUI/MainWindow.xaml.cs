using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Onyx.OpenTerminal.WinUI.Views;

namespace Onyx.OpenTerminal.WinUI;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        AppWindow.SetIcon(System.IO.Path.Combine(AppContext.BaseDirectory, "Assets", "Onyx.ico"));
        var version = typeof(MainWindow).Assembly
            .GetCustomAttributes(typeof(System.Reflection.AssemblyInformationalVersionAttribute), false)
            .OfType<System.Reflection.AssemblyInformationalVersionAttribute>()
            .Single().InformationalVersion.Split('+')[0];
        Title = $"Onyx Open Terminal {version}";
        Navigation.SelectedItem = HomeNavigationItem;
    }

    private void Navigation_SelectionChanged(
        NavigationView sender,
        NavigationViewSelectionChangedEventArgs args)
    {
        if (args.SelectedItem == HomeNavigationItem)
        {
            if (ContentFrame.CurrentSourcePageType != typeof(HomePage))
            {
                ContentFrame.Navigate(typeof(HomePage));
            }

            sender.Header = "Home";
        }
    }
}
