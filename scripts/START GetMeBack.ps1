$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

function Start-Port([int]$port) {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://127.0.0.1:$port/")
    $listener.Start()
    return $listener
}

$port = 8765
try {
    $listener = Start-Port $port
} catch {
    $port = 8766
    $listener = Start-Port $port
}

$url = "http://127.0.0.1:$port/GetMeBack.html"
Start-Process $url
Write-Host "GetMeBack is running at $url"
Write-Host "Leave this window open. Close it to quit."

$mime = @{
    '.html' = 'text/html'
    '.htm'  = 'text/html'
    '.js'   = 'application/javascript'
    '.mjs'  = 'application/javascript'
    '.json' = 'application/json'
    '.css'  = 'text/css'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
    '.jpeg' = 'image/jpeg'
    '.gif'  = 'image/gif'
    '.svg'  = 'image/svg+xml'
    '.webp' = 'image/webp'
    '.wasm' = 'application/wasm'
    '.woff' = 'font/woff'
    '.woff2'= 'font/woff2'
    '.ttf'  = 'font/ttf'
    '.otf'  = 'font/otf'
    '.wav'  = 'audio/wav'
    '.mp3'  = 'audio/mpeg'
    '.ico'  = 'image/x-icon'
    '.map'  = 'application/json'
}

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        $req = $ctx.Request
        $res = $ctx.Response
        $path = [Uri]::UnescapeDataString($req.Url.LocalPath)
        if ($path -eq '/' -or $path -eq '') { $path = '/GetMeBack.html' }
        $rel = $path.TrimStart('/').Replace('/', [IO.Path]::DirectorySeparatorChar)
        $file = Join-Path $root $rel
        $fullRoot = [IO.Path]::GetFullPath($root)
        $fullFile = [IO.Path]::GetFullPath($file)
        if (-not $fullFile.StartsWith($fullRoot)) {
            $res.StatusCode = 403
            $res.Close()
            continue
        }
        if (-not (Test-Path -LiteralPath $fullFile -PathType Leaf)) {
            $res.StatusCode = 404
            $bytes = [Text.Encoding]::UTF8.GetBytes('Not found')
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
            $res.Close()
            continue
        }
        $ext = [IO.Path]::GetExtension($fullFile).ToLowerInvariant()
        $res.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
        $bytes = [IO.File]::ReadAllBytes($fullFile)
        $res.ContentLength64 = $bytes.Length
        $res.Headers.Add('Cache-Control', 'no-cache')
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
        $res.Close()
    }
} finally {
    if ($listener -and $listener.IsListening) { $listener.Stop() }
}
