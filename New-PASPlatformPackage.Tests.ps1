BeforeAll {
    . .\New-PASPlatformPackage.ps1


}

Describe 'New-PASPlatformPackage' {
    BeforeAll {
        $PlatformId = 'SamplePlatform'
        $CreatedArchivePath = Join-Path -Path $TestDrive -ChildPath "$PlatformId.zip"
        $ExpandedArchivePath = Join-Path -Path $TestDrive -ChildPath $PlatformId

        Out-File -Path (Join-Path -Path $TestDrive -ChildPath "my-platforms-cpm-settings.ini") -Force
        Out-File -Path (Join-Path -Path $TestDrive -ChildPath "my-platforms-pvwa-settings.xml") -Force

        $BuildDirectory = Join-Path -Path $TestDrive -ChildPath 'Build'
        New-Item -Path $BuildDirectory -ItemType Directory
        Out-File -Path (Join-Path -Path $BuildDirectory -ChildPath 'Prompts.ini') -Force
        Out-File -Path (Join-Path -Path $BuildDirectory -ChildPath 'Processes.ini') -Force

        Get-ChildItem -Path $BuildDirectory `
        | New-PASPlatformPackage -PlatformId $PlatformId `
        -CPMPolicyFile (Join-Path -Path $TestDrive -ChildPath "my-platforms-cpm-settings.ini") `
        -PVWASettingsFile (Join-Path -Path $TestDrive -ChildPath "my-platforms-pvwa-settings.xml") `
        -DestinationPath "$TestDrive"

        Expand-Archive $CreatedArchivePath -DestinationPath $ExpandedArchivePath
    }
    Context 'when creating the package' {
        It 'accepts the plug-in files from the pipeline' {
            Test-Path -Path "$TestDrive\$PlatformId\Prompts.ini" | Should -Be $true
            Test-Path -Path "$TestDrive\$PlatformId\Processes.ini" | Should -Be $true
        }
        It 'it must contain a <Type> file named <Name>' {
            Test-Path -Path (Join-Path -Path $TestDrive -ChildPath $PlatformId -AdditionalChildPath $Name) | Should -Be $true
        }  -ForEach @(
            @{Type = 'CPM policy'; Name = "Policy-SamplePlatform.ini"}
            @{Type = 'PVWA settings'; Name = "Policy-SamplePlatform.xml"}
        )
    }

    Context 'when adding the CPM policy file' {
        It 'names the .ini based on the platformid' {}
        It 'adds an .ini file specified at a local path' {}
        It 'retrieves an .ini from the Vault' {}
    }

    Context 'when creating the PVWA settings file' {
        It 'names the PVWA settings file based on the platformid' {}
        It 'extracts the PVWA settings out of an existing Policies.xml' {}
        It 'can retrieve the Policies.xml from the Vault' {}
    }

    Context 'when creating a PVWA settings file for a platform' {
        It 'extracts the appropriate device name' {}
        It 'puts the PVWA settings as a child node to a device node' {}
    }
}

Describe 'Get-PlatformPVWASettings' {
    It 'extracts the PVWA settings for a <PlatformType> out of an existing Policies.xml' {
        $PlatformSettings = Get-PlatformPVWASettings -PoliciesFile '.\Policies.xml' -PlatformId $PlatformId
        $PlatformSettingsXml = [xml]$PlatformSettings

        Select-Xml -Xml $PlatformSettingsXml -XPath "//$PlatformType[@ID='$PlatformId']" | Should -Be $true
    } -ForEach @(
        @{PlatformType = 'Usage'; PlatformId = 'INIFile'}
        @{PlatformType = 'Policy'; PlatformId = 'CyberArk'}
    )

    Context 'when getting the PVWA settings for a Policy' {
        It 'puts the PVWA settings as a child node to a policies node which is a child to a device node' {
            $PlatformSettings = Get-PlatformPVWASettings -PoliciesFile '.\Policies.xml' -PlatformId CyberArk
            $PlatformSettingsXml = [xml]$PlatformSettings

            Select-Xml -Xml $PlatformSettingsXml -XPath "//Device[@Name='Application']/Policies/Policy[@ID='CyberArk']" | Should -Be $true
        }
    }
}