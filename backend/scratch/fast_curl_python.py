import subprocess
import os
import concurrent.futures

target_dir = r"C:\Users\Shadow\.gradle\wrapper\dists\gradle-8.3-bin\dxjbbhstwasg8cbags9q7cvli"
os.makedirs(target_dir, exist_ok=True)
target_zip = os.path.join(target_dir, "gradle-8.3-bin.zip")
target_ok = target_zip + ".ok"

url = "https://downloads.gradle-dn.com/distributions/gradle-8.3-bin.zip"
total_size = 130543701
num_chunks = 4
chunk_size = total_size // num_chunks

chunks = []
for i in range(num_chunks):
    start = i * chunk_size
    end = total_size - 1 if i == num_chunks - 1 else (i + 1) * chunk_size - 1
    part_file = os.path.join(target_dir, f"curl_part_{i}.tmp")
    chunks.append((i, start, end, part_file))

def download_chunk(item):
    idx, start, end, part_file = item
    print(f"Starting chunk {idx+1}/{num_chunks}: {start}-{end}...", flush=True)
    cmd = [
        "curl.exe", "-s", "-L",
        "-r", f"{start}-{end}",
        "-o", part_file,
        url
    ]
    res = subprocess.run(cmd)
    size_mb = os.path.getsize(part_file) / (1024*1024) if os.path.exists(part_file) else 0
    print(f"Chunk {idx+1}/{num_chunks} complete ({size_mb:.2f} MB)", flush=True)
    return part_file

print(f"Spawning {num_chunks} parallel curl workers...", flush=True)
with concurrent.futures.ThreadPoolExecutor(max_workers=num_chunks) as executor:
    part_files = list(executor.map(download_chunk, chunks))

print("Assembling final zip file...", flush=True)
with open(target_zip, "wb") as final_f:
    for pf in part_files:
        with open(pf, "rb") as f:
            final_f.write(f.read())
        os.remove(pf)

with open(target_ok, "w") as f:
    f.write("")

size_mb = os.path.getsize(target_zip) / (1024 * 1024)
print(f"FAST MULTI-THREAD CURL COMPLETE! Final size: {size_mb:.2f} MB", flush=True)
