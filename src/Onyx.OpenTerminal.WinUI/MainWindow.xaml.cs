using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Onyx.OpenTerminal.WinUI.Views;

namespace Onyx.OpenTerminal.WinUI;

public sealed partial class MainWindow : Window
{
    private TerminalPage? terminalPage;
    private readonly TerminalSettings settings = new();
    private string? openedTerminalUrl;
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
        settings.Changed += (_, _) => UpdateTerminalAvailability();
        TerminalConfigurationTip.PlacementTarget = TerminalNavigationItem;
        NavigationView.PointerMoved += (_, args) =>
        {
            if (!TerminalNavigationItem.IsLoaded || TerminalNavigationItem.XamlRoot is null) return;
            TerminalConfigurationTip.XamlRoot = TerminalNavigationItem.XamlRoot;
            var position = args.GetCurrentPoint(TerminalNavigationItem).Position;
            TerminalConfigurationTip.IsOpen = !settings.IsConfigured &&
                position.X >= 0 && position.Y >= 0 &&
                position.X <= TerminalNavigationItem.ActualWidth &&
                position.Y <= TerminalNavigationItem.ActualHeight;
        };
        NavigationView.PointerExited += (_, _) => TerminalConfigurationTip.IsOpen = false;
        UpdateTerminalAvailability();
        NavigationView.SelectedItem = HomeNavigationItem;
        Closed += (_, _) =>
        {
            TerminalConfigurationTip.IsOpen = false;
            terminalPage?.Close();
        };
    }

    private void Navigation_SelectionChanged(
        NavigationView sender,
        NavigationViewSelectionChangedEventArgs args)
    {
        var isTerminal = ReferenceEquals(args.SelectedItem, TerminalNavigationItem);
        if (isTerminal && !settings.IsConfigured)
        {
            sender.SelectedItem = HomeNavigationItem;
            return;
        }
        ContentFrame.Visibility = isTerminal ? Visibility.Collapsed : Visibility.Visible;
        TerminalHost.Visibility = isTerminal ? Visibility.Visible : Visibility.Collapsed;
        BackButton.Visibility = ForwardButton.Visibility =
            isTerminal ? Visibility.Visible : Visibility.Collapsed;
        sender.AlwaysShowHeader = !isTerminal;
        if (isTerminal)
        {
            if (terminalPage is null || openedTerminalUrl != settings.TerminalUrl)
            {
                terminalPage?.Close();
                openedTerminalUrl = settings.TerminalUrl;
                terminalPage = new TerminalPage(settings.TerminalUrl);
                terminalPage.HistoryChanged += (_, _) => UpdateHistoryButtons();
                TerminalHost.Content = terminalPage;
            }
            sender.Header = null;
            UpdateHistoryButtons();
        }
        else if (args.IsSettingsSelected)
        {
            ContentFrame.Navigate(typeof(SettingsPage), settings);
            sender.Header = "Settings";
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

    private void UpdateTerminalAvailability()
    {
        TerminalNavigationItem.IsEnabled = settings.IsConfigured;
        TerminalConfigurationTip.IsOpen = false;
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetHelpText(TerminalNavigationItem,
            settings.IsConfigured ? string.Empty : "Configure a Terminal URL in Settings to enable Terminal View.");

        if (!settings.IsConfigured && terminalPage is not null)
        {
            terminalPage.Close();
            terminalPage = null;
            TerminalHost.Content = null;
            openedTerminalUrl = null;
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
