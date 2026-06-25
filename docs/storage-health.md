# Storage Health Alerts

`smartd-telegram` and `mdadm-telegram` are small wrappers around
`telegram-notify`.

## smartd

Use `smartd-telegram` as an alert executable from your smartd configuration. It
formats `SMARTD_DEVICE`, `SMARTD_FAILTYPE`, `SMARTD_FULLMESSAGE`, and
`SMARTD_MESSAGE` when smartd provides them.

Manual test:

```bash
smartd-telegram /dev/sda "SMART alert" "test message"
```

## mdadm

Configure mdadm to call:

```text
PROGRAM /usr/local/bin/mdadm-telegram
```

The wrapper suppresses routine lifecycle events and sends alerts for failures,
degraded arrays, missing spares, and confirmed device disappearance. A status
report can be scheduled with cron:

```cron
0 9 * * 1 /usr/local/bin/mdadm-telegram --status
```
