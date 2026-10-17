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
    public void MainWindowDeclaresLeftNavigationWithHomeFirst()
    {
        var document = XDocument.Load(Path.Combine(AppContext.BaseDirectory, "MainWindow.xaml"));
        var window = Assert.IsType<XElement>(document.Root);
        XNamespace presentation = "http://schemas.microsoft.com/winfx/2006/xaml/presentation";
        XNamespace xaml = "http://schemas.microsoft.com/winfx/2006/xaml";

        Assert.Equal(presentation + "Window", window.Name);
        Assert.Equal(typeof(MainWindow).FullName, (string?)window.Attribute(xaml + "Class"));
        Assert.Equal("Onyx Open Terminal", (string?)window.Attribute("Title"));
        var navigation = Assert.Single(window.Descendants(presentation + "NavigationView"));
        Assert.Equal("Left", (string?)navigation.Attribute("PaneDisplayMode"));
        Assert.Equal("True", (string?)navigation.Attribute("IsPaneOpen"));
        Assert.Equal("True", (string?)navigation.Attribute("IsSettingsVisible"));
        var items = navigation.Element(presentation + "NavigationView.MenuItems")!;
        var home = items.Elements().First();
        Assert.Equal("Home", (string?)home.Attribute("Content"));
        Assert.Equal("Home", (string?)home.Attribute("AutomationProperties.Name"));
        Assert.Equal("Home", (string?)Assert.Single(home.Descendants(presentation + "SymbolIcon")).Attribute("Symbol"));
        var frame = Assert.Single(navigation.Descendants(presentation + "Frame"));
        Assert.Equal("False", (string?)frame.Attribute("IsNavigationStackEnabled"));
    }

    [Fact]
    public void HomePagePreservesTheCenteredWelcomeText()
    {
        var document = XDocument.Load(Path.Combine(AppContext.BaseDirectory, "HomePage.xaml"));
        XNamespace presentation = "http://schemas.microsoft.com/winfx/2006/xaml/presentation";
        var welcomeText = Assert.Single(document.Descendants(presentation + "TextBlock"));
        Assert.Equal("Onyx Open Terminal", (string?)welcomeText.Attribute("Text"));
        Assert.Equal("Center", (string?)welcomeText.Attribute("HorizontalAlignment"));
        Assert.Equal("Center", (string?)welcomeText.Attribute("VerticalAlignment"));
    }
}
