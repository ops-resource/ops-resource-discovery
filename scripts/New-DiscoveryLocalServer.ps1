<#
    .SYNOPSIS

    Connects to the remote machine, pushes all the necessary files up to it, executes the Chef cookbook that installs
    all the required files and applications in order to turn the remote machine into a service discovery server.


    .DESCRIPTION

    The New-DiscoveryLocalServer script takes all the actions necessary configure the remote machine as a service discovery server.


    .PARAMETER computerName

    The name of the machine that should be set up.


    .PARAMETER dataCenterName

    The name of the consul data center to which the remote machine should belong once configuration is completed.


    .PARAMETER clusterEntryPointAddress

    The DNS name of a machine that is part of the consul cluster to which the remote machine should be joined.


    .PARAMETER globalDnsServerAddress

    The DNS name or IP address of the DNS server that will be used by Consul to handle DNS fallback.


    .PARAMETER environmentName

    The name of the environment to which the remote machine should be added.


    .PARAMETER consulLocalAddress

    The URL to the local consul agent.


    .EXAMPLE

    New-WindowsResource -computerName "MyCoolServer"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $computerName         = $(throw 'Please specify the name of the machine that should be configured.'),

    [Parameter(Mandatory = $true,
               ParameterSetName = 'FromUserSpecification')]
    [string] $dataCenterName                                    = '',

    [Parameter(Mandatory = $true,
               ParameterSetName = 'FromUserSpecification')]
    [string] $clusterEntryPointAddress                          = '',

    [Parameter(Mandatory = $false,
               ParameterSetName = 'FromUserSpecification')]
    [string] $globalDnsServerAddress                            = '',

    [Parameter(Mandatory = $false,
               ParameterSetName = 'FromMetaCluster')]
    [string] $environmentName                                   = 'Development',

    [Parameter(Mandatory = $false,
               ParameterSetName = 'FromMetaCluster')]
    [string] $consulLocalAddress                                = "http://localhost:8500"
)

Write-Verbose "New-DiscoveryLocalServer - computerName: $computerName"
switch ($psCmdlet.ParameterSetName)
{
    'FromUserSpecification' {
        Write-Verbose "New-DiscoveryLocalServer - dataCenterName: $dataCenterName"
        Write-Verbose "New-DiscoveryLocalServer - clusterEntryPointAddress: $clusterEntryPointAddress"
        Write-Verbose "New-DiscoveryLocalServer - globalDnsServerAddress: $globalDnsServerAddress"
    }

    'FromMetaCluster' {
        Write-Verbose "New-DiscoveryLocalServer - environmentName: $environmentName"
    }
}

# Stop everything if there are errors
$ErrorActionPreference = 'Stop'

$commonParameterSwitches =
    @{
        Verbose = $PSBoundParameters.ContainsKey('Verbose');
        Debug = $PSBoundParameters.ContainsKey('Debug');
        ErrorAction = "Stop"
    }

try
{
    $installationScript = Join-Path $PSScriptRoot 'Initialize-LocalNetworkResource.ps1'
    switch ($psCmdlet.ParameterSetName)
    {
        'FromUserSpecification' {
            & $installationScript `
                -computerName $computerName `
                -dataCenterName $dataCenterName `
                -clusterEntryPointAddress $clusterEntryPointAddress `
                -globalDnsServerAddress $globalDnsServerAddress `
                @commonParameterSwitches
        }

        'FromMetaCluster' {
            & $installationScript `
                -computerName $computerName `
                -consulLocalAddress $consulLocalAddress `
                -environmentName $environmentName `
                @commonParameterSwitches
        }
    }
}
catch
{
    $errorRecord = $Error[0]

    $currentErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    try
    {
        Write-Error $errorRecord.Exception
        Write-Error $errorRecord.ScriptStackTrace
        Write-Error $errorRecord.InvocationInfo.PositionMessage
    }
    finally
    {
        $ErrorActionPreference = $currentErrorActionPreference
    }
}