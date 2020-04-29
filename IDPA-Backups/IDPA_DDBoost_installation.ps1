$global:copyFlag =1
Function OK-button_Check{
$Okbutton.Enabled = $false;

$servername = $servertext.Text.ToString();
$sqlservername = $sqlservertext.Text.ToString();
$portnumber = $sqlserverporttext.Text.ToString();
$idpaservername = $idpahostnametext.Text.ToString();
$idpaserverip = $idpahostiptext.Text.ToString();
$storageunituser = $StorageUnitusertext.Text.ToString();
$storageunitpass = $StorageUnitpasstext.Text.ToString();
$storageunitconfirmpass = $StorageUnitpasstext1.Text.ToString();
$softwarelocationserver = $SoftwareLocationText.Text.ToString();



        if([string]::IsNullOrWhiteSpace($servername)) {[System.Windows.MessageBox]::Show('ServerName cannot be blank'); $Okbutton.Enabled = $true; Return}
        if([string]::IsNullOrWhiteSpace($sqlservername)) {[System.Windows.MessageBox]::Show('SQL ServerName cannot be blank'); $Okbutton.Enabled = $true; Return}
        if([string]::IsNullOrWhiteSpace($portnumber)) {[System.Windows.MessageBox]::Show('Port Number cannot be blank'); $Okbutton.Enabled = $true; Return}
        if([string]::IsNullOrWhiteSpace($idpaservername)) {[System.Windows.MessageBox]::Show('IDPA ServerName cannot be blank'); $Okbutton.Enabled = $true; Return}
        if([string]::IsNullOrWhiteSpace($idpaserverip)) {[System.Windows.MessageBox]::Show('IDPA Server IP cannot be blank'); $Okbutton.Enabled = $true; Return}
        if([string]::IsNullOrWhiteSpace($storageunituser)) {[System.Windows.MessageBox]::Show('Storage Unit UserName cannot be blank'); $Okbutton.Enabled = $true; Return}
        if([string]::IsNullOrWhiteSpace($storageunitpass)) {[System.Windows.MessageBox]::Show('Password cannot be blank'); $Okbutton.Enabled = $true; Return}
        if([string]::IsNullOrWhiteSpace($storageunitconfirmpass)) {[System.Windows.MessageBox]::Show('Confirm Password Field cannot be blank'); $Okbutton.Enabled = $true; Return}
        if($copyFlag -eq 0) {if([string]::IsNullOrWhiteSpace($softwarelocationserver)) {[System.Windows.MessageBox]::Show('Software Location Field cannot be blank'); $Okbutton.Enabled = $true; Return}}
        if($storageunitpass -ne $storageunitconfirmpass) {[System.Windows.MessageBox]::Show('Passwords don''t match. Please try again.');$Okbutton.Enabled = $true;return;}
        $a = Invoke-Command -computername $ServerName -scriptblock {$env:computername} -ErrorAction SilentlyContinue
            if ($?)
            {}
            else
            {[System.Windows.MessageBox]::Show($error[0].Exception)
             $Okbutton.Enabled = $true; return;  
             }
        try{
                $OutputText.Text ="Testing the port connectivity";
                $testtelnet = Test-NetConnection $idpaserverip -port 2049 -informationlevel quiet
                if($testtelnet -eq "True"){$OutputText.Text +="`r`nTelnet to $idpaserverip on 2049 succeeeded";}
                else {$OutputText.Text +="`r`nTelnet to $idpaserverip on 2049 Failed . Exiting the script as install cannot proceed";$Okbutton.Enabled = $true;return; }
                $testtelnet = Test-NetConnection $idpaserverip -port 2052 -informationlevel quiet
                if($testtelnet -eq "True"){$OutputText.Text +="`r`nTelnet to $idpaserverip on 2052 succeeeded";}
                else {$OutputText.Text +="`r`nTelnet to $idpaserverip on 2052 Failed . `r`n`r`nExiting the script as install cannot proceed";$Okbutton.Enabled = $true;return; }
           }
        catch
            {
                if($testtelnet -eq "True"){$OutputText.Text +="`r`n" + $error[0].Exception;}
            }

        $OutputText.Text +="`r`nShutting down SSMS if it's up and running."
        $a = Get-Process | Where-Object {$_.ProcessName -like "*ssms*"} | Stop-Process -Force
        $OutputText.Text +="`r`nInstalling DDBoost"
        
        
        
        $job =Invoke-Command -computername $ServerName -scriptblock { D:\scripts\IDPA-Backups\msappagent191_win_x64\win_x64\emcmsappagent*.exe -silent -log "C:\Temp\Log.txt" ProductInstallPath="D:\Program Files\DPSAPPS\MSAPPAGENT" EnableSSMS=1  InstallECDMAgent=0  EnableCLR=1 } -AsJob
        #$job =Invoke-Command -computername $ServerName -scriptblock { D:\scripts\IDPA-Backups\msappagent191_win_x64\win_x64\emcmsappagent*.exe -silent ProductInstallPath="D:\Program Files\DPSAPPS\MSAPPAGENT" EnableSSMS=1  InstallECDMAgent=0  EnableCLR=1 } -AsJob
        While (Get-Job -State "Running") {$outputtext.Text += Receive-Job -Job $job;}

$OutputText.Text +="`r`nIn Proceed Function";
$Okbutton.Enabled = $true;
}


$Form = New-Object system.Windows.Forms.Form
$Form.Size = New-Object System.Drawing.Size(1100,700)
#You can use the below method as well
#$Form.Width = 400
#$Form.Height = 200
$form.MaximizeBox = $false
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = 'Fixed3D'
$Form.Text = "IDPA_DDBoost_installation"

$Label1 = New-Object System.Windows.Forms.Label
$Label1.Text = "Please enter the below details to proceed with IDPA DDBoost installation"
$Label1.AutoSize = $true
$Label1.Location = New-Object System.Drawing.Size(0,0)
$Font = New-Object System.Drawing.Font("Calibri",15,[System.Drawing.FontStyle]::Regular)

$serverLabel = New-Object System.Windows.Forms.Label
$serverLabel.Text = "Fully Qualified Server Name :"
$serverLabel.AutoSize = $true
$serverLabel.Location = New-Object System.Drawing.Size(0,40)

$servertext = New-Object System.Windows.Forms.TextBox
$servertext.Location = New-Object System.Drawing.Point(260,40)
$servertext.Size = New-Object System.Drawing.Size(200,20)

$sqlserverLabel = New-Object System.Windows.Forms.Label
$sqlserverLabel.Text = "SQL Server Name :"
$sqlserverLabel.AutoSize = $true
$sqlserverLabel.Location = New-Object System.Drawing.Size(0,80)

$sqlservertext = New-Object System.Windows.Forms.TextBox
$sqlservertext.Location = New-Object System.Drawing.Point(260,80)
$sqlservertext.Size = New-Object System.Drawing.Size(200,20)

$sqlserverportLabel = New-Object System.Windows.Forms.Label
$sqlserverportLabel.Text = "Port Number :"
$sqlserverportLabel.AutoSize = $true
$sqlserverportLabel.Location = New-Object System.Drawing.Size(0,120)

$sqlserverporttext = New-Object System.Windows.Forms.TextBox
$sqlserverporttext.Location = New-Object System.Drawing.Point(260,120)
$sqlserverporttext.Size = New-Object System.Drawing.Size(200,20)

$idpahostnameLabel = New-Object System.Windows.Forms.Label
$idpahostnameLabel.Text = "IDPA Server Name :"
$idpahostnameLabel.AutoSize = $true
$idpahostnameLabel.Location = New-Object System.Drawing.Size(0,160)

$idpahostnametext = New-Object System.Windows.Forms.TextBox
$idpahostnametext.Location = New-Object System.Drawing.Point(260,160)
$idpahostnametext.Size = New-Object System.Drawing.Size(200,20)

$idpahostipLabel = New-Object System.Windows.Forms.Label
$idpahostipLabel.Text = "IDPA Server IP :"
$idpahostipLabel.AutoSize = $true
$idpahostipLabel.Location = New-Object System.Drawing.Size(0,200)

$idpahostiptext = New-Object System.Windows.Forms.TextBox
$idpahostiptext.Location = New-Object System.Drawing.Point(260,200)
$idpahostiptext.Size = New-Object System.Drawing.Size(200,20)

$sqlserverporttext = New-Object System.Windows.Forms.TextBox
$sqlserverporttext.Location = New-Object System.Drawing.Point(260,120)
$sqlserverporttext.Size = New-Object System.Drawing.Size(200,20)

$StorageUnituserLabel = New-Object System.Windows.Forms.Label
$StorageUnituserLabel.Text = "Storage Unit User-Name :"
$StorageUnituserLabel.AutoSize = $true
$StorageUnituserLabel.Location = New-Object System.Drawing.Size(550,40)

$StorageUnitusertext = New-Object System.Windows.Forms.TextBox
$StorageUnitusertext.Location = New-Object System.Drawing.Point(800,40)
$StorageUnitusertext.Size = New-Object System.Drawing.Size(200,20)

$StorageUnitpassLabel = New-Object System.Windows.Forms.Label
$StorageUnitpassLabel.Text = "Storage Unit Password :"
$StorageUnitpassLabel.AutoSize = $true
$StorageUnitpassLabel.Location = New-Object System.Drawing.Size(550,80)

$StorageUnitpasstext = New-Object System.Windows.Forms.TextBox
$StorageUnitpasstext.Location = New-Object System.Drawing.Point(800,80)
$StorageUnitpasstext.Size = New-Object System.Drawing.Size(200,20)
$StorageUnitpasstext.PasswordChar = '*'

$StorageUnitpassLabel1 = New-Object System.Windows.Forms.Label
$StorageUnitpassLabel1.Text = "Confirm Password :"
$StorageUnitpassLabel1.AutoSize = $true
$StorageUnitpassLabel1.Location = New-Object System.Drawing.Size(550,120)

$StorageUnitpasstext1 = New-Object System.Windows.Forms.TextBox
$StorageUnitpasstext1.Location = New-Object System.Drawing.Point(800,120)
$StorageUnitpasstext1.Size = New-Object System.Drawing.Size(200,20)
$StorageUnitpasstext1.PasswordChar = '*'



$SoftwareCheckLabel = New-Object System.Windows.Forms.Label
$SoftwareCheckLabel.Text = "Software Exists on Server :"
$SoftwareCheckLabel.AutoSize = $true
$SoftwareCheckLabel.Location = New-Object System.Drawing.Size(550,160)



$SoftwareLocationLabel = New-Object System.Windows.Forms.Label
$SoftwareLocationLabel.Text = "Software Location on Server :"
$SoftwareLocationLabel.AutoSize = $true
$SoftwareLocationLabel.Visible = $false
$SoftwareLocationLabel.Location = New-Object System.Drawing.Size(550,200)
$Form.Controls.Add($SoftwareLocationLabel)

$SoftwareLocationText = New-Object System.Windows.Forms.TextBox
$SoftwareLocationText.Location = New-Object System.Drawing.Point(810,200)
$SoftwareLocationText.Size = New-Object System.Drawing.Size(200,20)
$SoftwareLocationText.Visible = $false
$Form.Controls.Add($SoftwareLocationText)

$SoftwareCheckBox = New-Object System.Windows.Forms.CheckBox
$SoftwareCheckBox.Location = New-Object System.Drawing.Point(800,160)
$SoftwareCheckBox.Size = New-Object System.Drawing.Size(200,20)
$SoftwareCheckBox.add_CheckedChanged({if($SoftwareCheckBox.Checked) {$SoftwareLocationLabel.Visible = $true;$SoftwareLocationText.Visible = $true; $global:copyFlag = 0} else {$SoftwareLocationLabel.Visible = $false;$SoftwareLocationText.Visible = $false}})
$Form.Controls.Add($SoftwareCheckBox)


$outputtext = New-Object System.Windows.Forms.TextBox
$outputtext.Multiline = $True;
$outputtext.Location = New-Object System.Drawing.Point(5,300)
$outputtext.Size = New-Object System.Drawing.Size(1000,320)
$outputtext.Scrollbars = "Vertical" 
$Form.Controls.Add($outputtext)

$Form.Controls.Add($Label1)
$Form.Controls.Add($serverLabel)
$Form.Controls.Add($servertext)
$Form.Controls.Add($sqlservertext)
$Form.Controls.Add($sqlserverLabel)
$Form.Controls.Add($sqlserverportLabel)
$Form.Controls.Add($idpahostnameLabel)
$Form.Controls.Add($idpahostnametext)
$Form.Controls.Add($idpahostipLabel)
$Form.Controls.Add($idpahostiptext)
$Form.Controls.Add($sqlserverporttext)
$Form.Controls.Add($StorageUnituserLabel)
$Form.Controls.Add($StorageUnitusertext)
$Form.Controls.Add($StorageUnitpassLabel)
$Form.Controls.Add($StorageUnitpasstext)
$Form.Controls.Add($StorageUnitpassLabel1)
$Form.Controls.Add($StorageUnitpasstext1)
$Form.Controls.Add($SoftwareCheckLabel)

$form.Font = $Font

$Okbutton = New-Object System.Windows.Forms.Button
$Okbutton.Location = New-Object System.Drawing.Size(5,250)
$Okbutton.Size = New-Object System.Drawing.Size(455,30)
$Okbutton.Text = "PROCEED"
$Okbutton.Add_Click({OK-button_Check})
$Form.Controls.Add($Okbutton)


$servertext.Text = "PWGR2TDBLAB2-1"
$sqlservertext.Text = "PWGR2TDBLAB2-1"
$sqlserverporttext.Text = "62754"
$idpahostnametext.Text = "psgr2idpa01-ddbkp1.mgmtroot.local"
$idpahostiptext.Text = "10.41.4.20"
$StorageUnitusertext.Text = "dduser1"
$StorageUnitpasstext.Text = "Jupiter00"
$StorageUnitpasstext1.Text = "Jupiter00"
$SoftwareLocationText.Text = ""



$Form.ShowDialog()
#$timer.Dispose()
$form.Dispose()