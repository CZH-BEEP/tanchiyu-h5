$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$srcDir = 'C:\Users\admin\Downloads\miniworld\miniworld'
$outRoot = Join-Path (Get-Location) 'pocket\effects'
if (!(Test-Path $outRoot)) { New-Item -ItemType Directory -Path $outRoot -Force | Out-Null }

function Save-Crop($bmp, [int]$x, [int]$y, [int]$w, [int]$h, [string]$path) {
  $dst = New-Object System.Drawing.Bitmap($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($dst)
  $g.Clear([System.Drawing.Color]::FromArgb(0,0,0,0))
  $g.DrawImage($bmp, (New-Object System.Drawing.Rectangle(0,0,$w,$h)), (New-Object System.Drawing.Rectangle($x,$y,$w,$h)), [System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose()
  $dst.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $dst.Dispose()
}

function AlphaBounds($bmp) {
  $minX=$bmp.Width; $minY=$bmp.Height; $maxX=-1; $maxY=-1; $count=0
  for($y=0;$y -lt $bmp.Height;$y++){
    for($x=0;$x -lt $bmp.Width;$x++){
      if($bmp.GetPixel($x,$y).A -gt 12){
        if($x -lt $minX){$minX=$x}; if($y -lt $minY){$minY=$y}; if($x -gt $maxX){$maxX=$x}; if($y -gt $maxY){$maxY=$y}; $count++
      }
    }
  }
  if($maxX -lt 0){ return $null }
  [pscustomobject]@{x=$minX;y=$minY;w=$maxX-$minX+1;h=$maxY-$minY+1;count=$count}
}

function Split-Equal($bmp, $baseDir, $stem) {
  $w=$bmp.Width; $h=$bmp.Height
  $candidates=@()
  foreach($n in 2..16){ if($w % $n -eq 0){ $fw=[int]($w/$n); if($fw -ge 12 -and $fw -le 512){ $candidates += [pscustomobject]@{dir='horizontal';n=$n;fw=$fw;fh=$h;score=[math]::Abs($fw-$h)} } } }
  foreach($n in 2..16){ if($h % $n -eq 0){ $fh=[int]($h/$n); if($fh -ge 12 -and $fh -le 512){ $candidates += [pscustomobject]@{dir='vertical';n=$n;fw=$w;fh=$fh;score=[math]::Abs($fh-$w)} } } }
  if(!$candidates){
    $b=AlphaBounds $bmp
    if($null -eq $b){ return [pscustomobject]@{frames=0;dir='empty';fw=0;fh=0} }
    Save-Crop $bmp $b.x $b.y $b.w $b.h (Join-Path $baseDir 'frame_000.png')
    return [pscustomobject]@{frames=1;dir='single';fw=$b.w;fh=$b.h}
  }
  $best=$candidates | Sort-Object score,n | Select-Object -First 1
  for($i=0;$i -lt $best.n;$i++){
    if($best.dir -eq 'horizontal'){ Save-Crop $bmp ($i*$best.fw) 0 $best.fw $best.fh (Join-Path $baseDir ('frame_{0:d3}.png' -f $i)) }
    else { Save-Crop $bmp 0 ($i*$best.fh) $best.fw $best.fh (Join-Path $baseDir ('frame_{0:d3}.png' -f $i)) }
  }
  [pscustomobject]@{frames=$best.n;dir=$best.dir;fw=$best.fw;fh=$best.fh}
}

function Split-ComponentsOrEqual($file) {
  $stem=[IO.Path]::GetFileNameWithoutExtension($file.Name)
  $safe=($stem -replace '[^a-zA-Z0-9_\.-]','_')
  $dir=Join-Path $outRoot $safe
  if(Test-Path $dir){ Remove-Item $dir -Recurse -Force }
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  $bmp=[System.Drawing.Bitmap]::FromFile($file.FullName)
  $res=Split-Equal $bmp $dir $safe
  $bmp.Dispose()
  [pscustomobject]@{source=$file.FullName;name=$safe;frameDir=('effects/'+$safe);frames=$res.frames;frameWidth=$res.fw;frameHeight=$res.fh;layout=$res.dir;suggestedFps=12}
}

$files = Get-ChildItem $srcDir -Filter '*ani*.png' | Where-Object { $_.Length -gt 500 -and $_.Length -lt 2MB } | Sort-Object Length -Descending | Select-Object -First 80
$meta=@()
foreach($f in $files){ try { $meta += Split-ComponentsOrEqual $f } catch { Write-Warning "skip $($f.Name): $($_.Exception.Message)" } }
$json = $meta | ConvertTo-Json -Depth 5
Set-Content -Path (Join-Path $outRoot 'frames.json') -Value $json -Encoding UTF8
"split files: $($meta.Count)"
$meta | Select-Object -First 20 name,frames,frameWidth,frameHeight,layout,suggestedFps | Format-Table -AutoSize
