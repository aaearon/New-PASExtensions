BeforeAll {
    . .\New-PASConnectionComponentPackage.ps1
}

Describe 'New-PASConnectionComponentPackage' {
    Context 'creating package.json' {
        BeforeAll {
            Out-File -Path "$TestDrive\Dispatcher.exe"
            New-PASConnectionComponentPackage -ConnectionComponentId PSM-SampleApp `
                -Path "$TestDrive" `
                -ConnectionComponentApplicationPaths @('C:\SampleApp\SampleApp.exe', 'C:\SampleApp\Driver.exe') `
                -DestinationPath "$TestDrive" `

            Expand-Archive "$TestDrive\PSM-SampleApp.zip" -DestinationPath "$TestDrive\PSM-SampleApp"
        }
        It 'adds all connection component application paths to the clientapppaths array in package.json' {
            # We properly escape the file so we can successfully convert it to json.
            $PackageJson = Get-Content -Path "$TestDrive\PSM-SampleApp\package.json" | ForEach-Object { $_ -replace '\\','\\' }
            $PackageJson = $PackageJson | ConvertFrom-Json
            $PackageJson.ClientAppPaths | Should -HaveCount 2
        }

        It 'ensures that package.json is in the root of the zip archive' {
            $ExpectedExpandedPackageJsonPath = "$TestDrive\PSM-SampleApp\package.json"
            Test-Path -Path $ExpectedExpandedPackageJsonPath | Should -Be $true
        }

        It 'ensures that the client app paths are not escaped' {
            $ExpectedExpandedPackageJsonPath = "$TestDrive\PSM-SampleApp\package.json"
            # The slashes need to be escaped when passing them as the Pattern argument to select string.
            Get-Content -Path $ExpectedExpandedPackageJsonPath | Select-String -Pattern '"Path": "C:\\SampleApp\\SampleApp.exe"' -Quiet | Should -Be $true
            Get-Content -Path $ExpectedExpandedPackageJsonPath | Select-String -Pattern '"Path": "C:\\SampleApp\\Driver.exe"' -Quiet | Should -Be $true
        }
    }

    Context 'creating connection component xml settings' {
        BeforeAll {
            $ConnectionComponentId = 'PSM-RealVNC'
            $ExpectedConnectionComponentXmlFileName = "CC-$ConnectionComponentId.xml"

            Out-File -Path "$TestDrive\Dispatcher.exe"
            Copy-Item *.xml -Destination "$TestDrive\PVConfiguration.xml" -Force

            New-PASConnectionComponentPackage -ConnectionComponentId $ConnectionComponentId `
                -Path "$TestDrive" `
                -ConnectionComponentApplicationPaths @('C:\SampleApp\SampleApp.exe', 'C:\SampleApp\Driver.exe') `
                -DestinationPath "$TestDrive" `
                -CreateConnectionComponentXmlFile $true `
                -PVConfigurationPath "$TestDrive\PVConfiguration.xml"

            Expand-Archive "$TestDrive\$ConnectionComponentId.zip" -DestinationPath "$TestDrive\$ConnectionComponentId"
        }

        It 'extracts existing connection component settings based on the provided connection component id and creates it as a file' {
            $ExpectedConnectionComponentXmlFile = "$TestDrive\$ConnectionComponentId\$ExpectedConnectionComponentXmlFileName"
            Test-Path -Path $ExpectedConnectionComponentXmlFile | Should -Be $true
        }

        It 'ensures the XML file is named CC-$ConnectionComponentId.xml' {
            Test-Path -Path "$TestDrive\$ConnectionComponentId\CC-$ConnectionComponentId.xml" | Should -Be $true
        }

        It 'ensures that the xml file is in the root of the zip archive' {
            $ExpectedExpandedPackageJsonPath = "$TestDrive\$ConnectionComponentId\$ExpectedConnectionComponentXmlFileName"
            Get-Item -Path $ExpectedExpandedPackageJsonPath | Should -Be $true
        }
    }
}