BeforeAll {
    . .\New-PASPlatformPackage.ps1


}

Describe 'New-PASPlatformPackage' {
    BeforeAll {
        # Set the generic details for the test
        $PlatformId = 'SamplePlatform'
        $CreatedArchivePath = Join-Path -Path $TestDrive -ChildPath "$PlatformId.zip"
        $ExpandedArchivePath = Join-Path -Path $TestDrive -ChildPath $PlatformId

        # Create dummy files for the required platform files.
        Out-File -Path (Join-Path -Path $TestDrive -ChildPath "my-platforms-cpm-settings.ini") -Force
        Out-File -Path (Join-Path -Path $TestDrive -ChildPath "my-platforms-pvwa-settings.xml") -Force

        # Create a directory and populate it for optional platform files
        $BuildDirectory = Join-Path -Path $TestDrive -ChildPath 'Build'
        New-Item -Path $BuildDirectory -ItemType Directory
        Out-File -Path (Join-Path -Path $BuildDirectory -ChildPath 'Prompts.ini') -Force
        Out-File -Path (Join-Path -Path $BuildDirectory -ChildPath 'Processes.ini') -Force

        Get-ChildItem -Path $BuildDirectory `
        | New-PASPlatformPackage -PlatformId $PlatformId `
            -CPMPolicyFile (Join-Path -Path $TestDrive -ChildPath "my-platforms-cpm-settings.ini") `
            -PVWASettingsFile (Join-Path -Path $TestDrive -ChildPath "my-platforms-pvwa-settings.xml") `
            -DestinationPath "$TestDrive"

        # Expand the archive as the tests depend on it.
        Expand-Archive $CreatedArchivePath -DestinationPath $ExpandedArchivePath
    }
    Context 'when creating the package' {
        It 'accepts the plug-in files from the pipeline' -ForEach 'Processes.ini', 'Prompts.ini' {
            Test-Path -Path (Join-Path -Path $TestDrive -ChildPath $PlatformId -AdditionalChildPath "$_") | Should -Be $true
        }
        It 'it must contain a <Type> file named <Name>' {
            Test-Path -Path (Join-Path -Path $TestDrive -ChildPath $PlatformId -AdditionalChildPath $Name) | Should -Be $true
        }  -ForEach @(
            @{Type = 'CPM policy'; Name = "Policy-SamplePlatform.ini" }
            @{Type = 'PVWA settings'; Name = "Policy-SamplePlatform.xml" }
        )
    }

    Context 'when creating the PVWA settings file' {
        BeforeAll {
            $PlatformId = 'CyberArk'
            $CreatedArchivePath = Join-Path -Path $TestDrive -ChildPath "$PlatformId.zip"
            $ExpandedArchivePath = Join-Path -Path $TestDrive -ChildPath $PlatformId

            $ExpectedPVWASettingsPath = Join-Path -Path $ExpandedArchivePath -ChildPath "Policy-$PlatformId.xml"

            Out-File -Path (Join-Path -Path $TestDrive -ChildPath "my-platforms-cpm-settings.ini") -Force
            Copy-Item *.xml -Destination $TestDrive -Force

            $DestinationPath = Join-Path -Path $TestDrive -ChildPath (New-Guid)
            New-Item -Path $DestinationPath -ItemType Directory

            New-PASPlatformPackage `
                -PlatformId $PlatformId `
                -CPMPolicyFile (Join-Path -Path $TestDrive -ChildPath 'my-platforms-cpm-settings.ini') `
                -ExtractPVWASettings $true `
                -PoliciesFile (Join-Path -Path $TestDrive -ChildPath 'Policies.xml') `
                -DestinationPath $TestDrive

            Expand-Archive -Path $CreatedArchivePath -DestinationPath $ExpandedArchivePath
        }
        It 'names the PVWA settings file based on the platformid' {
            Test-Path -Path $ExpectedPVWASettingsPath | Should -Be $true
        }
        It 'it can create it based on an existing Policies.xml' {
            [xml]$PlatformSettingsXml = Get-Content $ExpectedPVWASettingsPath

            Select-Xml $PlatformSettingsXml -XPath "//Device[@Name='Application']/Policies/Policy[@ID='CyberArk']/PrivilegedSessionManagement[@ID='PSMServer_2ab6ce8']" | Should -Be $true
        }
    }
}

Describe 'Get-PlatformPVWASettings' {
    It 'extracts the PVWA settings for a <PlatformType> out of an existing Policies.xml' {
        $PlatformSettings = Get-PlatformPVWASettings -PoliciesFile '.\Policies.xml' -PlatformId $PlatformId
        $PlatformSettingsXml = [xml]$PlatformSettings

        Select-Xml -Xml $PlatformSettingsXml -XPath "//$PlatformType[@ID='$PlatformId']" | Should -Be $true
    } -ForEach @(
        @{PlatformType = 'Usage'; PlatformId = 'INIFile' }
        @{PlatformType = 'Policy'; PlatformId = 'CyberArk' }
    )

    Context 'when getting the PVWA settings for a Policy' {
        It 'puts the PVWA settings as a child node to a policies node which is a child to a device node' {
            $PlatformSettings = Get-PlatformPVWASettings -PoliciesFile '.\Policies.xml' -PlatformId CyberArk
            $PlatformSettingsXml = [xml]$PlatformSettings

            Select-Xml -Xml $PlatformSettingsXml -XPath "//Device[@Name='Application']/Policies/Policy[@ID='CyberArk']" | Should -Be $true
        }
    }
}