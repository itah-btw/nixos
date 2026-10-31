#!/usr/bin/env bash
set -euo pipefail

repo=/opt/opencode-unlimited-proxy
stack="$repo/stack"

if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a Git checkout: $repo" >&2
  exit 1
fi
if [[ "$(git -C "$repo" branch --show-current)" != main ]]; then
  echo "Expected the main branch; refusing to update another branch." >&2
  exit 1
fi

tmpdir=$(mktemp -d)
chmod 700 "$tmpdir"
config_saved=0
config_merged=0
cleanup() {
  local result=$?
  trap - EXIT
  if (( config_saved && ! config_merged )); then
    install -m 600 "$tmpdir/config.local.json" "$stack/config.json"
  fi
  rm -rf -- "$tmpdir"
  exit "$result"
}
trap cleanup EXIT

echo "== Fetching upstream =="
git -C "$repo" fetch origin

echo "== Current checkout =="
git -C "$repo" status --short --branch

# Permit only the local config and known engine image pin edits. Any other
# working-tree change must be reviewed and saved by the user first.
while IFS= read -r entry; do
  [[ -z "$entry" ]] && continue
  case "$entry" in
    " M stack/config.json"|" M stack/docker-compose.yml"|" M stack/generate-compose.py") ;;
    *)
      echo "Unexpected local change: $entry" >&2
      echo "Save or resolve it before updating; no files were changed." >&2
      exit 1
      ;;
  esac
done < <(git -C "$repo" status --porcelain)

# The local v1.4.5 pin is already present upstream. Verify those are the only
# code edits before restoring the generated files; upstream may have rewritten
# the surrounding Compose structure, so patch-context matching is insufficient.
if ! git -C "$repo" diff --quiet HEAD -- stack/docker-compose.yml stack/generate-compose.py; then
python3 - "$repo" <<'PY'
import pathlib
import subprocess
import sys

repo = pathlib.Path(sys.argv[1])
specs = {
    "stack/docker-compose.yml": (
        "image: ghcr.io/jasonxu114514/opencode2api:v1.4.1",
        "image: ghcr.io/jasonxu114514/opencode2api:v1.4.5",
    ),
    "stack/generate-compose.py": (
        'ENGINE_IMAGE = "ghcr.io/jasonxu114514/opencode2api:v1.4.1"',
        'ENGINE_IMAGE = "ghcr.io/jasonxu114514/opencode2api:v1.4.5"',
    ),
}

for relative, (old, new) in specs.items():
    base = subprocess.check_output(
        ["git", "-C", str(repo), "show", f"HEAD:{relative}"], text=True
    )
    upstream = subprocess.check_output(
        ["git", "-C", str(repo), "show", f"origin/main:{relative}"], text=True
    )
    local = (repo / relative).read_text()
    if base.count(old) != 1 or local.count(new) != 1 or local.replace(new, old, 1) != base:
        raise SystemExit(f"Unexpected local edits in {relative}; refusing to discard them.")
    if new not in upstream:
        raise SystemExit(f"The local engine pin is not present upstream in {relative}.")

print("Local v1.4.5 pins are the only code edits and are present upstream.")
PY
else
  echo "No local Compose or generator edits."
fi

# Preserve only local config overrides. This lets new upstream defaults such as
# the WARP settings flow into the updated config without losing the API key or
# dashboard password.
git -C "$repo" show HEAD:stack/config.json > "$tmpdir/config.base.json"
install -m 600 "$stack/config.json" "$tmpdir/config.local.json"
config_saved=1
upstream_warp=$(git -C "$repo" show origin/main:stack/config.json | python3 -c 'import json,sys; print(str(json.load(sys.stdin).get("warp", {}).get("enabled", False)).lower())')
if [[ "$upstream_warp" == true ]] && ! grep -qx 'WARP_ACCEPT_TOS=1' "$stack/.env"; then
  echo "Upstream enables WARP. Read its terms and explicitly set WARP_ACCEPT_TOS=1 in $stack/.env before updating." >&2
  exit 1
fi

echo "== Local Compose and generator edits =="
git -C "$repo" diff -- stack/docker-compose.yml stack/generate-compose.py

git -C "$repo" restore --source=HEAD --staged --worktree -- \
  stack/config.json stack/docker-compose.yml stack/generate-compose.py

echo "== Updating source (fast-forward only) =="
if ! git -C "$repo" pull --ff-only; then
  echo "Git update failed; your local config will be restored." >&2
  exit 1
fi

python3 - "$tmpdir/config.base.json" "$tmpdir/config.local.json" "$stack/config.json" <<'PY'
import json
import os
import pathlib
import sys

base_path, local_path, current_path = map(pathlib.Path, sys.argv[1:])
base = json.loads(base_path.read_text())
local = json.loads(local_path.read_text())
current = json.loads(current_path.read_text())

def preserve_local_overrides(base_value, local_value, current_value):
    if isinstance(base_value, dict) and isinstance(local_value, dict) and isinstance(current_value, dict):
        merged = dict(current_value)
        for key in base_value.keys() | local_value.keys():
            if key not in local_value:
                if key in base_value:
                    merged.pop(key, None)
            elif key not in base_value:
                merged[key] = local_value[key]
            elif local_value[key] != base_value[key]:
                merged[key] = preserve_local_overrides(
                    base_value[key], local_value[key], current_value.get(key)
                )
        return merged
    return local_value if local_value != base_value else current_value

merged = preserve_local_overrides(base, local, current)
tmp_path = current_path.with_suffix(".json.tmp")
tmp_path.write_text(json.dumps(merged, indent=2) + "\n")
os.chmod(tmp_path, 0o600)
tmp_path.replace(current_path)
PY
config_merged=1
chmod 600 "$stack/config.json"

echo "== Pulling engine image and rebuilding the stack =="
sudo docker compose -f "$stack/docker-compose.yml" pull opencode-engine
sudo docker compose -f "$stack/docker-compose.yml" up -d --build --force-recreate --remove-orphans

echo "== Service status =="
sudo docker compose -f "$stack/docker-compose.yml" ps

api_key=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["server_keys"][0])' "$stack/config.json")
api_ready=0
for _ in {1..30}; do
  if curl -fs --connect-timeout 2 --max-time 5 --output /dev/null \
    --config <(printf 'header = "Authorization: Bearer %s"\n' "$api_key") \
    http://127.0.0.1:8080/v1/models; then
    api_ready=1
    break
  fi
  sleep 2
done
if (( api_ready )); then
  echo "API endpoint is reachable and authenticated."
else
  echo "Stack updated, but the authenticated API check failed." >&2
  exit 1
fi
