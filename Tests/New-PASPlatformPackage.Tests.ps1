BeforeAll {
    Import-Module $PSScriptRoot\..\New-PASExtensions\New-PASExtensions.psd1 -Force
}

Describe 'New-PASPlatformPackage' {
    BeforeAll {
        # Set the generic details for the test
        $PlatformId = 'SamplePlatform'
        $CreatedArchivePath = Join-Path -Path $TestDrive -ChildPath "$PlatformId.zip"
        $ExpandedArchivePath = Join-Path -Path $TestDrive -ChildPath $PlatformId
        $CPMPolicyFile = Join-Path -Path $TestDrive -ChildPath 'my-platforms-cpm-settings.ini'
        $PVWASettingsFile = Join-Path -Path $TestDrive -ChildPath 'my-platforms-pvwa-settings.xml'

        # Create dummy files for the required platform files.
        Out-File -Path $CPMPolicyFile -Force
        Out-File -Path $PVWASettingsFile -Force

        # Create a directory and populate it for optional platform files
        $BuildDirectory = Join-Path -Path $TestDrive -ChildPath 'Build'
        New-Item -Path $BuildDirectory -ItemType Directory
        Out-File -Path (Join-Path -Path $BuildDirectory -ChildPath 'Prompts.ini') -Force
        Out-File -Path (Join-Path -Path $BuildDirectory -ChildPath 'Processes.ini') -Force

        $parameters = @{
            PlatformId       = $PlatformId
            CPMPolicyFile    = $CPMPolicyFile
            PVWASettingsFile = $PVWASettingsFile
            DestinationPath  = $TestDrive
        }
        Get-ChildItem -Path $BuildDirectory | New-PASPlatformPackage @parameters

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
            @{Type = 'CPM policy'; Name = 'Policy-SamplePlatform.ini' }
            @{Type = 'PVWA settings'; Name = 'Policy-SamplePlatform.xml' }
        )
    }

    Context 'when creating the PVWA settings file' {
        BeforeAll {
            $PlatformId = 'CyberArk'
            $CreatedArchivePath = Join-Path -Path $TestDrive -ChildPath "$PlatformId.zip"
            $ExpandedArchivePath = Join-Path -Path $TestDrive -ChildPath $PlatformId

            $ExpectedPVWASettingsPath = Join-Path -Path $ExpandedArchivePath -ChildPath "Policy-$PlatformId.xml"

            $CPMPolicyFile = Join-Path -Path $TestDrive -ChildPath 'my-platforms-cpm-settings.ini'
            Out-File -Path $CPMPolicyFile -Force
            Copy-Item '.\Tests\*.xml' -Destination $TestDrive -Force

            $DestinationPath = Join-Path -Path $TestDrive -ChildPath (New-Guid)
            New-Item -Path $DestinationPath -ItemType Directory

            $parameters = @{
                PlatformId          = $PlatformId
                CPMPolicyFile       = $CPMPolicyFile
                ExtractPVWASettings = $true
                ExtractPlatform     = 'WinServerLocal'
                PoliciesFile        = (Join-Path -Path $TestDrive -ChildPath 'Policies.xml')
                DestinationPath     = $TestDrive
                OverwritePolicyIds  = $true
            }
            New-PASPlatformPackage @parameters

            Expand-Archive -Path $CreatedArchivePath -DestinationPath $ExpandedArchivePath
        }
        It 'names the PVWA settings file based on the platformid' {
            Test-Path -Path $ExpectedPVWASettingsPath | Should -Be $true
        }
        It 'can create it based on an existing Policies.xml' {
            [xml]$PlatformSettingsXml = Get-Content $ExpectedPVWASettingsPath

            Select-Xml $PlatformSettingsXml -XPath "//Policies/Policy[@ID='CyberArk']/PrivilegedSessionManagement[@ID='PSMServer_2ab6ce8']" | Should -Be $true
        }
    }
}

