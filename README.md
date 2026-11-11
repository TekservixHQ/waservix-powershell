# WAservix PowerShell module

Send WhatsApp messages from your own number in PowerShell, with [WAservix](https://tekservix.com/waservix) (formerly WApenda) by Tekservix.

**You need a Tekservix account with WAservix and a WhatsApp number connected in the dashboard.** The module is a client of the public WAservix API; your plan, limits and numbers are managed in your WAservix dashboard. [Create an account](https://tekservix.com/waservix) · [API docs](https://tekservix.com/waservix/docs/)

Works on Windows PowerShell 5.1 and PowerShell 7+ (Windows, Linux, macOS).

## Install

```powershell
Install-Module WAservix -Scope CurrentUser
```

## Connect

Each WhatsApp number has its own API key (it starts with `wpk_`). Copy it from **WAservix → Devices → your number**, then:

```powershell
Connect-WAservix -ApiKey 'wpk_your_device_key'
# or set it once for scripts:
$env:WASERVIX_API_KEY = 'wpk_your_device_key'
```

## Examples

```powershell
# Text, image, document, location
Send-WAservixMessage -To '+250788123456' -Text 'Your order #1042 has shipped.'
Send-WAservixMessage -To '+250788123456' -ImageUrl 'https://example.com/catalogue.jpg' -Text 'New arrivals'
Send-WAservixMessage -To '+250788123456' -DocumentUrl 'https://example.com/inv-1042.pdf' -FileName 'Invoice-1042.pdf' -Text 'Your invoice'
Send-WAservixMessage -To '+250788123456' -Latitude -1.9441 -Longitude 30.0619 -LocationName 'Our shop'

# Message to a group
Get-WAservixGroup | Select-Object id, subject
Send-WAservixMessage -To '120363000000000000@g.us' -Text 'Weekly offers are live.'

# Status, edit, delete, resend
$sent = Send-WAservixMessage -To '+250788123456' -Text 'Hello'
Get-WAservixMessageStatus -MsgId $sent.msgId
Set-WAservixMessage -MsgId $sent.msgId -Text 'Hello again'
Remove-WAservixMessage -MsgId $sent.msgId
Invoke-WAservixResend -MsgId 58190

# Checks
(Test-WAservixNumber -Phone '+250788123456').exists
(Get-WAservixStatus).status

# Contacts
Get-WAservixContact
Get-WAservixContact -Phone '+250788123456'

# Webhook calls (WAservix sends your number's webhook secret in X-Webhook-Signature)
Test-WAservixWebhookSecret -Signature $headers['X-Webhook-Signature'] -Secret $env:WASERVIX_WEBHOOK_SECRET

# Anything else in the API
Invoke-WAservixApi -Path '/user'
```

Commands that send or change something support `-WhatIf` and `-Confirm`.

## Commands

| Command | What it does |
| --- | --- |
| `Connect-WAservix` | Sets the device API key for the session |
| `Send-WAservixMessage` | Text, image, document or location to a number or group |
| `Get-WAservixMessageStatus` | Queued, sent, delivered, read, played or failed |
| `Set-WAservixMessage` | Edits a sent text (about 15 minutes) |
| `Remove-WAservixMessage` | Deletes a message for everyone |
| `Invoke-WAservixResend` | Sends a failed message again |
| `Test-WAservixNumber` | Does this number have WhatsApp? |
| `Get-WAservixStatus` | Connection status of your number |
| `Get-WAservixContact` | Contacts of your number |
| `Get-WAservixGroup` | Groups, members and settings |
| `Test-WAservixWebhookSecret` | Verifies a webhook call |
| `Invoke-WAservixApi` | Any other API endpoint |

## Other WAservix integrations

[npm](https://www.npmjs.com/package/waservix) · [PyPI](https://pypi.org/project/waservix/) · [n8n](https://www.npmjs.com/package/n8n-nodes-waservix) · [Node-RED](https://flows.nodered.org/node/node-red-contrib-waservix) · [Activepieces](https://www.npmjs.com/package/activepieces-piece-waservix) · [All docs](https://tekservix.com/waservix/docs/)

## Support

support@tekservix.com · [tekservix.com](https://tekservix.com) · MIT licensed.
