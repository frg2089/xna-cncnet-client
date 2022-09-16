#!/usr/bin/env pwsh
#Requires -Version 7.2

using module .\modules\utils\Enums.psm1
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

Build-All $Configuration -SkipMoveLibraries:$SkipMoveLibraries