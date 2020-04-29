[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Windows.Forms.Application]::EnableVisualStyles()
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended') | out-null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SQLWMIManagement') | out-null
$global:iFlag = 0
$global:cFlag = 1
$global:vFlag = 0
$global:spFlag = 0
$global:edFlag = 0
$global:copyFlag = 0
$global:ssmsFlag = 0
$global:ssmstargetlocation = ""
$global:ssmstargetloglocation = ""
$global:spdestlocationforupdate = ""
$global:ValidationRepositoryServer = "PWGR2RSQLDB1C-2.PROD.PB01.LOCAL,62754"
$global:setupbootstraplog = ""
$global:setupbootstrapsummary = ""
Function Post-Install-Config
{
    
        
    $outputtext.Text = $null
    $ServerName = $servertext.Text.ToString().split("\\")[0];

    
    $InsNames = $servertext.Text.ToString().split("\\")[1];


    $ServerName = $ServerName.ToUpper();
    $serveruserfield = $servertext.Text.ToString()
    if($serveruserfield.count -le 0 -or !$serveruserfield) {[System.Windows.MessageBox]::Show('ServerName cannot be blank'); $skipbutton.Enabled = $true;$okbutton.Visible = $true; Return}
    
    $response = [System.Windows.MessageBox]::Show("Proceed with Post-Install Configuration & hardening on $ServerName ?","Validation Check",'YesNoCancel','Question')
        if($response -eq "No" -or $response -eq "Cancel"){ $displayLabel.Text = "Exiting the script";$skipbutton.Enabled = $true;return;}
        else
        {
    $displayLabel.Text = "Performing Post-Install Configuration and Hardening on $ServerName"
    $outputtext.Visible = $true
    $dataGridView.Visible = $false;$dataGridView2.Visible = $false; $dataGridView3.Visible = $false;
    $okbutton.Visible = $false
    $skipbutton.Enabled = $false

    $a = Invoke-Command -computername $ServerName -scriptblock {$env:computername} -ErrorAction SilentlyContinue
            if ($?)
            {$Form.Cursor=[System.Windows.Forms.Cursors]::WaitCursor}
            else
            {[System.Windows.MessageBox]::Show($error[0].Exception)
             $displayLabel.Text = "Exiting the script"
             $skipbutton.Enabled = $true;$Form.Cursor=[System.Windows.Forms.Cursors]::Cursor; return;
               
             }

        if($ServerName -like "*\*"){ $Server = $ServerName.Split("\")[0]; $InsNames = $ServerName.Split("\")[1] } else { $Server = $ServerName }
                    
                       
                         try
                         {
                            $outputtext.Text = $null
                            $job = Start-Job -FilePath "D:\scripts\FullyAutomatedSQLInstall\SQLPostConfig\SQLPostConfig.ps1" -ArgumentList $Server,$InsNames
                            
                            While (Get-Job -State "Running") 
                            {
                                $jobprogress = Receive-Job -Job $job; if($jobprogress.Length -gt 0){$outputtext.Text += $jobprogress;[System.Windows.Forms.Application]::DoEvents();$outputtext.SelectionStart = $outputtext.TextLength;$outputtext.ScrollToCaret();$outputtext.Focus();}  
                            }

                            if($outputtext.Text -like "*Configuration Failed*")
                            {$outputtext.Text += "`r`n`r`n`r`nConfiguration Failed. Review the error and retry."
                            $outputtext.SelectionStart = $outputtext.TextLength;$outputtext.ScrollToCaret();$outputtext.Focus();
                            $skipbutton.Enabled = $true
                            $displayLabel.Text = "Configuration Failed. Review the error and retry.";$Form.Cursor=[System.Windows.Forms.Cursors]::Cursor  ;return;
                            }
                            else
                            {
                            $outputtext.Text += "`r`n`r`n`r`nSuccessfully Configured SQL Server. Review the results and proceed with the post validation."
                            $outputtext.SelectionStart = $outputtext.TextLength;$outputtext.ScrollToCaret();$outputtext.Focus();
                            }
                         }
                         catch
                         {
                         $outputtext.Text += $_.Exception.Message
                         
                         [System.Windows.Forms.Application]::DoEvents();$outputtext.SelectionStart = $outputtext.TextLength;$outputtext.ScrollToCaret();$outputtext.Focus();
                         exit
                         }   

        $skipbutton.Visible = $false
        $okbutton.Visible = $true
        $displayLabel.Text = "Successfully Configured SQL Server."
        $okbutton.Text = "Click to Perform Post Install Validation"    
        $okbutton.BackColor = "Yellow"
        #$skipbutton.Enabled = $true
        $global:iFlag  = 3
        #OK-button_Check
    #$skipbutton.Enabled = $true
    $Form.Cursor=[System.Windows.Forms.Cursors]::Cursor  
    }
}

Function OK-button_Check{

$dataGridView.Visible = $false;$dataGridView2.Visible = $false; $dataGridView3.Visible = $false;
$Okbutton.Enabled = $false
$ServerName = $servertext.Text.ToString();
$ServerName = $ServerName.ToUpper();
$sapwd = $sapwdtext.text.ToString();
$sqlgrp = $sqlacttext.text.ToString();
$insName = $instypetext.Text.ToString();

if($iFlag -eq 3)
    {
        $outputtext.Visible = $false
        if($ServerName.count -le 0 -or !$ServerName) {[System.Windows.MessageBox]::Show('ServerName cannot be blank'); $Okbutton.Enabled = $true;$Form.Cursor=[System.Windows.Forms.Cursors]::Cursor; Return}
        $a = Invoke-Command -computername $ServerName -scriptblock {$env:computername} -ErrorAction SilentlyContinue
            if ($?)
            {}
            else
            {[System.Windows.MessageBox]::Show($error[0].Exception)
             $Okbutton.Enabled = $true; $Form.Cursor=[System.Windows.Forms.Cursors]::Cursor;return;  
             }
        $response = [System.Windows.MessageBox]::Show("Proceed with POST Install Check on $ServerName ?","Validation Check",'YesNoCancel','Question')
        if($response -eq "No" -or $response -eq "Cancel"){ $displayLabel.Text = "Exiting the script";$Okbutton.Enabled = $true;$dataGridView.Visible = $false;$dataGridView2.Visible = $false; $dataGridView3.Visible = $false;$Form.Cursor=[System.Windows.Forms.Cursors]::Cursor;return;}
        else
        {
        $Form.Cursor=[System.Windows.Forms.Cursors]::WaitCursor
        $displayLabel.Text = "Performing Post-Install Validation Check"
        $result = & D:\scripts\FullyAutomatedSQLInstall\SQLBuildValidation\SQLBuildValidation.ps1 $ServerName POST
        $dataGridView4.Visible = $true
        $displayLabel.Text = "Post-Install Validation performed successfully. Review the results below:"
        
        }
        $CentralServer = $ValidationRepositoryServer
        $conn = New-Object System.Data.SqlClient.SqlConnection
        $cmd = New-Object System.Data.SqlClient.SqlCommand
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $dsControls = New-Object System.Data.DataSet
        $conn.ConnectionString = "Data Source=$CentralServer;Initial Catalog=INFODB;Integrated Security=SSPI;"
        $conn.open()
        $cmd.connection = $conn
        $cmd.CommandText = @"
                              SET NOCOUNT ON;SELECT RTRIM([ServerName]) AS ServerName
                                                  ,RTRIM([Control]) AS Control
                                                  ,RTRIM([Result]) AS Result
                                                  ,RTRIM([UserName]) AS UserName
                                                  ,RTRIM([DateCheckedOn]) AS DateCheckedOn
                                              FROM [INFODB].[build].[PostInstallMiscResults] where ServerName = '$postcheckservername' and DateCheckedOn in (select max(datecheckedon) from [INFODB].[build].[PostInstallMiscResults] where ServerName = '$postcheckservername')
                                            order by [DateCheckedOn] desc, serialID asc 
  
"@
        $adapter.SelectCommand = $cmd
        $adapter.Fill($dsControls) | Out-Null
        $dataGridView4.Visible = $true
        $dataGridView4.DataSource = $dsControls.tables[0]
        $dataGridView4.Columns | Foreach-Object{
                                                $_.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
                                                }
        $dataGridView4.ColumnHeadersHeight = 40
        $dataGridView4.AllowUserToAddRows = $false;
        $dataGridView4.AllowUserToDeleteRows = $false;
        $dataGridView4.AllowUserToOrderColumns = $true;
        $dataGridView4.ReadOnly = $true;
        $dataGridView4.AllowUserToResizeColumns = $false;
        $dataGridView4.AllowUserToResizeRows = $false;
        $c=$dataGridView4.RowCount
        for ($x=0;$x -lt $c;$x++) {
            for ($y=0;$y -lt $dataGridView4.Rows[$x].Cells.Count;$y++) {
                $value = $dataGridView4.Rows[$x].Cells[$y].Value
                
                Switch ($value) {
                    "No" {
                        $dataGridView4.Rows[$x].Cells[$y].Style.ForeColor=[System.Drawing.Color]::FromArgb(255,255,255,255)
                        $dataGridView4.Rows[$x].Cells[$y].Style.BackColor=[System.Drawing.Color]::FromArgb(255,255,0,0)
                    }
                }
            }
        }
        $Form.Cursor=[System.Windows.Forms.Cursors]::Cursor

    }

if($iFlag -eq 2)
    {
        $displayLabel.Text = ""
        if($ServerName.count -le 0 -or !$ServerName) {[System.Windows.MessageBox]::Show('ServerName cannot be blank'); $Okbutton.Enabled = $true; Return}
        if([string]::IsNullOrWhiteSpace($sapwd)) {[System.Windows.MessageBox]::Show('Password cannot be blank'); $Okbutton.Enabled = $true; Return}
        if([string]::IsNullOrWhiteSpace($sqlgrp)) {[System.Windows.MessageBox]::Show('SQL SysAdmin Group cannot be blank'); $Okbutton.Enabled = $true; Return}
        if($cFlag -eq 1){if([string]::IsNullOrWhiteSpace($insName)) {[System.Windows.MessageBox]::Show('Instance Name cannot be blank'); $Okbutton.Enabled = $true; Return}}
        if($vFlag -eq 0){[System.Windows.MessageBox]::Show('Version cannot be blank'); $Okbutton.Enabled = $true; Return}
        if($spFlag -eq 0 -and ($vFlag -ne 2019 -and $vFlag -ne 2017)){[System.Windows.MessageBox]::Show('Service Pack cannot be blank'); $Okbutton.Enabled = $true; Return}
        if($edFlag -eq 0){[System.Windows.MessageBox]::Show('Edition cannot be blank'); $Okbutton.Enabled = $true; Return}
        if($ssmsFlag -eq 0){[System.Windows.MessageBox]::Show('SSMS option cannot be blank'); $Okbutton.Enabled = $true; Return}
        $a = Invoke-Command -computername $ServerName -scriptblock {$env:computername} -ErrorAction SilentlyContinue
            if ($?)
            {$Form.Cursor=[System.Windows.Forms.Cursors]::WaitCursor}
            else
            {[System.Windows.MessageBox]::Show($error[0].Exception)
             $Okbutton.Enabled = $true; $Form.Cursor=[System.Windows.Forms.Cursors]::Cursor;return;  
             }
        
         if($vFlag -eq 2019)
            {
                $setupbootstraplog = "\\" + $ServerName + "\C$\Program Files\Microsoft SQL Server\150\Setup Bootstrap\Log"
                $spsourcelocation ="\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2019\SQLUpdates"
                if($edFlag -eq 1){$sqlsourcelocation = "\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2019\Developer"}
                Elseif($edFlag -eq 2){$sqlsourcelocation = "\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2019\Standard"}
                Elseif($edFlag -eq 3){$sqlsourcelocation = "\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2019\Enterprise"}
                $spdestlocationforupdate = "C:\Temp\SQL" + $vFlag + "\SQLUpdates"
            }

         if($vFlag -eq 2017)
            {
                $setupbootstraplog = "\\" + $ServerName + "\C$\Program Files\Microsoft SQL Server\140\Setup Bootstrap\Log"
                $spsourcelocation ="\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2017\SQLUpdates"
                if($edFlag -eq 1){$sqlsourcelocation = "\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2017\Developer"}
                Elseif($edFlag -eq 2){$sqlsourcelocation = "\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2017\Standard"}
                Elseif($edFlag -eq 3){$sqlsourcelocation = "\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2017\Enterprise"}
                $spdestlocationforupdate = "C:\Temp\SQL" + $vFlag + "\SQLUpdates"
            }
        
        if($vFlag -eq 2016)
            {
                $setupbootstraplog = "\\" + $ServerName + "\C$\Program Files\Microsoft SQL Server\130\Setup Bootstrap\Log"
                if($spFlag -eq 1){$spsourcelocation ="\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2016\SQLUpdates\SP1"}
                Elseif($spFlag -eq 2){$spsourcelocation ="\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2016\SQLUpdates\SP2"}
                Elseif($spFlag -eq 3){$spsourcelocation ="\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2016\SQLUpdates\SP3"}
                Elseif($spFlag -eq 4){$spsourcelocation ="\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2016\SQLUpdates\SP4"}
                if($edFlag -eq 1){$sqlsourcelocation = "\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2016\Developer"}
                Elseif($edFlag -eq 2){$sqlsourcelocation = "\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2016\Standard"}
                Elseif($edFlag -eq 3){$sqlsourcelocation = "\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2016\Enterprise"}
                $spdestlocationforupdate = "C:\Temp\SQL" + $vFlag + "\SP" + $spFlag
            }
        if($vFlag -eq 2014)
            {
                $setupbootstraplog = "\\" + $ServerName + "\C$\Program Files\Microsoft SQL Server\120\Setup Bootstrap\Log"
                if($spFlag -eq 1){$spsourcelocation ="\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2014\SQLUpdates\SP1"}
                Elseif($spFlag -eq 2){$spsourcelocation ="\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2014\SQLUpdates\SP2"}
                Elseif($spFlag -eq 3){$spsourcelocation ="\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2014\SQLUpdates\SP3"}
                Elseif($spFlag -eq 4){$spsourcelocation ="\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2014\SQLUpdates\SP4"}
                if($edFlag -eq 1){$sqlsourcelocation = "\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2014\Developer"}
                Elseif($edFlag -eq 2){$sqlsourcelocation = "\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2014\Standard"}
                Elseif($edFlag -eq 3){$sqlsourcelocation = "\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2014\Enterprise"}
                $spdestlocationforupdate = "C:\Temp\SQL" + $vFlag + "\SP" + $spFlag
            }
        if($vFlag -eq 2012)
            {
                $setupbootstraplog = "\\" + $ServerName + "\C$\Program Files\Microsoft SQL Server\110\Setup Bootstrap\Log"
                if($spFlag -eq 1){$spsourcelocation ="\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2012\SQLUpdates\SP1"}
                Elseif($spFlag -eq 2){$spsourcelocation ="\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2012\SQLUpdates\SP2"}
                Elseif($spFlag -eq 3){$spsourcelocation ="\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2012\SQLUpdates\SP3"}
                Elseif($spFlag -eq 4){$spsourcelocation ="\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2012\SQLUpdates\SP4"}
                if($edFlag -eq 1){$sqlsourcelocation = "\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2012\Developer"}
                Elseif($edFlag -eq 2){$sqlsourcelocation = "\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2012\Standard"}
                Elseif($edFlag -eq 3){$sqlsourcelocation = "\\PWGR2PSQLATMN01.prod.pb01.local\Software\SQL2012\Enterprise"}
                $spdestlocationforupdate = "C:\Temp\SQL" + $vFlag + "\SP" + $spFlag
            }
        
        $SQLInstallEXELocation = "C:\Temp\SQL" + $vFlag + "\setup.exe"
        $ConfigINILocation = "C:\Temp\SQL" + $vFlag + "\ConfigurationFile.ini"

        $temp1 = Get-ChildItem $sqlsourcelocation -ErrorAction SilentlyContinue
        if ($?)
            {
                $global:copyFlag = 1
                if($ssmsFlag -eq 1)
                {
                    $ssmssourcelocation ="\\PWGR2PSQLATMN01.prod.pb01.local\Software\SSMS17.9.1"
                    if(!(Test-Path "$ssmssourcelocation\*.exe")){$ssmsresponse = [System.Windows.MessageBox]::Show("SSMS installable missing in the source directory: `n$ssmssourcelocation`n`nNOTE: Hit 'Yes' to proceed with the install, after making sure you have manually copied the installable on the server and updated it's location in this script. Search for variable `$ssmstargetlocation at the start of this script.`n`n            Hit 'No' to stay on the screen and retry after placing the SSMS installable in the source directory.","SSMS Check",'YesNoCancel','Question')}
                    if($ssmsresponse -eq "No" -or $ssmsresponse -eq "Cancel"){ $Okbutton.Enabled = $true;$Form.Cursor=[System.Windows.Forms.Cursors]::Cursor; Return}    
                }
                if(!(Test-Path "$sqlsourcelocation\setup.exe")){$sqlresponse = [System.Windows.MessageBox]::Show("SQL installable missing in the source directory: `n$sqlsourcelocation`n`nNOTE: Hit 'Yes' to proceed with SQL installation, making sure that software is manually placed on target server and the location is updated in SQLRemoteInstall.ps1 script.`n            Hit 'No' to stay on the screen and retry after placing the SQL installable in the source directory.","SQL Install Check",'YesNoCancel','Question')}
                if($sqlresponse -eq "No" -or $sqlresponse -eq "Cancel"){ $Okbutton.Enabled = $true;$Form.Cursor=[System.Windows.Forms.Cursors]::Cursor; Return}
                if(!(Test-Path "$spsourcelocation\*x64*.exe")){$spresponse = [System.Windows.MessageBox]::Show("SP$spFlag installable missing in the source directory: `n$spsourcelocation`n`nNOTE: Hit 'Yes' to proceed with just SQL install, ignoring the service pack.`n            Hit 'No' to stay on the screen and retry after placing the service pack in the source directory.","ServicePack Check",'YesNoCancel','Question')}
                if($spresponse -eq "No" -or $spresponse -eq "Cancel"){ $Okbutton.Enabled = $true; $Form.Cursor=[System.Windows.Forms.Cursors]::Cursor;Return}
                $response = [System.Windows.MessageBox]::Show("Proceed with SQL Install on $ServerName ?","Install Check",'YesNoCancel','Question')
        
            }
            else
            {
                $global:copyFlag = 0
                $response = [System.Windows.MessageBox]::Show("$sqlsourcelocation`n`nAbove software Folder not accessible. Copy the Files manually on the target server.`n`n1. Make sure the SQL Software is mounted on the target server`n2. Make note of the mounted drive and change it accordingly in the D:\scripts\FullyAutomatedSQLInstall\SQLRemoteInstall\SQLRemoteInstall.ps1 script.`n3. Make sure the configuration file is saved in the location specified in D:\scripts\FullyAutomatedSQLInstall\SQLRemoteInstall\SQLRemoteInstall.ps1.`n`nProceed with SQL Install on $ServerName ?","Install Check",'YesNoCancel','Question')
             }
        if($response -eq "No" -or $response -eq "Cancel"){ $displayLabel.Text = "Exiting the script";$Okbutton.Enabled = $true;$dataGridView.Visible = $false;$dataGridView2.Visible = $false; $dataGridView3.Visible = $false;$Form.Cursor=[System.Windows.Forms.Cursors]::Cursor;return;}
        else
        {
        if(!$insName){$ins2 = "MSSQLSERVER" ; $global:postcheckservername = $ServerName} else {$ins2 = "MSSQL$" + $insName; $global:postcheckservername = $ServerName + "\" + $insName}
        if(!$insName){$postinstallconfigservername = $ServerName + "\MSSQLSERVER" } else {$postinstallconfigservername = $ServerName + "\" + $insName}
        $SQLServiceCheck = (Get-Service -ComputerName $ServerName | Where-Object { $_.Name -like "*$ins2*"}).Count 
        if ($SQLServiceCheck -gt 0){[System.Windows.MessageBox]::Show("Default instance already discovered on $ServerName. Please choose instance type to Named and try again.");$Okbutton.Enabled = $true;return}
        
        if($copyFlag -eq 1)
        {
        $versionLabel.Visible = $false;$versiondropdown.Visible = $false;$servicepackLabel.Visible = $false;$servicepackdropdown.Visible = $false;$editionLabel.Visible = $false;$editiondropdown.Visible = $false;$SSMSLabel.Visible = $false;$SSMSdropdown.Visible = $false
        if($ssmsFlag -eq 1)
        {
        $displayLabel.Text = "Copying SSMS installable Files"
        $outputtext.Visible = $true
        $outputtext.Text = $null
        $ssmsdestfolderlocation = "\\" + $ServerName + "\C$\Temp\SSMS17.9.1"
        #$ssmstargetlocation = "\\" + $ServerName + "\C$\Temp\SQL" + $vFlag + "\SSMS17.9.1\SSMS-Setup-ENU.exe"
        
        if(!(Test-Path $ssmsdestfolderlocation)){New-Item -ItemType directory -Path $ssmsdestfolderlocation}
        
        $copyjob = Start-Job -ScriptBlock {robocopy $($args[0]) $($args[1]) /e /MT:64 /ETA /NFL /NDL} -ArgumentList $ssmssourcelocation,$ssmsdestfolderlocation
        While (Get-Job -State "Running") {$outputtext.Text += Receive-Job -Job $copyjob;$outputtext.SelectionStart = $outputtext.TextLength;$outputtext.ScrollToCaret();[System.Windows.Forms.Application]::DoEvents(); }
        
        
        $displayLabel.Text = "Successfully copied SSMS installable Files."
        $ssmstargetlocation = "C:\Temp\SSMS17.9.1\SSMS-Setup-ENU.exe"
        $ssmstargetloglocation = "C:\Temp\SSMS17.9.1\SSMS_Install_Log.txt"
        }
        $displayLabel.Text = "Copying SQL Server Software Files"
        $outputtext.Visible = $true
        $outputtext.Text = $null
        $sqldestlocation = "\\" + $ServerName + "\C$\Temp\SQL" + $vFlag
        $spdestlocation = $sqldestlocation + "\SP" + $spFlag 
        
        $SQLInstallEXELocation = "C:\Temp\SQL" + $vFlag + "\setup.exe"
        $ConfigINILocation = "C:\Temp\SQL" + $vFlag + "\ConfigurationFile.ini"
        
        if(!(Test-Path $sqldestlocation)){New-Item -ItemType directory -Path $sqldestlocation}
        
        $copyjob = Start-Job -ScriptBlock {robocopy $($args[0]) $($args[1]) /e /MT:64 /ETA /NFL /NDL} -ArgumentList $sqlsourcelocation,$sqldestlocation
        While (Get-Job -State "Running") {$outputtext.Text += Receive-Job -Job $copyjob;$outputtext.SelectionStart = $outputtext.TextLength;$outputtext.ScrollToCaret();[System.Windows.Forms.Application]::DoEvents(); }
        $displayLabel.Text = "Successfully copied SQL install files."
        
        if(Test-Path "$spsourcelocation\*x64*.exe")
        {
        if(!(Test-Path $spdestlocation)){New-Item -ItemType directory -Path $spdestlocation}
        $outputtext.Text = $null
        $displayLabel.Text = "Copying SQL Server Service Pack Files"
        $copyjob = Start-Job -ScriptBlock {robocopy $($args[0]) $($args[1]) *x64*.exe /MT:64 /ETA} -ArgumentList $spsourcelocation,$spdestlocation
        While (Get-Job -State "Running") {$outputtext.Text += Receive-Job -Job $copyjob;$outputtext.SelectionStart = $outputtext.TextLength;$outputtext.ScrollToCaret();[System.Windows.Forms.Application]::DoEvents(); }
        $displayLabel.Text = "Successfully copied SQL install and service pack Files. Installing SQL Server"
        }
        $displayLabel.Text = "Successfully copied SQL install Files. "
        }
        
       
        $versionLabel.Visible = $false;$versiondropdown.Visible = $false;$servicepackLabel.Visible = $false;$servicepackdropdown.Visible = $false;$editionLabel.Visible = $false;$editiondropdown.Visible = $false;$SSMSLabel.Visible = $false;$SSMSdropdown.Visible = $false
        $displayLabel.Text += "Installing SQL Server"
        $outputtext.Visible = $true
        $outputtext.Text = $null
        $num_of_cores = invoke-command -computername $ServerName -ScriptBlock {(Get-WmiObject –class Win32_processor |Measure-Object -Property 'NumberOfCores' -Sum).Sum}
        if($num_of_cores -le 8){$SQLTEMPDBFILECOUNT = $num_of_cores} else { $SQLTEMPDBFILECOUNT = 8}
        $protectionpolicyreg = Invoke-Command -ComputerName $ServerName -ScriptBlock {Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Cryptography\Protect\Providers\df9d8cd0-1501-11d1-8c7a-00c04fc297eb" | Where-object {$_ -like "*ProtectionPolicy*" }}
        if(!$protectionpolicyreg)
        {
        $b = invoke-command -computername $ServerName -ScriptBlock {New-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Cryptography\Protect\Providers\df9d8cd0-1501-11d1-8c7a-00c04fc297eb" -Name ProtectionPolicy -Value 1}
        }
        echo "exe : $SQLInstallEXELocation"
        echo "ini: $ConfigINILocation"
        $job = Start-Job -FilePath "D:\scripts\FullyAutomatedSQLInstall\SQLRemoteInstall\SQLRemoteInstall.ps1" -ArgumentList $ServerName,$sapwd,$sqlgrp,$SQLTEMPDBFILECOUNT,$insName,$SQLInstallEXELocation,$ConfigINILocation,$vFlag,$spdestlocationforupdate
        $jobcountFlag= 0
        While (Get-Job -State "Running") {$outputtext.Text += Receive-Job -Job $job;Start-Sleep 1;$jobcountFlag++;if($jobcountFlag -eq 500){$jobcountFlag = 0; <#$outputtext.Text = $null #>};$outputtext.SelectionStart = $outputtext.TextLength;$outputtext.ScrollToCaret();$outputtext.Focus();<#$outputtext.Focus();#> }#$outputtext.Text += "`r`n"}
        if(!$insName){$insName = "MSSQLSERVER"}
        $Form.Cursor=[System.Windows.Forms.Cursors]::Cursor
        $SQLServiceCheck = (Get-Service -ComputerName $ServerName | Where-Object { $_.Name -like "*$insName*"}).Count 
        if ($SQLServiceCheck -eq 0)
        {
            $log_folder = Get-ChildItem -Path $setupbootstraplog | Where-Object {$_.PSIsContainer} | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | select -ExpandProperty Name
            $setupbootstrapsummary = Get-Content "$setupbootstraplog\$log_folder\Summary*.txt" | Select-String -Pattern 'Exit message:' | Select -ExpandProperty line
            [System.Windows.MessageBox]::Show("SQL Install failed. Please review & fix the error and try again. `r`n`r`n$setupbootstrapsummary");$versionLabel.Visible = $true;$versiondropdown.Visible = $true;$servicepackLabel.Visible = $true;$servicepackdropdown.Visible = $true;$editionLabel.Visible = $true;$editiondropdown.Visible = $true;$SSMSLabel.Visible = $true;$SSMSdropdown.Visible = $true;$outputtext.Visible = $true;$Okbutton.Enabled = $true;$Okbutton.Enabled = $true;return
        }
        if($ssmsFlag -eq 1)
        {
        $displayLabel.Text = "Successfully installed SQL Server. Installing SSMS 17.9.1 "
        $outputtext.Text = $null
        #$outputtext.Text += "`r`n`n`n**************************************************************************************************`r`n"
        #$outputtext.SelectionStart = $outputtext.TextLength;$outputtext.ScrollToCaret();$outputtext.Focus();
            $RegistryPath = "hklm:\SOFTWARE\Microsoft\Microsoft SQL Server\140\Tools\Setup\SQL_SSMS_Adv" 
            $IsKeyExist = Invoke-Command -ComputerName $ServerName -ScriptBlock {Test-Path $using:RegistryPath -ErrorAction SilentlyContinue}
            if($IsKeyExist)
            {$displayLabel.Text = "SSMS found installed on the Server. Executing Post Configuration script"}
            else
            {
            $global:ssmsoutputfile = "\\" + $ServerName + "\C$\Temp\SSMS17.9.1\SSMS_Install_Log.txt"
            #$ssmstargetlocation = "C:\Temp\SSMS17.9.1\ssms.exe"
            $ssmsjob1 = Invoke-Command -ComputerName $ServerName -ScriptBlock {Start-Process "$Using:ssmstargetlocation" -ArgumentList "/install /quiet /log $Using:ssmstargetloglocation" -wait } -AsJob
            While (Get-Job -State "Running") {if(Test-Path $ssmsoutputfile){$ssmsresults = (Get-content $ssmsoutputfile )[-1] | where-object {$_ -like "*overall progress:*"};if(!([string]::IsNullOrWhiteSpace($ssmsresults))){$pbr.Visible = $true;$ssmsresults = $ssmsresults.split(",")[1].trim();$pbr.Value = $ssmsresults.split(":")[1].Trim();$outputtext.Text = $ssmsresults;$outputtext.Text += " %`r`n";}}; Start-Sleep 1; }
            }
            $pbr.Visible = $false
            $IsKeyExist = Test-Path $RegistryPath
        if($IsKeyExist)
        {
        $displayLabel.Text = "Successfully installed SSMS. Executing Post Configuration script"
        }
        else
        {
        $displayLabel.Text = "Unable to install SSMS. Executing Post Configuration script"
        }
        }
        $displayLabel.Text = "Successfully installed SQL Server. Executing Post Configuration script"
        $outputtext.Text = $null
        $outputtext.Text += "`r`n`n`n**************************************************************************************************`r`n"
        
        $outputtext.SelectionStart = $outputtext.TextLength;$outputtext.ScrollToCaret();$outputtext.Focus();
       
        
                        
    
                        if($postinstallconfigservername -like "*\*"){ $Server = $postinstallconfigservername.Split("\")[0]; $InsNames = $postinstallconfigservername.Split("\")[1] } else { $Server = $postinstallconfigservername }
                    
                       
                         try
                         {
                            $outputtext.Text = $null
                            $job = Start-Job -FilePath "D:\scripts\FullyAutomatedSQLInstall\SQLPostConfig\SQLPostConfig.ps1" -ArgumentList $Server,$InsNames
                            
                            While (Get-Job -State "Running") 
                            {
                                $jobprogress = Receive-Job -Job $job; if($jobprogress.Length -gt 0){$outputtext.Text += $jobprogress;[System.Windows.Forms.Application]::DoEvents();$outputtext.SelectionStart = $outputtext.TextLength;$outputtext.ScrollToCaret();$outputtext.Focus();}  
                            }

                            if($outputtext.Text -like "*Configuration Failed*")
                            {$outputtext.Text += "`r`n`r`n`r`nConfiguration Failed. Review the error and retry."
                            $outputtext.SelectionStart = $outputtext.TextLength;$outputtext.ScrollToCaret();$outputtext.Focus();
                            $skipbutton.Text = "Perform Post-Install Configuration"
                            $skipbutton.Enabled = $true
                            $skipbutton.Visible = $true
                            $okbutton.Visible = $false
                            $displayLabel.Text = "Configuration Failed. Review the error and retry.";$Form.Cursor=[System.Windows.Forms.Cursors]::Cursor  ;return;
                            }
                            else
                            {
                            $outputtext.Text += "`r`n`r`n`r`nSuccessfully Configured SQL Server. Review the results and proceed with the post validation."
                            $outputtext.SelectionStart = $outputtext.TextLength;$outputtext.ScrollToCaret();$outputtext.Focus();
                            }
                         }
                         catch
                         {
                         
                         $outputtext.Text += $_.Exception.Message
                         
                         [System.Windows.Forms.Application]::DoEvents();$outputtext.SelectionStart = $outputtext.TextLength;$outputtext.ScrollToCaret();$outputtext.Focus();
                         $Form.Cursor=[System.Windows.Forms.Cursors]::Cursor;return;
                         }   
        
       
    





        }
      
        $displayLabel.Text = "Successfully installed and configured SQL Server."
        $Okbutton.Text = "Click to Perform Post Install Validation"    
        $Okbutton.BackColor = "Yellow"
        $Okbutton.Enabled = $true
        $global:iFlag  = 3
    }


if($iFlag -eq 1)
    {
        $displayLabel.Text = ""

        if($ServerName.count -le 0 -or !$ServerName) {[System.Windows.MessageBox]::Show('ServerName cannot be blank'); $Okbutton.Enabled = $true; $Form.Cursor=[System.Windows.Forms.Cursors]::Cursor;Return}
        $a = Invoke-Command -computername $ServerName -scriptblock {$env:computername} -ErrorAction SilentlyContinue
            if ($?)
            {}
            else
            {[System.Windows.MessageBox]::Show($error[0].Exception)
             $Okbutton.Enabled = $true; $Form.Cursor=[System.Windows.Forms.Cursors]::Cursor;return;  
             }
        $sapwdLabel.Visible = $true
        $sapwdtext.Visible = $true
        $sqlactLabel.Visible = $true
        $sqlacttext.Visible = $true
        $instypeLabel.Visible = $true
        $instypedropdown.Visible = $true
        $versionLabel.Visible = $true
        $versiondropdown.Visible = $true
        $servicepackLabel.Visible = $true
        $servicepackdropdown.Visible = $true
        $editionLabel.Visible = $true
        $editiondropdown.Visible = $true
        $SSMSLabel.Visible = $true
        $SSMSdropdown.Visible = $true
        $Okbutton.Text = "Click to Install SQL Server"    
        $Okbutton.BackColor = "Aqua"
        $Okbutton.Enabled = $true
        
        $global:iFlag  = 2
        
    }
    
    
        
        
        
    

if($iFlag -eq 0)
{
$skipbutton.Visible = $false
if($ServerName.count -le 0 -or !$ServerName) {[System.Windows.MessageBox]::Show('ServerName cannot be blank'); $Okbutton.Enabled = $true; $skipbutton.Visible = $true; $Form.Cursor=[System.Windows.Forms.Cursors]::Cursor;Return}
$response = [System.Windows.MessageBox]::Show("Proceed with PreInstall Check on $ServerName ?`n`nNOTE: Hit 'No' to skip the pre-install check, and still proceed with SQL install.","Validation Check",'YesNoCancel','Question')
if($response -eq "Cancel"){ $displayLabel.Text = "Exiting the script";$Okbutton.Enabled = $true;$dataGridView.Visible = $false;$dataGridView2.Visible = $false; $dataGridView3.Visible = $false;$Form.Cursor=[System.Windows.Forms.Cursors]::Cursor;return;}
if($response -eq "No"){ $displayLabel.Text = "Click above to Load SQL Install Options";$Okbutton.Text = "Click to Load SQL Install Options" ; $Okbutton.BackColor = "Yellow";$Okbutton.Enabled = $true;$skipbutton.Visible = $false;$global:iFlag = 1}
if($response -eq "Yes")
{


$a = Invoke-Command -computername $ServerName -scriptblock {$env:computername} -ErrorAction SilentlyContinue
            if ($?)
            {}
            else
            {[System.Windows.MessageBox]::Show($error[0].Exception)
             $Okbutton.Enabled = $true;$skipbutton.Visible = $true; $Form.Cursor=[System.Windows.Forms.Cursors]::Cursor;return;  
             }
$displayLabel.Text = "Performing Pre-Install Validation Check"
$Form.Cursor=[System.Windows.Forms.Cursors]::WaitCursor
$result = & D:\scripts\FullyAutomatedSQLInstall\SQLBuildValidation\SQLBuildValidation.ps1 $ServerName PRE
if($result -like "*Script Execution Complete.*")
{
    $displayLabel.Text = "Pre-Install Validation performed successfully. Review the results below:"
            $CentralServer = $ValidationRepositoryServer
        $conn = New-Object System.Data.SqlClient.SqlConnection
        $cmd = New-Object System.Data.SqlClient.SqlCommand
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $dsControls = New-Object System.Data.DataSet
        $conn.ConnectionString = "Data Source=$CentralServer;Initial Catalog=INFODB;Integrated Security=SSPI;"
        $conn.open()
        $cmd.connection = $conn
        $cmd.CommandText = @"
                              SET NOCOUNT ON;SELECT RTrim([ServerName]) AS ServerName
                                  ,RTRIM([Control]) AS Control
                                  ,RTRIM([Result]) AS Result
                                  ,RTRIM([UserName]) AS UserName
                                  ,RTRIM([DateCheckedOn]) AS DateCheckedOn
                              FROM [INFODB].[build].[PreInstallMiscResults] where ServerName = '$ServerName' and DateCheckedOn in (select max(datecheckedon) from [INFODB].[build].[PreInstallMiscResults] where ServerName = '$ServerName')
                            order by [DateCheckedOn] desc, serialID asc  
  
"@
        $adapter.SelectCommand = $cmd
               $adapter.Fill($dsControls) | Out-Null
        #$outputtext.Text = Invoke-SqlCmd -ServerInstance $CentralServer  -Query $resultquery  |Format-Table | Out-String
        #Invoke-SqlCmd -ServerInstance $CentralServer  -Query $resultquery | Export-csv "C:\temp\result.rpt"
        #$dataGridView.DataSource = Import-CSV "C:\temp\result.rpt" -Header "ServerName","Control","Result","UserName","DateCheckedOn" | Format-Table
        $dataGridView.Visible = $true
        $dataGridView.DataSource = $dsControls.tables[0]
        $dataGridView.Columns | Foreach-Object{
    $_.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
        }
        $dataGridView.ColumnHeadersHeight = 40
        $dataGridView.AllowUserToAddRows = $false;
    $dataGridView.AllowUserToDeleteRows = $false;
    $dataGridView.AllowUserToOrderColumns = $true;
    $dataGridView.ReadOnly = $true;
    $dataGridView.AllowUserToResizeColumns = $false;
    $dataGridView.AllowUserToResizeRows = $false;
    $c=$dataGridView.RowCount
        for ($x=0;$x -lt $c;$x++) {
            for ($y=0;$y -lt $dataGridView.Rows[$x].Cells.Count;$y++) {
                $value = $dataGridView.Rows[$x].Cells[$y].Value
                
                Switch ($value) {
                    ".Net 3.5 MISSING" {
                        $dataGridView.Rows[$x].Cells[$y].Style.ForeColor=[System.Drawing.Color]::FromArgb(255,255,255,255)
                        $dataGridView.Rows[$x].Cells[$y].Style.BackColor=[System.Drawing.Color]::FromArgb(255,255,0,0)
                    }
                    "NOT Activated" {
                        $dataGridView.Rows[$x].Cells[$y].Style.ForeColor=[System.Drawing.Color]::FromArgb(255,255,255,255)
                        $dataGridView.Rows[$x].Cells[$y].Style.BackColor=[System.Drawing.Color]::FromArgb(255,255,0,0)
                    }
                }
            }
        }
        
        
    
    $dsControls = New-Object System.Data.DataSet
    $cmd.connection = $conn
        $cmd.CommandText = @"
                              SET NOCOUNT ON;SELECT RTRIM([ServerName]) AS ServerName
                                                      ,RTRIM([Control]) As Control
                                                      ,RTRIM([DriveLetter]) As DriveLetter
                                                      ,RTRIM([VolumeName]) AS VolumeName
                                                      ,RTRIM([FreeSpaceinGB]) AS FreeSpaceinGB
                                                      ,RTRIM([AllocatedSpaceinGB]) AS AllocatedSpaceinGB
                                                      ,RTRIM([UserName]) AS UserName
                                                      ,RTRIM([DateCheckedOn]) AS DateCheckedOn
                                                  FROM [INFODB].[build].[PreInstallDriveResults] where ServerName = '$ServerName' and DateCheckedOn in (select max(datecheckedon) from [INFODB].[build].[PreInstallDriveResults] where ServerName = '$ServerName')
                                                  order by [DateCheckedOn] desc, serialID asc
"@
        $adapter.SelectCommand = $cmd
               $adapter.Fill($dsControls) | Out-Null
         $dataGridView2.Visible = $true
         $dataGridView2.DataSource = $dsControls.tables[0]
        $dataGridView2.Columns | Foreach-Object{
    $_.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
        }
        $dataGridView2.ColumnHeadersHeight = 40
        $dataGridView2.AllowUserToAddRows = $false;
    $dataGridView2.AllowUserToDeleteRows = $false;
    $dataGridView2.AllowUserToOrderColumns = $true;
    $dataGridView2.ReadOnly = $true;
    $dataGridView2.AllowUserToResizeColumns = $false;
    $dataGridView2.AllowUserToResizeRows = $false;
     
     $dsControls = New-Object System.Data.DataSet
    $cmd.connection = $conn
        $cmd.CommandText = @"
                              SET NOCOUNT ON; SELECT RTRIM([ServerName]) AS ServerName
                                                      ,RTRIM([Control]) AS Control
                                                      ,RTRIM([FileName]) AS FileName
                                                      ,RTRIM([AllocatedSpaceinGB]) AS AllocatedSpaceinGB
                                                      ,RTRIM([UserName]) AS UserName
                                                      ,RTRIM([DateCheckedOn]) AS DateCheckedOn
                                                  FROM [INFODB].[build].[PreInstallPageFileResults] where ServerName = '$ServerName' and DateCheckedOn in (select max(datecheckedon) from [INFODB].[build].[PreInstallDriveResults] where ServerName = '$ServerName')
                                                  order by [DateCheckedOn] desc, serialID asc
"@
        $adapter.SelectCommand = $cmd
               $adapter.Fill($dsControls) | Out-Null
         $dataGridView3.Visible = $true
         $dataGridView3.DataSource = $dsControls.tables[0]
        $dataGridView3.Columns | Foreach-Object{
    $_.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
        }
        $dataGridView3.ColumnHeadersHeight = 40
        $dataGridView3.AllowUserToAddRows = $false;
    $dataGridView3.AllowUserToDeleteRows = $false;
    $dataGridView3.AllowUserToOrderColumns = $true;
    $dataGridView3.ReadOnly = $true;
    $dataGridView3.AllowUserToResizeColumns = $false;
    $dataGridView3.AllowUserToResizeRows = $false; 
    $Okbutton.Text = "Click to Load SQL Install Options"    
    $Okbutton.BackColor = "Yellow"
$Okbutton.Enabled = $true
$global:iFlag = 1
$Form.Cursor=[System.Windows.Forms.Cursors]::Cursor
} 
else {
            $displayLabel.Text = "Pre-Install Validation FAILED.";
            $Form.Cursor=[System.Windows.Forms.Cursors]::Cursor
            $response = [System.Windows.MessageBox]::Show("Do you Still want to proceed with SQL Install on $ServerName ?","Validation Check",'YesNoCancel','Question')
            if($response -eq "No" -or $response -eq "Cancel"){ $displayLabel.Text = "Exiting the script";$Okbutton.Enabled = $true;$dataGridView.Visible = $false;$dataGridView2.Visible = $false; $dataGridView3.Visible = $false;$Form.Cursor=[System.Windows.Forms.Cursors]::Cursor;return;}
            else {
            $Okbutton.Text = "Click to Load SQL Install Options"    
            $Okbutton.BackColor = "Yellow"
            $Okbutton.Enabled = $true
            $global:iFlag = 1
            }
            }

    }

}

    
}


$Form = New-Object system.Windows.Forms.Form
$Form.Size = New-Object System.Drawing.Size(1450,864)
#You can use the below method as well
#$Form.Width = 400
#$Form.Height = 200
$form.MaximizeBox = $false
$Form.StartPosition = "CenterScreen"

$Form.FormBorderStyle = 'Fixed3D'

$Form.Text = "FullyAutomatedSQLInstall"

$Label1 = New-Object System.Windows.Forms.Label
$Label1.Text = "Please enter the below details to proceed with SQL Build"
$Label1.AutoSize = $true
$Label1.Location = New-Object System.Drawing.Size(0,0)
$Font = New-Object System.Drawing.Font("Calibri",15,[System.Drawing.FontStyle]::Regular)



$serverLabel = New-Object System.Windows.Forms.Label
$serverLabel.Text = "Fully Qualified Server Name :"
$serverLabel.AutoSize = $true
$serverLabel.Location = New-Object System.Drawing.Size(0,40)

$sapwdLabel = New-Object System.Windows.Forms.Label
$sapwdLabel.Text = "SA Password :"
$sapwdLabel.AutoSize = $true
$sapwdLabel.Location = New-Object System.Drawing.Size(600,0)
$sapwdLabel.Visible = $false
$form.Controls.Add($sapwdLabel)

$sapwdtext = New-Object System.Windows.Forms.TextBox
$sapwdtext.Location = New-Object System.Drawing.Point(800,0)
$sapwdtext.Size = New-Object System.Drawing.Size(200,20)
$sapwdtext.PasswordChar = '*'
$sapwdtext.Visible = $false
$form.Controls.Add($sapwdtext)

$sqlactLabel = New-Object System.Windows.Forms.Label
$sqlactLabel.Text = "SQL SysAdmin Group :"
$sqlactLabel.AutoSize = $true
$sqlactLabel.Location = New-Object System.Drawing.Size(600,40)
$sqlactLabel.Visible = $false
$form.Controls.Add($sqlactLabel)

$sqlacttext = New-Object System.Windows.Forms.TextBox
$sqlacttext.Location = New-Object System.Drawing.Point(800,40)
$sqlacttext.Size = New-Object System.Drawing.Size(200,20)
$sqlacttext.Visible = $false
$form.Controls.Add($sqlacttext)

$instypeLabel = New-Object System.Windows.Forms.Label
$instypeLabel.Text = "Instance Type :"
$instypeLabel.AutoSize = $true
$instypeLabel.Location = New-Object System.Drawing.Size(600,80)
$instypeLabel.Visible = $false
$form.Controls.Add($instypeLabel)

$instypedropdown = New-Object System.Windows.Forms.ComboBox
$instypedropdown.Location = New-Object System.Drawing.Point(800,80)
$instypedropdown.Size = New-Object System.Drawing.Size(200,20)
#[void] $instypedropdown.BeginUpdate()
[void] $instypedropdown.Items.add("")
[void] $instypedropdown.Items.add("Default")
[void] $instypedropdown.Items.add("Named")
$instypedropdown.SelectedIndex=0
#if ($instypedropdown.SelectedItem -eq "Named") {$insnameLabel.Visible = $true;$instypetext.Visible = $true}
$instypedropdown.add_SelectedIndexChanged({if ($instypedropdown.SelectedItem -eq "Named") {$insnameLabel.Visible = $true;$instypetext.Visible = $true; $global:cFlag = 1}}) 
$instypedropdown.add_SelectedIndexChanged({if ($instypedropdown.SelectedItem -eq "Default") {$insnameLabel.Visible = $false;$instypetext.Visible = $false; $global:cFlag = 0}}) 
$instypedropdown.add_SelectedIndexChanged({if ($instypedropdown.SelectedItem -eq "") {$insnameLabel.Visible = $false;$instypetext.Visible = $false ; $global:cFlag = 1}}) 

#[void] $instypedropdown.endUpdate()
$instypedropdown.Visible = $false
$instypedropdown.DropDownStyle = "DropDownList"
$form.Controls.Add($instypedropdown)

$insnameLabel = New-Object System.Windows.Forms.Label
$insnameLabel.Text = "Instance Name :"
$insnameLabel.AutoSize = $true
$insnameLabel.Location = New-Object System.Drawing.Size(600,120)
$insnameLabel.Visible = $false
$form.Controls.Add($insnameLabel)

$instypetext = New-Object System.Windows.Forms.TextBox
$instypetext.Location = New-Object System.Drawing.Point(800,120)
$instypetext.Size = New-Object System.Drawing.Size(200,20)
$instypetext.Visible = $false
$form.Controls.Add($instypetext)

$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Text = "SQL Version :"
$versionLabel.AutoSize = $true
$versionLabel.Location = New-Object System.Drawing.Size(600,160)
$versionLabel.Visible = $false
$form.Controls.Add($versionLabel)
$versiondropdown = New-Object System.Windows.Forms.ComboBox
$versiondropdown.Location = New-Object System.Drawing.Point(800,160)
$versiondropdown.Size = New-Object System.Drawing.Size(200,20)

[void] $versiondropdown.Items.add("")
[void] $versiondropdown.Items.add("SQL Server 2019")
[void] $versiondropdown.Items.add("SQL Server 2017")
[void] $versiondropdown.Items.add("SQL Server 2016")
[void] $versiondropdown.Items.add("SQL Server 2014")
[void] $versiondropdown.Items.add("SQL Server 2012")
$versiondropdown.SelectedIndex=0
$versiondropdown.add_SelectedIndexChanged({if ($versiondropdown.SelectedItem -eq "SQL Server 2019") {$servicepackLabel.ForeColor = "gray";$servicepackdropdown.Enabled = $false;$global:vFlag = 2019}}) 
$versiondropdown.add_SelectedIndexChanged({if ($versiondropdown.SelectedItem -eq "SQL Server 2017") {$servicepackLabel.ForeColor = "gray";$servicepackdropdown.Enabled = $false;$global:vFlag = 2017}}) 
$versiondropdown.add_SelectedIndexChanged({if ($versiondropdown.SelectedItem -eq "SQL Server 2016") {$servicepackLabel.ForeColor = "black";$servicepackdropdown.Enabled = $true;$global:vFlag = 2016}}) 
$versiondropdown.add_SelectedIndexChanged({if ($versiondropdown.SelectedItem -eq "SQL Server 2014") {$servicepackLabel.ForeColor = "black";$servicepackdropdown.Enabled = $true;$global:vFlag = 2014}}) 
$versiondropdown.add_SelectedIndexChanged({if ($versiondropdown.SelectedItem -eq "SQL Server 2012") {$servicepackLabel.ForeColor = "black";$servicepackdropdown.Enabled = $true;$global:vFlag = 2012}}) 
$versiondropdown.add_SelectedIndexChanged({if ($versiondropdown.SelectedItem -eq "") {$global:vFlag = 0}}) 

$versiondropdown.Visible = $false
$versiondropdown.DropDownStyle = "DropDownList"
$form.Controls.Add($versiondropdown)

$servicepackLabel = New-Object System.Windows.Forms.Label
$servicepackLabel.Text = "Service Pack :"

$servicepackLabel.AutoSize = $true
$servicepackLabel.Location = New-Object System.Drawing.Size(600,200)
$servicepackLabel.Visible = $false
$form.Controls.Add($servicepackLabel)
$servicepackdropdown = New-Object System.Windows.Forms.ComboBox
$servicepackdropdown.Location = New-Object System.Drawing.Point(800,200)
$servicepackdropdown.Size = New-Object System.Drawing.Size(200,20)
[void] $servicepackdropdown.Items.add("")
[void] $servicepackdropdown.Items.add("SP1")
[void] $servicepackdropdown.Items.add("SP2")
[void] $servicepackdropdown.Items.add("SP3")
[void] $servicepackdropdown.Items.add("SP4")
$servicepackdropdown.SelectedIndex=0
$servicepackdropdown.add_SelectedIndexChanged({if ($servicepackdropdown.SelectedItem -eq "SP1") {$global:spFlag = 1}}) 
$servicepackdropdown.add_SelectedIndexChanged({if ($servicepackdropdown.SelectedItem -eq "SP2") {$global:spFlag = 2}}) 
$servicepackdropdown.add_SelectedIndexChanged({if ($servicepackdropdown.SelectedItem -eq "SP3") {$global:spFlag = 3}}) 
$servicepackdropdown.add_SelectedIndexChanged({if ($servicepackdropdown.SelectedItem -eq "SP4") {$global:spFlag = 4}}) 
$servicepackdropdown.add_SelectedIndexChanged({if ($servicepackdropdown.SelectedItem -eq "") {$global:spFlag = 0}}) 
$servicepackdropdown.Visible = $false
$servicepackdropdown.DropDownStyle = "DropDownList"
$form.Controls.Add($servicepackdropdown)

$editionLabel = New-Object System.Windows.Forms.Label
$editionLabel.Text = "SQL Edition :"
$editionLabel.AutoSize = $true
$editionLabel.Location = New-Object System.Drawing.Size(600,240)
$editionLabel.Visible = $false
$form.Controls.Add($editionLabel)
$editiondropdown = New-Object System.Windows.Forms.ComboBox
$editiondropdown.Location = New-Object System.Drawing.Point(800,240)
$editiondropdown.Size = New-Object System.Drawing.Size(200,20)
[void] $editiondropdown.Items.add("")
[void] $editiondropdown.Items.add("Developer")
[void] $editiondropdown.Items.add("Standard")
[void] $editiondropdown.Items.add("Enterprise")
$editiondropdown.SelectedIndex=0
$editiondropdown.add_SelectedIndexChanged({if ($editiondropdown.SelectedItem -eq "Developer") {$global:edFlag = 1}}) 
$editiondropdown.add_SelectedIndexChanged({if ($editiondropdown.SelectedItem -eq "Standard") {$global:edFlag = 2}}) 
$editiondropdown.add_SelectedIndexChanged({if ($editiondropdown.SelectedItem -eq "Enterprise") {$global:edFlag = 3}}) 
$editiondropdown.add_SelectedIndexChanged({if ($editiondropdown.SelectedItem -eq "") {$global:edFlag = 0}}) 
$editiondropdown.Visible = $false
$editiondropdown.DropDownStyle = "DropDownList"
$form.Controls.Add($editiondropdown)

$SSMSLabel = New-Object System.Windows.Forms.Label
$SSMSLabel.Text = "SSMS install:"
$SSMSLabel.AutoSize = $true
$SSMSLabel.Location = New-Object System.Drawing.Size(600,280)
$SSMSLabel.Visible = $false
$form.Controls.Add($SSMSLabel)
$SSMSdropdown = New-Object System.Windows.Forms.ComboBox
$SSMSdropdown.Location = New-Object System.Drawing.Point(800,280)
$SSMSdropdown.Size = New-Object System.Drawing.Size(200,20)
[void] $SSMSdropdown.Items.add("")
[void] $SSMSdropdown.Items.add("Yes")
[void] $SSMSdropdown.Items.add("No")
$SSMSdropdown.SelectedIndex=0
$SSMSdropdown.add_SelectedIndexChanged({if ($SSMSdropdown.SelectedItem -eq "Yes") {$global:ssmsFlag = 1}}) 
$SSMSdropdown.add_SelectedIndexChanged({if ($SSMSdropdown.SelectedItem -eq "No") {$global:ssmsFlag = 2}}) 
$SSMSdropdown.add_SelectedIndexChanged({if ($SSMSdropdown.SelectedItem -eq "") {$global:ssmsFlag = 0}}) 
$SSMSdropdown.Visible = $false
$SSMSdropdown.DropDownStyle = "DropDownList"
$form.Controls.Add($SSMSdropdown)

$servertext = New-Object System.Windows.Forms.TextBox
$servertext.Location = New-Object System.Drawing.Point(260,40)
$servertext.Size = New-Object System.Drawing.Size(200,20)

$outputtext = New-Object System.Windows.Forms.TextBox
$outputtext.Multiline = $True;
$outputtext.Location = New-Object System.Drawing.Point(10,180)
$outputtext.Size = New-Object System.Drawing.Size(1300,580)
$outputtext.Scrollbars = "Vertical" 
$outputtext.Visible = $false

$outputtext.WordWrap = $true;
$dataGridView = New-Object System.Windows.Forms.DataGridView
$dataGridView.Size=New-Object System.Drawing.Size(1300,150)
$dataGridView.Location = New-Object System.Drawing.Point(10,170)
$dataGridView.ColumnHeadersVisible = $true
$dataGridView.Visible = $false

$form.Controls.Add($dataGridView)
$dataGridView2 = New-Object System.Windows.Forms.DataGridView
$dataGridView2.Size=New-Object System.Drawing.Size(1300,260)
$dataGridView2.Location = New-Object System.Drawing.Point(10,340)
$dataGridView2.ColumnHeadersVisible = $true
$dataGridView2.Visible = $false
$form.Controls.Add($dataGridView2)

$form.Controls.Add($dataGridView)
$dataGridView3 = New-Object System.Windows.Forms.DataGridView
$dataGridView3.Size=New-Object System.Drawing.Size(1300,150)
$dataGridView3.Location = New-Object System.Drawing.Point(10,620)
$dataGridView3.ColumnHeadersVisible = $true
$dataGridView3.Visible = $false
$form.Controls.Add($dataGridView3)

$dataGridView4 = New-Object System.Windows.Forms.DataGridView
$dataGridView4.Size=New-Object System.Drawing.Size(1300,580)
$dataGridView4.Location = New-Object System.Drawing.Point(10,180)
$dataGridView4.ColumnHeadersVisible = $true
$dataGridView4.Visible = $false
$form.Controls.Add($dataGridView4)

$displayLabel = New-Object System.Windows.Forms.Label
$displayLabel.Text = ""
$displayLabel.AutoSize = $true
$displayLabel.ForeColor = "Green"
$displayLabel.Location = New-Object System.Drawing.Size(10,140)

$pbr = New-Object System.Windows.Forms.ProgressBar
$pbr.Maximum = 100
$pbr.Minimum = 0
$pbr.Location = new-object System.Drawing.Size(10,760)
$pbr.size = new-object System.Drawing.Size(1300,30)
$pbr.Visible = $false
$pbr.Style = 'Continuous'

$Form.Controls.Add($pbr)

$form.Font = $Font
$Form.Controls.Add($Label1)
$Form.Controls.Add($serverLabel)
$Form.Controls.Add($DisplayLabel)
$Form.Controls.Add($servertext)
$Form.Controls.Add($outputtext)
#$timer = New-Object System.Windows.Forms.Timer
#$timer.Interval = 250

#$timer.Add_Tick({$DisplayLabel.Visible = -not($DisplayLabel.Visible)})
#$form.Add_Load({$timer.Start()})



$Okbutton = New-Object System.Windows.Forms.Button
$Okbutton.Location = New-Object System.Drawing.Size(5,80)
$Okbutton.Size = New-Object System.Drawing.Size(455,30)
$Okbutton.Text = "Proceed to SQL Install"
$Okbutton.BackColor = "#B1DDF1"
$Okbutton.Add_Click({OK-button_Check})
$Form.Controls.Add($Okbutton)

$skipbutton = New-Object System.Windows.Forms.Button
$skipbutton.Location = New-Object System.Drawing.Size(5,110)
$skipbutton.Size = New-Object System.Drawing.Size(455,30)
$skipbutton.Text = "Skip Install and Perform Post-Install Configuration"
$skipbutton.BackColor = "#F7DB89"
$skipbutton.Add_Click({Post-Install-Config})
$Form.Controls.Add($skipbutton)
#$Form.Cursor=[System.Windows.Forms.Cursors]::WaitCursor
#$Form.Cursor=[System.Windows.Forms.Cursors]::Hand
$Form.ShowDialog()
#$timer.Dispose()
$form.Dispose()
