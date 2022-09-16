function Get-TargetFrameworkWithoutTFM
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [string]
    $TargetFramework
  )

  return ($TargetFramework -split '-')[0]
}