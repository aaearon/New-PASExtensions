# New-PASExtensions

A collection of Powershell functions that enable the creation of connection component and platform packages for CyberArk's Privileged Account Security solution.

## New-PASConnectionComponentPackage

A PowerShell function that makes it easy to create a package for connection components / connnectors that can be imported into CyberArk.

Given a directory of files that make up the connection component / connector, it creates a Zip archive. Optionally will create a `package.json` that is used by the [deployment process of Universal Connectors](https://docs.cyberark.com/Product-Doc/OnlineHelp/PAS/Latest/en/Content/PASIMP/ConfigurePSMUniversalConnector.htm) to add the application executables to the AppLocker rules. Furthermore, given an existing PVConfiguration.xml it will extract the connection component / connector settings and include them in the package as well.

### Usage

1. Dot source the function.

   ```powershell
   . .\New-PASConnectionComponentPackage.ps1
   ```

2. Use `Get-Help` to see the available parameters and arguments.

   ```powershell
   Get-Help New-PASConnectionComponentPackage
   ```

### Example

Creates a connection component package zip archive for the `PSM-SampleApp` connection component. It includes all the files in `C:\SampleAppDispatcherFiles` directory and creates a `package.json` where `C:\SampleApp\SampleApp.exe` will be added to the AppLocker rules. It also extracts the connection component settings from the existing `PVConfiguration.xml` file defined and adds them as `CC-PSM-SampleApp.xml` to the archive.

```powershell
$parameters = @{
    ConnectionComponentId               = 'PSM-SampleApp'
    Path                                = 'C:\SampleAppDispatcherFiles'
    ConnectionComponentApplicationPaths = @('C:\SampleApp\SampleApp.exe')
    CreateConnectionComponentXmlFile    = $true
    PVConfigurationPath                 = 'C:\Program Files (x86)\CyberArk\PSM\Temp\PVConfiguration.xml'
    DestinationPath                     = 'C:\ConnectionComponentPackages'
}

New-PASConnectionComponentPackage @parameters
```

## New-PASPlatformPackage

A PowerShell function that makes it easy to create a package for platforms that can be imported into CyberArk.

Given an existing PVWA settings file and a CPM file that make up the platform, it creates a Zip archive. Optionally it takes an array of platform files (for example, processes and prompts files) and includes them. Furthermore, in lieu of giving an existing PVWA settings file, it can instead extract the settings from a provided `Policies.xml` and include it in the package.

### Usage

1. Dot source the function.

   ```powershell
   . .\New-PASPlatformPackage.ps1
   ```

2. Use `Get-Help` to see the available parameters and arguments.

   ```powershell
   Get-Help New-PASPlatformPackage
   ```

### Example

Creates a platform package zip archive for the SamplePlatform platform using the provided CPM policy file. The PVWA settings file is extracted out of an existing `Policies.xml` file and included in the zip archive.

```powershell
$parameters = @{
    PlatformId          = 'SamplePlatform'
    CPMPolicyFile       = 'C:\SamplePlatformBuild\my-platforms-cpm-settings.ini'
    ExtractPVWASettings = $true
    PoliciesFile        = 'C:\Program Files (x86)\CyberArk\PSM\Temp'
}

New-PASPlatformPackage @parameters
```
