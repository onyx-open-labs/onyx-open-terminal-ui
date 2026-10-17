using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Navigation;

namespace Onyx.OpenTerminal.WinUI.Views;

public sealed partial class SettingsPage : Page
{
    private TerminalSettings settings = null!;

    public SettingsPage() => InitializeComponent();

    private void SettingsViewport_SizeChanged(object sender, SizeChangedEventArgs args)
    {
        // Use the available content viewport, including when Snap or the navigation pane changes it.
        var availableWidth = Math.Max(0, args.NewSize.Width -
            SettingsLayout.Margin.Left - SettingsLayout.Margin.Right);
        SettingsLayout.Width = Math.Min(SettingsLayout.MaxWidth, availableWidth);
        VisualStateManager.GoToState(this, availableWidth >= 900 ? "Wide" : "Compact", false);
    }

    protected override void OnNavigatedTo(NavigationEventArgs args)
    {
        base.OnNavigatedTo(args);
        settings = (TerminalSettings)args.Parameter;
        TerminalUrlBox.Text = settings.TerminalUrl;
    }

    private void Save_Click(object sender, RoutedEventArgs args)
    {
        try
        {
            settings.Save(TerminalUrlBox.Text);
            TerminalUrlBox.Text = settings.TerminalUrl;
            SaveResult.Severity = InfoBarSeverity.Success;
            SaveResult.Message = "Terminal URL saved.";
        }
        catch (Exception exception) when (exception is ArgumentException or IOException or UnauthorizedAccessException)
        {
            SaveResult.Severity = InfoBarSeverity.Error;
            SaveResult.Message = exception is ArgumentException
                ? "Enter an http:// or https:// URL, or about:blank."
                : "The Terminal URL could not be saved. Check access to your local settings and try again.";
        }
        SaveResult.IsOpen = true;
    }
}
