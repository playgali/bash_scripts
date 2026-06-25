# Telegram Alerts

`telegram-notify` sends a plain-text message with the Telegram Bot API. It reads
`BOT_TOKEN` and `CHAT_ID` from a config file.

## Create A Bot

1. In Telegram, open a chat with `@BotFather`.
2. Send `/newbot`.
3. Follow the prompts for a display name and a username ending in `bot`.
4. Copy the bot token BotFather gives you.
5. Start a chat with your new bot and send it any message.
6. Visit `https://api.telegram.org/bot<token>/getUpdates` in a browser.
7. Copy the numeric `chat.id` from the JSON response.
8. Put both values in your config file.

For a group chat, add the bot to the group, send a message in the group, then
use `getUpdates`; group chat IDs are often negative numbers.

## Configure

```bash
cp examples/telegram-notify.conf.example ~/.config/telegram-notify.conf
chmod 600 ~/.config/telegram-notify.conf
telegram-notify "hello from $(hostname)"
```

By default, the current hostname is prepended to the message. Disable that with:

```bash
TELEGRAM_NOTIFY_PREFIX_HOST=false telegram-notify "plain message"
```

Keep the real config file out of Git. If a bot token is exposed, revoke it with
BotFather and create a replacement.
