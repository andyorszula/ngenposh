#Test for required modules before loading
<#
@(
    "ngenposhLogging"
    "ngenposhDatabaseMailNotifier"
) | ForEach-Object {
    if($null -eq (Get-Module -Name $_)) {
        Write-Error -Message "Missing required module `"$($_)`"" -ErrorAction Stop
    }
}
#>

#Get public and private function definition files.
$privatePathPattern = "$PSScriptRoot\Private\*.ps1"
$publicPathPattern = "$PSScriptRoot\Public\*.ps1"

#Dot source the files
Get-ChildItem -Path @($privatePathPattern, $publicPathPattern) -File -Recurse `
| ForEach-Object {
    $import = $_
    try {
        . $import.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($import.FullName): $($_)" -ErrorAction Stop
    }
}

# Export Public functions ($Public.BaseName) for WIP modules
Get-ChildItem -Path @($publicPathPattern) -File -Recurse `
| ForEach-Object {
    $exportMember = $_
    try {
        Export-ModuleMember $exportMember.BaseName
    }
    catch {
        Write-Error -Message "Failed to export module member $($exportMember.BaseName): $($_)" -ErrorAction Stop
    }
}
