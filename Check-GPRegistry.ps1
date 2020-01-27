<#
.SYNOPSIS

    Checks for and resets corrupted local Group Policy registry files.

.DESCRIPTION

    These are two PowerShell workflows used to both Check for and Reset 
    the Registry.pol file used by Group Policy on Windows systems.
    Occassionally this file becomes corrupted and no longer will properly
    pull Group Policy updates from the server. 
    
    Check-GPRegistry checks the Last Modified date on a list of PC's and 
    determines if it is more than one month out of date. If it is then 
    there is possible corruption.

    Reset-GPRegistry renames the Registry.pol file to Registry.pol.bak and 
    then runs a Group Policy update.

    This file is not ran as a script itself, but each workflow can be called
    separately if first this script is ran in PowerShell to register both 
    workflows. Generally the Fix-GPRegistry.ps1 script should be ran as it 
    will also find all the PC names in a given OU for you and runs both of 
    these workflows together if the -Fix flag is set.
    
#>


# Remotely checks in parallel the Registry.pol file on a list of PC's and
# compares it to today's date minus one month. If it is older than one month
# it will output the PC name's which can then be directed into a variable to
# be used by Reset-GPRegistry.
workflow Check-GPRegistry {
    param([string[]]$computers)

    # Path to Registry.pol file
    $registryPath = "C:\Windows\System32\GroupPolicy\Machine\Registry.pol"

    # How many months back the last modified date should compare itself to.
    # Always should be a negative number. Ex. To check against a last modified
    # date of older than one month set variable to -1. 
    $months = -1

    # Run against each PC in parallel, but run the commands in order
    foreach -parallel ($computer in $computers) {
        sequence {
            inlinescript {
                try {
                    # Create remote session on PC
                    $session = New-PSSession -ComputerName $using:computer
            
                    $lastModified = Invoke-Command -Session $session -ScriptBlock {
                        param($registryPath, $months)
                        
                        # Check last write time of file
                        $lastModified = (Get-Item $registryPath).LastWriteTime

                        # Compare it to today's date minus one month
                        if ($lastModified -lt (Get-Date).AddMonths($months)) {
                            return $lastModified
                        }
                        
                    } -Args ($using:registryPath, $using:months)

                    # Output if the modified date is older than one month
                    if ($lastModified) {
                        Write-Output $using:computer
                    }
                }
                catch {
                    continue
                }
            }
        }
    }
}

# Does the same thing as Check-GPRegistry except instead of just checking the 
# modification date it renames the file to Registry.pol.bak and then prompts the
# PC for a Group Policy update.
workflow Reset-GPRegistry {
    param([string[]]$computers)

    $registryPath = "C:\Windows\System32\GroupPolicy\Machine\Registry.pol"
    $backupName = "Registry.pol.bak"

    foreach -parallel ($computer in $computers) {
        sequence {
            inlinescript {
                try {
                    $session = New-PSSession -ComputerName $using:computer
            
                    $success = Invoke-Command -Session $session -ScriptBlock {
                        param($registryPath,$backupName)
                        try {
                            # Rename Registry.pol file and start a GP update
                            Rename-Item -Path $registryPath -NewName $backupName
                            Invoke-GPUpdate
                            return true
                        }
                        catch {
                            return $_
                        }
                    } -Args ($using:registryPath, $using:backupName)
                    if ($success) {
                        Write-Output "$using:computer's group policy has been updated. Computer may need a reboot"
                    }
                    else {
                        Write-Output $success
                    }
                }
                catch {
                    continue
                }
            }
        }
    }
}
