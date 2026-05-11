# M001: xdg-open-switchbar — Core URL Routing

## Project Description

xdg-open-switchbar is a Python script that shadows `/usr/bin/xdg-open` at `~/.local/bin/xdg-open`. When any application opens a URL, the script intercepts it, matches the URL's hostname against a JSON rules file (derived from Switchbar's format), and dispatches the URL to the correct Brave Browser profile via `brave-browser --profile-directory`. URLs that match no rule fall through to the real `xdg-open`.

## Why This Milestone

Linux lacks a native equivalent of Switchbar — the Windows/macOS tool that routes URLs to specific browser profiles by rule. The user already maintains a `windows-switchbar-rules.json` with 28 routing rules across 3 Brave profiles, and wants to reuse that same routing logic on Linux without maintaining a separate config format or adopting any runtime beyond stdlib Python.

## User-Visible Outcome

- User places the script at `~/.local/bin/xdg-open` and it becomes the active URL handler for all desktop link clicks.
- User creates `~/.config/switchbar/switchbar-rules.json` (seeded from the existing `windows-switchbar-rules.json`) with an added `profiles` section that maps Switchbar UUID profileIds to Brave profile directory names.
- Clicking a link to `youtu.be` opens in the personal Brave profile; clicking an `s1.ariba.com` link opens in the work Brave profile — automatically, with no manual chooser.
- Unrecognized URLs open via the real `/usr/bin/xdg-open` as before.
- Running `XDG_SWITCHBAR_DEBUG=1 xdg-open https://example.com` prints which rule matched (or that no rule matched) to `~/.local/share/xdg-open-switchbar/switchbar.log`.

## Completion Class

Integration — the script must be installed and exercise the real `brave-browser` binary and real Brave profile directories to be considered done.

## Final Integrated Acceptance

1. Install the script; click a `youtu.be` link from a terminal or file manager — Brave opens in the correct profile.
2. Click an `s1.ariba.com` link — Brave opens in the work profile, not the personal one.
3. Click a URL for a hostname not in any rule — the system default handler opens it (e.g., Firefox or the configured browser).
4. Run with `XDG_SWITCHBAR_DEBUG=1`; confirm `switchbar.log` records the matched rule and target profile.
5. Remove the script from `~/.local/bin`; confirm system reverts to standard `xdg-open` behavior.

## Architectural Decisions

### Decision: Shadow via `~/.local/bin/xdg-open`
Deploy the script as `~/.local/bin/xdg-open`. This takes priority over `/usr/bin/xdg-open` when `~/.local/bin` appears first in `$PATH` (standard on most distros). No root required. Reverting is `rm ~/.local/bin/xdg-open`.

Alternatives considered: `/usr/local/bin` wrapper (requires root), `update-alternatives` (system-wide, invasive), shell alias (misses GUI app clicks).

### Decision: Reuse Switchbar JSON format natively
Config lives at `~/.config/switchbar/switchbar-rules.json` and follows the existing `windows-switchbar-rules.json` schema (version 2, `rules[]` array with `type`, `appId`, `profileId`, `valueType`, `value`). A `profiles` top-level key is added to map UUID profileIds to Brave profile directory names.

Alternatives considered: YAML/TOML custom format (migration friction, no reuse benefit).

### Decision: Config-based UUID → profile directory mapping
A `profiles` object in the config maps each Switchbar UUID `profileId` to a Brave profile directory string (e.g., `"Default"`, `"Profile 1"`). This is explicit, portable, and requires no filesystem scanning.

Alternatives considered: Auto-discover by scanning `~/.config/brave/*/Preferences` (fragile, order-sensitive).

### Decision: Brave launched via `brave-browser --profile-directory`
The script invokes `brave-browser --profile-directory="<dir>" <url>`. This is the documented Chromium-family mechanism for opening a URL in a specific profile.

### Decision: No-match falls through to real xdg-open
When no rule matches, the script `exec`s `/usr/bin/xdg-open` with the original arguments, preserving all default system behavior for non-browser URLs (PDFs, mailto, etc.) as well as unmatched web URLs.

### Decision: Debug logging behind `XDG_SWITCHBAR_DEBUG`
Log file at `~/.local/share/xdg-open-switchbar/switchbar.log`. Only written when `XDG_SWITCHBAR_DEBUG=1` is set. Logs: timestamp, input URL, matched rule ID (or "no match"), dispatched command.

## Error Handling Strategy

- **Config file missing:** fall through to real `xdg-open` and optionally log a warning under debug mode.
- **Config file malformed JSON:** fall through to real `xdg-open`; log parse error under debug mode.
- **Unknown profileId in rule:** skip rule, log warning under debug mode, continue matching.
- **`brave-browser` not found:** fall through to real `xdg-open`; log under debug mode.
- **Non-HTTP/HTTPS URLs:** pass directly to real `xdg-open` without attempting rule matching.

## Risks and Unknowns

- **`$PATH` ordering:** if the user's desktop session does not include `~/.local/bin` early in `$PATH`, the shadow will not activate. Installation instructions must verify this.
- **Brave profile directory names:** mapping UUIDs to directory names is manual; if the user adds a new Brave profile, the config must be updated.
- **`app` rule type:** the existing rules include `type: "app"` entries (not just `type: "profile"`). The MVP can ignore non-profile rules; this should be noted as out of scope.

## Existing Codebase / Prior Art

- `windows-switchbar-rules.json` — 28 existing rules, schema v2. Seeding source for the Linux config.
- No existing Python source. The script is net-new.

## Relevant Requirements

None formally defined yet. This milestone establishes the initial functional baseline.

## Scope

**In Scope:**
- Single Python script, stdlib only, no third-party dependencies.
- HTTP/HTTPS URL routing by hostname.
- Brave Browser profile dispatch via `--profile-directory`.
- Config at `~/.config/switchbar/switchbar-rules.json` with `profiles` mapping extension.
- No-match fallthrough to real `xdg-open`.
- Optional debug logging via `XDG_SWITCHBAR_DEBUG`.
- Installation instructions in README.

**Out of Scope:**
- Email (`mailto:`) handling.
- Multi-browser dispatch (non-Brave browsers).
- Interactive chooser/prompt UI.
- `type: "app"` rules (app-based routing, not profile-based).
- `openInNewWindow` support.
- GUI config editor.
- Auto-discovery of Brave profile directories.
- Package manager distribution (`.deb`, AUR, etc.).

**Non-Goals:**
- Parity with every Switchbar feature — only hostname-based profile routing for Brave.

## Technical Constraints

- Python 3.6+ (stdlib only — `json`, `os`, `sys`, `subprocess`, `urllib.parse`, `logging`).
- Must not import any third-party package.
- Script must be a single file for simple deployment.
- Must handle being called as `xdg-open <url>` exactly as the real binary is called.

## Integration Points

- **Brave Browser:** invoked via `brave-browser --profile-directory="<dir>" <url>`.
- **Real xdg-open:** `/usr/bin/xdg-open` — called for no-match fallthrough.
- **`~/.config/switchbar/switchbar-rules.json`:** user-managed config file.
- **`~/.local/share/xdg-open-switchbar/switchbar.log`:** optional debug log.

## Testing Requirements

- **Manual integration tests** against real Brave + real profile directories (unit tests alone cannot validate profile dispatch).
- **Unit-testable module:** URL → rule matching logic should be isolated as a pure function so it can be tested without launching a browser.
- Scenarios: exact hostname match, subdomain match (if supported), no-match fallthrough, missing config fallthrough, malformed config fallthrough.

## Acceptance Criteria

- `~/.local/bin/xdg-open https://youtu.be/abc` launches Brave with the personal profile directory.
- `~/.local/bin/xdg-open https://s1.ariba.com/path` launches Brave with the work profile directory.
- `~/.local/bin/xdg-open https://unknown-host.example` calls `/usr/bin/xdg-open https://unknown-host.example`.
- `~/.local/bin/xdg-open /path/to/file.pdf` calls `/usr/bin/xdg-open /path/to/file.pdf` (non-URL passthrough).
- With missing config, calls real `xdg-open` without crashing.
- `XDG_SWITCHBAR_DEBUG=1` produces a log entry for each invocation.
- Script passes `python3 -m py_compile` with no errors.
- No third-party imports.

## Open Questions

- **Subdomain matching:** should `hp.zoom.us` match only the exact hostname, or also `*.zoom.us`? Current rules have an explicit `hp.zoom.us` entry, suggesting exact match is sufficient for now — but worth confirming before implementation.
- **`app` rule type:** the existing JSON has some rules with `type: "app"` and empty `appId`/`profileId`. These should be silently ignored in MVP — confirm this is acceptable.
- **`openInNewWindow` field:** currently always `false` in the rules. No action needed for MVP unless the user wants this honored in future.
