[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [psobject] $metaEntryPoint,
    [psobject] $entryPoint,
    [string] $jenkinsDataLocation,
    [string] $nugetDataLocation,
    [hashtable] $externalServices
)

Write-Verbose "Set-ProductionKeyValuePairsInConsul: param metaEntryPoint = $metaEntryPoint"
Write-Verbose "Set-ProductionKeyValuePairsInConsul: param entryPoint = $entryPoint"
Write-Verbose "Set-ProductionKeyValuePairsInConsul: param jenkinsDataLocation = $jenkinsDataLocation"
Write-Verbose "Set-ProductionKeyValuePairsInConsul: param nugetDataLocation = $nugetDataLocation"

# Stop everything if there are errors
$ErrorActionPreference = 'Stop'

$commonParameterSwitches =
    @{
        Verbose = $PSBoundParameters.ContainsKey('Verbose');
        Debug = $PSBoundParameters.ContainsKey('Debug');
        ErrorAction = "Stop"
    }

. (Join-Path $PSScriptRoot 'Consul.ps1')



# UPDATE THE CONSUL CONFIG FILE
# - Number of servers
# - datacenter
# - domain



# START CONSUL


# PUSH CONSUL K-V INFORMATION




# Set the address of the meta server
$machine_fqdn = "$($env:computername).$($env:userdnsdomain)".ToLower()
$httpUrl = "http://localhost:$($entryPoint.HttpPort)"
$dataCenter = $entryPoint.DataCenter

$metaHttpUrl = "http://$($machine_fqdn)"

Set-ConsulMetaServer `
    -dataCenter $dataCenter `
    -httpUrl $httpUrl `
    -metaDataCenter $metaEntryPoint.DataCenter `
    -metaHttpUrl $metaHttpUrl `
    @commonParameterSwitches

Set-ConsulKeyValue `
    -dataCenter $dataCenter `
    -httpUrl $httpUrl `
    -keyPath 'service/jenkins/data' `
    -value $jenkinsDataLocation `
    @commonParameterSwitches

Set-ConsulKeyValue `
    -dataCenter $dataCenter `
    -httpUrl $httpUrl `
    -keyPath 'service/nuget/data' `
    -value $nugetDataLocation `
    @commonParameterSwitches

foreach($pair in $externalServices)
{
    $name = $pair.Name
    $url = $pair.url
    $tags = $pair.Tags
    Set-ConsulExternalService `
        -dataCenter $dataCenter `
        -httpUrl $httpUrl `
        -serviceName $name `
        -serviceUrl $url `
        -tags $tags `
        -Verbose
}

