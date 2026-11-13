$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$sourceDir = 'C:\Users\admin\Downloads\miniworld\miniworld'
$outRoot = Join-Path $root 'assets'
$effectOut = Join-Path $outRoot 'effects'
$uiOut = Join-Path $outRoot 'ui'
$manifestPath = Join-Path $outRoot 'assets_manifest.json'

foreach($d in @($outRoot,$effectOut,$uiOut)){ if(!(Test-Path $d)){ New-Item -ItemType Directory -Path $d -Force | Out-Null } }

function SafeName([string]$name){ return (($name -replace '\.png$','') -replace '[^a-zA-Z0-9_\.-]','_').ToLowerInvariant() }
function AlphaBounds($bmp){
  $minX=$bmp.Width; $minY=$bmp.Height; $maxX=-1; $maxY=-1; $count=0
  for($y=0;$y -lt $bmp.Height;$y++){
    for($x=0;$x -lt $bmp.Width;$x++){
      if($bmp.GetPixel($x,$y).A -gt 10){
        if($x -lt $minX){$minX=$x}; if($y -lt $minY){$minY=$y}; if($x -gt $maxX){$maxX=$x}; if($y -gt $maxY){$maxY=$y}; $count++
      }
    }
  }
  if($maxX -lt 0){ return $null }
  [pscustomobject]@{x=$minX;y=$minY;w=$maxX-$minX+1;h=$maxY-$minY+1;count=$count}
}
function SaveNormalized($srcBmp,[int]$x,[int]$y,[int]$w,[int]$h,[int]$cw,[int]$ch,[string]$path){
  $dst = New-Object System.Drawing.Bitmap($cw,$ch)
  $g = [System.Drawing.Graphics]::FromImage($dst)
  $g.Clear([System.Drawing.Color]::FromArgb(0,0,0,0))
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
  $scale = [Math]::Min(($cw-8)/[double]$w, ($ch-8)/[double]$h)
  if($scale -gt 1){ $scale = [Math]::Floor($scale) }
  if($scale -lt 0.1){ $scale = [Math]::Min($cw/[double]$w, $ch/[double]$h) }
  $dw=[Math]::Max(1,[int][Math]::Round($w*$scale)); $dh=[Math]::Max(1,[int][Math]::Round($h*$scale))
  $dx=[int][Math]::Floor(($cw-$dw)/2); $dy=[int][Math]::Floor(($ch-$dh)/2)
  $g.DrawImage($srcBmp,(New-Object System.Drawing.Rectangle($dx,$dy,$dw,$dh)),(New-Object System.Drawing.Rectangle($x,$y,$w,$h)),[System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose(); $dst.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $dst.Dispose()
  [pscustomobject]@{drawX=$dx;drawY=$dy;drawW=$dw;drawH=$dh;scale=$scale}
}
function GuessGrid($bmp){
  $w=$bmp.Width; $h=$bmp.Height; $c=@()
  foreach($n in 2..12){ if($w % $n -eq 0){ $fw=[int]($w/$n); if($fw -ge 16 -and $fw -le 1024){ $c += [pscustomobject]@{layout='horizontal';frames=$n;fw=$fw;fh=$h;score=[Math]::Abs($fw-$h)} } } }
  foreach($n in 2..12){ if($h % $n -eq 0){ $fh=[int]($h/$n); if($fh -ge 16 -and $fh -le 1024){ $c += [pscustomobject]@{layout='vertical';frames=$n;fw=$w;fh=$fh;score=[Math]::Abs($fh-$w)} } } }
  if(!$c){ return [pscustomobject]@{layout='single';frames=1;fw=$w;fh=$h;score=99999} }
  $c | Sort-Object score,frames | Select-Object -First 1
}
function BuildAnim($file,$kind,$canvasW,$canvasH,$fps){
  $bmp=[System.Drawing.Bitmap]::FromFile($file.FullName)
  $grid=GuessGrid $bmp
  $name=SafeName $file.Name
  $dir=Join-Path $(if($kind -eq 'ui'){$uiOut}else{$effectOut}) $name
  if(Test-Path $dir){ Remove-Item $dir -Recurse -Force }
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  $frames=@()
  for($i=0;$i -lt $grid.frames;$i++){
    $sx=0; $sy=0
    if($grid.layout -eq 'horizontal'){ $sx=$i*$grid.fw }
    elseif($grid.layout -eq 'vertical'){ $sy=$i*$grid.fh }
    $cell = New-Object System.Drawing.Bitmap($grid.fw,$grid.fh)
    $g=[System.Drawing.Graphics]::FromImage($cell)
    $g.DrawImage($bmp,(New-Object System.Drawing.Rectangle(0,0,$grid.fw,$grid.fh)),(New-Object System.Drawing.Rectangle($sx,$sy,$grid.fw,$grid.fh)),[System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    $b=AlphaBounds $cell
    if($null -eq $b){ $cell.Dispose(); continue }
    $out=Join-Path $dir ('frame_{0:d3}.png' -f $frames.Count)
    $norm=SaveNormalized $cell $b.x $b.y $b.w $b.h $canvasW $canvasH $out
    $cell.Dispose()
    $frames += [pscustomobject]@{file=('assets/'+$(if($kind -eq 'ui'){'ui'}else{'effects'})+'/'+$name+'/frame_{0:d3}.png' -f ($frames.Count));sourceBox=$b;draw=$norm}
  }
  $bmp.Dispose()
  [pscustomobject]@{id=$name;kind=$kind;source=$file.FullName;layout=$grid.layout;fps=$fps;canvas=@($canvasW,$canvasH);frameCount=$frames.Count;frames=$frames}
}

$select = @(
  @{file='ani_yufahuo.png';kind='effect';w=96;h=96;fps=14},
  @{file='ani_suipian3.png';kind='effect';w=96;h=96;fps=12},
  @{file='actct94_ani_btn_guang.png';kind='ui';w=96;h=48;fps=10},
  @{file='0730_ani_shouye_men.png';kind='ui';w=160;h=80;fps=8},
  @{file='act_shanguang_ani.png';kind='effect';w=96;h=96;fps=14},
  @{file='actct97_ani_qiuqiu.png';kind='effect';w=96;h=96;fps=12}
)
$assets=@()
foreach($s in $select){
  $f=Get-ChildItem $sourceDir -Filter $s.file -File -ErrorAction SilentlyContinue | Select-Object -First 1
  if($f){ $assets += BuildAnim $f $s.kind $s.w $s.h $s.fps }
}
$manifest=[pscustomobject]@{version='0.1.0';builtAt=(Get-Date).ToString('s');style='pipeline/style_spec.json';assets=$assets}
$manifest | ConvertTo-Json -Depth 20 | Set-Content $manifestPath -Encoding UTF8
"assets built: $($assets.Count)"
$assets | Select-Object id,kind,layout,frameCount,fps,@{n='canvas';e={$_.canvas -join 'x'}} | Format-Table -AutoSize
