# Rclone State Sync

`rclone-state-sync` pushes local changes to a remote path while keeping a small
state file in the local directory and on the remote. It is useful when you want a
simple local-source-of-truth workflow with readable logs of detected additions,
updates, and deletions.

```bash
rclone-state-sync /srv/backups/photos gdrive:backups/photos
```

To bootstrap state from the current local directory without contacting a remote:

```bash
rclone-state-sync /srv/backups/photos --create-state
```

The script ignores its own state file and generated logs when building state.
Paths containing tabs or newlines are rejected because the state format is
tab-separated.

This command can delete destination files when they no longer exist locally.
Test with throwaway paths before using it on important data.
