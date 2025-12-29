# Bootstrap macOS

Idempotent bootstrap script to configure a MacBook from scratch.

## Requirements

- macOS
- Ruby 2.6+ (comes with macOS)

## Usage

```bash
./bin/bootstrap
```

## Steps

| Step | Description |
|------|-------------|
| Xcode | Installs Xcode Command Line Tools |
| Homebrew | Installs and configures Homebrew |
| Display | Sets display resolution to 2304x1440 |
| ModifierKeys | Swaps Caps Lock and Left Control |
| Dock | Clears persistent apps, sets small size |
| Finder | Configures Finder preferences |
| ClaudeCode | Installs Claude Code via Homebrew |

## Running Tests

```bash
rake test
```

## Manual Configuration Required

Some settings cannot be automated via command line and must be configured manually:

### Finder Sidebar

Open **Finder > Settings > Sidebar** and uncheck:
- Recents
- Shared (under Locations)
