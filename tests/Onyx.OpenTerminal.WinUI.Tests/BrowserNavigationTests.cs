using Onyx.OpenTerminal.WinUI.Views;

namespace Onyx.OpenTerminal.WinUI.Tests;

public sealed class BrowserNavigationTests
{
    [Theory]
    [InlineData("https://www.google.com/", true)]
    [InlineData("http://localhost:8080/page", true)]
    [InlineData("HTTPS://example.com/path?q=1#section", true)]
    [InlineData("mailto:someone@example.com", false)]
    [InlineData("microsoft-edge:https://example.com", false)]
    [InlineData("file:///C:/example.html", false)]
    [InlineData("javascript:window.open('https://example.com')", false)]
    [InlineData("custom-app:launch", false)]
    [InlineData("/relative-path", false)]
    [InlineData("", false)]
    public void OnlyWebAddressesCanBeNavigated(string address, bool allowed)
    {
        Assert.Equal(allowed, BrowserNavigation.IsWebAddress(address));
    }
}
