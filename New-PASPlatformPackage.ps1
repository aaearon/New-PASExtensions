﻿function New-PASPlatformPackage {
    [CmdletBinding()]
    param (
        # Specifies the Id of the platform the package is being created for.
        [Parameter(Mandatory = $true)]
        [string]
        $PlatformId,

        # Specifies a path to the CPM Policy file to be included in the package.
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path -Path $_ -PathType Leaf })]
        [ValidateNotNullOrEmpty()]
        [string]
        $CPMPolicyFile,

        [Parameter(Mandatory = $false)]
        [ValidateScript( { Test-Path -Path $_ -PathType Leaf })]
        [ValidateNotNullOrEmpty()]
        [string]
        $PVWASettingsFile,

        # Parameter help description
        [Parameter(Mandatory = $false)]
        [boolean]
        $ExtractPVWASettingsFromPoliciesFile,

        [Parameter(Mandatory = $false)]
        [ValidateScript( { Test-Path -Path $_ -PathType Leaf })]
        [ValidateNotNullOrEmpty()]
        [string]
        $PoliciesFile,

        # Specifies a path to one or more locations.
        [Parameter(
            ValueFromPipeline = $true,
            Mandatory = $false
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path -Path $_ })]
        [string[]]
        [Alias('PSPath')]
        $Path,

        # Folder path where to create the package zip archive.
        [Parameter(Mandatory = $false)]
        $DestinationPath = $PWD
    )

    begin {
        $FilesToArchive = @()

        $TemporaryDirectory = New-TemporaryDirectory
        $PlatformWorkingDirectory = Join-Path -Path $TemporaryDirectory -ChildPath $PlatformId
        New-Item -Path $PlatformWorkingDirectory -ItemType Directory

        $CPMPolicyFile = Copy-Item -Path $CPMPolicyFile -Destination (Join-Path -Path $PlatformWorkingDirectory -ChildPath "Policy-$PlatformId.ini") -PassThru
        $FilesToArchive += $CPMPolicyFile

        if ($PVWASettingsFile) {
            $PVWASettingsFile = Copy-Item -Path $PVWASettingsFile -Destination (Join-Path -Path $PlatformWorkingDirectory -ChildPath "Policy-$PlatformId.xml") -PassThru
            $FilesToArchive += $PVWASettingsFile
        }
        elseif ($ExtractPVWASettingsFromPoliciesFile) {
            $PVWASettingsFilePath = Join-Path -Path $PlatformWorkingDirectory -ChildPath "Policy-$PlatformId.xml"

            $Settings = Get-PlatformPVWASettings -PlatformId $PlatformId -PoliciesFile $PoliciesFile
            $Settings | Set-Content -Path $PVWASettingsFilePath
            $FilesToArchive += $PVWASettingsFilePath
        }


    }
    process {
        if ($Path.Count -gt 0) {
            $FilesToArchive += Get-ChildItem -Path $Path | ForEach-Object FullName
        }
        else {
            Write-Debug "No platform files passed!"
        }
    }
    end {
        Compress-Archive -Path $FilesToArchive -DestinationPath (Join-Path -Path $DestinationPath -ChildPath "$PlatformId.zip") -CompressionLevel Fastest
        Remove-Item $TemporaryDirectory -Force -Recurse
    }
}

function Get-PlatformPVWASettings {
    param (
        # Id of the platform to extract settings for.
        [Parameter(Mandatory = $true)]
        [string]$PlatformId,
        # Path to the Policies.xml file to extract the settings from.
        [Parameter(Mandatory = $true)]
        [string]$PoliciesFile
    )

    $FileXml = [xml](Get-Content -Path $PoliciesFile)
    $SelectXPath = "//Device/Policies/Policy[@ID='$PlatformId'] | //Usages/Usage[@ID='$PlatformId']"
    $PlatformXml = $FileXml.SelectSingleNode($SelectXPath)

    if ($PlatformXml.Name -eq 'Usage') {
        $SettingsXml = $PlatformXml

    }
    elseif ($PlatformXml.Name -eq 'Policy') {

        # Get name of the Device
        $DeviceName = $PlatformXml.ParentNode.ParentNode.Name

        # Create a new XML document.
        $NewXml = New-Object xml

        # Create the Device element with the Name attribute and add it to our new XML document.
        $DeviceElement = $NewXml.CreateElement('Device')
        $DeviceElement.SetAttribute('Name', $DeviceName)
        # Must have Out-Null here as AppendChild returns an XmlNode and uncaptured output in PowerShell
        # is implicity emitted to the pipeline.
        $NewXml.AppendChild($DeviceElement) | Out-Null

        # Create and add Policies
        $PoliciesElement = $NewXml.CreateElement('Policies')
        $NewXml.Device.AppendChild($PoliciesElement) | Out-Null

        # Add the Policy element under Policies.
        $Policy = $NewXml.ImportNode($PlatformXml, $true)
        # FirstChild = Policies in this case as there is only one child.
        $NewXml.Device.FirstChild.AppendChild($Policy) | Out-Null

        $SettingsXml = $NewXml
    }

    return $SettingsXml.OuterXml
}

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}