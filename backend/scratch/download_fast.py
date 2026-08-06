import urllib.request
import os

target_dir = r"C:\Users\Shadow\.gradle\wrapper\dists\gradle-8.3-bin\dxjbbhstwasg8cbags9q7cvli"
os.makedirs(target_dir, exist_ok=True)
target_zip = os.path.join(target_dir, "gradle-8.3-bin.zip")
target_ok = target_zip + ".ok"

url = "https://downloads.gradle-dn.com/distributions/gradle-8.3-bin.zip"

print(f"Downloading directly from CDN: {url}...")

req = urllib.request.Request(
    url, 
    headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
)

with urllib.request.urlopen(req, timeout=30) as response, open(target_zip, 'wb') as out_file:
    total_length = response.getheader('content-length')
    if total_length:
        total_length = int(total_length)
    downloaded = 0
    chunk_size = 1024 * 512 # 512 KB chunks
    while True:
        chunk = response.read(chunk_size)
        if not chunk:
            break
        downloaded += len(chunk)
        out_file.write(chunk)
        if total_length:
            pct = (downloaded / total_length) * 100
            print(f"Downloaded {downloaded / (1024*1024):.2f} MB / {total_length / (1024*1024):.2f} MB ({pct:.1f}%)", flush=True)
        else:
            print(f"Downloaded {downloaded / (1024*1024):.2f} MB", flush=True)

with open(target_ok, 'w') as f:
    f.write("")

print("GRADLE DOWNLOAD FINISHED SUCCESSFULLY!", flush=True)
