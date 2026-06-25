# Managed Rclone Bisync

`rclone-managed-bisync` runs named `rclone bisync` jobs from a Bash config file.
It keeps each job's workdir and logdir separate, detects unusable bisync state,
quarantines bad state, and retries once with `--resync` when the state markers
show that a clean resync is required.

```bash
RCLONE_MANAGED_BISYNC_CONFIG=~/.config/rclone-managed-bisync.conf \
  rclone-managed-bisync photos
```

Run every configured job:

```bash
rclone-managed-bisync all
```

Each job needs:

- `JOB_<name>_LOCAL`
- `JOB_<name>_REMOTE`
- `JOB_<name>_WORKDIR`
- `JOB_<name>_LOGDIR`

Optional settings include `JOB_<name>_OPTS`, `JOB_<name>_OWNER_GROUP`, and
`JOB_<name>_AFTER_SYNC`.

The `AFTER_SYNC` hook is deliberately generic. For Nextcloud, it can run `occ
files:scan`; for plain folders, leave it empty.
