param([string]$ServerName)
$global:rowtemp = @()
$global:resultfiledata = @()
function Get-ClusterValidation
{
    [CmdletBinding()]
    Param
    (
        [string]$ServerName  
    )
    $global:resultfilepath = Split-Path -Parent $PSCommandPath
    $date = (Get-Date -Format "MM_dd_yyyy") 
    #$global:rowtemp = @()
    #$global:tempresult = @()




    ##run everything below

    Write-Output "Performing Cluster validation"
    $ClusterResoucesInfo = @()
     
    $clusterName = Invoke-command -ComputerName $ServerName -ScriptBlock {Get-Cluster}
    $WindowsVersion = Invoke-command -ComputerName $ServerName -ScriptBlock {(Get-WmiObject -class Win32_OperatingSystem).Caption}
    $clusterFunctionalLevel = Invoke-command -ComputerName $ServerName -ScriptBlock {Get-Cluster | Select-Object -ExpandProperty ClusterFunctionalLevel}
    $global:resultfile = "$resultfilepath\Output\$clusterName-ClusterChecklist_$date.csv"
    $clusterNodes = Invoke-command -ComputerName $ServerName -ScriptBlock {Get-ClusterNode | Select-Object -ExpandProperty name}
    $witnessType = Invoke-command -ComputerName $ServerName {get-clusterresource | where-object name -like *Witness* | Select-Object -ExpandProperty  Name}
    If($witnessType -eq 'Cloud Witness') {
    $witnessName = Invoke-command -ComputerName $ServerName {get-clusterresource | where-object name -eq $Using:witnessType | Get-ClusterParameter | Where-object name -eq 'AccountName' | Select-Object -ExpandProperty value}
    }
    ELSE{
    $witnessName = Invoke-command -ComputerName $ServerName {get-clusterresource | where-object name -eq $Using:witnessType | Get-ClusterParameter | Where-object name -eq 'SharePath' | Select-Object -ExpandProperty value}
    }
    $ClusterResources   = Invoke-command -ComputerName $ServerName -ScriptBlock {get-clusterGroup | where-object Name -ne 'Available Storage' | Select-Object -ExpandProperty Name}
    ForEach($clusterObject in $ClusterResources)
        {
        $IPAddresses = Invoke-command -ComputerName $ServerName -ScriptBlock {Get-ClusterResource  | where-object ResourceType -EQ 'IP Address' | where-object OwnerGroup -EQ  $Using:clusterObject | get-clusterparameter -name Address | Select-Object -expandProperty value}
        $IpList = $null
        $NodeList = $null
            ForEach($i in $IPAddresses)
            {
            $IpList += $i + "; "  
            }
            ForEach($n in $clusterNodes)
            {
            $NodeList += $n + "; "  
            }

        $clusterObject = $clusterObject.ToString()
        $OwnerNode = Invoke-command -ComputerName $ServerName -ScriptBlock {get-clusterGroup -name $Using:clusterObject | Select-Object -ExpandProperty ownernode | Select-Object -ExpandProperty Name}
        $ListenerName = Invoke-command -ComputerName $ServerName -ScriptBlock {Get-ClusterResource | where-object ResourceType -eq 'Network Name' | Select-Object * | where-object OwnerGroup -eq $Using:clusterObject | Select-Object -ExpandProperty name}
        $ListenerName = $ListenerName.ToString()

        $RegAllIps = Invoke-command -ComputerName $ServerName -ScriptBlock {Get-ClusterResource -name $Using:ListenerName | Get-ClusterParameter | where-object Name -eq RegisterAllProvidersIP | Select-Object -ExpandProperty value}
        $HostRecordTTL = Invoke-command -ComputerName $ServerName -ScriptBlock {Get-ClusterResource -name $Using:ListenerName | Get-ClusterParameter | where-object Name -eq HostRecordTTL | Select-Object -ExpandProperty value}

            #$ClusterResoucesInfo = Get-ClusterResource  | where-object ResourceType -EQ 'IP Address' | where-object OwnerGroup -EQ  $clusterObject | get-clusterparameter -name Address | select *
        $ClusterResoucesInfo += New-Object -TypeName psobject -Property @{ClusterName ="$clusterName";WindowsVersion ="$WindowsVersion";ClusterFunctionalLevel ="$clusterFunctionalLevel";ClusterResource="$clusterObject"; IpAddresses="$IpList";NodeList="$NodeList";OwnerNode="$OwnerNode";NetworkName ="$ListenerName";RegisterAllProvidersIP="$RegAllIps";HostRecordTTL="$HostRecordTTL";WitnessType="$witnessType";WitnessValue="$witnessName";}

        

        }
    #$ClusterResoucesInfo | Select-Object Clustername, NodeList, WitnessType,WitnessValue,ClusterResource, OwnerNode, IpAddresses, ListenerName, RegisterAllProvidersIP,HostRecordTTL
    $ClusterResoucesInfo | Select-Object Clustername, WindowsVersion, ClusterFunctionalLevel, NodeList, WitnessType, WitnessValue, ClusterResource, OwnerNode, NetworkName, IpAddresses, RegisterAllProvidersIP,HostRecordTTL | Export-CSV $resultfile -notypeinformation


      ##run everything above for testing

      
}

####Function Ends Here




Get-ClusterValidation $ServerName

