using namespace System.IO

$Script:AssetsPath = Join-Path $PSScriptRoot '..' 'assets' | Resolve-Path
$Script:AssetsPath = Join-Path $Script:AssetsPath 'Special{0}List.txt'

# About why not use [System.IO.Path]
# ###################################
# > $Name = 'a.1.2.3'
#
# > [System.IO.Path]::GetFileNameWithoutExtension($Name)
# a.1.2
#
# > [System.IO.Path]::GetExtension($Name)
# 3
# ###################################
# > $Name | Get-FileNameWithoutExtension
# a
#
# > $Name | Get-FileExtension
# 1.2.3

function Get-FileNameWithoutExtension
{
  [CmdletBinding()]
  param (
    # FileInfo
    [Parameter(Mandatory, ValueFromPipeline)]
    [FileInfo]
    $File
  )

  return $File.Name.Substring(0, $File.Name.IndexOf('.'))
}

function Get-FileExtension
{
  [CmdletBinding()]
  param (
    # FileInfo
    [Parameter(Mandatory, ValueFromPipeline)]
    [FileInfo]
    $File
  )

  return $File.Name.Substring($File.Name.IndexOf('.'))
}

function Move-Libraries
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [string]
    $Path,
    [Parameter(Mandatory)]
    [string]
    $Destination,
    [Parameter()]
    [Engines]
    $Engine
  )

  begin
  {
    $Private:ClientSpecialLibraries = $null
    if ($Engine)
    {
      $Private:ClientSpecialLibraries = `
        Get-Content ($Script:AssetsPath -f $Engine)
    }

    Write-Debug ''
    Write-Debug 'Invoke Move-Libraries'
    Write-Debug ''
    Write-Debug "Engine: $Engine"
    Write-Debug "Path: $Path"
    Write-Debug "Destination: $Destination"
    Write-Debug "ClientSpecialLibraries: $Private:ClientSpecialLibraries"
  }

  process
  {
    $tmp = Get-ChildItem $Path

    if ($Engine)
    {
      $tmp = $tmp | Where-Object Name -In $Private:ClientSpecialLibraries
    }

    $tmp | ForEach-Object {
      $Private:TargetPath = (Join-Path $Destination $_.Name)
      if (!(Test-Path $Private:TargetPath))
      {
        # If File Not Exists
        Write-Debug "Move $_ to $Private:TargetPath"
        Move-Item -Path $_ -Destination $Private:TargetPath -Force
      }
      else
      {
        Write-Debug "Delete $_"
        Remove-Item -Path $_ -Recurse -Force
      }
    }
  }
}

function Move-ClientBinaries
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [FileInfo]
    $File,
    [Parameter(Mandatory)]
    [string]
    $Target
  )

  if (Test-Path $File.FullName)
  {
    Move-Item $File.FullName $Target -Force
  }
  else
  {
    Write-Error "File not found: $File"
  }
}

function Clear-Compiled
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [string]
    $Path
  )

  if (Test-Path $Path)
  {
    Remove-Item $Path -Recurse -Force | Out-Null
  }
}