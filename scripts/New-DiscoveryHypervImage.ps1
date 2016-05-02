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
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $osName                                            = '',

    [Parameter(Mandatory = $true)]
    [string] $hypervHost                                        = '',

    [Parameter()]
    [string] $vhdxTemplatePath                                  = "\\$($hypervHost)\vmtemplates",

    [Parameter()]
    [string] $hypervHostVmStoragePath                           = "\\$($hypervHost)\vms\machines"
)

Write-Verbose "New-DiscoveryHypervImage - osName = $osName"
Write-Verbose "New-DiscoveryHypervImage - hypervHost: $hypervHost"
Write-Verbose "New-DiscoveryHypervImage - vhdxTemplatePath = $vhdxTemplatePath"
Write-Verbose "New-DiscoveryHypervImage - hypervHostVmStoragePath = $hypervHostVmStoragePath"


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
    & $installationScript `
        -osName $osName `
        -hypervHost $hypervHost `
        -vhdxTemplatePath $vhdxTemplatePath `
        -hypervHostVmStoragePath $hypervHostVmStoragePath `
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