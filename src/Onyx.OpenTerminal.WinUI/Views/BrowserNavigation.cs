namespace Onyx.OpenTerminal.WinUI.Views;

public static class BrowserNavigation
{
    public static bool IsWebAddress(string address) =>
        Uri.TryCreate(address, UriKind.Absolute, out var uri) &&
        (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps);
}
