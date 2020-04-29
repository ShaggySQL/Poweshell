[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Windows.Forms.Application]::EnableVisualStyles()
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended') | out-null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SQLWMIManagement') | out-null

$global:cFlag = 2

function AG-Creation
{
$Okbutton.Enabled = $false;

$ag1 = $ag1text.Text
$ag1ip = $ag1iptext.Text
$port = $porttext.Text
$PRD1 = $prod1text.Text
$PRD2 = $prod2text.Text
$insname = $instypetext.Text

$PRODSERVER1 = $PRD1 + "," + $port
$PRODSERVER2 = $PRD2 + "," + $port

if (!$PRD1) { [System.Windows.MessageBox]::Show('Server - 1 cannot be blank'); $Okbutton.Enabled = $true; Return }
if (!$PRD2) { [System.Windows.MessageBox]::Show('Server - 2 cannot be blank'); $Okbutton.Enabled = $true; Return }
if (!$port) { [System.Windows.MessageBox]::Show('Port Number cannot be blank'); $Okbutton.Enabled = $true; Return }
if (!$ag1) { [System.Windows.MessageBox]::Show('Availability group name cannot be blank'); $Okbutton.Enabled = $true; Return }
if (!$ag1ip) { [System.Windows.MessageBox]::Show('Availability group IP cannot be blank'); $Okbutton.Enabled = $true; Return }
if ($cFlag -eq 2) { [System.Windows.MessageBox]::Show('Instance Type needs to be chosen'); $Okbutton.Enabled = $true; Return }
if ($cFlag -eq 1) { if (!$insname){[System.Windows.MessageBox]::Show('Instance Name cannot be blank'); $Okbutton.Enabled = $true; Return }}
$a = Invoke-Command -computername $PRD1 -scriptblock {$env:computername} -ErrorAction SilentlyContinue
            if ($?)
            {}
            else
            {
                $err_message = "Unable to reach the server : $PRD1 `r`n`r`nError Message:`r`n"
                $err_message = $err_message + $error[0].Exception
                [System.Windows.MessageBox]::Show($err_message)
                $Okbutton.Enabled = $true; Return 
             }
$a = Invoke-Command -computername $PRD2 -scriptblock {$env:computername} -ErrorAction SilentlyContinue
            if ($?)
            {}
            else
            {
                $err_message = "Unable to reach the server : $PRD2 `r`n`r`nError Message:`r`n"
                $err_message = $err_message + $error[0].Exception
                [System.Windows.MessageBox]::Show($err_message)
                $Okbutton.Enabled = $true; Return 
             }

$PRD1ip = Test-Connection -ComputerName $PRD1 -Count 1  | Select -ExpandProperty IPV4Address | select -ExpandProperty IPAddressToString

$ag1ipsubnet = Get-WmiObject -ComputerName $PRD1 Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -eq $PRD1ip } | select -ExpandProperty IpSubnet
$ag1ipsubnet = $ag1ipsubnet | Select-Object -First 1

$ag1listenerip = $ag1ip + "/" + $ag1ipsubnet

try
{

Import-Module SQLServer -DisableNameChecking -ErrorAction Stop

}
catch
{
$textbox7.text = $_.Exception.Message;$textbox7.SelectionStart = $textbox7.TextLength;$textbox7.ScrollToCaret();
$Okbutton.Enabled = $true;
Return;
}
$textbox7.text = "1. Enabling SqlAlwaysOn Feature on both servers - Takes approximately 2 minutes.`r`n";
if($cFlag -eq 0)
{
$agt1 = "SQLSERVERAGENT"
$aginstance = "Default"
Invoke-Command -ComputerName $PRD1 -ScriptBlock { Enable-SqlAlwaysOn -ServerInstance $using:PRD1 -Force }
Invoke-Command -ComputerName $PRD2 -ScriptBlock { Enable-SqlAlwaysOn -ServerInstance $using:PRD2 -Force } 

}
if($cFlag -eq 1)
{
$agt1 = "SQLAgent$" + $insname
$insname = $insname.Trim()
$aginstance = $insname
$PRD1instance = $PRD1 + "\" + $insname
$PRD2instance = $PRD2 + "\" + $insname
Invoke-Command -ComputerName $PRD1 -ScriptBlock { Enable-SqlAlwaysOn -ServerInstance $using:PRD1instance -Force }
Invoke-Command -ComputerName $PRD2 -ScriptBlock { Enable-SqlAlwaysOn -ServerInstance $using:PRD2instance -Force } 
}
Get-Service -Name $agt1 -ComputerName $PRD1 | Restart-Service -Force
Get-Service -Name $agt1 -ComputerName $PRD2 | Restart-Service -Force

$s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $PRODSERVER1
$ag1check = $s.AvailabilityGroups | where { $_.Name -eq $ag1} | select -ExpandProperty Name

if($ag1check -ne $null)
{$textbox7.text += "$ag1 already exists. Exiting the script `r`n";
$Okbutton.Enabled = $true; Return;}

$textbox7.text += "2. Performing below steps to Create Availabilty Group : $ag1 `r`n";$textbox7.SelectionStart = $textbox7.TextLength;$textbox7.ScrollToCaret();

$textbox7.text += "3. Creating and starting the Endpoints on both the servers, if it isn't already. `r`n";$textbox7.SelectionStart = $textbox7.TextLength;$textbox7.ScrollToCaret();
$textbox7.text += "4. Granting CONNECT ON ENDPOINT permissions and Starting the extended events session for AlwaysOn. `r`n";$textbox7.SelectionStart = $textbox7.TextLength;$textbox7.ScrollToCaret();
        $s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $PRODSERVER1
        $svcactPRD1 = $s.ServiceAccount
        $s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server $PRODSERVER2
        $svcactPRD2 = $s.ServiceAccount
        
        
foreach($srv1 in $PRD1,$PRD2)
{
        
        $s = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server "$srv1,$port"
        $CreateEndpointFlag = $s.Endpoints | where {$_.Name -eq "Hadr_endpoint"}
        
        if($CreateEndpointFlag -ne $null)
        {
            $StartEndpointFlag = $s.Endpoints | where {$_.Name -eq "Hadr_endpoint"} | select -ExpandProperty EndpointState
            if($StartEndpointFlag -ne "Started")
            {
    
                $a = Set-SqlHADREndpoint -Path "SQLSERVER:\SQL\$srv1\$aginstance,$port\Endpoints\Hadr_endpoint" -State Started
               # Invoke-SqlCmd -ServerInstance $PRODSERVER1 -Query $query
            }
            #$textbox7.text += "8. Hadr_endpoint Endpoint already exists and is started on $srv1. `r`n";

        }
        else
        {
            
            $a = New-SqlHADREndpoint -Path "SQLSERVER:\SQL\$srv1\$aginstance,$port" -Name "Hadr_endpoint" -Port 5022
            $a = Set-SqlHADREndpoint -Path "SQLSERVER:\SQL\$srv1\$aginstance,$port\Endpoints\Hadr_endpoint" -State Started
            #$textbox7.text += "8. Hadr_endpoint Endpoint created and started on $srv1. `r`n";
        }

        $createLogin = "IF  NOT EXISTS (select loginname from master.dbo.syslogins where name like '%$svcactPRD1%') CREATE LOGIN [$svcactPRD1] FROM WINDOWS"
        $grantConnectPermissions = "GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$svcactPRD1]"
        $a = Invoke-SqlCmd -ServerInstance "$srv1,$port" -Query $createLogin
        $a = Invoke-SqlCmd -ServerInstance "$srv1,$port" -Query $grantConnectPermissions
        $createLogin = "IF  NOT EXISTS (select loginname from master.dbo.syslogins where name like '%$svcactPRD2%') CREATE LOGIN [$svcactPRD2] FROM WINDOWS"
        $grantConnectPermissions = "GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [$svcactPRD2]"
        $a = Invoke-SqlCmd -ServerInstance "$srv1,$port" -Query $createLogin
        $a = Invoke-SqlCmd -ServerInstance "$srv1,$port" -Query $grantConnectPermissions
        

        $exevent1 = "IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name='AlwaysOn_health') ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE=ON);"
        $exevent2 = "IF NOT EXISTS (SELECT * FROM sys.dm_xe_sessions WHERE name='AlwaysOn_health') ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=START;"
        $a = Invoke-SqlCmd -ServerInstance "$srv1,$port" -Query $exevent1
        $a = Invoke-SqlCmd -ServerInstance "$srv1,$port" -Query $exevent2
        $alterendpoint = "ALTER ENDPOINT [Hadr_endpoint] AS TCP (LISTENER_IP = ALL)"
        $a = Invoke-SqlCmd -ServerInstance "$srv1,$port" -Query $alterendpoint

}
$PRD1 = Invoke-command -computerName $PRD1 -ScriptBlock {$env:COMPUTERNAME}
$PRD2 = Invoke-command -computerName $PRD2 -ScriptBlock {$env:COMPUTERNAME}
$ServerObject = Get-Item "SQLSERVER:\SQL\$PRD1\$aginstance,$port"
$PRD1FQDN = [System.Net.Dns]::GetHostByName($PRD1) | select -ExpandProperty  hostname
$PRD2FQDN = [System.Net.Dns]::GetHostByName($PRD2) | select -ExpandProperty  hostname
$PRD1EndPointURL = "TCP://" + $PRD1FQDN + ":5022"
$PRD2EndPointURL = "TCP://" + $PRD2FQDN + ":5022"
if($aginstance -eq "Default")
{
$ag1primaryReplica = New-SqlAvailabilityReplica -Name "$PRD1" -EndpointUrl $PRD1EndPointURL -AvailabilityMode "SynchronousCommit" -FailoverMode 'Automatic' -AsTemplate -Version $ServerObject.version
$ag1secondaryReplica = New-SqlAvailabilityReplica -Name "$PRD2" -EndpointUrl $PRD2EndPointURL -AvailabilityMode "SynchronousCommit" -FailoverMode 'Automatic' -AsTemplate -Version $ServerObject.version
}
else
{
$ag1primaryReplica = New-SqlAvailabilityReplica -Name "$PRD1\$aginstance" -EndpointUrl $PRD1EndPointURL -AvailabilityMode "SynchronousCommit" -FailoverMode 'Automatic' -AsTemplate -Version $ServerObject.version
$ag1secondaryReplica = New-SqlAvailabilityReplica -Name "$PRD2\$aginstance" -EndpointUrl $PRD2EndPointURL -AvailabilityMode "SynchronousCommit" -FailoverMode 'Automatic' -AsTemplate -Version $ServerObject.version
}
$textbox7.text += "5. Creating the Availability group $ag1 `r`n";$textbox7.SelectionStart = $textbox7.TextLength;$textbox7.ScrollToCaret();



try{
#$test = "New-SqlAvailabilityGroup -InputObject ""$PRD1,$port"" -Name $ag1 -AvailabilityReplica @($ag1primaryReplica,$ag1secondaryReplica) -AutomatedBackupPreference Primary -Database ""TestAGdb"" "
#$textbox7.text +=$test
$a = New-SqlAvailabilityGroup -InputObject "$PRD1,$port" -Name $ag1 -AvailabilityReplica @($ag1primaryReplica,$ag1secondaryReplica) -AutomatedBackupPreference Primary  
}
catch
{
$agError = "AG Creation Failed with the below error:`r`n`r`nError Message:`r`n"
$agError = $agError + $error[0].Exception
$textbox7.text += "AG Creation Failed. `r`n";$textbox7.SelectionStart = $textbox7.TextLength;$textbox7.ScrollToCaret();
[System.Windows.MessageBox]::Show($agError)

$Okbutton.Enabled = $true; Return;
}
#$a = New-SqlAvailabilityGroup -InputObject $PRODSERVER1 -Name $ag1 -AvailabilityReplica $replicas -Database "TestAGdb" 
$textbox7.text += "6. Joining the secondary replica $PRD2 to the Availability group $ag1 `r`n";$textbox7.SelectionStart = $textbox7.TextLength;$textbox7.ScrollToCaret();
$a = Join-SqlAvailabilityGroup -Path "SQLSERVER:\SQL\$PRD2\$aginstance,$port" -Name $ag1  
$textbox7.text += "7. Creating the listener. `r`n";$textbox7.SelectionStart = $textbox7.TextLength;$textbox7.ScrollToCaret(); 
$listenercreationcmd = "New-SqlAvailabilityGroupListener -Name $ag1 -staticIP $ag1listenerip -Port $port -Path 'SQLSERVER:\Sql\$PRD1\$aginstance,$port\AvailabilityGroups\$ag1'"
try
{
Invoke-Expression $listenercreationcmd -ErrorVariable $err
}
catch
{
$listenerError = "Listener Creation Failed with the below error:`r`n`r`nError Message:`r`n"
$listenerError = $listenerError + $error[0].Exception
$textbox7.text += "Listener creation failed. `r`n";$textbox7.SelectionStart = $textbox7.TextLength;$textbox7.ScrollToCaret();
[System.Windows.MessageBox]::Show($listenerError)

$Okbutton.Enabled = $true; Return;
}
$textbox7.text += "8. Listener created successfully. `r`n14. Availability Group created successfully`r`n";$textbox7.SelectionStart = $textbox7.TextLength;$textbox7.ScrollToCaret();[System.Windows.Forms.Application]::DoEvents(); 

$grantcreateanydatabase1 = "ALTER AVAILABILITY GROUP [$ag1] GRANT CREATE ANY DATABASE"


$a = Invoke-SqlCmd -ServerInstance $PRODSERVER1 -Query $grantcreateanydatabase1
$a = Invoke-SqlCmd -ServerInstance $PRODSERVER2 -Query $grantcreateanydatabase1



 $Okbutton.Enabled = $true;
#$textbox7.text += $PRODSERVER1
}


$Form = New-Object system.Windows.Forms.Form
$Form.Size = New-Object System.Drawing.Size(850,650)
#You can use the below method as well
#$Form.Width = 400
#$Form.Height = 200
$form.MaximizeBox = $false
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = 'Fixed3D'
$Form.Text = "AG Creation without Database"

$Label1 = New-Object System.Windows.Forms.Label
$Label1.Text = "Please enter the below details to create an AvailabilityGroup without a Database"
$Label1.AutoSize = $true
$Label1.Location = New-Object System.Drawing.Size(0,0)
$Font = New-Object System.Drawing.Font("Calibri",15,[System.Drawing.FontStyle]::Regular)



$ag1Label = New-Object System.Windows.Forms.Label
$ag1Label.Text = "Availability Group Name :"
$ag1Label.AutoSize = $true
$ag1Label.Location = New-Object System.Drawing.Size(0,110)


$ag1text = New-Object System.Windows.Forms.TextBox
$ag1text.Location = New-Object System.Drawing.Point(300,110)
$ag1text.Size = New-Object System.Drawing.Size(300,20)



$Label5 = New-Object System.Windows.Forms.Label
$Label5.Text = "Port Number :"
$Label5.AutoSize = $true
$Label5.Location = New-Object System.Drawing.Size(0,190)

$porttext = New-Object System.Windows.Forms.TextBox
$porttext.Location = New-Object System.Drawing.Point(300,190)
$porttext.Size = New-Object System.Drawing.Size(300,20)


$Label6 = New-Object System.Windows.Forms.Label
$Label6.Text = "Availability Group IP :"
$Label6.AutoSize = $true
$Label6.Location = New-Object System.Drawing.Size(0,150)

$ag1iptext = New-Object System.Windows.Forms.TextBox
$ag1iptext.Location = New-Object System.Drawing.Point(300,150)
$ag1iptext.Size = New-Object System.Drawing.Size(300,20)



$textBox7 = New-Object System.Windows.Forms.TextBox
$textBox7.Multiline = $True;
$textBox7.Location = New-Object System.Drawing.Point(10,400)
$textBox7.Size = New-Object System.Drawing.Size(740,200)
$textBox7.Scrollbars = "Vertical" 

$Label8 = New-Object System.Windows.Forms.Label
$Label8.Text = "Fully Qualified Server Name - 1 :"
$Label8.AutoSize = $true
$Label8.Location = New-Object System.Drawing.Size(0,30)

$Label9 = New-Object System.Windows.Forms.Label
$Label9.Text = "Fully Qualified Server Name - 2 :"
$Label9.AutoSize = $true
$Label9.Location = New-Object System.Drawing.Size(0,70)



$prod1text = New-Object System.Windows.Forms.TextBox
$prod1text.Location = New-Object System.Drawing.Point(300,30)
$prod1text.Size = New-Object System.Drawing.Size(300,20)

$prod2text = New-Object System.Windows.Forms.TextBox
$prod2text.Location = New-Object System.Drawing.Point(300,70)
$prod2text.Size = New-Object System.Drawing.Size(300,20)

$instypeLabel = New-Object System.Windows.Forms.Label
$instypeLabel.Text = "Instance Type :"
$instypeLabel.AutoSize = $true
$instypeLabel.Location = New-Object System.Drawing.Size(0,230)
$instypeLabel.Visible = $true
$form.Controls.Add($instypeLabel)

$instypedropdown = New-Object System.Windows.Forms.ComboBox
$instypedropdown.Location = New-Object System.Drawing.Point(300,230)
$instypedropdown.Size = New-Object System.Drawing.Size(300,20)
#[void] $instypedropdown.BeginUpdate()
[void] $instypedropdown.Items.add("")
[void] $instypedropdown.Items.add("Default")
[void] $instypedropdown.Items.add("Named")
$instypedropdown.SelectedIndex=0
#if ($instypedropdown.SelectedItem -eq "Named") {$insnameLabel.Visible = $true;$instypetext.Visible = $true}
$instypedropdown.add_SelectedIndexChanged({if ($instypedropdown.SelectedItem -eq "Named") {$insnameLabel.Visible = $true;$instypetext.Visible = $true; $global:cFlag = 1}}) 
$instypedropdown.add_SelectedIndexChanged({if ($instypedropdown.SelectedItem -eq "Default") {$insnameLabel.Visible = $false;$instypetext.Visible = $false; $global:cFlag = 0}}) 
$instypedropdown.add_SelectedIndexChanged({if ($instypedropdown.SelectedItem -eq "") {$insnameLabel.Visible = $false;$instypetext.Visible = $false ; $global:cFlag = 2}}) 

#[void] $instypedropdown.endUpdate()
$instypedropdown.Visible = $true
$instypedropdown.DropDownStyle = "DropDownList"
$form.Controls.Add($instypedropdown)
$insnameLabel = New-Object System.Windows.Forms.Label
$insnameLabel.Text = "Instance Name :"
$insnameLabel.AutoSize = $true
$insnameLabel.Location = New-Object System.Drawing.Size(0,270)
$insnameLabel.Visible = $false
$form.Controls.Add($insnameLabel)

$instypetext = New-Object System.Windows.Forms.TextBox
$instypetext.Location = New-Object System.Drawing.Point(300,270)
$instypetext.Size = New-Object System.Drawing.Size(300,20)
$instypetext.Visible = $false
$form.Controls.Add($instypetext)

<#

$prod1text.Text = "PWFLOPSQL001C-1.AD001.infoftps.com"
$prod2text.Text = "PWFLOPSQL001C-2.AD001.infoftps.com"

$porttext.Text = "53691"
$ag1text.Text = "PVFLOPSQL001CA1"
$ag1iptext.Text = "10.104.11.157"

#>



$form.Font = $Font
$Form.Controls.Add($Label1)
$Form.Controls.Add($ag1Label)
$Form.Controls.Add($Label5)
$Form.Controls.Add($Label6)
$Form.Controls.Add($Label8)
$Form.Controls.Add($Label9)
$Form.Controls.Add($prod1text)
$Form.Controls.Add($prod2text)
$Form.Controls.Add($ag1text)

$Form.Controls.Add($porttext)
$Form.Controls.Add($ag1iptext)

$Form.Controls.Add($textBox7)



#$formIcon = New-Object system.drawing.icon ("$env:USERPROFILE\desktop\Blog\v.ico")
#$form.Icon = $formicon

$Okbutton = New-Object System.Windows.Forms.Button
$Okbutton.Location = New-Object System.Drawing.Size(5,350)
$Okbutton.Size = New-Object System.Drawing.Size(120,30)
$Okbutton.Text = "PROCEED"
$Okbutton.Add_Click({AG-Creation})
$Form.Controls.Add($Okbutton)

$Form.ShowDialog()
