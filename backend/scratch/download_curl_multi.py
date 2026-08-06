import subprocess
import os

target_dir = r"C:\Users\Shadow\.gradle\wrapper\dists\gradle-8.3-bin\dxjbbhstwasg8cbags9q7cvli"
os.makedirs(target_dir, exist_ok=True)
target_zip = os.path.join(target_dir, "gradle-8.3-bin.zip")
target_ok = target_zip + ".ok"

url = "https://downloads.gradle-dn.com/distributions/gradle-8.3-bin.zip"
total_size = 130543701
num_chunks = 4
chunk_size = total_size // num_chunks

processes = []
part_files = []

print(f"Spawning {num_chunks} parallel curl processes to download {total_size / (1024*1024):.2f} MB...")

for i in range(num_chunks):
    start = i * chunk_size
    end = total_size - 1 if i == num_chunks - 1 else (i + 1) * chunk_size - 1
    part_file = os.path.join(target_dir, f"curl_part_{i}.tmp")
    part_files.append(part_file)
    
    cmd = [
        "curl.exe", "-s", "-L",
        "-r", f"{start}-{end}",
        "-o", part_file,
        url
    ]
    p = subprocess.Popen(cmd)
    processes.append(p)
    print(f"  -> Spawned Process {i+1}/{num_chunks} for range {start}-{end}")

print("Waiting for all curl processes to finish...")
for p in processes:
    p.wait()

print("Assembling final zip file...")
with open(target_zip, "wb") as final_f:
    for pf in part_files:
        with open(pf, "rb") as f:
            final_f.write(f.read())
        os.remove(pf)

with open(target_ok, "w") as f:
    f.write("")

size_mb = os.path.getsize(target_zip) / (1024 * 1024)
print(f"CURL MULTI-THREAD DOWNLOAD FINISHED SUCCESSFULLY! Final file size: {size_mb:.2f} MB")
