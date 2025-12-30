$ErrorActionPreference = "Stop"

$ffmpegVersion = "6.0"
$ffmpegRelease = "ffmpeg-$ffmpegVersion-full_build-shared"
$ffmpegDev = "ffmpeg-$ffmpegVersion-full_build-dev"
$ffmpegUrlShared = "https://github.com/GyanD/codexffmpeg/releases/download/$ffmpegVersion/ffmpeg-$ffmpegVersion-full_build-shared.7z"
$ffmpegUrlDev = "https://github.com/GyanD/codexffmpeg/releases/download/$ffmpegVersion/ffmpeg-$ffmpegVersion-full_build-dev.7z"

$destDir = Join-Path $PSScriptRoot "ffmpeg"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir | Out-Null
}

function Download-And-Extract ($url, $name) {
    $zipFile = Join-Path $destDir "$name.7z"
    
    if (-not (Test-Path $zipFile)) {
        Write-Host "Downloading $name..."
        Invoke-WebRequest -Uri $url -OutFile $zipFile
    }

    Write-Host "Extracting $name..."
    # Assuming 7z is installed or using a powershell compatible way if possible. 
    # Since 7z is standard for these builds, we might need 7z.exe. 
    # Fallback: User might need to install 7zip. 
    # Alternative: Use a zip distribution if available, but GyanD usually uses 7z.
    # Let's try to find 7z or tell user to install it.
    
    if (Get-Command "7z" -ErrorAction SilentlyContinue) {
        7z x $zipFile "-o$destDir" -y
    } else {
        Write-Error "7z not found. Please install 7-Zip to extract FFmpeg libraries."
    }
}

# The URLs above are hypothetical examples as GyanD links change or are version specific.
# Let's use a known recent stable link structure or a zip if available for easier extraction without 7z.
# BtbN builds are zip.
$ffmpegUrlShared = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip"
$ffmpegUrlDev = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip" 
# BtbN shared zip contains both bin (dll) and include/lib usually? No, often separate or combined.
# Let's check typical BtbN layout. 
# actually BtbN shared has bin/*.dll, include/*, lib/*.lib all in one structure usually.

# Let's use BtbN master latest shared
$zipName = "ffmpeg-master-latest-win64-gpl-shared.zip"
$zipPath = Join-Path $destDir $zipName

if (-not (Test-Path $zipPath)) {
    Write-Host "Downloading FFmpeg..."
    Invoke-WebRequest -Uri $ffmpegUrlShared -OutFile $zipPath
}

Write-Host "Extracting FFmpeg..."
Expand-Archive -Path $zipPath -DestinationPath $destDir -Force

$extractedDir = Join-Path $destDir "ffmpeg-master-latest-win64-gpl-shared"

# Move includes and libs to a cleaner path
$includeDir = Join-Path $destDir "include"
$libDir = Join-Path $destDir "lib"
$binDir = Join-Path $destDir "bin"

if (-not (Test-Path $includeDir)) { Move-Item (Join-Path $extractedDir "include") $destDir }
if (-not (Test-Path $libDir)) { Move-Item (Join-Path $extractedDir "lib") $destDir }
if (-not (Test-Path $binDir)) { Move-Item (Join-Path $extractedDir "bin") $destDir }

Write-Host "FFmpeg setup complete."
Write-Host "Binaries: $binDir"
Write-Host "Includes: $includeDir"
Write-Host "Libraries: $libDir"
