using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.Web.WebView2.Core;

namespace Onyx.OpenTerminal.WinUI.Views;

public sealed partial class TerminalPage : Page
{
    private WebView2? browser;
    private bool initializing;
    private bool closed;
    private string retryAddress = "https://www.google.com/";
    private ulong navigationId;

    public event EventHandler? HistoryChanged;
    public bool CanGoBack => browser?.CoreWebView2?.CanGoBack == true;
    public bool CanGoForward => browser?.CoreWebView2?.CanGoForward == true;

    public TerminalPage()
    {
        InitializeComponent();
        // Visual Studio's design-time XAML stub can omit the generated connector
        // assignments. Resolve the loaded names explicitly for that compilation too.
        LoadingIndicator = (ProgressBar)FindName(nameof(LoadingIndicator));
        NavigationError = (InfoBar)FindName(nameof(NavigationError));
        BrowserHost = (Grid)FindName(nameof(BrowserHost));
    }

    private async void Page_Loaded(object sender, RoutedEventArgs args)
    {
        if (browser is null && !initializing && !NavigationError.IsOpen)
        {
            await InitializeBrowserAsync();
        }
    }

    private async Task InitializeBrowserAsync()
    {
        if (initializing || closed) return;
        initializing = true;
        SetLoading(true);
        NavigationError.IsOpen = false;
        try
        {
            var candidate = new WebView2();
            browser = candidate;
            BrowserHost.Children.Add(candidate);
            await candidate.EnsureCoreWebView2Async();
            if (closed) return;
            var core = candidate.CoreWebView2;
            core.NewWindowRequested += NewWindowRequested;
            // Prevent OS protocol handlers from escaping the application, including in frames.
            core.LaunchingExternalUriScheme += (_, args) => args.Cancel = true;
            core.NavigationStarting += NavigationStarting;
            core.NavigationCompleted += NavigationCompleted;
            core.HistoryChanged += (_, _) => HistoryChanged?.Invoke(this, EventArgs.Empty);
            core.ProcessFailed += (_, _) => ShowError("The browser stopped responding. Select Retry to recover.", true);
            core.Navigate(retryAddress);
        }
        catch (Exception)
        {
            if (!closed) ShowError("The embedded browser could not start. Check that Microsoft Edge WebView2 Runtime is installed, then select Retry.", true);
        }
        finally
        {
            initializing = false;
        }
    }

    private void NewWindowRequested(CoreWebView2 sender, CoreWebView2NewWindowRequestedEventArgs args)
    {
        args.Handled = true;
        if (BrowserNavigation.IsWebAddress(args.Uri))
        {
            // Dispatch after handling the popup so the existing WebView owns the navigation.
            var address = args.Uri;
            DispatcherQueue.TryEnqueue(() =>
            {
                if (!closed && browser?.CoreWebView2 == sender) sender.Navigate(address);
            });
        }
    }

    private void NavigationStarting(CoreWebView2 sender, CoreWebView2NavigationStartingEventArgs args)
    {
        if (!BrowserNavigation.IsWebAddress(args.Uri))
        {
            args.Cancel = true;
            return;
        }
        navigationId = args.NavigationId;
        retryAddress = args.Uri;
        NavigationError.IsOpen = false;
        SetLoading(true);
    }

    private void NavigationCompleted(CoreWebView2 sender, CoreWebView2NavigationCompletedEventArgs args)
    {
        if (args.NavigationId != navigationId) return;
        SetLoading(false);
        if (!args.IsSuccess && args.WebErrorStatus != CoreWebView2WebErrorStatus.OperationCanceled)
        {
            ShowError("The website could not be loaded. Check your connection and select Retry.", false);
        }
        HistoryChanged?.Invoke(this, EventArgs.Empty);
    }

    private void ShowError(string message, bool resetBrowser)
    {
        SetLoading(false);
        NavigationError.Message = message;
        NavigationError.IsOpen = true;
        if (resetBrowser)
        {
            browser?.Close();
            BrowserHost.Children.Clear();
            browser = null;
        }
        HistoryChanged?.Invoke(this, EventArgs.Empty);
    }

    private void SetLoading(bool loading)
    {
        LoadingIndicator.IsIndeterminate = loading;
        LoadingIndicator.Visibility = loading ? Visibility.Visible : Visibility.Collapsed;
    }

    private async void Retry_Click(object sender, RoutedEventArgs args)
    {
        if (closed || initializing) return;
        if (browser?.CoreWebView2 is { } core)
        {
            NavigationError.IsOpen = false;
            core.Navigate(retryAddress);
        }
        else await InitializeBrowserAsync();
    }

    public void GoBack()
    {
        if (CanGoBack) browser!.CoreWebView2.GoBack();
    }

    public void GoForward()
    {
        if (CanGoForward) browser!.CoreWebView2.GoForward();
    }

    public void Close()
    {
        closed = true;
        browser?.Close();
    }
}
