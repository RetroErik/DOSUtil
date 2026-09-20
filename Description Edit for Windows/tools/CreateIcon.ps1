[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $SourcePng,
    [Parameter(Mandatory)][string] $DestinationIco
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.Drawing

$sizes = @(16, 20, 24, 32, 40, 48, 64, 128, 256)
$source = [Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $SourcePng))
$images = [Collections.Generic.List[byte[]]]::new()

try {
    foreach ($size in $sizes) {
        $bitmap = [Drawing.Bitmap]::new($size, $size, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $graphics = [Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear([Drawing.Color]::Transparent)
                $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
                $graphics.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphics.DrawImage($source, 0, 0, $size, $size)
            } finally {
                $graphics.Dispose()
            }

            $stream = [IO.MemoryStream]::new()
            try {
                $bitmap.Save($stream, [Drawing.Imaging.ImageFormat]::Png)
                $images.Add($stream.ToArray())
            } finally {
                $stream.Dispose()
            }
        } finally {
            $bitmap.Dispose()
        }
    }
} finally {
    $source.Dispose()
}

$destination = [IO.Path]::GetFullPath($DestinationIco)
$directory = [IO.Path]::GetDirectoryName($destination)
[IO.Directory]::CreateDirectory($directory) | Out-Null
$output = [IO.File]::Create($destination)
$writer = [IO.BinaryWriter]::new($output)
try {
    $writer.Write([uint16] 0)
    $writer.Write([uint16] 1)
    $writer.Write([uint16] $sizes.Count)
    $offset = 6 + (16 * $sizes.Count)

    for ($index = 0; $index -lt $sizes.Count; $index++) {
        $size = $sizes[$index]
        $data = $images[$index]
        $writer.Write([byte] $(if ($size -eq 256) { 0 } else { $size }))
        $writer.Write([byte] $(if ($size -eq 256) { 0 } else { $size }))
        $writer.Write([byte] 0)
        $writer.Write([byte] 0)
        $writer.Write([uint16] 1)
        $writer.Write([uint16] 32)
        $writer.Write([uint32] $data.Length)
        $writer.Write([uint32] $offset)
        $offset += $data.Length
    }

    foreach ($data in $images) {
        $writer.Write($data)
    }
} finally {
    $writer.Dispose()
    $output.Dispose()
}

Write-Host "Created '$destination' with $($sizes.Count) icon sizes."
