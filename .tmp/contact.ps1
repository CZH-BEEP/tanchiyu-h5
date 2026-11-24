$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$outDir = Join-Path (Get-Location) 'pocket\art'
$shotDir = Join-Path (Get-Location) '.tmp'
if (!(Test-Path $shotDir)) { New-Item -ItemType Directory -Path $shotDir -Force | Out-Null }

$cell = 100
$cols = 12
foreach ($prefix in @('a', 'b', 'c')) {
  $files = Get-ChildItem $outDir -Filter "$prefix`_*.png" | Sort-Object Name
  $rows = [Math]::Ceiling($files.Count / $cols)
  $bmp = New-Object System.Drawing.Bitmap(($cell * $cols), ($cell * $rows))
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $i = 0
  foreach ($f in $files) {
    $c = $i % $cols
    $r = [int][Math]::Floor($i / $cols)
    $img = [System.Drawing.Image]::FromFile($f.FullName)
    $scale = [Math]::Min(($cell - 22) / $img.Width, ($cell - 22) / $img.Height)
    $w = [int]($img.Width * $scale)
    $h = [int]($img.Height * $scale)
    $g.DrawImage($img, (New-Object System.Drawing.Rectangle(($c * $cell + ($cell - $w) / 2), ($r * $cell + 16 + ($cell - 16 - $h) / 2), $w, $h)))
    $img.Dispose()
    $label = $f.BaseName.Substring(2)
    $font = New-Object System.Drawing.Font('Consolas', 10, [System.Drawing.FontStyle]::Bold)
    $g.DrawString($label, $font, [System.Drawing.Brushes]::Black, ($c * $cell + 5), ($r * $cell + 2))
    $font.Dispose()
    $i++
  }
  $g.Dispose()
  $bmp.Save((Join-Path $shotDir "contact_$prefix.png"), [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  "saved $prefix"
}
