$Script:SuffixMap = @{
  [Engines]::WindowsDX   = 'dx'
  [Engines]::WindowsGL   = 'ogl'
  [Engines]::UniversalGL = 'ogl'
  [Engines]::WindowsXNA  = 'xna'
}

$Script:PlatformNameMap = @{
  [Engines]::WindowsDX   = 'Windows'
  [Engines]::WindowsGL   = 'OpenGL'
  [Engines]::UniversalGL = 'OpenGL'
  [Engines]::WindowsXNA  = 'XNA'
}

function Get-Suffix
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [Engines]
    $Engine
  )
  return $Script:SuffixMap[$Engine]
}


function Get-PlatformName
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [Engines]
    $Engine
  )
  return $Script:PlatformNameMap[$Engine]
}
