import urllib.request
import ssl
import os
import concurrent.futures

target_dir = r"C:\Users\Shadow\.gradle\wrapper\dists\gradle-8.3-bin\dxjbbhstwasg8cbags9q7cvli"
os.makedirs(target_dir, exist_ok=True)
target_zip = os.path.join(target_dir, "gradle-8.3-bin.zip")
target_ok = target_zip + ".ok"

url = "https://downloads.gradle-dn.com/distributions/gradle-8.3-bin.zip"
num_chunks = 8

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

def get_content_length(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
    with urllib.request.urlopen(req, context=ctx, timeout=15) as resp:
        return int(resp.getheader('content-length'))

total_size = get_content_length(url)
print(f"Total file size: {total_size / (1024*1024):.2f} MB. Spawning {num_chunks} parallel threads...")

chunk_size = total_size // num_chunks
ranges = []
for i in range(num_chunks):
    start = i * chunk_size
    end = total_size - 1 if i == num_chunks - 1 else (i + 1) * chunk_size - 1
    ranges.append((i, start, end))

def download_range(arg):
    idx, start, end = arg
    req = urllib.request.Request(
        url, 
        headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
            'Range': f'bytes={start}-{end}'
        }
    )
    temp_file = target_zip + f".part{idx}"
    with urllib.request.urlopen(req, context=ctx, timeout=60) as resp, open(temp_file, 'wb') as f:
        f.write(resp.read())
    print(f"  -> Thread {idx+1}/{num_chunks} finished ({start}-{end})", flush=True)
    return temp_file

with concurrent.futures.ThreadPoolExecutor(max_workers=num_chunks) as executor:
    part_files = list(executor.map(download_range, ranges))

print("Combining parallel chunks into final zip...")
with open(target_zip, 'wb') as final_f:
    for part in part_files:
        with open(part, 'rb') as pf:
            final_f.write(pf.read())
        os.remove(part)

with open(target_ok, 'w') as f:
    f.write("")

size_mb = os.path.getsize(target_zip) / (1024 * 1024)
print(f"FAST PARALLEL DOWNLOAD COMPLETE! File size: {size_mb:.2f} MB", flush=True)
