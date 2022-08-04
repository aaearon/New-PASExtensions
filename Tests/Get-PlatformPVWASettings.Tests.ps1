BeforeAll {
    Import-Module $PSScriptRoot\..\New-PASExtensions\New-PASExtensions.psd1 -Force
}

Describe 'Get-PlatformPVWASettings' {
    It 'extracts the PVWA settings for a <PlatformType> out of an existing Policies.xml' {
        $PlatformSettings = Get-PlatformPVWASettings -PoliciesFile '.\Tests\Policies.xml' -PlatformId $PlatformId
        $PlatformSettingsXml = [xml]$PlatformSettings

        Select-Xml -Xml $PlatformSettingsXml -XPath "//$PlatformType[@ID='$PlatformId']" | Should -Be $true
    } -ForEach @(
        @{PlatformType = 'Usage'; PlatformId = 'INIFile' }
        @{PlatformType = 'Policy'; PlatformId = 'CyberArk' }
    )

    Context 'when getting the PVWA settings for a Policy' {
        It 'puts the PVWA settings as a child node to a policies node which is a child to a device node' {
            $PlatformSettings = Get-PlatformPVWASettings -PoliciesFile '.\Tests\Policies.xml' -PlatformId CyberArk
            $PlatformSettingsXml = [xml]$PlatformSettings

            Select-Xml -Xml $PlatformSettingsXml -XPath "//Device[@Name='Application']/Policies/Policy[@ID='CyberArk']" | Should -Be $true
        }
    }
}