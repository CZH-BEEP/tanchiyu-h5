$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$src = @(
  @{ id='a'; path='c:\Users\admin\.trae-cn\attachments\f6a59b0c-5bf7-42ea-a6ac-65ae6b6e5804_d7bd3438-1bd6-447d-999f-4a976f55c2f9_image.png'; rows=5 },
  @{ id='b'; path='c:\Users\admin\.trae-cn\attachments\8e4c6928-c450-4051-909b-3976ebad8860_fdb8c949-52fc-4fac-a464-1946cd3c3431_image.png'; rows=6 },
  @{ id='c'; path='c:\Users\admin\.trae-cn\attachments\9aef4ae7-b9c7-4e69-abc1-894f5eceb80d_a4865fd5-82f1-4016-858e-9941b9c8f6e4_image.png'; rows=6 }
)

$outDir = Join-Path (Get-Location) 'pocket\art'
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$cols = 12

foreach ($s in $src) {
  $bmp = [System.Drawing.Bitmap]::FromFile($s.path)
  $cw = $bmp.Width / $cols
  $ch = $bmp.Height / $s.rows
  for ($r = 0; $r -lt $s.rows; $r++) {
    for ($c = 0; $c -lt $cols; $c++) {
      $x0 = [int][Math]::Round($c * $cw) + 3
      $y0 = [int][Math]::Round($r * $ch) + 3
      $x1 = [int][Math]::Round(($c + 1) * $cw) - 3
      $y1 = [int][Math]::Round(($r + 1) * $ch) - 26
      if ($y1 -le $y0) { continue }
      $w = $x1 - $x0
      $h = $y1 - $y0
      $cell = New-Object System.Drawing.Bitmap($w, $h)
      $g = [System.Drawing.Graphics]::FromImage($cell)
      $g.DrawImage($bmp, (New-Object System.Drawing.Rectangle(0, 0, $w, $h)), (New-Object System.Drawing.Rectangle($x0, $y0, $w, $h)), [System.Drawing.GraphicsUnit]::Pixel)
      $g.Dispose()
      $seed = $cell.GetPixel(2, 2)
      $visited = New-Object 'bool[,]' $w, $h
      $queue = New-Object 'System.Collections.Generic.Queue[int]'
      $queue.Enqueue(0)
      $visited[0, 0] = $true
      $tol = 26
      while ($queue.Count -gt 0) {
        $idx = $queue.Dequeue()
        $px = $idx % $w
        $py = [int][Math]::Floor($idx / $w)
        $col = $cell.GetPixel($px, $py)
        if ([Math]::Abs($col.R - $seed.R) -gt $tol -or [Math]::Abs($col.G - $seed.G) -gt $tol -or [Math]::Abs($col.B - $seed.B) -gt $tol) { continue }
        $cell.SetPixel($px, $py, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        for ($k = 0; $k -lt 4; $k++) {
          $nx = $px + @(1, -1, 0, 0)[$k]
          $ny = $py + @(0, 0, 1, -1)[$k]
          if ($nx -lt 0 -or $ny -lt 0 -or $nx -ge $w -or $ny -ge $h) { continue }
          if ($visited[$nx, $ny]) { continue }
          $visited[$nx, $ny] = $true
          $queue.Enqueue($ny * $w + $nx)
        }
      }
      $minX = $w; $minY = $h; $maxX = -1; $maxY = -1
      for ($py = 0; $py -lt $h; $py++) {
        for ($px = 0; $px -lt $w; $px++) {
          if ($cell.GetPixel($px, $py).A -gt 16) {
            if ($px -lt $minX) { $minX = $px }
            if ($py -lt $minY) { $minY = $py }
            if ($px -gt $maxX) { $maxX = $px }
            if ($py -gt $maxY) { $maxY = $py }
          }
        }
      }
      if ($maxX -lt 0) { $cell.Dispose(); continue }
      $tw = $maxX - $minX + 1
      $th = $maxY - $minY + 1
      $pad = 4
      $final = New-Object System.Drawing.Bitmap(($tw + $pad * 2), ($th + $pad * 2))
      $g2 = [System.Drawing.Graphics]::FromImage($final)
      $g2.DrawImage($cell, (New-Object System.Drawing.Rectangle($pad, $pad, $tw, $th)), (New-Object System.Drawing.Rectangle($minX, $minY, $tw, $th)), [System.Drawing.GraphicsUnit]::Pixel)
      $g2.Dispose()
      $final.Save((Join-Path $outDir ("$($s.id)_{0}_{1}.png" -f $r, $c)), [System.Drawing.Imaging.ImageFormat]::Png)
      $final.Dispose()
      $cell.Dispose()
    }
  }
  $bmp.Dispose()
  "done $($s.id)"
}
(Get-ChildItem $outDir -Filter *.png).Count
