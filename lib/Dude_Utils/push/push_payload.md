## Backend payload (promo)

You selected **device-token based** delivery and **OS notification payload** display.

Send via FCM HTTP v1 using:

- `notification.title`
- `notification.body`
- optional `data.screen` (string) for in-app routing on tap

Example:

```json
{
  "message": {
    "token": "<device_token>",
    "notification": {
      "title": "Dude Promo",
      "body": "Get 20% bonus coins today"
    },
    "data": {
      "screen": "wallet"
    },
    "android": {
      "notification": {
        "channel_id": "promo_channel"
      }
    },
    "apns": {
      "payload": {
        "aps": {
          "sound": "default"
        }
      }
    }
  }
}
```

