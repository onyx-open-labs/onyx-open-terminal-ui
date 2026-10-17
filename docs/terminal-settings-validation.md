# Terminal settings (OOT-15)

Settings is available at the bottom of the navigation pane. The Terminal URL
defaults to `about:blank`. Empty and whitespace-only values are saved as
`about:blank`; HTTP and HTTPS URLs enable Terminal View. Settings are stored
per user in `%LOCALAPPDATA%/Onyx/OpenTerminal/settings.json`.

Saving a different URL replaces the embedded browser when Terminal View is next
opened. Switching between views without changing the URL retains the session.
Clearing the URL closes the retained browser and disables Terminal View.

## Desktop verification

1. With no saved settings, verify Terminal View is visible but disabled. Hover
   over its row with the pane expanded and collapsed and confirm the tooltip:
   “Configure a Terminal URL in Settings to enable Terminal View.”
2. Open Settings at the bottom; verify `about:blank`. Save an HTTPS URL, then
   open Terminal View and confirm the configured page loads.
3. Browse within Terminal View, visit Settings, and return without changing the
   URL. Confirm the existing browser session remains intact.
4. Save a different URL and reopen Terminal View. Confirm the new page loads.
5. Restart the app and verify the saved URL and enabled navigation persist.
6. Save whitespace or `about:blank`. Confirm Terminal View is disabled and its
   tooltip returns. Restart and confirm it remains disabled.
7. Try an invalid URL and verify an error appears without replacing the saved
   value. Make the settings location unwritable and verify a save error appears.
