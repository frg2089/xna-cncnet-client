#!/usr/bin/env pwsh
#Requires -Version 7.2

using module .\modules\BuildTools.psd1

[CmdletBinding()]
param (
  [Parameter()]
  [string]
  $Configuration = 'Release',
  [Parameter()]
  [Switch]
  $SkipMoveLibraries
)

try
{
  Build-YR $Configuration -SkipMoveLibraries:$SkipMoveLibraries
}
finally
{
  Remove-Module BuildTools
}