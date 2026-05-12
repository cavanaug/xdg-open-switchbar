# xdg-open-switchbar

Linux equivalent of [Switchbar](https://switchbar.app/) — routes URLs to specific Brave Browser profiles by hostname rule, with an interactive profile picker for `promptSelection` rules.

When any application opens a URL, this script intercepts it, matches the URL against a JSON rules file, and dispatches to the correct Brave Browser profile via `--profile-directory`. URLs that match no rule fall through to the real `/usr/bin/xdg-open`.

## Requirements

- Python 3.6+ with `tkinter` (stdlib; `tkinter` is a separate package on some distros — e.g. `python3-tk` on Debian/Ubuntu)
- Brave Browser installed natively (`brave-browser` in `$PATH`) **or** via Flatpak (`com.brave.Browser`) — the script auto-detects which is available
- `~/.local/bin` appearing before `/usr/bin` in `$PATH` (standard on most modern Linux distros)

## Installation

### 1. Install the scripts

```bash
cp xdg-open ~/.local/bin/xdg-open
cp switchbar-prompt ~/.local/bin/switchbar-prompt
chmod +x ~/.local/bin/xdg-open ~/.local/bin/switchbar-prompt
```

Verify the shadow is active:

```bash
which xdg-open
# Should print: /home/<you>/.local/bin/xdg-open
```

If `~/.local/bin` is not first in your `$PATH`, add this to `~/.profile` or `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then log out and back in (or re-source the file) for GUI apps to pick it up.

### 2. Create the config directory

```bash
mkdir -p ~/.config/switchbar
```

### 3. Install and configure the rules file

Copy the bundled `switchbar-rules.json` to your config directory:

```bash
cp switchbar-rules.json ~/.config/switchbar/switchbar-rules.json
```

Then edit the `profiles` section to map the UUID profileIds to your actual Brave profile directory names. Find your profile directories with:

**Native install:**
```bash
ls ~/.config/brave/ | grep -E "^(Default|Profile)"
```

**Flatpak install:**
```bash
ls ~/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/ | grep -E "^(Default|Profile)"
```

Edit `~/.config/switchbar/switchbar-rules.json` and update the `profiles` object:

```json
{
  "profiles": {
    "3eb9aed1-fbe0-5f1a-96be-22558750d33f": "Default",
    "5060a893-157e-532a-9f4f-322fdcab2272": "HP",
    "default": "Default"
  },
  ...
}
```

The special `"default"` key sets the profile used when no rule matches an HTTP/HTTPS URL.

## Config File Format

The config follows the Switchbar v2 schema with added `profiles` and `default` top-level keys:

```json
{
  "version": 2,
  "profiles": {
    "<uuid-profileId>": "<brave-profile-directory-name>",
    "default": "<brave-profile-directory-name>"
  },
  "rules": [
    {
      "id": "<uuid>",
      "type": "profile",
      "appId": "COM.BRAVE.BROWSER",
      "profileId": "<uuid-profileId>",
      "valueType": "hostname",
      "value": "example.com"
    }
  ]
}
```

**Supported rule types:**

| `valueType` | `value` format | Example |
|---|---|---|
| `hostname` | Exact hostname or `*.domain` wildcard | `"hp.zoom.us"`, `"*.apps.cavanaughs.org"` |
| `url` | Regex matched against the full URL | `"https://github.com/login/device"`, `"file://.*"` |

**`actionType: "promptSelection"`** — instead of dispatching immediately, shows the `switchbar-prompt` GUI picker so the user can choose which profile to open the URL in.

Rules with `type: "app"` or unknown profileIds are silently skipped.

## Profile Picker (`switchbar-prompt`)

When a `promptSelection` rule matches, `xdg-open` launches `switchbar-prompt` — a tkinter-based GUI dialog showing a horizontal row of profile cards. Each card displays:

- Colored avatar circle with the profile initial
- Profile display name
- "Brave" browser label
- Keyboard shortcut (Ctrl+1, Ctrl+2, …)

Press **Escape** to cancel without opening anything.

Profile colors are read from Brave's `Local State` file. You can override colors by editing the `COLOR_OVERRIDES` dict in `xdg-open`'s `load_brave_profile_metadata()` function.

## Debug Logging

To see what the script is doing, set `XDG_SWITCHBAR_DEBUG=1`:

```bash
XDG_SWITCHBAR_DEBUG=1 xdg-open https://youtu.be/dQw4w9WgXcQ
tail ~/.local/share/xdg-open-switchbar/switchbar.log
```

The log records: timestamp, input URL, matched rule ID, resolved profile, and dispatched command.

## Uninstallation

```bash
rm ~/.local/bin/xdg-open ~/.local/bin/switchbar-prompt
```

The system reverts to using `/usr/bin/xdg-open` immediately.

## Error Handling

| Condition | Behavior |
|---|---|
| Config file missing | Falls through to real `xdg-open` |
| Config file malformed JSON | Falls through to real `xdg-open` |
| Unknown profileId in rule | Skips that rule, continues matching |
| `brave-browser` not found | Tries `flatpak run com.brave.Browser`; if neither found, falls through |
| Non-HTTP/HTTPS URL with no matching rule | Passes to real `xdg-open` |
| `switchbar-prompt` not found | Falls back to Brave's built-in profile picker |
| Unexpected exception | Falls through to real `xdg-open` |

## Out of Scope (MVP)

- `mailto:` and other non-HTTP URL schemes (unless a `url` rule explicitly matches)
- Multi-browser dispatch (non-Brave)
- `openInNewWindow` support
- Auto-discovery of Brave profile directories
- Package manager distribution

