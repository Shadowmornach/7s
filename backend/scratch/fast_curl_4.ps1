$targetDir = "C:\Users\Shadow\.gradle\wrapper\dists\gradle-8.3-bin\dxjbbhstwasg8cbags9q7cvli"
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

$zipPath = Join-Path $targetDir "gradle-8.3-bin.zip"
$okPath = Join-Path $targetDir "gradle-8.3-bin.zip.ok"
$url = "https://downloads.gradle-dn.com/distributions/gradle-8.3-bin.zip"
$totalBytes = 130543701
$numChunks = 4
$chunkSize = [math]::Floor($totalBytes / $numChunks)

$procs = @()
for ($i = 0; $i -lt $numChunks; $i++) {
    $start = $i * $chunkSize
    if ($i -eq ($numChunks - 1)) {
        $end = $totalBytes - 1
    } else {
        $end = (($i + 1) * $chunkSize) - 1
    }
    $partFile = Join-Path $targetDir "part_$i.tmp"
    $rangeHeader = "$start-$end"
    
    $p = Start-Process -FilePath "curl.exe" -ArgumentList "-s", "-L", "-r", "$rangeHeader", "-o", "`"$partFile`"", "`"$url`"" -NoNewWindow -PassThru
    $procs += $p
    Write-Host "Spawned Process $($p.Id) for range $rangeHeader"
}

Write-Host "Waiting for 4 parallel curl processes to finish..."
$procs | ForEach-Object { $_.WaitForExit() }

Write-Host "Assembling final zip file..."
$outStream = [System.IO.File]::Create($zipPath)
for ($i = 0; $i -lt $numChunks; $i++) {
    $partFile = Join-Path $targetDir "part_$i.tmp"
    $bytes = [System.IO.File]::ReadAllBytes($partFile)
    $outStream.Write($bytes, 0, $bytes.Length)
    Remove-Item -Force $partFile
}
$outStream.Close()

Set-Content -Path $okPath -Value ""
$finalSize = (Get-Item $zipPath).Length / 1MB
Write-Host "FAST 4-THREAD CURL DOWNLOAD COMPLETED! Final size: $finalSize MB"
