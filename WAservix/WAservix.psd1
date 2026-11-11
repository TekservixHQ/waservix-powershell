@{
    RootModule           = 'WAservix.psm1'
    ModuleVersion        = '1.0.0'
    GUID                 = 'b3be9898-b2ea-4f03-9161-36c2ff3c5ed0'
    Author               = 'Tekservix'
    CompanyName          = 'Tekservix'
    Copyright            = '(c) 2026 Tekservix. MIT License.'
    Description          = 'PowerShell client for the WAservix WhatsApp API Gateway (formerly WApenda) by Tekservix: send WhatsApp API Gateway messages - texts, images, documents and locations from your own number, check delivery status, check numbers, list contacts and groups, and verify webhook calls. Requires a Tekservix account with WAservix and a device API key: https://tekservix.com/waservix'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    FunctionsToExport    = @(
        'Connect-WAservix', 'Invoke-WAservixApi', 'Send-WAservixMessage', 'Get-WAservixMessageStatus', 'Set-WAservixMessage',
        'Remove-WAservixMessage', 'Invoke-WAservixResend', 'Test-WAservixNumber', 'Get-WAservixStatus',
        'Get-WAservixContact', 'Get-WAservixGroup', 'Test-WAservixWebhookSecret'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @('WhatsApp', 'WhatsAppAPIGateway', 'APIGateway', 'WhatsAppAPI', 'Messaging', 'API', 'Tekservix', 'WAservix', 'WApenda', 'Notifications', 'PSEdition_Desktop', 'PSEdition_Core', 'Windows', 'Linux', 'MacOS')
            LicenseUri   = 'https://github.com/TekservixHQ/waservix-powershell/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/TekservixHQ/waservix-powershell'
            IconUri      = 'https://cdn.jsdelivr.net/gh/TekservixHQ/activepieces-piece-waservix@main/logo.png'
            ReleaseNotes = 'First release: send text, image, document and location; status, edit, delete, resend; number check; connection status; contacts; groups; webhook secret check.'
        }
    }
    HelpInfoURI          = 'https://tekservix.com/waservix/docs/'
}
