BeforeAll {
    . .\New-PASConnectionComponentPackage.ps1
}

Describe 'New-PASConnectionComponentPackage' {
    Context 'creating package.json' {
        BeforeAll {
            Out-File -Path "$TestDrive\Dispatcher.exe"
            New-PASConnectionComponentPackage -ConnectionComponentId PSM-SampleApp `
                -PackageFilesPath "$TestDrive" `
                -ConnectionComponentApplicationPaths @('C:\SampleApp\SampleApp.exe', 'C:\SampleApp\Driver.exe') `
                -DestinationPath "$TestDrive" `

            Expand-Archive "$TestDrive\PSM-SampleApp.zip" -DestinationPath "$TestDrive\PSM-SampleApp"
        }
        It 'adds all connection component application paths to the clientapppaths array in package.json' {
            $PackageJson = Get-Content -Path "$TestDrive\PSM-SampleApp\package.json" | ConvertFrom-Json
            $PackageJson.ClientAppPaths | Should -HaveCount 2
        }

        It 'ensures that package.json is in the root of the zip archive' {
            $ExpectedExpandedPackageJsonPath = "$TestDrive\PSM-SampleApp\package.json"
            Get-Item -Path $ExpectedExpandedPackageJsonPath | Should -Exist
        }
    }

    Context 'creating connection component xml settings' {
        BeforeAll {
            Out-File -Path "$TestDrive\Dispatcher.exe"
            Copy-Item *.xml -Destination "$TestDrive\PVConfiguration.xml" -Force

            New-PASConnectionComponentPackage -ConnectionComponentId PSM-RealVNC `
                -PackageFilesPath "$TestDrive" `
                -ConnectionComponentApplicationPaths @('C:\SampleApp\SampleApp.exe', 'C:\SampleApp\Driver.exe') `
                -DestinationPath "$TestDrive" `
                -CreateConnectionComponentXmlFile $true `
                -PVConfigurationPath "$TestDrive\PVConfiguration.xml"

            Expand-Archive "$TestDrive\PSM-RealVNC.zip" -DestinationPath "$TestDrive\PSM-RealVNC"
        }

        It 'extracts existing connection component settings based on the provided connection component id and creates it as a file' {
            $ExpectedConnectionComponentXmlFile = "$TestDrive\PSM-RealVNC\PSM-RealVNC.xml"
            Get-Item -Path $ExpectedConnectionComponentXmlFile | Should -Exist
        }

        It 'ensures that the xml file is in the root of the zip archive' {
            $ExpectedExpandedPackageJsonPath = "$TestDrive\PSM-RealVNC\PSM-RealVNC.xml"
            Get-Item -Path $ExpectedExpandedPackageJsonPath | Should -Exist
        }
    }
}