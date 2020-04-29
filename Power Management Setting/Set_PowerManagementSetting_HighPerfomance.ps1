$computers = "NWFLODPPDSRST01",
"NWFLODSQL004",
"NWFLODSQL005"



##SELECTS 
Get-WmiObject -ComputerName $Computers  -Class win32_powerplan -Namespace root\cimv2\power -Filter "ElementName = 'High performance'" | Select-Object PSComputerName, ElementName, IsActive



#$P = gwmi -ComputerName $Computers -NS root\cimv2\power -Class win32_PowerPlan -Filter "ElementName = 'High performance'"
#$P.activate()