# Terminal Session (OOT-13)

Select Terminal Session to open Google inside the application. The page has no
header and fills the content area. Back and Forward sit before the navigation
pane toggle and are hidden on Home. Switching to Home preserves the browser
instance, website and history for the current application session.

New-window and new-tab requests navigate the existing WebView. HTTP and HTTPS
destinations are supported; external protocol handlers are cancelled so they
cannot launch a browser or another application. Browser popups requiring a
separate window/opener are not supported by this single-WebView story.

Microsoft Edge WebView2 Runtime is required. Initialization and navigation
failures show an error with Retry. Initialization retry recreates the browser;
navigation retry uses the failed destination.

## Manual checks

- Launch: Home is first, selected, and shows the welcome page.
- Select Terminal Session: Google loads with a loading indicator, without a
  page header. Resize the window and toggle the pane; content fills the canvas.
- Follow several links, then use Back and Forward with mouse and keyboard.
  Confirm disabled states at either end of history.
- Switch to Home: history buttons disappear. Return: website and history remain.
- Using a test website, exercise ordinary links, target="_blank" links and
  window.open calls. Confirm all web destinations stay in the existing WebView.
- Exercise mailto:, microsoft-edge: and a custom protocol from the page and an
  iframe. Confirm no external application launches.
- Disconnect the network and navigate to an uncached site. Confirm loading ends,
  an error appears, and Retry recovers after restoring connectivity.
- Test on a machine without WebView2 Runtime. Confirm initialization failure is
  recoverable with Retry after installing the runtime.
- Close during initial loading and after switching pages; confirm clean exit.

Automated tests cover shell declarations and the web-address navigation policy.
They do not substitute for these interactive WebView checks.
