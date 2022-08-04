Get-ChildItem $PSScriptRoot\ -Recurse -Include '*.ps1' | ForEach-Object {
    . $_.FullName
}