using System.Xml.Linq;
using Microsoft.UI.Xaml;
using Onyx.OpenTerminal.WinUI;

namespace Onyx.OpenTerminal.WinUI.Tests;

public sealed class MainWindowTests
{
    [Fact]
    public void MainWindowIsAWinUIWindow()
    {
        Assert.True(typeof(Window).IsAssignableFrom(typeof(MainWindow)));
    }

    [Fact]
    public void MainWindowDeclaresTheTerminalTitleAndCenteredWelcomeText()
    {
        var document = XDocument.Load(Path.Combine(AppContext.BaseDirectory, "MainWindow.xaml"));
        var window = Assert.IsType<XElement>(document.Root);
        XNamespace presentation = "http://schemas.microsoft.com/winfx/2006/xaml/presentation";
        XNamespace xaml = "http://schemas.microsoft.com/winfx/2006/xaml";

        Assert.Equal(presentation + "Window", window.Name);
        Assert.Equal(typeof(MainWindow).FullName, (string?)window.Attribute(xaml + "Class"));
        Assert.Equal("Onyx Open Terminal", (string?)window.Attribute("Title"));
        var welcomeText = Assert.Single(window.Descendants(presentation + "TextBlock"));
        Assert.Equal("Onyx Open Terminal", (string?)welcomeText.Attribute("Text"));
        Assert.Equal("Center", (string?)welcomeText.Attribute("HorizontalAlignment"));
        Assert.Equal("Center", (string?)welcomeText.Attribute("VerticalAlignment"));
    }
}
