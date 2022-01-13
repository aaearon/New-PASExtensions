BeforeAll {
    . .\New-PASPlatformPackage.ps1
}

Describe 'New-PASPlatformPackage' {
    Context 'when creating the package' {
        It 'accepts the plug-in files from the pipeline' {}
        It 'it must contain a CPM policy file' {}
        It 'it must contain a PVWA settings file' {}
    }

    Context 'when adding the CPM policy file' {
        It 'names the .ini based on the platformid' {}
        It 'adds an .ini file specified at a local path' {}
        It 'retrieves an .ini from the Vault' {}
    }

    Context 'when creating the PVWA settings file' {
        It 'names the PVWA settings file based on the platformid' {}
        It 'extracts the PVWA settings out of an existing Policies.xml' {}
        It 'can retrieve the Policies.xml from the Vault' {}
    }

    Context 'when creating a PVWA settings file for a platform' {
        It 'extracts the appropriate device name' {}
        It 'puts the PVWA settings as a child node to a device node' {}
    }
}