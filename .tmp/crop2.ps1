$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$code = @'
using System;
using System.Drawing;
using System.Collections.Generic;

public class Cropper {
  public static int Run(string path, string prefix, int rows, int cols, string outDir) {
    int made = 0;
    using (var bmp = new Bitmap(path)) {
      double cw = (double)bmp.Width / cols;
      double ch = (double)bmp.Height / rows;
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          int x0 = (int)Math.Round(c * cw) + 3;
          int y0 = (int)Math.Round(r * ch) + 3;
          int x1 = (int)Math.Round((c + 1) * cw) - 3;
          int y1 = (int)Math.Round((r + 1) * ch) - 27;
          int w = x1 - x0, h = y1 - y0;
          if (w <= 6 || h <= 6) continue;

          Bitmap cell = new Bitmap(w, h);
          using (var g = Graphics.FromImage(cell)) {
            g.DrawImage(bmp, new Rectangle(0, 0, w, h), new Rectangle(x0, y0, w, h), GraphicsUnit.Pixel);
          }

          Color seed = cell.GetPixel(2, 2);
          bool[,] vis = new bool[w, h];
          Queue<int> q = new Queue<int>();
          q.Enqueue(0); vis[0, 0] = true;
          int tol = 30;
          while (q.Count > 0) {
            int idx = q.Dequeue();
            int px = idx % w, py = idx / w;
            Color col = cell.GetPixel(px, py);
            if (Math.Abs(col.R - seed.R) > tol || Math.Abs(col.G - seed.G) > tol || Math.Abs(col.B - seed.B) > tol) continue;
            cell.SetPixel(px, py, Color.FromArgb(0, 0, 0, 0));
            int[] dx = { 1, -1, 0, 0 };
            int[] dy = { 0, 0, 1, -1 };
            for (int k = 0; k < 4; k++) {
              int nx = px + dx[k], ny = py + dy[k];
              if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
              if (vis[nx, ny]) continue;
              vis[nx, ny] = true;
              q.Enqueue(ny * w + nx);
            }
          }

          int minX = w, minY = h, maxX = -1, maxY = -1;
          for (int py = 0; py < h; py++)
            for (int px = 0; px < w; px++)
              if (cell.GetPixel(px, py).A > 16) {
                if (px < minX) minX = px;
                if (py < minY) minY = py;
                if (px > maxX) maxX = px;
                if (py > maxY) maxY = py;
              }
          if (maxX < 0) { cell.Dispose(); continue; }

          int tw = maxX - minX + 1, th = maxY - minY + 1, pad = 3;
          Bitmap fin = new Bitmap(tw + pad * 2, th + pad * 2);
          using (var g2 = Graphics.FromImage(fin)) {
            g2.DrawImage(cell, new Rectangle(pad, pad, tw, th), new Rectangle(minX, minY, tw, th), GraphicsUnit.Pixel);
          }
          fin.Save(System.IO.Path.Combine(outDir, prefix + "_" + r + "_" + c + ".png"), System.Drawing.Imaging.ImageFormat.Png);
          fin.Dispose();
          cell.Dispose();
          made++;
        }
      }
    }
    return made;
  }
}
'@
Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing

$outDir = Join-Path (Get-Location) 'pocket\art'
if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

$sheetA = 'c:\Users\admin\.trae-cn\attachments\f6a59b0c-5bf7-42ea-a6ac-65ae6b6e5804_d7bd3438-1bd6-447d-999f-4a976f55c2f9_image.png'
$sheetB = 'c:\Users\admin\.trae-cn\attachments\8e4c6928-c450-4051-909b-3976ebad8860_fdb8c949-52fc-4fac-a464-1946cd3c3431_image.png'
$sheetC = 'c:\Users\admin\.trae-cn\attachments\9aef4ae7-b9c7-4e69-abc1-894f5eceb80d_a4865fd5-82f1-4016-858e-9941b9c8f6e4_image.png'

"a: " + [Cropper]::Run($sheetA, 'a', 5, 12, $outDir)
"b: " + [Cropper]::Run($sheetB, 'b', 6, 12, $outDir)
"c: " + [Cropper]::Run($sheetC, 'c', 6, 12, $outDir)
(Get-ChildItem $outDir -Filter *.png).Count
