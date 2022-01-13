function New-PASPlatformPackage {
    param (
        # Specifies the Id of the platform the package is being created for.
        [Parameter(Mandatory = $true)]
        [string]
        $PlatformId,

        # Specifies a path to the CPM Policy file to be included in the package.
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CPMPolicyFile,



        # Specifies a path to one or more locations.
        [Parameter(Mandatory=$true,
                   Position=0,
                   ParameterSetName="ParameterSetName",
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Path to one or more locations.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path
    )

    begin {}
    process {}
    end {}
}