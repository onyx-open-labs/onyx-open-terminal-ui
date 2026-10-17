namespace Onyx.OpenTerminal.WinUI.Tests;

public sealed class TerminalSettingsTests : IDisposable
{
    private readonly string directory = Path.Combine(Path.GetTempPath(), "OnyxSettingsTests", Guid.NewGuid().ToString("N"));
    private string SettingsPath => Path.Combine(directory, "settings.json");

    [Fact]
    public void FirstRunIsBlankAndDisabled()
    {
        var settings = new TerminalSettings(SettingsPath);
        Assert.Equal("about:blank", settings.TerminalUrl);
        Assert.False(settings.IsConfigured);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("about:blank")]
    public void ClearingSavedUrlDisablesTerminalAcrossRestarts(string value)
    {
        var settings = new TerminalSettings(SettingsPath);
        settings.Save("https://example.com");
        Assert.True(settings.IsConfigured);
        settings.Save(value);
        var reopened = new TerminalSettings(SettingsPath);
        Assert.False(reopened.IsConfigured);
        Assert.Equal("about:blank", reopened.TerminalUrl);
    }

    [Fact]
    public void SavedUrlPersistsAndNotifiesAfterWrite()
    {
        var settings = new TerminalSettings(SettingsPath);
        var notifications = 0;
        settings.Changed += (_, _) =>
        {
            notifications++;
            Assert.Equal(settings.TerminalUrl, new TerminalSettings(SettingsPath).TerminalUrl);
        };
        settings.Save("  https://example.com/terminal  ");
        Assert.Equal(1, notifications);
        Assert.True(settings.IsConfigured);
        Assert.Equal("https://example.com/terminal", new TerminalSettings(SettingsPath).TerminalUrl);
    }

    [Theory]
    [InlineData("javascript:alert(1)")]
    [InlineData("file:///C:/test")]
    [InlineData("invalid")]
    public void InvalidUrlDoesNotReplaceSavedValue(string value)
    {
        var settings = new TerminalSettings(SettingsPath);
        settings.Save("https://example.com");
        Assert.Throws<ArgumentException>(() => settings.Save(value));
        Assert.Equal("https://example.com", new TerminalSettings(SettingsPath).TerminalUrl);
    }

    [Fact]
    public void DamagedSettingsFallBackToBlank()
    {
        Directory.CreateDirectory(directory);
        File.WriteAllText(SettingsPath, "{broken");
        Assert.False(new TerminalSettings(SettingsPath).IsConfigured);
    }

    public void Dispose()
    {
        if (Directory.Exists(directory)) Directory.Delete(directory, true);
    }
}
