[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Windows.Forms.Application]::EnableVisualStyles()
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended') | out-null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SQLWMIManagement') | out-null



function AG-Creation
{
$Okbutton.Enabled = $false;

$ag1 = $ag1text.Text
$ag2 = $ag2text.Text
$dag = $dagtext.Text
$ag1ip = $ag1iptext.Text
$ag2ip = $ag2iptext.Text
$port = $porttext.Text
$PRD1 = $prod1text.Text
$PRD2 = $prod2text.Text
$DR1 = $dr1text.Text
$DR2 = $dr2text.Text


$PRODSERVER1 = $PRD1 + "," + $port
$PRODSERVER2 = $PRD2 + "," + $port
$DRSERVER1 = $DR1 + "," + $port
$DRSERVER2 = $DR2 + "," + $port



if (!$PRD1) { [System.Windows.MessageBox]::Show('Prod Server - 1 cannot be blank'); $Okbutton.Enabled = $true; Return }
if (!$PRD2) { [System.Windows.MessageBox]::Show('Prod Server - 2 cannot be blank'); $Okbutton.Enabled = $true; Return }
if (!$DR1) { [System.Windows.MessageBox]::Show('DR Server - 1 cannot be blank'); $Okbutton.Enabled = $true; Return }
if (!$DR2) { [System.Windows.MessageBox]::Show('DR Server - 2 cannot be blank'); $Okbutton.Enabled = $true; Return }
if (!$port) { [System.Windows.MessageBox]::Show('Port Number cannot be blank'); $Okbutton.Enabled = $true; Return }
if (!$ag1) { [System.Windows.MessageBox]::Show('AG1 cannot be blank'); $Okbutton.Enabled = $true; Return }
if (!$ag1ip) { [System.Windows.MessageBox]::Show('AG1 IP cannot be blank'); $Okbutton.Enabled = $true; Return }
if (!$ag2) { [System.Windows.MessageBox]::Show('AG2 cannot be blank'); $Okbutton.Enabled = $true; Return }
if (!$ag2ip) { [System.Windows.MessageBox]::Show('AG2 IP cannot be blank'); $Okbutton.Enabled = $true; Return }
if (!$dag) { [System.Windows.MessageBox]::Show('Distributed AG cannot be blank'); $Okbutton.Enabled = $true; Return }

$PRD1ip = Resolve-DNSName $PRD1 | select -ExpandProperty IPAddress
$DR1ip = Resolve-DNSName $DR1 | select -ExpandProperty IPAddress
$ag1ipsubnet = Get-WmiObject -ComputerName $PRD1 Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -eq $PRD1ip } | select -ExpandProperty IpSubnet
$ag1ipsubnet = $ag1ipsubnet | Select-Object -First 1
$ag2ipsubnet = Get-WmiObject -ComputerName $DR1 Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -eq $DR1ip } | Select -ExpandProperty IpSubnet
$ag2ipsubnet = $ag2ipsubnet | Select-Object -First 1
$ag1listenerip = $ag1ip + "/" + $ag1ipsubnet
$ag2listenerip = $ag2ip + "/" + $ag2ipsubnet
try
{

Import-Module SQLServer -DisableNameChecking -ErrorAction Stop

}
catch
{
$textbox7.text = $_.Exception.Message;
$Okbutton.Enabled = $true;
Return;
}
$textbox7.text = "1. Enabling SqlAlwaysOn Feature on all 4 servers - Takes approximately 2 minutes.`r`n";
<#
Invoke-Command -ComputerName $PRD1 -ScriptBlock { Enable-SqlAlwaysOn -ServerInstance $using:PRD1 -Force }
Invoke-Command -ComputerName $PRD2 -ScriptBlock { Enable-SqlAlwaysOn -ServerInstance $using:PRD2 -Force } 
Invoke-Command -ComputerName $DR1 -ScriptBlock { Enable-SqlAlwaysOn -ServerInstance $using:DR1 -Force } 
Invoke-Command -ComputerName $DR2 -ScriptBlock { Enable-SqlAlwaysOn -ServerInstance $using:DR2 -Force } 
#>

$s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $PRODSERVER1
$dbExists = $FALSE
foreach ($db in $s.databases) {
  if ($db.name -eq "TestAGdb") {
    $dbExists = $TRUE
  }
}
$textbox7.text += "2. Creating first AG : $ag1 `r`n";
if ($dbExists -eq $FALSE) {
$textbox7.text += "3. Creating a test database : TestAGdb `r`n";
$db = New-Object Microsoft.SqlServer.Management.Smo.Database -argumentlist $s, "TestAGdb"
$db.Create();
}
else
{
    $textbox7.text += "3. Test database : TestAGdb already exists`r`n";
}
if (Test-Path "\\$PRD1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.bak") 
{
  Remove-Item "\\$PRD1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.bak"
}
if (Test-Path "\\$PRD1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.trn") 
{
  Remove-Item "\\$PRD1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.trn"
}
if (Test-Path "\\$PRD2\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.bak") 
{
  Remove-Item "\\$PRD2\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.bak"
}
if (Test-Path "\\$PRD2\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.trn") 
{
  Remove-Item "\\$PRD2\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.trn"
}
if (Test-Path "\\$DR1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.bak") 
{
  Remove-Item "\\$DR1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.bak"
}
if (Test-Path "\\$DR1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.trn") 
{
  Remove-Item "\\$DR1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.trn"
}
if (Test-Path "\\$DR2\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.bak") 
{
  Remove-Item "\\$DR2\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.bak"
}
if (Test-Path "\\$DR2\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.trn") 
{
  Remove-Item "\\$DR2\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.trn"
}
$textbox7.text += "4. Executing TestAGdb database backup `r`n";
$a= Backup-SqlDatabase -Database "TestAGdb" -BackupFile "\\$PRD1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.bak" -ServerInstance "$PRODSERVER1"  
$a= Backup-SqlDatabase -Database "TestAGdb" -BackupFile "\\$PRD1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.trn" -ServerInstance "$PRODSERVER1" -BackupAction Log  
$textbox7.text += "5. Copying TestAGdb database backup files `r`n";
$a= Copy-Item "\\$PRD1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.bak" -destination "\\$PRD2\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup"
$a= Copy-Item "\\$PRD1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.trn" -destination "\\$PRD2\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup"
$a= Copy-Item "\\$PRD1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.bak" -destination "\\$DR1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup"
$a= Copy-Item "\\$PRD1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.trn" -destination "\\$DR1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup"
$a= Copy-Item "\\$PRD1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.bak" -destination "\\$DR2\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup"
$a= Copy-Item "\\$PRD1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.trn" -destination "\\$DR2\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup"
$textbox7.text += "6. Restoring TestAGdb database `r`n";
$a= Restore-SqlDatabase -Database "TestAGdb" -BackupFile "\\$PRD2\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.bak" -ServerInstance "$PRODSERVER2" -ReplaceDatabase -NoRecovery
$a= Restore-SqlDatabase -Database "TestAGdb" -BackupFile "\\$PRD2\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.trn" -ServerInstance "$PRODSERVER2" -RestoreAction Log -NoRecovery
$a= Restore-SqlDatabase -Database "TestAGdb" -BackupFile "\\$DR1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.bak" -ServerInstance "$DRSERVER1" -ReplaceDatabase -NoRecovery
$a= Restore-SqlDatabase -Database "TestAGdb" -BackupFile "\\$DR1\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.trn" -ServerInstance "$DRSERVER1" -RestoreAction Log -NoRecovery
$a= Restore-SqlDatabase -Database "TestAGdb" -BackupFile "\\$DR2\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.bak" -ServerInstance "$DRSERVER2" -ReplaceDatabase -NoRecovery
$a= Restore-SqlDatabase -Database "TestAGdb" -BackupFile "\\$DR2\S$\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\TestAGdb.trn" -ServerInstance "$DRSERVER2" -RestoreAction Log -NoRecovery

$textbox7.text += "7. Creating and starting the Endpoints on all 4 servers, if it isn't already. `r`n";
$textbox7.text += "8. Granting CONNECT ON ENDPOINT permissions and Starting the extended events session for AlwaysOn. `r`n";
        $s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $PRODSERVER1
        $svcactPRD1 = $s.ServiceAccount
        $s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $PRODSERVER2
        $svcactPRD2 = $s.ServiceAccount
        $s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $DRSERVER1
        $svcactDR1 = $s.ServiceAccount
        $s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $DRSERVER2
        $svcactDR2 = $s.ServiceAccount
        
foreach($srv1 in $PRODSERVER1,$PRODSERVER2,$DRSERVER1,$DRSERVER2)
{
        
        $s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $srv1
        $CreateEndpointFlag = $s.Endpoints | where {$_.Name -eq "Hadr_endpoint"}
        
        if($CreateEndpointFlag -ne $null)
        {
            $StartEndpointFlag = $s.Endpoints | where {$_.Name -eq "Hadr_endpoint"} | select -ExpandProperty EndpointState
            if($StartEndpointFlag -ne "Started")
            {
    
                $a = Set-SqlHADREndpoint -Path "SQLSERVER:\SQL\$srv1\Default\Endpoints\Hadr_endpoint" -State Started
               # Invoke-SqlCmd -ServerInstance $PRODSERVER1 -Query $query
            }
            #$textbox7.text += "8. Hadr_endpoint Endpoint already exists and is started on $srv1. `r`n";

        }
        else
        {
            
            $a = New-SqlHADREndpoint -Path "SQLSERVER:\SQL\$srv1\Default" -Name "Hadr_endpoint" -Port 5022
            $a = Set-SqlHADREndpoint -Path "SQLSERVER:\SQL\$srv1\Default\Endpoints\Hadr_endpoint" -State Started
            #$textbox7.text += "8. Hadr_endpoint Endpoint created and started on $srv1. `r`n";
        }

        $createLogin = "IF  NOT EXISTS (select loginname from master.dbo.syslogins where name like '%$svcactPRD1%') CREATE LOGIN [$svcactPRD1] FROM WINDOWS"
        $grantConnectPermissions = "GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$svcactPRD1]"
        $a = Invoke-SqlCmd -ServerInstance $srv1 -Query $createLogin
        $a = Invoke-SqlCmd -ServerInstance $srv1 -Query $grantConnectPermissions
        $createLogin = "IF  NOT EXISTS (select loginname from master.dbo.syslogins where name like '%$svcactPRD2%') CREATE LOGIN [$svcactPRD2] FROM WINDOWS"
        $grantConnectPermissions = "GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$svcactPRD2]"
        $a = Invoke-SqlCmd -ServerInstance $srv1 -Query $createLogin
        $a = Invoke-SqlCmd -ServerInstance $srv1 -Query $grantConnectPermissions
        $createLogin = "IF  NOT EXISTS (select loginname from master.dbo.syslogins where name like '%$svcactDR1%') CREATE LOGIN [$svcactDR1] FROM WINDOWS"
        $grantConnectPermissions = "GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$svcactDR1]"
        $a = Invoke-SqlCmd -ServerInstance $srv1 -Query $createLogin
        $a = Invoke-SqlCmd -ServerInstance $srv1 -Query $grantConnectPermissions
        $createLogin = "IF  NOT EXISTS (select loginname from master.dbo.syslogins where name like '%$svcactDR2%') CREATE LOGIN [$svcactDR2] FROM WINDOWS"
        $grantConnectPermissions = "GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$svcactDR2]"
        $a = Invoke-SqlCmd -ServerInstance $srv1 -Query $createLogin
        $a = Invoke-SqlCmd -ServerInstance $srv1 -Query $grantConnectPermissions

        $exevent1 = "IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name='AlwaysOn_health') ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE=ON);"
        $exevent2 = "IF NOT EXISTS (SELECT * FROM sys.dm_xe_sessions WHERE name='AlwaysOn_health') ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=START;"
        $a = Invoke-SqlCmd -ServerInstance $srv1 -Query $exevent1
        $a = Invoke-SqlCmd -ServerInstance $srv1 -Query $exevent2
        $alterendpoint = "ALTER ENDPOINT [Hadr_endpoint] AS TCP (LISTENER_IP = ALL)"
        $a = Invoke-SqlCmd -ServerInstance $srv1 -Query $alterendpoint

}
$ServerObject = Get-Item "SQLSERVER:\SQL\$PRODSERVER1\Default"
$PRD1FQDN = [System.Net.Dns]::GetHostByName($PRD1) | select -ExpandProperty  hostname
$PRD2FQDN = [System.Net.Dns]::GetHostByName($PRD2) | select -ExpandProperty  hostname
$PRD1EndPointURL = "TCP://" + $PRD1FQDN + ":5022"
$PRD2EndPointURL = "TCP://" + $PRD2FQDN + ":5022"
$ag1primaryReplica = New-SqlAvailabilityReplica -Name $PRD1 -EndpointUrl $PRD1EndPointURL -AvailabilityMode "SynchronousCommit" -FailoverMode 'Automatic' -AsTemplate -Version $ServerObject.version
$ag1secondaryReplica = New-SqlAvailabilityReplica -Name $PRD2 -EndpointUrl $PRD2EndPointURL -AvailabilityMode "SynchronousCommit" -FailoverMode 'Automatic' -AsTemplate -Version $ServerObject.version
$textbox7.text += "9. Creating the Availability group $ag1 `r`n"

$s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $PRODSERVER1
$ag1check = $s.AvailabilityGroups | where { $_.Name -eq $ag1} | select -ExpandProperty Name
$s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $DRSERVER1
$ag2check = $s.AvailabilityGroups | where { $_.Name -eq $ag2} | select -ExpandProperty Name

if($ag1check -ne $null)
{$textbox7.text += "$ag1 already exists. Exiting the script `r`n";
Return;}
if($ag2check -ne $null)
{$textbox7.text += "$ag2 already exists. Exiting the script `r`n";
Return;}

$a = New-SqlAvailabilityGroup -Name $ag1 -Path "SQLSERVER:\SQL\$PRODSERVER1\DEFAULT" -AvailabilityReplica @($ag1primaryReplica,$ag1secondaryReplica) -AutomatedBackupPreference Primary -Database "TestAGdb" 
#$a = New-SqlAvailabilityGroup -InputObject $PRODSERVER1 -Name $ag1 -AvailabilityReplica $replicas -Database "TestAGdb" 
$textbox7.text += "10. Joining the secondary replica $PRD2 to the Availability group $ag1 `r`n"
$a = Join-SqlAvailabilityGroup -Path "SQLSERVER:\SQL\$PRODSERVER2\DEFAULT" -Name $ag1  
$textbox7.text += "11. Joining the secondary database TestAGdb to the Availability group $ag1 `r`n"
$a = Add-SqlAvailabilityDatabase -Path "SQLSERVER:\SQL\$PRODSERVER2\DEFAULT\AvailabilityGroups\$ag1" -Database "TestAGdb" 
$textbox7.text += "12. Creating the listener. `r`n"
$a = New-SqlAvailabilityGroupListener -Name $ag1 -staticIP $ag1listenerip -Port $port -Path "SQLSERVER:\Sql\$PRODSERVER1\DEFAULT\AvailabilityGroups\$ag1"


$ServerObject = Get-Item "SQLSERVER:\SQL\$DRSERVER1\Default"
$DR1FQDN = [System.Net.Dns]::GetHostByName($DR1) | select -ExpandProperty  hostname
$DR2FQDN = [System.Net.Dns]::GetHostByName($DR2) | select -ExpandProperty  hostname
$DR1EndPointURL = "TCP://" + $DR1FQDN + ":5022"
$DR2EndPointURL = "TCP://" + $DR2FQDN + ":5022"
$ag2primaryReplica = New-SqlAvailabilityReplica -Name $DR1 -EndpointUrl $DR1EndPointURL -AvailabilityMode "SynchronousCommit" -FailoverMode 'Automatic' -AsTemplate -Version $ServerObject.version
$ag2secondaryReplica = New-SqlAvailabilityReplica -Name $DR2 -EndpointUrl $DR2EndPointURL -AvailabilityMode "SynchronousCommit" -FailoverMode 'Automatic' -AsTemplate -Version $ServerObject.version
$textbox7.text += "13. Creating the second Availability group $ag2 `r`n"


$a = New-SqlAvailabilityGroup -Name $ag2 -Path "SQLSERVER:\SQL\$DRSERVER1\DEFAULT" -AvailabilityReplica @($ag2primaryReplica,$ag2secondaryReplica) -AutomatedBackupPreference Primary 
#$a = New-SqlAvailabilityGroup -InputObject $PRODSERVER1 -Name $ag1 -AvailabilityReplica $replicas -Database "TestAGdb" 
$textbox7.text += "14. Joining the secondary replica $DR2 to the Availability group $ag2 `r`n"
$a = Join-SqlAvailabilityGroup -Path "SQLSERVER:\SQL\$DRSERVER2\DEFAULT" -Name $ag2  

$textbox7.text += "15. Creating the listener. `r`n"
$a = New-SqlAvailabilityGroupListener -Name $ag2 -staticIP $ag2listenerip -Port $port -Path "SQLSERVER:\Sql\$DRSERVER1\DEFAULT\AvailabilityGroups\$ag2"
$textbox7.text += "16. Creating the Distributed AG : $dag `r`n"
$grantcreateanydatabase1 = "ALTER AVAILABILITY GROUP [$ag1] GRANT CREATE ANY DATABASE"
$grantcreateanydatabase2 = "ALTER AVAILABILITY GROUP [$ag2] GRANT CREATE ANY DATABASE"

$a = Invoke-SqlCmd -ServerInstance $PRODSERVER1 -Query $grantcreateanydatabase1
$a = Invoke-SqlCmd -ServerInstance $PRODSERVER2 -Query $grantcreateanydatabase1
$a = Invoke-SqlCmd -ServerInstance $DRSERVER1 -Query $grantcreateanydatabase2
$a = Invoke-SqlCmd -ServerInstance $DRSERVER2 -Query $grantcreateanydatabase2

$AG1FQDN = [System.Net.Dns]::GetHostByName($ag1) | select -ExpandProperty  hostname
$AG2FQDN = [System.Net.Dns]::GetHostByName($ag2) | select -ExpandProperty  hostname
$AG1ListenerURL = "TCP://" + $AG1FQDN + ":5022"
$AG2ListenerURL = "TCP://" + $AG2FQDN + ":5022"

$createDistributedAG =  @"
                        CREATE AVAILABILITY GROUP [$dag] 
                        WITH (DISTRIBUTED)  
                        AVAILABILITY GROUP ON 
                        '$ag1' WITH   
                        (  
                        LISTENER_URL = '$AG1ListenerURL',   
                        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
                        FAILOVER_MODE = MANUAL,  
                        SEEDING_MODE = AUTOMATIC  
                        ),  
                        '$ag2' WITH   
                        (  
                        LISTENER_URL = '$AG2ListenerURL',  
                        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
                        FAILOVER_MODE = MANUAL,  
                        SEEDING_MODE = AUTOMATIC  
                        );   
                        GO 
"@
$joinDistributedAG =  @"
                        ALTER AVAILABILITY GROUP [$dag] 
                        JOIN  
                        AVAILABILITY GROUP ON 
                        '$ag1' WITH   
                        (  
                        LISTENER_URL = '$AG1ListenerURL',   
                        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
                        FAILOVER_MODE = MANUAL,  
                        SEEDING_MODE = AUTOMATIC  
                        ),  
                        '$ag2' WITH   
                        (  
                        LISTENER_URL = '$AG2ListenerURL',  
                        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
                        FAILOVER_MODE = MANUAL,  
                        SEEDING_MODE = AUTOMATIC  
                        );   
                        GO 
"@

$a = Invoke-SqlCmd -ServerInstance $PRODSERVER1 -Query $createDistributedAG
$a = Invoke-SqlCmd -ServerInstance $DRSERVER1 -Query $joinDistributedAG

$secondarydbjoin = "ALTER DATABASE [TestAGdb] SET HADR AVAILABILITY GROUP = [$ag2]; "
try {
$a = Invoke-SqlCmd -ServerInstance $DRSERVER2 -Query $secondarydbjoin -ErrorAction Stop
}
catch
{
Start-Sleep -s 10
try
{$a = Invoke-SqlCmd -ServerInstance $DRSERVER2 -Query $secondarydbjoin -ErrorAction Stop}
catch { 
        $textbox7.text += "NOTE: Unable to join the TestAGdb database on $DR2 . Please join it manually.`r`n"
        }

}
$textbox7.text += "17. Successfully created the distributed AG`r`n"
 $Okbutton.Enabled = $true;
#$textbox7.text += $PRODSERVER1
}


$Form = New-Object system.Windows.Forms.Form
$Form.Size = New-Object System.Drawing.Size(800,600)
#You can use the below method as well
#$Form.Width = 400
#$Form.Height = 200
$form.MaximizeBox = $false
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = 'Fixed3D'
$Form.Text = "Distributed AG Configuration"

$Label1 = New-Object System.Windows.Forms.Label
$Label1.Text = "Please enter the below details to create a Distributed AvailabilityGroup"
$Label1.AutoSize = $true
$Label1.Location = New-Object System.Drawing.Size(0,0)
$Font = New-Object System.Drawing.Font("Calibri",15,[System.Drawing.FontStyle]::Regular)



$ag1Label = New-Object System.Windows.Forms.Label
$ag1Label.Text = "AG1 :"
$ag1Label.AutoSize = $true
$ag1Label.Location = New-Object System.Drawing.Size(400,30)


$ag1text = New-Object System.Windows.Forms.TextBox
$ag1text.Location = New-Object System.Drawing.Point(550,30)
$ag1text.Size = New-Object System.Drawing.Size(200,20)


$ag2text = New-Object System.Windows.Forms.TextBox
$ag2text.Location = New-Object System.Drawing.Point(550,110)
$ag2text.Size = New-Object System.Drawing.Size(200,20)


$dagtext = New-Object System.Windows.Forms.TextBox
$dagtext.Location = New-Object System.Drawing.Point(550,190)
$dagtext.Size = New-Object System.Drawing.Size(200,20)


$ag2Label = New-Object System.Windows.Forms.Label
$ag2Label.Text = "AG2 :"
$ag2Label.AutoSize = $true
$ag2Label.Location = New-Object System.Drawing.Size(400,110)

$Label4 = New-Object System.Windows.Forms.Label
$Label4.Text = "Distributed AG :"
$Label4.AutoSize = $true
$Label4.Location = New-Object System.Drawing.Size(400,190)

$Label5 = New-Object System.Windows.Forms.Label
$Label5.Text = "Port Number :"
$Label5.AutoSize = $true
$Label5.Location = New-Object System.Drawing.Size(0,190)

$porttext = New-Object System.Windows.Forms.TextBox
$porttext.Location = New-Object System.Drawing.Point(150,190)
$porttext.Size = New-Object System.Drawing.Size(200,20)


$Label6 = New-Object System.Windows.Forms.Label
$Label6.Text = "AG1 IP :"
$Label6.AutoSize = $true
$Label6.Location = New-Object System.Drawing.Size(400,70)

$ag1iptext = New-Object System.Windows.Forms.TextBox
$ag1iptext.Location = New-Object System.Drawing.Point(550,70)
$ag1iptext.Size = New-Object System.Drawing.Size(200,20)

$Label7 = New-Object System.Windows.Forms.Label
$Label7.Text = "AG2 IP  :"
$Label7.AutoSize = $true
$Label7.Location = New-Object System.Drawing.Size(400,150)

$ag2iptext = New-Object System.Windows.Forms.TextBox
$ag2iptext.Location = New-Object System.Drawing.Point(550,150)
$ag2iptext.Size = New-Object System.Drawing.Size(200,20)

$textBox7 = New-Object System.Windows.Forms.TextBox
$textBox7.Multiline = $True;
$textBox7.Location = New-Object System.Drawing.Point(10,300)
$textBox7.Size = New-Object System.Drawing.Size(740,200)
$textBox7.Scrollbars = "Vertical" 

$Label8 = New-Object System.Windows.Forms.Label
$Label8.Text = "Prod Server - 1 :"
$Label8.AutoSize = $true
$Label8.Location = New-Object System.Drawing.Size(0,30)

$Label9 = New-Object System.Windows.Forms.Label
$Label9.Text = "Prod Server - 2 :"
$Label9.AutoSize = $true
$Label9.Location = New-Object System.Drawing.Size(0,70)

$Label10 = New-Object System.Windows.Forms.Label
$Label10.Text = "DR Server - 1 :"
$Label10.AutoSize = $true
$Label10.Location = New-Object System.Drawing.Size(0,110)

$Label11 = New-Object System.Windows.Forms.Label
$Label11.Text = "DR Server - 2 :"
$Label11.AutoSize = $true
$Label11.Location = New-Object System.Drawing.Size(0,150)

$prod1text = New-Object System.Windows.Forms.TextBox
$prod1text.Location = New-Object System.Drawing.Point(150,30)
$prod1text.Size = New-Object System.Drawing.Size(200,20)

$prod2text = New-Object System.Windows.Forms.TextBox
$prod2text.Location = New-Object System.Drawing.Point(150,70)
$prod2text.Size = New-Object System.Drawing.Size(200,20)

$dr1text = New-Object System.Windows.Forms.TextBox
$dr1text.Location = New-Object System.Drawing.Point(150,110)
$dr1text.Size = New-Object System.Drawing.Size(200,20)

$dr2text = New-Object System.Windows.Forms.TextBox
$dr2text.Location = New-Object System.Drawing.Point(150,150)
$dr2text.Size = New-Object System.Drawing.Size(200,20)


<#
$prod1text.Text = "NWFLOTDBLAB1-1"
$prod2text.Text = "NWFLOTDBLAB1-2"
$dr1text.Text = "NWGRATDBLAB1-1"
$dr2text.Text = "NWGRATDBLAB1-2"
$porttext.Text = "53734"
$ag1text.Text = "NVFLOTDBLAB1CA1"
$ag1iptext.Text = "10.100.166.172"
$ag2text.Text = "NVGRATDBLAB1CA1"
$ag2iptext.Text = "10.101.162.180"
$dagtext.Text = "NVFLOTDBLAB1DA1"

#>


$form.Font = $Font
$Form.Controls.Add($Label1)
$Form.Controls.Add($ag1Label)
$Form.Controls.Add($ag2Label)
$Form.Controls.Add($Label4)
$Form.Controls.Add($Label5)
$Form.Controls.Add($Label6)
$Form.Controls.Add($Label7)
$Form.Controls.Add($Label8)
$Form.Controls.Add($Label9)
$Form.Controls.Add($Label10)
$Form.Controls.Add($Label11)
$Form.Controls.Add($ag1text)
$Form.Controls.Add($ag2text)
$Form.Controls.Add($dagtext)
$Form.Controls.Add($porttext)
$Form.Controls.Add($ag1iptext)
$Form.Controls.Add($ag2iptext)
$Form.Controls.Add($textBox7)
$Form.Controls.Add($prod1text)
$Form.Controls.Add($prod2text)
$Form.Controls.Add($dr1text)
$Form.Controls.Add($dr2text)

#$formIcon = New-Object system.drawing.icon ("$env:USERPROFILE\desktop\Blog\v.ico")
#$form.Icon = $formicon

$Okbutton = New-Object System.Windows.Forms.Button
$Okbutton.Location = New-Object System.Drawing.Size(5,250)
$Okbutton.Size = New-Object System.Drawing.Size(120,30)
$Okbutton.Text = "PROCEED"
$Okbutton.Add_Click({AG-Creation})
$Form.Controls.Add($Okbutton)

$Form.ShowDialog()
