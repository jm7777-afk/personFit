Add-Type -AssemblyName System.Drawing

$srcPath = (Resolve-Path "WhatsApp Image 2026-11-16 at 7.17.52 PM.jpeg").Path
$srcImg = [System.Drawing.Image]::FromFile($srcPath)

$targets = @{
    "mi_personfit_mobile\android\app\src\main\res\mipmap-mdpi\ic_launcher.png" = 48
    "mi_personfit_mobile\android\app\src\main\res\mipmap-hdpi\ic_launcher.png" = 72
    "mi_personfit_mobile\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png" = 96
    "mi_personfit_mobile\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png" = 144
    "mi_personfit_mobile\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png" = 192
}

foreach ($dest in $targets.Keys) {
    $size = $targets[$dest]
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($srcImg, 0, 0, $size, $size)
    $g.Dispose()
    
    $fullDest = [System.IO.Path]::GetFullPath($dest)
    $dir = [System.IO.Path]::GetDirectoryName($fullDest)
    if (-not [System.IO.Directory]::Exists($dir)) {
        [System.IO.Directory]::CreateDirectory($dir) | Out-Null
    }
    
    $bmp.Save($fullDest, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Generated $dest (${size}x${size})"
}

$srcImg.Dispose()
Write-Host "ALL ICONS GENERATED SUCCESSFULLY!"
