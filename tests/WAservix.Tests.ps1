$modulePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'WAservix\WAservix.psd1'
Import-Module $modulePath -Force

Describe 'WAservix module' {
    It 'exports all 12 commands' {
        (Get-Command -Module WAservix).Count | Should Be 12
    }

    It 'manifest is valid' {
        { Test-ModuleManifest -Path $modulePath -ErrorAction Stop } | Should Not Throw
    }

    It 'every command has a synopsis' {
        foreach ($c in Get-Command -Module WAservix) {
            (Get-Help $c.Name).Synopsis | Should Not BeNullOrEmpty
        }
    }
}

Describe 'Test-WAservixWebhookSecret' {
    It 'accepts the matching secret' {
        Test-WAservixWebhookSecret -Signature 's3cret' -Secret 's3cret' | Should Be $true
    }
    It 'rejects a different secret' {
        Test-WAservixWebhookSecret -Signature 'wrong!' -Secret 's3cret' | Should Be $false
    }
    It 'rejects a missing header' {
        Test-WAservixWebhookSecret -Signature '' -Secret 's3cret' | Should Be $false
    }
}

Describe 'API calls' {
    It 'asks for a key when none is set' {
        $saved = $env:WASERVIX_API_KEY
        $env:WASERVIX_API_KEY = $null
        Remove-Module WAservix -Force
        Import-Module $modulePath -Force
        try { { Get-WAservixStatus } | Should Throw 'No WAservix API key' }
        finally { $env:WASERVIX_API_KEY = $saved }
    }

    It 'turns an invalid key into a clear 401 error from the live API' {
        Connect-WAservix -ApiKey 'invalid_pester_test_key'
        { Get-WAservixStatus } | Should Throw 'WAservix API error 401'
    }

    It 'supports -WhatIf for every kind of send without calling the API' {
        Connect-WAservix -ApiKey 'invalid_pester_test_key'
        { Send-WAservixMessage -To '+250788123456' -Text 'hi' -WhatIf } | Should Not Throw
        { Send-WAservixMessage -To '+250788123456' -ImageUrl 'https://example.com/a.png' -WhatIf } | Should Not Throw
        { Send-WAservixMessage -To '+250788123456' -DocumentUrl 'https://example.com/a.pdf' -FileName 'a.pdf' -WhatIf } | Should Not Throw
        { Send-WAservixMessage -To '+250788123456' -Latitude -1.9441 -Longitude 30.0619 -WhatIf } | Should Not Throw
    }
}
