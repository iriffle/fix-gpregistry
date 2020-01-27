# Fix-GPRegistry

These are two PowerShell workflows and a script used to both Check for and Reset the Registry.pol file used by Group Policy on Windows systems. Occassionally this file becomes corrupted and no longer will properly pull Group Policy updates from the server. 

# Check-GPRegistry
Check-GPRegistry checks the Last Modified date on a list of PC's and determines if it is more than one month out of date. If it is then there is possible corruption.

# Reset-GPRegistry
Reset-GPRegistry renames the Registry.pol file to Registry.pol.bak and then runs a Group Policy update.
