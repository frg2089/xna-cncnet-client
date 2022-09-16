$Script:ClientCompiledTarget = `
  Join-Path $PSScriptRoot '..' '..' 'Compiled'
$Script:ClientProjectPath = `
  Join-Path $PSScriptRoot '..' '..' 'DXMainClient' | Resolve-Path
if (!(Test-Path $Script:ClientCompiledTarget))
{
  New-Item -ItemType Directory -Force -Path $Script:ClientCompiledTarget
}
$Script:ClientCompiledTarget = Resolve-Path $Script:ClientCompiledTarget

<#
.SYNOPSIS
  Project builder core functions
.DESCRIPTION
  The purpose of this function is to build the entire project in a specific way
.PARAMETER Game
  The client will serve this game
.PARAMETER Engine
  The client will use this graphics engine to build
.PARAMETER Configuration
  The client will be built using this configuration file
.PARAMETER TargetFramework
  The client will use this target framework
.PARAMETER RuntimeIdentifier
  Runtime identifier
.PARAMETER PlatformTarget
  Platform Target
.PARAMETER SkipMoveLibraries
  Skip moving dependency library files
  This will cause all dependent libraries to be tiled in the generated folder
.EXAMPLE
  Build-Project Ares WindowsDX Release 'net6.0-windows10.0.22000.0'

.EXAMPLE
  Build-Project -Configuration Release Ares WindowsDX `
    'net6.0-windows10.0.22000.0'

.EXAMPLE
  Build-Project -Configuration Release -Game Ares -Engine WindowsDX `
    -TargetFramework 'net6.0-windows10.0.22000.0'
#>
function Build-Project
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [Games]
    $Game,
    [Parameter(Mandatory)]
    [Engines]
    $Engine,
    [Parameter(Mandatory)]
    [Configurations]
    $Configuration,
    [Parameter(Mandatory)]
    [string]
    $TargetFramework,
    [Parameter()]
    [string]
    $RuntimeIdentifier,
    [Parameter()]
    [string]
    $PlatformTarget,
    [Parameter()]
    [Switch]
    $SkipMoveLibraries
  )

  begin
  {
    Write-Host
    Write-Host `
      "Building $Game $Engine $Configuration $TargetFramework " `
      "$PlatformTarget $RuntimeIdentifier..." `
      -ForegroundColor Blue
    Write-Host

    $Private:DotnetCommand = Get-Command 'dotnet'

    # Check the Build Environment in here.

    $Private:TargetFrameworkWithoutTFM = `
      $TargetFramework | Get-TargetFrameworkWithoutTFM
    $Private:SpecialName = $Engine | Get-PlatformName
    $Private:ClientSuffix = $Engine | Get-Suffix

    $Private:RootDirectory = Join-Path $ClientCompiledTarget $Game `
      $TargetFramework $RuntimeIdentifier
    $Private:ResourcesDirectory = Join-Path $Private:RootDirectory 'Resources'
    $Private:CommonLibsDirectory = Join-Path $Private:ResourcesDirectory `
      'Binaries'
    $Private:SpecialLibsDirectory = Join-Path $Private:CommonLibsDirectory `
      $Private:SpecialName

    $Private:BuildTargetDirectory = $SkipMoveLibraries `
      ? $Private:SpecialLibsDirectory `
      : (Join-Path $Private:SpecialLibsDirectory 'Source')

    $Private:DotnetArgs = @(
      'publish'
      $ClientProjectPath
      "--framework:$TargetFramework"
      "--output:$Private:BuildTargetDirectory" `
        + [IO.Path]::DirectorySeparatorChar
      '--no-self-contained'
      "--configuration:$Configuration"
      "-p:Engine=$Engine"
      "-p:Game=$Game"
      if ($PlatformTarget) { "-p:PlatformTarget=$PlatformTarget" }
      if ($RuntimeIdentifier -and $RuntimeIdentifier -ne 'any')
      { "--runtime:$RuntimeIdentifier" }
    )

    # Write-Debug ''
    # Write-Debug 'Invoke Build-Project'
    # Write-Debug ''
    # Write-Debug "Dotnet: $Private:DotnetCommand"
    # Write-Debug `
    #   "Game: $Game; Engine: $Engine; Configuration: $Configuration; " `
    #   + "TargetFramework: $TargetFramework; PlatformTarget: $PlatformTarget; " `
    #   + "RuntimeIdentifier: $RuntimeIdentifier"
    # Write-Debug `
    #   "SkipMoveLibraries: $SkipMoveLibraries; " `
    #   + "TargetFrameworkWithoutTFM: $Private:TargetFrameworkWithoutTFM; " `
    #   + "SpecialName: $Private:SpecialName; " `
    #   + "ClientSuffix: $Private:ClientSuffix"
    # Write-Debug "RootDirectory: $Private:RootDirectory"
    # Write-Debug "ResourcesDirectory: $Private:ResourcesDirectory"
    # Write-Debug "CommonLibsDirectory: $Private:CommonLibsDirectory"
    # Write-Debug "SpecialLibsDirectory: $Private:SpecialLibsDirectory"
    # Write-Debug "BuildTargetDirectory: $Private:BuildTargetDirectory"
    # Write-Debug "DotnetArgs: $Private:DotnetArgs"
  }

  process
  {
    & $Private:DotnetCommand $Private:DotnetArgs
    if ($LASTEXITCODE)
    {
      throw 'Build failed'
    }
  }

  end
  {
    $Private:tmp = Join-Path `
      $Private:BuildTargetDirectory `
      "client$Private:ClientSuffix"
    if ($Engine -eq 'UniversalGL' -and $RuntimeIdentifier -eq 'any')
    {
      # cross platform net6.0, net7.0
      # no startup executable (run with 'dotnet')
      $Private:tmp += '.nomatches'
    }
    elseif ("$Private:tmp." | Test-Path)
    {
      # linux based
      $Private:tmp += '.'
    }
    elseif ("$Private:tmp.exe" | Test-Path)
    {
      # WinForms net6.0-windows, net7.0-windows
      # or UniversalGL Windows specific net7.0 win10-x64, ...
      $Private:tmp += '.exe'
    }
    elseif ("$Private:tmp.dll" | Test-Path)
    {
      # net48, net6.0 android-arm64, ...
      $Private:tmp += '.*'
    }
    if ($Private:tmp | Test-Path)
    {
      $Private:tmp | Get-ChildItem | ForEach-Object {
        $_ | Move-ClientBinaries -Target $Private:ResourcesDirectory
      }
    }
    if (!$SkipMoveLibraries)
    {
      # Move All of the special libraries to special folder.
      $Private:BuildTargetDirectory | Move-Libraries `
        -Destination $Private:SpecialLibsDirectory -Engine $Engine
      # Move All of the files to common folder.
      $Private:BuildTargetDirectory | Move-Libraries `
        -Destination $Private:CommonLibsDirectory
      # Remove the temp dir.
      $Private:BuildTargetDirectory | Remove-Item -Force
    }

    Write-Host
    Write-Host `
      "Build succeeded for $Game $Engine $Configuration " `
      + "$TargetFramework $PlatformTarget $RuntimeIdentifier..." `
      -ForegroundColor Green
    Write-Host
  }
}

function Build-Core
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [Configurations]
    $Configuration,
    [Parameter(Mandatory)]
    [Games]
    $Game,
    [Parameter()]
    [Switch]
    $SkipMoveLibraries
  )

  Join-Path $Script:ClientCompiledTarget $Game | Clear-Compiled

  Build-Project `
    -Configuration $Configuration `
    -Game $Game `
    -Engine UniversalGL `
    -TargetFramework 'net6.0' `
    -SkipMoveLibraries:$SkipMoveLibraries `
    -RuntimeIdentifier 'any'

  if ($IsWindows)
  {
    Build-Project `
      -Configuration $Configuration `
      -Game $Game `
      -Engine WindowsDX `
      -TargetFramework 'net6.0-windows10.0.22000.0' `
      -SkipMoveLibraries:$SkipMoveLibraries
    Build-Project `
      -Configuration $Configuration `
      -Game $Game `
      -Engine WindowsGL `
      -TargetFramework 'net6.0-windows10.0.22000.0' `
      -SkipMoveLibraries:$SkipMoveLibraries
    Build-Project `
      -Configuration $Configuration `
      -Game $Game `
      -Engine WindowsXNA `
      -TargetFramework 'net6.0-windows10.0.22000.0' `
      -SkipMoveLibraries:$SkipMoveLibraries `
      -PlatformTarget 'x86'

    Build-Project `
      -Configuration $Configuration `
      -Game $Game `
      -Engine WindowsDX `
      -TargetFramework 'net48' `
      -SkipMoveLibraries:$SkipMoveLibraries
    Build-Project `
      -Configuration $Configuration `
      -Game $Game `
      -Engine WindowsGL `
      -TargetFramework 'net48' `
      -SkipMoveLibraries:$SkipMoveLibraries
    Build-Project `
      -Configuration $Configuration `
      -Game $Game `
      -Engine WindowsXNA `
      -TargetFramework 'net48' `
      -SkipMoveLibraries:$SkipMoveLibraries `
      -PlatformTarget 'x86'
  }
}

function Build-Ares
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [Configurations]
    $Configuration,
    [Parameter()]
    [Switch]
    $SkipMoveLibraries
  )
  Build-Core $Configuration Ares -SkipMoveLibraries:$SkipMoveLibraries
}

function Build-TS
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [Configurations]
    $Configuration,
    [Parameter()]
    [Switch]
    $SkipMoveLibraries
  )

  Build-Core $Configuration TS -SkipMoveLibraries:$SkipMoveLibraries
}

function Build-YR
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [Configurations]
    $Configuration,
    [Parameter()]
    [Switch]
    $SkipMoveLibraries
  )

  Build-Core $Configuration YR -SkipMoveLibraries:$SkipMoveLibraries
}

function Build-All
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [Configurations]
    $Configuration,
    [Parameter()]
    [Switch]
    $SkipMoveLibraries
  )

  process
  {
    Build-Ares $Configuration -SkipMoveLibraries:$SkipMoveLibraries
    Build-TS $Configuration -SkipMoveLibraries:$SkipMoveLibraries
    Build-YR $Configuration -SkipMoveLibraries:$SkipMoveLibraries
  }
}