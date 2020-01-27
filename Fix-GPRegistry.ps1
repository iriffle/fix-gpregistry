
 <#
.SYNOPSIS

    Scans a list of OU's for computers with potentially corrupted local group policy registries.

.DESCRIPTION
	Using two workflows this script takes the input of a list of locations (eg. "do", "skadisc", "skadet", etc),
    grabs all computers that contain that starting abreviation, checks if the last date modified of Registry.pol
    is older than a month, and if so renames it to Registry.pol.bak and runs a Group Policy update. 

    See Check-GPRegistry.ps1 for both workflows that do most of the work in this script.
	
.PARAMETER OU
	Parameter that specifies OU of computers to be scanned. It actually uses the computer prefix, not the full
    OU designation.
#>

param(
    [string[]]$OUs,
    [switch]$fix
)

# Register/update workflows for PowerShell
& \\esd189.org\dfs\wpkg\AdminScripts\gp\Fix-GPRegistry\Check-GPRegistry.ps1

# Find all computers in OU
function Get-Computers {
    param($ou)
    $computers = Get-ADComputer -LDAPFilter "(name=$ou*)" | Select-Object -ExpandProperty name
    return $computers
}


foreach ($OU in $OUs) {
            $computers = Get-Computers($OU)

            # Scan found PC's and check Registry.pol last modified dates
            $computers = Check-GPRegistry -computers $computers
            Write-Output $computers

            if ($fix) {
                Reset-GPRegistry -computers $computers
            }
}
