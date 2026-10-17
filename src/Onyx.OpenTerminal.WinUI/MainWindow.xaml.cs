using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Onyx.OpenTerminal.WinUI.Views;

namespace Onyx.OpenTerminal.WinUI;

public sealed partial class MainWindow : Window
{
    private TerminalPage? terminalPage;
    public NavigationView NavigationView
    {
        get { return NavigationViewControl; }
    }

    public MainWindow()
    {
        InitializeComponent();
        AppWindow.SetIcon(System.IO.Path.Combine(AppContext.BaseDirectory, "Assets", "Onyx.ico"));
        var version = typeof(MainWindow).Assembly
            .GetCustomAttributes(typeof(System.Reflection.AssemblyInformationalVersionAttribute), false)
            .OfType<System.Reflection.AssemblyInformationalVersionAttribute>()
            .Single().InformationalVersion.Split('+')[0];
        Title = $"Onyx Open Terminal {version}";
        NavigationView.SelectedItem = HomeNavigationItem;
        Closed += (_, _) => terminalPage?.Close();
    }

    private void Navigation_SelectionChanged(
        NavigationView sender,
        NavigationViewSelectionChangedEventArgs args)
    {
        var isTerminal = ReferenceEquals(args.SelectedItem, TerminalNavigationItem);
        ContentFrame.Visibility = isTerminal ? Visibility.Collapsed : Visibility.Visible;
        TerminalHost.Visibility = isTerminal ? Visibility.Visible : Visibility.Collapsed;
        BackButton.Visibility = ForwardButton.Visibility =
            isTerminal ? Visibility.Visible : Visibility.Collapsed;
        sender.AlwaysShowHeader = !isTerminal;
        if (isTerminal)
        {
            if (terminalPage is null)
            {
                terminalPage = new TerminalPage();
                terminalPage.HistoryChanged += (_, _) => UpdateHistoryButtons();
                TerminalHost.Content = terminalPage;
            }
            sender.Header = null;
            UpdateHistoryButtons();
        }
        else if (ReferenceEquals(args.SelectedItem, HomeNavigationItem))
        {
            if (ContentFrame.CurrentSourcePageType != typeof(HomePage))
            {
                ContentFrame.Navigate(typeof(HomePage));
            }

            sender.Header = "Home";
        }
    }

    private void UpdateHistoryButtons()
    {
        BackButton.IsEnabled = terminalPage?.CanGoBack == true;
        ForwardButton.IsEnabled = terminalPage?.CanGoForward == true;
    }

    private void Back_Click(object sender, RoutedEventArgs args) => terminalPage?.GoBack();
    private void Forward_Click(object sender, RoutedEventArgs args) => terminalPage?.GoForward();
    private void TogglePane_Click(object sender, RoutedEventArgs args) =>
        NavigationView.IsPaneOpen = !NavigationView.IsPaneOpen;
}
