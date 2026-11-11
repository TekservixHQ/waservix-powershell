#Requires -Version 5.1
Set-StrictMode -Version Latest

$script:WAservixBaseUrl = 'https://tekservix.com/waservix/api'
$script:WAservixApiKey = $null

function Connect-WAservix {
    <#
    .SYNOPSIS
    Sets the WAservix device API key used by the other WAservix commands in this session.
    .DESCRIPTION
    Each WhatsApp number has its own API key (it starts with wpk_). Find it in your Tekservix dashboard under
    WAservix > Devices > your number. You can also set the WASERVIX_API_KEY environment variable instead.
    No account yet? Start at https://tekservix.com/waservix
    .EXAMPLE
    Connect-WAservix -ApiKey $env:WASERVIX_API_KEY
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiKey,
        [string]$BaseUrl = 'https://tekservix.com/waservix/api'
    )
    $script:WAservixApiKey = $ApiKey
    $script:WAservixBaseUrl = $BaseUrl.TrimEnd('/')
}

function Invoke-WAservixApi {
    <#
    .SYNOPSIS
    Calls any WAservix API endpoint with your device key and returns the "data" part of the answer.
    .EXAMPLE
    Invoke-WAservixApi -Path '/status'
    .LINK
    https://tekservix.com/waservix/docs/
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')][string]$Method = 'GET',
        [object]$Body
    )
    $key = if ($script:WAservixApiKey) { $script:WAservixApiKey } else { $env:WASERVIX_API_KEY }
    if (-not $key) {
        throw 'No WAservix API key. Run Connect-WAservix -ApiKey <key> or set WASERVIX_API_KEY. Find the key at https://tekservix.com/waservix'
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $params = @{
        Uri         = $script:WAservixBaseUrl + '/' + $Path.TrimStart('/')
        Method      = $Method
        Headers     = @{ 'Authorization' = "Bearer $key"; 'Accept' = 'application/json' }
        ErrorAction = 'Stop'
    }
    if ($PSBoundParameters.ContainsKey('Body') -and $null -ne $Body) {
        $json = $Body | ConvertTo-Json -Depth 10 -Compress
        $params.Body = [Text.Encoding]::UTF8.GetBytes($json)
        $params.ContentType = 'application/json; charset=utf-8'
    }

    try {
        $response = Invoke-RestMethod @params
    }
    catch {
        $status = $null
        $message = $_.Exception.Message
        $raw = $null
        if ($_.Exception.PSObject.Properties['Response'] -and $_.Exception.Response) {
            try { $status = [int]$_.Exception.Response.StatusCode } catch { $status = $null }
            try {
                $stream = $_.Exception.Response.GetResponseStream()
                if ($stream) { $raw = (New-Object IO.StreamReader($stream)).ReadToEnd() }
            }
            catch { $raw = $null }
        }
        if (-not $raw -and $_.ErrorDetails -and $_.ErrorDetails.Message) { $raw = $_.ErrorDetails.Message }
        if ($raw) {
            try {
                $parsed = $raw | ConvertFrom-Json
                if ($parsed.PSObject.Properties['message'] -and $parsed.message) { $message = $parsed.message }
            }
            catch { $message = $raw }
        }
        $prefix = if ($status) { "WAservix API error $status" } else { 'WAservix API error' }
        throw "${prefix}: $message"
    }

    if ($null -ne $response -and $response.PSObject.Properties['data']) { return $response.data }
    return $response
}

function Send-WAservixMessage {
    <#
    .SYNOPSIS
    Sends a WhatsApp text, image, document or location from your number.
    .PARAMETER To
    Phone number in international format (+250788123456) or a group ID ending in @g.us.
    .PARAMETER Text
    The message text, or the caption for an image or document.
    .EXAMPLE
    Send-WAservixMessage -To '+250788123456' -Text 'Your order has shipped.'
    .EXAMPLE
    Send-WAservixMessage -To '+250788123456' -DocumentUrl 'https://example.com/invoice.pdf' -FileName 'Invoice-1042.pdf' -Text 'Your invoice'
    .EXAMPLE
    Send-WAservixMessage -To '+250788123456' -Latitude -1.9441 -Longitude 30.0619 -LocationName 'Our shop'
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Text')]
    param(
        [Parameter(Mandatory)][string]$To,
        [Parameter(Mandatory, ParameterSetName = 'Text')]
        [Parameter(ParameterSetName = 'Image')]
        [Parameter(ParameterSetName = 'Document')]
        [string]$Text,
        [Parameter(Mandatory, ParameterSetName = 'Image')][uri]$ImageUrl,
        [Parameter(Mandatory, ParameterSetName = 'Document')][uri]$DocumentUrl,
        [Parameter(ParameterSetName = 'Document')][string]$FileName,
        [Parameter(Mandatory, ParameterSetName = 'Location')][double]$Latitude,
        [Parameter(Mandatory, ParameterSetName = 'Location')][double]$Longitude,
        [Parameter(ParameterSetName = 'Location')][string]$LocationName
    )
    $body = @{ to = $To }
    switch ($PSCmdlet.ParameterSetName) {
        'Text' { $body.text = $Text }
        'Image' { $body.imageUrl = "$ImageUrl"; if ($Text) { $body.text = $Text } }
        'Document' {
            $body.documentUrl = "$DocumentUrl"
            if ($FileName) { $body.fileName = $FileName }
            if ($Text) { $body.text = $Text }
        }
        'Location' {
            $loc = @{ latitude = $Latitude; longitude = $Longitude }
            if ($LocationName) { $loc.name = $LocationName }
            $body.location = $loc
        }
    }
    if ($PSCmdlet.ShouldProcess($To, "Send WhatsApp $($PSCmdlet.ParameterSetName.ToLower())")) {
        Invoke-WAservixApi -Path '/send-message' -Method POST -Body $body
    }
}

function Get-WAservixMessageStatus {
    <#
    .SYNOPSIS
    Gets the status of a sent message: queued, sent, delivered, read, played or failed.
    .EXAMPLE
    Get-WAservixMessageStatus -MsgId 58213
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory, ValueFromPipelineByPropertyName)][string]$MsgId)
    process { Invoke-WAservixApi -Path "/messages/$([uri]::EscapeDataString($MsgId))/info" }
}

function Set-WAservixMessage {
    <#
    .SYNOPSIS
    Edits the text of a message you sent (WhatsApp allows about 15 minutes).
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$MsgId,
        [Parameter(Mandatory)][string]$Text
    )
    if ($PSCmdlet.ShouldProcess("message $MsgId", 'Edit')) {
        Invoke-WAservixApi -Path "/messages/$([uri]::EscapeDataString($MsgId))" -Method PUT -Body @{ text = $Text }
    }
}

function Remove-WAservixMessage {
    <#
    .SYNOPSIS
    Deletes a message you sent, for everyone.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param([Parameter(Mandatory, ValueFromPipelineByPropertyName)][string]$MsgId)
    process {
        if ($PSCmdlet.ShouldProcess("message $MsgId", 'Delete for everyone')) {
            Invoke-WAservixApi -Path "/messages/$([uri]::EscapeDataString($MsgId))" -Method DELETE
        }
    }
}

function Invoke-WAservixResend {
    <#
    .SYNOPSIS
    Queues a failed message to be sent again.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory, ValueFromPipelineByPropertyName)][string]$MsgId)
    process {
        if ($PSCmdlet.ShouldProcess("message $MsgId", 'Resend')) {
            Invoke-WAservixApi -Path "/messages/$([uri]::EscapeDataString($MsgId))/resend" -Method POST
        }
    }
}

function Test-WAservixNumber {
    <#
    .SYNOPSIS
    Checks whether a phone number has a WhatsApp account.
    .EXAMPLE
    (Test-WAservixNumber -Phone '+250788123456').exists
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory, ValueFromPipeline)][string]$Phone)
    process { Invoke-WAservixApi -Path "/on-whatsapp/$([uri]::EscapeDataString($Phone))" }
}

function Get-WAservixStatus {
    <#
    .SYNOPSIS
    Gets the connection status of your number: connected, connecting, need_scan, disconnected, logged_out or expired.
    #>
    [CmdletBinding()]
    param()
    Invoke-WAservixApi -Path '/status'
}

function Get-WAservixContact {
    <#
    .SYNOPSIS
    Lists the contacts of your WhatsApp number, or gets one by phone number.
    #>
    [CmdletBinding()]
    param([string]$Phone)
    if ($Phone) { return Invoke-WAservixApi -Path "/contacts/$([uri]::EscapeDataString($Phone))" }
    Invoke-WAservixApi -Path '/contacts'
}

function Get-WAservixGroup {
    <#
    .SYNOPSIS
    Lists the WhatsApp groups your number is in, or gets one group's details.
    .PARAMETER GroupId
    The group ID, ending in @g.us. It is sent as is: the WAservix API expects the "@" unencoded.
    #>
    [CmdletBinding()]
    param([string]$GroupId)
    if ($GroupId) { return Invoke-WAservixApi -Path "/groups/$($GroupId.Trim())/metadata" }
    Invoke-WAservixApi -Path '/groups'
}

function Test-WAservixWebhookSecret {
    <#
    .SYNOPSIS
    Checks the X-Webhook-Signature header of a WAservix webhook call against your number's webhook secret.
    .DESCRIPTION
    WAservix sends the secret itself in the header, so this is a constant-time string comparison.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Signature,
        [Parameter(Mandatory)][string]$Secret
    )
    if (-not $Signature -or $Signature.Length -ne $Secret.Length) { return $false }
    $diff = 0
    for ($i = 0; $i -lt $Secret.Length; $i++) { $diff = $diff -bor ([int][char]$Secret[$i] -bxor [int][char]$Signature[$i]) }
    return ($diff -eq 0)
}

Export-ModuleMember -Function Connect-WAservix, Invoke-WAservixApi, Send-WAservixMessage, Get-WAservixMessageStatus, Set-WAservixMessage, Remove-WAservixMessage, Invoke-WAservixResend, Test-WAservixNumber, Get-WAservixStatus, Get-WAservixContact, Get-WAservixGroup, Test-WAservixWebhookSecret
