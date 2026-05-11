# xdg-open-switchbar

Linux equivalent of [Switchbar](https://switchbar.app/) — routes URLs to specific Brave Browser profiles by hostname rule.

When any application opens a URL, this script intercepts it, matches the hostname against a JSON rules file, and dispatches the URL to the correct Brave Browser profile via `brave-browser --profile-directory`. URLs that match no rule fall through to the real `/usr/bin/xdg-open`.

## Requirements

- Python 3.6+ (stdlib only — no third-party packages)
- `brave-browser` in `$PATH`
- `~/.local/bin` appearing before `/usr/bin` in `$PATH` (standard on most modern Linux distros)

## Installation

### 1. Install the script

```bash
cp xdg-open ~/.local/bin/xdg-open
chmod +x ~/.local/bin/xdg-open
```

Verify it shadows the system binary:

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

```bash
ls ~/.config/brave/
# Example output: Default  Profile 1  Profile 2
```

Edit `~/.config/switchbar/switchbar-rules.json` and update the `profiles` object:

```json
{
  "profiles": {
    "3eb9aed1-fbe0-5f1a-96be-22558750d33f": "Default",
    "5060a893-157e-532a-9f4f-322fdcab2272": "Profile 1"
  },
  ...
}
```

Replace `"Default"` and `"Profile 1"` with the actual directory names for your personal and work profiles.

## Config File Format

The config follows the Switchbar v2 schema with an added `profiles` top-level key:

```json
{
  "version": 2,
  "profiles": {
    "<uuid-profileId>": "<brave-profile-directory-name>"
  },
  "rules": [
    {
      "id": "<uuid>",
      "type": "profile",
      "appId": "COM.BRAVE.BROWSER",
      "profileId": "<uuid-profileId>",
      "openInNewWindow": false,
      "valueType": "hostname",
      "value": "example.com"
    }
  ]
}
```

**Supported rule types:**
- `type: "profile"` with `valueType: "hostname"` — exact hostname match (e.g. `"hp.zoom.us"`) or wildcard prefix (e.g. `"*.apps.cavanaughs.org"`)
- `type: "profile"` with `valueType: "url"` — glob pattern match against the full URL

Rules with `type: "app"` or unknown profileIds are silently skipped.

## Debug Logging

To see what the script is doing, set `XDG_SWITCHBAR_DEBUG=1`:

```bash
XDG_SWITCHBAR_DEBUG=1 xdg-open https://youtu.be/dQw4w9WgXcQ
tail ~/.local/share/xdg-open-switchbar/switchbar.log
```

The log records: timestamp, input URL, matched rule ID, and dispatched command.

## Uninstallation

```bash
rm ~/.local/bin/xdg-open
```

The system reverts to using `/usr/bin/xdg-open` immediately.

## Error Handling

| Condition | Behavior |
|---|---|
| Config file missing | Falls through to real `xdg-open` |
| Config file malformed JSON | Falls through to real `xdg-open` |
| Unknown profileId in rule | Skips that rule, continues matching |
| `brave-browser` not found | Falls through to real `xdg-open` |
| Non-HTTP/HTTPS URL | Passes directly to real `xdg-open` |
| Unexpected exception | Falls through to real `xdg-open` |

## Out of Scope (MVP)

- `mailto:` and other non-HTTP URL schemes
- Multi-browser dispatch (non-Brave)
- Interactive profile chooser
- `openInNewWindow` support
- Auto-discovery of Brave profile directories
- Package manager distribution
