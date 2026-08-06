import urllib.request
import os
import shutil

target_dir = r"C:\Users\Shadow\.gradle\wrapper\dists\gradle-8.3-bin\dxjbbhstwasg8cbags9q7cvli"
os.makedirs(target_dir, exist_ok=True)
target_zip = os.path.join(target_dir, "gradle-8.3-bin.zip")
target_ok = target_zip + ".ok"

url = "https://services.gradle.org/distributions/gradle-8.3-bin.zip"

print(f"Downloading {url} to {target_zip}...")

req = urllib.request.Request(
    url, 
    headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
)

with urllib.request.urlopen(req) as response, open(target_zip, 'wb') as out_file:
    shutil.copyfileobj(response, out_file)

# Touch .ok file to signal Gradle wrapper that download is complete
with open(target_ok, 'w') as f:
    f.write("")

size_mb = os.path.getsize(target_zip) / (1024 * 1024)
print(f"Download complete! File size: {size_mb:.2f} MB")
