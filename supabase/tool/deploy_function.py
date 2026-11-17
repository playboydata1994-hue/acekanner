"""Deploy a Supabase Edge Function through the Management API (multipart upload of its source).

Usage (token injected by the session proxy or SUPABASE_ACCESS_TOKEN):
  python3 supabase/tool/deploy_function.py <project-ref> supabase/functions license
"""
import json, os, sys, uuid, urllib.request

ref, functions_dir, slug = sys.argv[1], sys.argv[2], sys.argv[3]
files = []
for sub in (slug, "_shared"):
    for name in sorted(os.listdir(os.path.join(functions_dir, sub))):
        if name.endswith(".ts"):
            files.append((f"{sub}/{name}", open(os.path.join(functions_dir, sub, name), "rb").read()))
meta = {"name": slug, "entrypoint_path": f"{slug}/index.ts", "verify_jwt": False}
boundary = uuid.uuid4().hex
parts = [f"--{boundary}\r\nContent-Disposition: form-data; name=\"metadata\"\r\nContent-Type: application/json\r\n\r\n{json.dumps(meta)}\r\n".encode()]
for path, data in files:
    parts.append(f"--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"{path}\"\r\nContent-Type: application/typescript\r\n\r\n".encode() + data + b"\r\n")
parts.append(f"--{boundary}--\r\n".encode())
req = urllib.request.Request(
    f"https://api.supabase.com/v1/projects/{ref}/functions/deploy?slug={slug}",
    data=b"".join(parts),
    headers={"Authorization": "Bearer " + os.environ.get("SUPABASE_ACCESS_TOKEN", "proxy-injected"), "Content-Type": f"multipart/form-data; boundary={boundary}"},
    method="POST",
)
try:
    with urllib.request.urlopen(req, timeout=300) as r:
        d = json.loads(r.read())
        print(slug, "deployed:", r.status, {k: d.get(k) for k in ("slug", "version", "status", "verify_jwt", "entrypoint_path")})
except urllib.error.HTTPError as e:
    print(slug, "FAILED:", e.code, e.read().decode()[:800])
    sys.exit(1)
