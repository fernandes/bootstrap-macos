# Bootstrap macOS

Idempotent bootstrap script to configure a MacBook from scratch.

## Requirements

- macOS
- Ruby 2.6+ (comes with macOS)

## Configuration

The bootstrap script requires a `config.yml` file with your personal settings. You have two options:

### Option A: Local Configuration File

Copy the example file and customize it:

```bash
cp config.example.yml config.yml
# Edit config.yml with your settings
./bin/bootstrap
```

### Option B: Download from URL (Gist)

Set the `BOOTSTRAP_CONFIG_URL` environment variable to automatically download the configuration:

```bash
BOOTSTRAP_CONFIG_URL="https://gist.githubusercontent.com/user/id/raw/config.yml" ./bin/bootstrap
```

This is useful for quickly bootstrapping a new machine without manually creating the config file.

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
| Dock | Clears persistent apps, sets size, disables animations |
| Finder | Configures Finder preferences and dialogs |
| Screenshots | Disables shadow, sets location to ~/Screenshots |
| Safari | Shows full URL in address bar |
| ActivityMonitor | Sets update frequency to 2 seconds |
| Wallpaper | Sets solid color wallpaper (Blue Violet) |
| MenuBar | Hides Spotlight icon from menu bar |
| Sound | Configures alert sound, disables UI sounds |
| Keyboard | Sets key repeat, enables keyboard navigation |
| Trackpad | Enables tap to click, App Expose gesture |
| Bitwarden | Installs CLI and configures server URL |

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
