<#
    .SYNOPSIS

    Connects to a container host and creates a container that stores a service discovery server.


    .DESCRIPTION

    The New-DiscoveryContainer script takes all the actions necessary configure a windows server container as a service discovery server.


    .PARAMETER containerHost

    The name of the machine on which the containers can be created


    .PARAMETER containerBaseName

    The name of the base container.


    .PARAMETER environmentName

    The name of the environment to which the remote machine should be added.


    .PARAMETER consulLocalAddress

    The URL to the local consul agent.


    .EXAMPLE

    New-WindowsResource -containerHost "MyContainerHost" -containerBaseName 'MyImageWithAllMyStuff'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $containerHost         = $(throw 'Please specify the name of the machine that should be configured.'),

    [Parameter(Mandatory = $true)]
    [string] $containerBaseName     = $(throw 'Please specify the name of the base container image.'),

    [Parameter(Mandatory = $false)]
    [string] $environmentName      = 'Development',

    [Parameter(Mandatory = $false)]
    [string] $consulLocalAddress   = "http://localhost:8500"
)

Write-Verbose "New-DiscoveryServer - containerHost: $containerHost"
Write-Verbose "New-DiscoveryServer - containerBaseName: $containerBaseName"
Write-Verbose "New-DiscoveryServer - environmentName: $environmentName"
Write-Verbose "New-DiscoveryServer - consulLocalAddress: $consulLocalAddress"

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
    $installationScript = Join-Path $PSScriptRoot 'Initialize-ContainerResource.ps1'
    & $installationScript `
        -containerHost $containerHost `
        -containerBase $containerBaseName `
        -consulLocalAddress $consulLocalAddress `
        -environmentName $environmentName `
        @commonParameterSwitches
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