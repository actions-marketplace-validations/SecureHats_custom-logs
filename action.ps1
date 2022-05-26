<#
    Title:          Custom Logs Ingestion
    Language:       PowerShell
    Version:        1.0
    Author:         Rogier Dijkman
    Last Modified:  05/26/2022

    DESCRIPTION
    This GitHub action is used to upload custom data to a log analytics workspace.
    The input can be either JSON or CSV formatted. This function will build the signature and authorization header needed to
    post the data to the Log Analytics workspace via the HTTP Data Connector API.

    The GitHub action will post each log type to their individual tables in Log Analytics, for example,
    SecureHats_CL. If the filename ends with _CL the name of the file will be used as the table name
#>

param (
    [parameter(Mandatory = $true)]
    [string]$FilesPath,

    [parameter(Mandatory = $true)]
    [string]$workspaceId,

    [parameter(Mandatory = $true)]
    [string]$workspaceKey,

    [parameter(Mandatory = $false)]
    [string]$TableName
)

# Import custom modules
Get-ChildItem $($PSScriptRoot)
Import-Module "$($PSScriptRoot)/modules/HelperFunctions.psm1"

Write-Output "Also dot source"
. "$($PSScriptRoot)/modules/HelperFunctions.psm1"

$parameters = @{
    workspaceId   = $workspaceId
    workspaceKey  = $workspaceKey
    tableName     = $TableName
    dataInput     = ''
}

if ($FilesPath -ne '.') {
    Write-Output  "Files path is [$FilesPath]"
}

$files = Get-ChildItem -Path $FilesPath | ForEach-Object {
    Write-Host "Processing File input [$_]"
    if ($_.FullName -like "*.csv") {
        try {
            $parameters.dataInput = (Get-Content $_.FullName | ConvertFrom-CSV)
            if ($_.BaseName -like "_CL") {
                Write-Host "Converted file from CSV"
                $parameters.tableName = ($_.BaseName).Replace('_CL', '')
            }
            Write-Host "Sending JSON to workspace"
            $response = Send-CustomLogs @parameters
        }
        catch {
            Write-Host "Unable to process CSV file [$_]"
        }
    } elseif ($_.FullName -like "*.json") {
        try {
            $parameters.dataInput = (Get-Content $_.FullName | ConvertFrom-JSON)
            if ($_.BaseName -like "_CL") {
            Write-Host "Converted file from JSON"
                $parameters.tableName = ($_.BaseName).Replace('_CL', '')
            }
            Write-Host "Sending JSON to workspace"
            $response = Send-CustomLogs @parameters
        }
        catch {
            Write-Host "Unable to process JSON file [$_]"
        }

    } else {
        Write-Host "Nothing to progress"
    }
}

write-Host $response
