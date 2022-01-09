BeforeAll {
    . .\New-PASConnectionComponentPackage.ps1
}

Describe 'New-PASConnectionComponentPackage' {
    Context 'when creating the package' {
        It 'accepts a list of files from the pipeline' {
            $ConnectionComponentId = 'PSM-SampleApp'
            $CreatedArchivePath = Join-Path -Path $TestDrive -ChildPath "$ConnectionComponentId.zip"
            $ExpandedArchivePath = Join-Path -Path $TestDrive -ChildPath $ConnectionComponentId

            $BuildDirectory = Join-Path -Path $TestDrive -ChildPath 'Build'
            New-Item -Path $BuildDirectory -ItemType Directory
            Out-File -Path (Join-Path -Path $BuildDirectory -ChildPath 'Dispatcher.exe') -Force
            Out-File -Path (Join-Path -Path $BuildDirectory -ChildPath 'DispatcherUtils.dll') -Force

            Get-ChildItem -Path $BuildDirectory `
            | New-PASConnectionComponentPackage -ConnectionComponentId $ConnectionComponentId `
                -ConnectionComponentApplicationPaths @('C:\SampleApp\SampleApp.exe', 'C:\SampleApp\Driver.exe') `
                -DestinationPath "$TestDrive"

            Expand-Archive $CreatedArchivePath -DestinationPath $ExpandedArchivePath
            Test-Path -Path "$TestDrive\PSM-SampleApp\Dispatcher.exe" | Should -Be $true
            Test-Path -Path "$TestDrive\PSM-SampleApp\DispatcherUtils.dll" | Should -Be $true

        }
    }

    Context 'creating package.json' {
        BeforeAll {
            $ConnectionComponentId = 'PSM-SampleApp'
            $CreatedArchivePath = Join-Path -Path $TestDrive -ChildPath "$ConnectionComponentId.zip"
            $ExpandedArchivePath = Join-Path -Path $TestDrive -ChildPath $ConnectionComponentId
            $ExpectedPackageJsonPath = Join-Path -Path $ExpandedArchivePath -ChildPath 'package.json'

            Out-File -Path (Join-Path -Path $TestDrive -ChildPath 'Dispatcher.exe')
            New-PASConnectionComponentPackage -ConnectionComponentId $ConnectionComponentId `
                -Path "$TestDrive" `
                -ConnectionComponentApplicationPaths @('C:\SampleApp\SampleApp.exe', 'C:\SampleApp\Driver.exe') `
                -DestinationPath "$TestDrive" `

            Expand-Archive $CreatedArchivePath -DestinationPath $ExpandedArchivePath
        }
        It 'adds all connection component application paths to the clientapppaths array in package.json' {
            # We properly escape the file so we can successfully convert it to json.
            $PackageJson = Get-Content -Path $ExpectedPackageJsonPath | ForEach-Object { $_ -replace '\\', '\\' }
            $PackageJson = $PackageJson | ConvertFrom-Json
            $PackageJson.ClientAppPaths | Should -HaveCount 2
        }

        It 'ensures that package.json is in the root of the zip archive' {
            $ExpectedExpandedPackageJsonPath = $ExpectedPackageJsonPath
            Test-Path -Path $ExpectedExpandedPackageJsonPath | Should -Be $true
        }

        It 'ensures that the client app paths are not escaped' {
            $ExpectedExpandedPackageJsonPath = $ExpectedPackageJsonPath
            # The slashes need to be escaped when passing them as the Pattern argument to select string.
            Get-Content -Path $ExpectedExpandedPackageJsonPath | Select-String -Pattern '"Path": "C:\\SampleApp\\SampleApp.exe"' -Quiet | Should -Be $true
            Get-Content -Path $ExpectedExpandedPackageJsonPath | Select-String -Pattern '"Path": "C:\\SampleApp\\Driver.exe"' -Quiet | Should -Be $true
        }
    }

    Context 'creating connection component xml settings' {
        BeforeAll {
            $ConnectionComponentId = 'PSM-RealVNC'
            $CreatedArchivePath = Join-Path -Path $TestDrive -ChildPath "$ConnectionComponentId.zip"
            $ExpandedArchivePath = Join-Path -Path $TestDrive -ChildPath $ConnectionComponentId
            $PVConfigurationPath = Join-Path -Path $TestDrive -ChildPath 'PVConfiguration.xml'
            $ExpectedConnectionComponentXmlPath = Join-Path -Path $ExpandedArchivePath -ChildPath "CC-$ConnectionComponentId.xml"

            Out-File -Path (Join-Path -Path $TestDrive -ChildPath 'Dispatcher.exe')
            Copy-Item *.xml -Destination $PVConfigurationPath -Force

            New-PASConnectionComponentPackage -ConnectionComponentId $ConnectionComponentId `
                -Path "$TestDrive" `
                -ConnectionComponentApplicationPaths @('C:\SampleApp\SampleApp.exe', 'C:\SampleApp\Driver.exe') `
                -DestinationPath "$TestDrive" `
                -CreateConnectionComponentXmlFile $true `
                -PVConfigurationPath $PVConfigurationPath

            Expand-Archive $CreatedArchivePath -DestinationPath $ExpandedArchivePath
        }

        It 'extracts existing connection component settings based on the provided connection component id and creates it as a file' {
            Test-Path -Path $ExpectedConnectionComponentXmlPath | Should -Be $true
        }

        It 'ensures the XML file is named CC-$ConnectionComponentId.xml' {
            Test-Path -Path $ExpectedConnectionComponentXmlPath | Should -Be $true
        }

        It 'ensures that the xml file is in the root of the zip archive' {
            Get-Item -Path $ExpectedConnectionComponentXmlPath | Should -Be $true
        }
    }
}