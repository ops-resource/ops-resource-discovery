<#
    .SYNOPSIS

    Creates a new VM image with all the required files and applications in order to turn the VM into a service discovery server.


    .DESCRIPTION

    The New-DiscoveryHypervImage  script takes all the actions necessary to create and configure a Hyper-V VM image as a service discovery server.


    .PARAMETER osName

    The name of the OS that should be used to create the new VM.


    .PARAMETER hypervHost

    The name of the machine on which the hyper-v server is located.


    .PARAMETER vhdxTemplatePath

    The UNC path to the directory that contains the Hyper-V images.


    .PARAMETER hypervHostVmStoragePath

    The UNC path to the directory that stores the Hyper-V VM information.


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
    [string] $osName                                            = '',

    [Parameter(Mandatory = $true,
               ParameterSetName = 'FromUserSpecification')]
    [string] $hypervHost                                        = '',

    [Parameter(Mandatory = $true,
               ParameterSetName = 'FromUserSpecification')]
    [string] $vhdxTemplatePath                                  = "\\$($hypervHost)\vmtemplates",

    [Parameter(Mandatory = $true,
               ParameterSetName = 'FromUserSpecification')]
    [string] $hypervHostVmStoragePath                           = "\\$(hypervHost)\vms\machines",

    [Parameter(Mandatory = $true,
               ParameterSetName = 'FromUserSpecification')]
    [string] $dataCenterName                                    = '',

    [Parameter(Mandatory = $true,
               ParameterSetName = 'FromUserSpecification')]
    [string] $clusterEntryPointAddress                          = '',

    [Parameter(Mandatory = $false,
               ParameterSetName = 'FromUserSpecification')]
    [string] $globalDnsServerAddress                            = '',

    [Parameter(Mandatory = $true,
               ParameterSetName = 'FromMetaCluster')]
    [string] $environmentName                                   = 'Development',

    [Parameter(Mandatory = $false,
               ParameterSetName = 'FromMetaCluster')]
    [string] $consulLocalAddress                                = "http://localhost:8500"
)

Write-Verbose "New-DiscoveryHypervImage - osName = $osName"
Write-Verbose "New-DiscoveryHypervImage - hypervHost: $hypervHost"
switch ($psCmdlet.ParameterSetName)
{
    'FromUserSpecification' {
        Write-Verbose "New-DiscoveryHypervImage - hypervHost = $hypervHost"
        Write-Verbose "New-DiscoveryHypervImage - vhdxTemplatePath = $vhdxTemplatePath"
        Write-Verbose "New-DiscoveryHypervImage - hypervHostVmStoragePath = $hypervHostVmStoragePath"
        Write-Verbose "New-DiscoveryHypervImage - dataCenterName = $dataCenterName"
        Write-Verbose "New-DiscoveryHypervImage - clusterEntryPointAddress = $clusterEntryPointAddress"
        Write-Verbose "New-DiscoveryHypervImage - globalDnsServerAddress = $globalDnsServerAddress"
    }

    'FromMetaCluster' {
        Write-Verbose "New-DiscoveryHypervImage - environmentName = $environmentName"
        Write-Verbose "New-DiscoveryHypervImage - consulLocalAddress = $consulLocalAddress"
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
    $installationScript = Join-Path $PSScriptRoot 'Initialize-HyperVImage.ps1'
    switch ($psCmdlet.ParameterSetName)
    {
        'FromUserSpecification' {
            & $installationScript `
                -osName $osName `
                -hypervHost $hypervHost `
                -vhdxTemplatePath $vhdxTemplatePath `
                -hypervHostVmStoragePath $hypervHostVmStoragePath `
                -dataCenterName $dataCenterName `
                -clusterEntryPointAddress $clusterEntryPointAddress `
                -globalDnsServerAddress $globalDnsServerAddress `
                @commonParameterSwitches
        }

        'FromMetaCluster' {
            & $installationScript `
                -osName $osName `
                -hypervHost $hypervHost `
                -environmentName $environmentName `
                -consulLocalAddress $consulLocalAddress `
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