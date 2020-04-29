param([string]$ComputerName, [string]$SAPWD, [string]$SQLSYSADMINACCOUNTS, [int]$SQLTEMPDBFILECOUNT, [string]$instancenamearg, [string]$SQLInstallEXELocation, [string]$ConfigINILocation, $vFlag, [string]$spdestlocationforupdate)
#$global:SQLInstallEXELocation = "D:\SQL 2016 Developer\en_sql_server_2016_developer_with_service_pack_1_x64_dvd_9548071\setup.exe"
#$global:ConfigINILocation = "D:\SQL 2016 Developer\en_sql_server_2016_developer_with_service_pack_1_x64_dvd_9548071\ConfigurationFile2016.ini"
$global:vFlag = $vFlag
$global:SQLInstallEXELocation = $SQLInstallEXELocation
$global:ConfigINILocation = $ConfigINILocation
#$global:SQLInstallEXELocation = "F:\setup.exe"
#$global:ConfigINILocation = "C:\temp\ConfigurationFile.ini"
$UpdateEnabled = "True"
$UpdateSource = $spdestlocationforupdate
#$UpdateSource = "D:\temp\SQLUpdates"

$global:SQLTEMPDBFILESIZE = 1024
$global:SQLTEMPDBFILESIZE = [int]$SQLTEMPDBFILESIZE 
if([string]::IsNullOrWhiteSpace($instancenamearg)) {$global:InstanceName = 'MSSQLSERVER'}else {$global:InstanceName = $instancenamearg}   ##MSSQLSERVER is the default instance.  Only creates a named instance if one is provided

if($vFlag -eq 2019){

$sbdefault = [scriptblock]::Create("& '$SQLInstallEXELocation' /ConfigurationFile='$ConfigINILocation' /IACCEPTSQLSERVERLICENSETERMS /SAPWD='$SAPWD' /UpdateEnabled='$UpdateEnabled' /UpdateSource='$UpdateSource' /SQLSYSADMINACCOUNTS='$SQLSYSADMINACCOUNTS' /SQLTEMPDBFILECOUNT=$SQLTEMPDBFILECOUNT /SQLTEMPDBFILESIZE=$SQLTEMPDBFILESIZE")
#$sbdefault = [scriptblock]::Create("& '$SQLInstallEXELocation' /ConfigurationFile='$ConfigINILocation' /IACCEPTSQLSERVERLICENSETERMS /SAPWD='$SAPWD' /UpdateEnabled='$UpdateEnabled' /UpdateSource='$UpdateSource' /SQLSYSADMINACCOUNTS='$SQLSYSADMINACCOUNTS' /SQLTEMPDBFILECOUNT=$SQLTEMPDBFILECOUNT /SQLTEMPDBFILESIZE=$SQLTEMPDBFILESIZE /INSTALLSQLDATADIR='E:\Program Files\Microsoft SQL Server' /SQLBACKUPDIR='E:\Backup' /SQLUSERDBDIR='E:\MSSQL\" + $InstanceName + "\Data01' /SQLUSERDBLOGDIR='E:\MSSQL\" + $InstanceName + "\Data01' /SQLTEMPDBDIR='E:\MSSQL\" + $InstanceName + "\Data01' /SQLTEMPDBLOGDIR='E:\MSSQL\" + $InstanceName + "\Data01' ")
$sbnamed = [scriptblock]::Create("& '$SQLInstallEXELocation' /ConfigurationFile='$ConfigINILocation' /IACCEPTSQLSERVERLICENSETERMS /SAPWD='$SAPWD' /UpdateEnabled='$UpdateEnabled' /UpdateSource='$UpdateSource' /SQLSYSADMINACCOUNTS='$SQLSYSADMINACCOUNTS' /SQLTEMPDBFILECOUNT=$SQLTEMPDBFILECOUNT /SQLTEMPDBFILESIZE=$SQLTEMPDBFILESIZE /INSTANCENAME=$InstanceName /INSTANCEID=$InstanceName /SQLUSERDBDIR='K:\MSSQL\" + $InstanceName + "\Data01' /SQLUSERDBLOGDIR='L:\MSSQL\" + $InstanceName + "\Data01' /SQLTEMPDBDIR='P:\MSSQL\" + $InstanceName + "\Data01' /SQLTEMPDBLOGDIR='P:\MSSQL\" + $InstanceName + "\Data01' /SQLTELSVCACCT='NT Service\SQLTELEMETRY$" +$InstanceName + "'" +" /AGTSVCACCOUNT='NT Service\SQLAgent$" +  $InstanceName + "'" + " /SQLSVCACCOUNT='NT Service\MSSQL$" + $InstanceName + "'")
}

if($vFlag -eq 2016){
$sbdefault = [scriptblock]::Create("& '$SQLInstallEXELocation' /ConfigurationFile='$ConfigINILocation' /IACCEPTSQLSERVERLICENSETERMS /SAPWD='$SAPWD' /UpdateEnabled='$UpdateEnabled' /UpdateSource='$UpdateSource' /SQLSYSADMINACCOUNTS='$SQLSYSADMINACCOUNTS' /SQLTEMPDBFILECOUNT=$SQLTEMPDBFILECOUNT /SQLTEMPDBFILESIZE=$SQLTEMPDBFILESIZE")
#$sbdefault = [scriptblock]::Create("& '$SQLInstallEXELocation' /ConfigurationFile='$ConfigINILocation' /IACCEPTSQLSERVERLICENSETERMS /SAPWD='$SAPWD' /UpdateEnabled='$UpdateEnabled' /UpdateSource='$UpdateSource' /SQLSYSADMINACCOUNTS='$SQLSYSADMINACCOUNTS' /SQLTEMPDBFILECOUNT=$SQLTEMPDBFILECOUNT /SQLTEMPDBFILESIZE=$SQLTEMPDBFILESIZE /INSTALLSQLDATADIR='E:\Program Files\Microsoft SQL Server' /SQLBACKUPDIR='E:\Backup' /SQLUSERDBDIR='E:\MSSQL\" + $InstanceName + "\Data01' /SQLUSERDBLOGDIR='E:\MSSQL\" + $InstanceName + "\Data01' /SQLTEMPDBDIR='E:\MSSQL\" + $InstanceName + "\Data01' /SQLTEMPDBLOGDIR='E:\MSSQL\" + $InstanceName + "\Data01' ")
$sbnamed = [scriptblock]::Create("& '$SQLInstallEXELocation' /ConfigurationFile='$ConfigINILocation' /IACCEPTSQLSERVERLICENSETERMS /SAPWD='$SAPWD' /UpdateEnabled='$UpdateEnabled' /UpdateSource='$UpdateSource' /SQLSYSADMINACCOUNTS='$SQLSYSADMINACCOUNTS' /SQLTEMPDBFILECOUNT=$SQLTEMPDBFILECOUNT /SQLTEMPDBFILESIZE=$SQLTEMPDBFILESIZE /INSTANCENAME=$InstanceName /INSTANCEID=$InstanceName /SQLUSERDBDIR='K:\MSSQL\" + $InstanceName + "\Data01' /SQLUSERDBLOGDIR='L:\MSSQL\" + $InstanceName + "\Data01' /SQLTEMPDBDIR='P:\MSSQL\" + $InstanceName + "\Data01' /SQLTEMPDBLOGDIR='P:\MSSQL\" + $InstanceName + "\Data01' /SQLTELSVCACCT='NT Service\SQLTELEMETRY$" +$InstanceName + "'" +" /AGTSVCACCOUNT='NT Service\SQLAgent$" +  $InstanceName + "'" + " /SQLSVCACCOUNT='NT Service\MSSQL$" + $InstanceName + "'")
}
if($vFlag -eq 2014){
$sbdefault = [scriptblock]::Create("& '$SQLInstallEXELocation' /ConfigurationFile='$ConfigINILocation' /IACCEPTSQLSERVERLICENSETERMS /SAPWD='$SAPWD' /UpdateEnabled='$UpdateEnabled' /UpdateSource='$UpdateSource' /SQLSYSADMINACCOUNTS='$SQLSYSADMINACCOUNTS' ")
$sbnamed = [scriptblock]::Create("& '$SQLInstallEXELocation' /ConfigurationFile='$ConfigINILocation' /IACCEPTSQLSERVERLICENSETERMS /SAPWD='$SAPWD' /UpdateEnabled='$UpdateEnabled' /UpdateSource='$UpdateSource' /SQLSYSADMINACCOUNTS='$SQLSYSADMINACCOUNTS' /INSTANCENAME=$InstanceName /INSTANCEID=$InstanceName /SQLUSERDBDIR='K:\MSSQL\" + $InstanceName + "\Data01' /SQLUSERDBLOGDIR='L:\MSSQL\" + $InstanceName + "\Data01' /SQLTEMPDBDIR='P:\MSSQL\" + $InstanceName + "\Data01' /AGTSVCACCOUNT='NT Service\SQLAgent$" +  $InstanceName + "'" + " /SQLSVCACCOUNT='NT Service\MSSQL$" + $InstanceName + "'")
}
if($vFlag -eq 2012){
$sbdefault = [scriptblock]::Create("& '$SQLInstallEXELocation' /ConfigurationFile='$ConfigINILocation' /IACCEPTSQLSERVERLICENSETERMS /SAPWD='$SAPWD' /UpdateEnabled='$UpdateEnabled' /UpdateSource='$UpdateSource' /SQLSYSADMINACCOUNTS='$SQLSYSADMINACCOUNTS' ")
$sbnamed = [scriptblock]::Create("& '$SQLInstallEXELocation' /ConfigurationFile='$ConfigINILocation' /IACCEPTSQLSERVERLICENSETERMS /SAPWD='$SAPWD' /UpdateEnabled='$UpdateEnabled' /UpdateSource='$UpdateSource' /SQLSYSADMINACCOUNTS='$SQLSYSADMINACCOUNTS' /INSTANCENAME=$InstanceName /INSTANCEID=$InstanceName /SQLUSERDBDIR='K:\MSSQL\" + $InstanceName + "\Data01' /SQLUSERDBLOGDIR='L:\MSSQL\" + $InstanceName + "\Data01' /SQLTEMPDBDIR='P:\MSSQL\" + $InstanceName + "\Data01' /AGTSVCACCOUNT='NT Service\SQLAgent$" +  $InstanceName + "'" + " /SQLSVCACCOUNT='NT Service\MSSQL$" + $InstanceName + "'")
}
$sbdefault
IF($InstanceName -eq "MSSQLSERVER" -or $InstanceName -eq ""){

Invoke-Command -ComputerName $ComputerName -ScriptBlock $sbdefault
}
ELSE {

Invoke-Command -ComputerName $ComputerName -ScriptBlock $sbnamed

}

