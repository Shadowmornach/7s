$targetDir = "C:\Users\Shadow\.gradle\wrapper\dists\gradle-8.3-bin\dxjbbhstwasg8cbags9q7cvli"
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

$zipPath = Join-Path $targetDir "gradle-8.3-bin.zip"
$okPath = Join-Path $targetDir "gradle-8.3-bin.zip.ok"
$url = "https://downloads.gradle-dn.com/distributions/gradle-8.3-bin.zip"
$totalBytes = 130543701

Write-Host "Total size: $($totalBytes / 1MB) MB. Spawning 10 parallel curl jobs..."

$numChunks = 10
$chunkSize = [math]::Floor($totalBytes / $numChunks)
$jobs = @()

for ($i = 0; $i -lt $numChunks; $i++) {
    $start = $i * $chunkSize
    if ($i -eq ($numChunks - 1)) {
        $end = $totalBytes - 1
    } else {
        $end = (($i + 1) * $chunkSize) - 1
    }
    $partFile = Join-Path $targetDir "part_$i.tmp"
    $rangeHeader = "$start-$end"
    
    $job = Start-Job -ScriptBlock {
        param($u, $r, $f)
        curl.exe -s -L -r $r -o $f $u
    } -ArgumentList $url, $rangeHeader, $partFile
    
    $jobs += $job
}

Write-Host "Waiting for 10 parallel curl download jobs to complete..."
$jobs | Wait-Job | Out-Null
$jobs | Remove-Job

Write-Host "Concatenating 10 part files into final gradle-8.3-bin.zip..."
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
Write-Host "PARALLEL CURL DOWNLOAD COMPLETED SUCCESSFULLY! Final size: $finalSize MB"
