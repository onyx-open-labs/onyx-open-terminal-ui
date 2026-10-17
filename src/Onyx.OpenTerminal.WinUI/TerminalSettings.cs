using System.Text.Json;
using Onyx.OpenTerminal.WinUI.Views;

namespace Onyx.OpenTerminal.WinUI;

public sealed class TerminalSettings
{
    public const string DefaultUrl = "about:blank";
    private readonly string filePath;
    public string TerminalUrl { get; private set; } = DefaultUrl;
    public bool IsConfigured => BrowserNavigation.IsWebAddress(TerminalUrl);
    public event EventHandler? Changed;

    public TerminalSettings(string? filePath = null)
    {
        this.filePath = filePath ?? Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Onyx", "OpenTerminal", "settings.json");
        try
        {
            if (File.Exists(this.filePath))
            {
                var saved = JsonSerializer.Deserialize<Dictionary<string, string>>(File.ReadAllText(this.filePath));
                var value = saved?.GetValueOrDefault(nameof(TerminalUrl));
                if (TryNormalize(value, out var normalized)) TerminalUrl = normalized;
            }
        }
        catch (Exception exception) when (exception is IOException or UnauthorizedAccessException or JsonException)
        {
            // Missing, unreadable or damaged settings leave the terminal safely disabled.
        }
    }

    public static bool TryNormalize(string? value, out string normalized)
    {
        normalized = string.IsNullOrWhiteSpace(value) ? DefaultUrl : value.Trim();
        if (string.Equals(normalized, DefaultUrl, StringComparison.OrdinalIgnoreCase))
        {
            normalized = DefaultUrl;
            return true;
        }
        return BrowserNavigation.IsWebAddress(normalized);
    }

    public void Save(string? value)
    {
        if (!TryNormalize(value, out var normalized))
            throw new ArgumentException("Enter an http:// or https:// URL, or about:blank.", nameof(value));
        Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(filePath))!);
        var temporaryPath = filePath + ".tmp";
        File.WriteAllText(temporaryPath, JsonSerializer.Serialize(
            new Dictionary<string, string> { [nameof(TerminalUrl)] = normalized }));
        File.Move(temporaryPath, filePath, true);
        TerminalUrl = normalized;
        Changed?.Invoke(this, EventArgs.Empty);
    }
}
