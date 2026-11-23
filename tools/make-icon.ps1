# Draws the addon icon (a flyout of three spell icons above a gold macro button).
# Writes a 32-bit TGA for the game and, optionally, a PNG (README, project pages).
#
# Usage (Windows PowerShell, from the addon folder):
#   powershell -ExecutionPolicy Bypass -File tools\make-icon.ps1 -OutTga Media\Icon.tga -OutPng Media\Icon.png -Size 128
#   powershell -ExecutionPolicy Bypass -File tools\make-icon.ps1 -OutTga dist\big.tga -OutPng dist\FlyoutBars-icon-512.png -Size 512
# Size should be a power of two for the TGA (WoW requirement).
param([string]$OutTga, [string]$OutPng, [int]$Size = 128)
Add-Type -AssemblyName System.Drawing

# .NET resolves relative paths against the process folder, not PowerShell's location
function Resolve-OutPath([string]$p) {
    if (-not $p -or [IO.Path]::IsPathRooted($p)) { return $p }
    return Join-Path (Get-Location).Path $p
}
$OutTga = Resolve-OutPath $OutTga
$OutPng = Resolve-OutPath $OutPng

$S = 256 # design coordinates; rendered at 2x the output size (min 256), then downscaled for anti-aliasing
$R = [Math]::Max(256, 2 * $Size)
$big = New-Object System.Drawing.Bitmap $R, $R, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($big)
$g.ScaleTransform($R / $S, $R / $S)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)

function RoundRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}
function C($a, $r, $gg, $b) { [System.Drawing.Color]::FromArgb($a, $r, $gg, $b) }
function LinBrush($x, $y, $w, $h, $c1, $c2) {
    New-Object System.Drawing.Drawing2D.LinearGradientBrush ((New-Object System.Drawing.RectangleF $x, $y, $w, $h), $c1, $c2, 90.0)
}

# --- background: deep slate-blue with a soft glow behind the flyout
$bg = LinBrush 0 0 $S $S (C 255 34 52 74) (C 255 10 15 24)
$g.FillRectangle($bg, 0, 0, $S, $S)
$glowPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$glowPath.AddEllipse(28, 10, 200, 236)
$glow = New-Object System.Drawing.Drawing2D.PathGradientBrush $glowPath
$glow.CenterColor = C 110 70 150 210
$glow.SurroundColors = @(C 0 70 150 210)
$g.FillPath($glow, $glowPath)

# --- popup panel (the flyout)
$panel = RoundRect 82 18 92 140 14
$g.FillPath((New-Object System.Drawing.SolidBrush (C 170 0 0 0)), $panel)
$g.DrawPath((New-Object System.Drawing.Pen (C 200 120 190 230), 4), $panel)

# --- three spell icons inside the panel
$icons = @(
    @{ y = 28;  top = (C 255 255 196 70);  bot = (C 255 200 40 20) },   # fire
    @{ y = 72;  top = (C 255 140 235 110); bot = (C 255 20 120 40) },   # nature
    @{ y = 116; top = (C 255 200 140 255); bot = (C 255 80 40 190) }    # arcane
)
foreach ($ic in $icons) {
    $r = RoundRect 100 $ic.y 56 36 6
    $g.FillPath((LinBrush 100 $ic.y 56 36 $ic.top $ic.bot), $r)
    # sheen
    $sheen = RoundRect 104 ($ic.y + 3) 48 12 4
    $g.FillPath((New-Object System.Drawing.SolidBrush (C 70 255 255 255)), $sheen)
    $g.DrawPath((New-Object System.Drawing.Pen (C 255 0 0 0), 3), $r)
}

# --- connector chevron between panel and button
$chev = New-Object System.Drawing.Drawing2D.GraphicsPath
$chev.AddPolygon(@(
    (New-Object System.Drawing.PointF 128, 162),
    (New-Object System.Drawing.PointF 148, 180),
    (New-Object System.Drawing.PointF 108, 180)))
$g.FillPath((New-Object System.Drawing.SolidBrush (C 255 255 214 90)), $chev)

# --- the action button (gold frame, dark face, macro "lines")
$btn = RoundRect 88 184 80 56 10
$g.FillPath((LinBrush 88 184 80 56 (C 255 255 224 120) (C 255 170 110 20)), $btn)
$face = RoundRect 97 193 62 38 6
$g.FillPath((LinBrush 97 193 62 38 (C 255 40 44 58) (C 255 16 18 26)), $face)
$linePen = New-Object System.Drawing.Pen (C 255 255 214 90), 5
$linePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$linePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawLine($linePen, 107, 205, 149, 205)
$g.DrawLine($linePen, 107, 219, 135, 219)
$g.DrawPath((New-Object System.Drawing.Pen (C 255 60 35 0), 3), $btn)

# --- subtle inner frame so it reads as a WoW-style icon
$g.DrawRectangle((New-Object System.Drawing.Pen (C 150 0 0 0), 6), 3, 3, $S - 6, $S - 6)
$g.Dispose()

# --- downscale
$bmp = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g2 = [System.Drawing.Graphics]::FromImage($bmp)
$g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g2.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g2.DrawImage($big, 0, 0, $Size, $Size)
$g2.Dispose()

if ($OutPng) { $bmp.Save($OutPng, [System.Drawing.Imaging.ImageFormat]::Png) }

# --- write uncompressed 32-bit TGA, bottom-left origin, BGRA
$rect = New-Object System.Drawing.Rectangle 0, 0, $Size, $Size
$data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$stride = $data.Stride
$raw = New-Object byte[] ($stride * $Size)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $raw, 0, $raw.Length)
$bmp.UnlockBits($data)

$out = New-Object System.IO.MemoryStream
$hdr = New-Object byte[] 18
$hdr[2] = 2
$hdr[12] = $Size -band 0xFF; $hdr[13] = ($Size -shr 8) -band 0xFF
$hdr[14] = $Size -band 0xFF; $hdr[15] = ($Size -shr 8) -band 0xFF
$hdr[16] = 32
$hdr[17] = 8 # 8 alpha bits, bottom-left origin
$out.Write($hdr, 0, 18)
for ($y = $Size - 1; $y -ge 0; $y--) { $out.Write($raw, $y * $stride, $Size * 4) }
[System.IO.File]::WriteAllBytes($OutTga, $out.ToArray())
"wrote $OutTga ($($out.Length) bytes)"
