function New-PASConnectionComponentPackage {
    [CmdletBinding()]
    param (
        # The unique ID of the connection component. This will be used to name the zip archive and used to find an extract the connection component settings from an existing PVConfiguration.xml.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionComponentId,

        # A path to a folder containing all the files to be a part of the connection component package.
        [Parameter(
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path -Path $_ })]
        [string[]]
        [Alias('PSPath')]
        $Path,

        # An array of paths used by the connection component application. These paths will be used to update AppLocker rules.
        [Parameter(Mandatory = $false)]
        [string[]]
        $ConnectionComponentApplicationPaths,

        # Determines whether to create an XML file with the connection component settings from an existing PVConfiguration.xml
        [Parameter(
            ParameterSetName = 'CreateConnectionComponentXml',
            Mandatory = $false
        )]
        [boolean]
        $CreateConnectionComponentXmlFile = $false,

        # File path of the PVConfiguration.xml to extract the connection component settings from.
        [Parameter(
            ParameterSetName = 'CreateConnectionComponentXml',
            Mandatory = $false
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path -Path $_ -PathType Leaf })]
        [string]
        $PVConfigurationPath,

        # Folder path where to create the package zip archive.
        [Parameter(Mandatory = $false)]
        $DestinationPath = $PWD
    )

    begin {
        $FilesToArchive = @()

        # We create a new temporary directory as we need to save generated files somewhere in order to add it to our archive
        $TemporaryDirectory = New-TemporaryDirectory
        $ConnectionComponentWorkingDirectory = Join-Path -Path $TemporaryDirectory -ChildPath $ConnectionComponentId
        New-Item -Path $ConnectionComponentWorkingDirectory -ItemType Directory

        if ($ConnectionComponentApplicationPaths.Count -gt 0) {
            $PackageJsonContent = [PSCustomObject]@{
                PackageName    = $ConnectionComponentId;
                ClientAppPaths = @()
            }

            foreach ($ApplicationPath in $ConnectionComponentApplicationPaths) {
                $PackageJsonContent.ClientAppPaths += @{Path = $ApplicationPath }
            }

            $PackageJsonFilePath = Join-Path -Path $ConnectionComponentWorkingDirectory -ChildPath 'package.json'
            # We need to UNESCAPE the slashes in the Paths before we write to file as the import scripts for the connection components package deployment
            # process assumes the Paths are unescaped tries to escape it at time of import.
            $PackageJsonContent | ConvertTo-Json | ForEach-Object { $_ -replace '\\\\', '\' } | Out-File -FilePath $PackageJsonFilePath -Force
            $FilesToArchive += $PackageJsonFilePath
        }

        if ($CreateConnectionComponentXmlFile) {
            [xml]$PVConfigurationXml = Get-Content $PVConfigurationPath
            $ConnectionComponentXml = Select-Xml -Xml $PVConfigurationXml -XPath "//ConnectionComponent[@Id='$ConnectionComponentId']"

            if ($null -ne $ConnectionComponentXml) {
                $ConnectionComponentXmlFilePath = Join-Path -Path $ConnectionComponentWorkingDirectory -ChildPath "CC-$ConnectionComponentId.xml"

                $ConnectionComponentXml.Node.OuterXml | Out-File -FilePath $ConnectionComponentXmlFilePath -Force
                $FilesToArchive += $ConnectionComponentXmlFilePath
            }
        }
    }
    process {
        Get-ChildItem -Path $Path | ForEach-Object { $FilesToArchive += $_.FullName }

    }
    end {
        Compress-Archive -Path $FilesToArchive -DestinationPath (Join-Path -Path $DestinationPath -ChildPath "$ConnectionComponentId.zip") -CompressionLevel Fastest
        Remove-Item $TemporaryDirectory -Force -Recurse
    }
}
# https://stackoverflow.com/a/34559554
function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}