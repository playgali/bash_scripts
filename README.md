# bash_scripts

Portable Bash utilities for self-hosted sync, storage-health alerts, and small
automation glue.

The scripts in this repo started from practical home-lab workflows, but they are
written to be reusable on different hosts. Personal paths, rclone remote names,
Nextcloud users, container names, and Telegram credentials live in config files
or command-line flags instead of the scripts.

## Install

Install the scripts somewhere on your `PATH`:

```bash
sudo install -m 755 bin/* /usr/local/bin/
```

Every script supports `--help`:

```bash
rclone-state-sync --help
telegram-notify --help
```

## rclone-state-sync

Problem it solves: `rclone sync` is powerful, but it can feel too opaque when
you want a local-source-of-truth workflow with a visible record of what changed.
`rclone-state-sync` keeps a small state file locally and remotely, detects added,
updated, and deleted paths, then applies those changes to the remote.

Connection to other scripts: this is the standalone one-off sync tool. Use
`rclone-push-sync` when you want named jobs from a config file, and use
`rclone-managed-bisync` when both sides are allowed to change.

Usage:

```bash
rclone-state-sync <local-path> <rclone_remote:path>
rclone-state-sync <local-path> --create-state
```

Examples:

```bash
rclone-state-sync /srv/backups/photos gdrive:backups/photos
rclone-state-sync ./documents s3:archive/documents
rclone-state-sync /srv/backups/photos --create-state
```

Extras:

- `RCLONE_BIN` sets the rclone binary. Default: `rclone`.
- `RCLONE_STATE_SYNC_STATE_NAME` sets the state filename. Default:
  `rclone.state`.
- `RCLONE_STATE_SYNC_LOG_PREFIX` sets the log filename prefix.
- The command can delete destination files when they no longer exist locally.

## rclone-managed-bisync

Problem it solves: `rclone bisync` is useful when two locations can both change,
but scheduled bisync jobs need durable workdirs, logs, conflict policy, and
careful recovery when rclone marks a listing pair unusable. This script wraps
named bisync jobs with those operational guardrails.

Connection to other scripts: this is the two-way sync runner. It can call
post-sync hooks such as a Nextcloud `occ files:scan`; it does not require
Telegram, but you can pair it with `telegram-notify` from cron or systemd
failure handlers.

Usage:

```bash
rclone-managed-bisync [job-name|all]
```

Examples:

```bash
cp examples/rclone-managed-bisync.conf.example ~/.config/rclone-managed-bisync.conf
RCLONE_MANAGED_BISYNC_CONFIG=~/.config/rclone-managed-bisync.conf \
  rclone-managed-bisync photos
rclone-managed-bisync all
```

Extras:

- Config is Bash syntax; see `examples/rclone-managed-bisync.conf.example`.
- `JOB_<name>_LOCAL`, `JOB_<name>_REMOTE`, `JOB_<name>_WORKDIR`, and
  `JOB_<name>_LOGDIR` are required per job.
- `JOB_<name>_OPTS` adds job-specific rclone flags.
- `JOB_<name>_OWNER_GROUP` can repair local ownership after sync.
- `JOB_<name>_AFTER_SYNC` can run a hook after a successful job.
- `RCLONE_MANAGED_BISYNC_CONFIG` sets the config path.

## rclone-push-sync

Problem it solves: sometimes you do want plain `rclone sync`, but with repeatable
named jobs, shared defaults, and per-job logs. `rclone-push-sync` reads a config
file and runs local-to-remote sync jobs where local is the source of truth.

Connection to other scripts: this is the configured one-way counterpart to
`rclone-state-sync`. Use `rclone-managed-bisync` instead when remote-side
changes should be brought back locally.

Usage:

```bash
rclone-push-sync [job-name|all]
```

Examples:

```bash
cp examples/rclone-push-sync.conf.example ~/.config/rclone-push-sync.conf
RCLONE_PUSH_SYNC_CONFIG=~/.config/rclone-push-sync.conf rclone-push-sync photos
rclone-push-sync all
```

Extras:

- Config is Bash syntax; see `examples/rclone-push-sync.conf.example`.
- `JOB_<name>_LOCAL`, `JOB_<name>_REMOTE`, and `JOB_<name>_LOGDIR` define each
  job.
- `JOB_<name>_OPTS` adds job-specific rclone flags.
- This command can delete remote files absent from the local path.

## telegram-notify

Problem it solves: scripts and system services often need one reliable way to
send a short alert without each script knowing Telegram API details.
`telegram-notify` reads a private config file and sends a plain-text message.

Connection to other scripts: `smartd-telegram` and `mdadm-telegram` call this
script. The rclone scripts do not require it, but it is useful from cron,
systemd, or wrapper scripts that report sync failures.

Usage:

```bash
telegram-notify [message...]
```

Examples:

```bash
cp examples/telegram-notify.conf.example ~/.config/telegram-notify.conf
chmod 600 ~/.config/telegram-notify.conf
telegram-notify "Backup completed"
TELEGRAM_NOTIFY_PREFIX_HOST=false telegram-notify "Plain message"
```

Extras:

- `TELEGRAM_NOTIFY_CONFIG` sets the config path.
- `TELEGRAM_NOTIFY_PREFIX_HOST=false` disables the default hostname prefix.
- Keep the real config file out of Git.

Create a Telegram bot and get credentials:

1. In Telegram, open a chat with `@BotFather`.
2. Send `/newbot`.
3. Follow the prompts for a display name and a username ending in `bot`.
4. Copy the bot token BotFather gives you.
5. Start a chat with your new bot and send it any message.
6. Visit `https://api.telegram.org/bot<token>/getUpdates` in a browser.
7. Copy the numeric `chat.id` from the JSON response.
8. Put both values in your config:

```bash
BOT_TOKEN="123456:replace-with-real-token"
CHAT_ID="123456789"
```

For a group chat, add the bot to the group, send a message in the group, then
use `getUpdates`; group chat IDs are often negative numbers.

## smartd-telegram

Problem it solves: `smartd` provides disk-health alert details through
environment variables, but raw smartd messages are not always convenient to send
directly. `smartd-telegram` formats those variables into a readable alert and
passes it to `telegram-notify`.

Connection to other scripts: this depends on `telegram-notify` for delivery.
Use it alongside `mdadm-telegram` when a host has both SMART disk monitoring and
Linux software RAID.

Usage:

```bash
smartd-telegram [device] [alert-type] [details]
```

Examples:

```bash
smartd-telegram /dev/sda "SMART alert" "Reallocated sector count changed"
TELEGRAM_NOTIFY_BIN=/usr/local/bin/telegram-notify \
  smartd-telegram /dev/nvme0n1 "SMART alert" "Manual test"
```

Extras:

- `TELEGRAM_NOTIFY_BIN` sets the notify command. Default: `telegram-notify`.
- smartd-provided `SMARTD_DEVICE`, `SMARTD_FAILTYPE`, `SMARTD_FULLMESSAGE`, and
  `SMARTD_MESSAGE` are preferred over positional arguments.

## mdadm-telegram

Problem it solves: mdadm can call a program for every RAID event, including
routine rebuild progress. `mdadm-telegram` filters out noisy informational
events, confirms transient disappearance events, and sends actionable RAID
alerts or proof-of-life status reports.

Connection to other scripts: this depends on `telegram-notify` for delivery.
It complements `smartd-telegram`: SMART alerts tell you about disk health, while
mdadm alerts tell you about array health.

Usage:

```bash
mdadm-telegram <event> <md-device> [devices]
mdadm-telegram --status
```

Examples:

```bash
mdadm-telegram Fail /dev/md0 /dev/sdb1
mdadm-telegram DegradedArray /dev/md0 unknown
mdadm-telegram --status
```

Extras:

- `TELEGRAM_NOTIFY_BIN` sets the notify command. Default: `telegram-notify`.
- `MDADM_MDSTAT_FILE` sets the mdstat path. Default: `/proc/mdstat`.
- `MDADM_CONFIRM_DELAY` controls confirmation delay for `DeviceDisappeared`.
- `MDADM_RUNTIME_DIR` stores lock files for duplicate suppression.

## Documentation

- [Rclone state sync](docs/rclone-state-sync.md)
- [Managed rclone bisync](docs/rclone-managed-bisync.md)
- [Telegram alerts](docs/telegram-alerts.md)
- [Storage health alerts](docs/storage-health.md)

## License

This repository is free and open-source software licensed under the GNU General
Public License v3.0 or later (`GPL-3.0-or-later`). You can use, study, modify,
and redistribute it, and redistributed modified versions must remain under the
same license. See [LICENSE](LICENSE).
