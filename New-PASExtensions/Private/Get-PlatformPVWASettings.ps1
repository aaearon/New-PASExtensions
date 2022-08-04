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

    } elseif ($PlatformXml.Name -eq 'Policy') {

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