#!/bin/bash
set -u  # (optional) treat unset vars as an error

#############################################
# Config (edit or pass as env/args)
#############################################
REDIS_HOST="${REDIS_HOST:-sit-redis.hmhtzc.0001.usw2.cache.amazonaws.com}"
REDIS_PORT="${REDIS_PORT:-6379}"
REDIS_AUTH="${REDIS_AUTH:-}"          # leave empty if no auth
REDIS_TLS="${REDIS_TLS:-0}"           # 1 to enable --tls
REDIS_CLUSTER="${REDIS_CLUSTER:-0}"   # 1 to enable -c (cluster)
PATTERN="${PATTERN:-hyrax_session:redisson:tomcat_session:*}"
OUT_CSV="${OUT_CSV:-sessions.csv}"

# Allow simple CLI args: ./dump_sessions.sh host port auth
if [[ $# -ge 1 ]]; then REDIS_HOST="$1"; fi
if [[ $# -ge 2 ]]; then REDIS_PORT="$2"; fi
if [[ $# -ge 3 ]]; then REDIS_AUTH="$3"; fi

#############################################
# Build redis-cli base command
#############################################
REDIS=(
  redis-cli
  -h "$REDIS_HOST"
  -p "$REDIS_PORT"
)

if [[ "$REDIS_TLS" == "1" ]]; then
  REDIS+=(--tls)
fi
if [[ -n "$REDIS_AUTH" ]]; then
  REDIS+=(-a "$REDIS_AUTH")
fi
if [[ "$REDIS_CLUSTER" == "1" ]]; then
  REDIS+=(-c)
fi

# --- Existing: scan and de-dupe ---
echo "Scanning keys with pattern: $PATTERN (host=$REDIS_HOST port=$REDIS_PORT tls=$REDIS_TLS cluster=$REDIS_CLUSTER)"
mapfile -t keys < <("${REDIS[@]}" --scan --pattern "$PATTERN")

declare -A seen=()
unique_keys=()
for k in "${keys[@]}"; do
  [[ -z "${k:-}" ]] && continue
  if [[ -z "${seen[$k]:-}" ]]; then
    seen["$k"]=1
    unique_keys+=("$k")
  fi
done
echo "Found ${#unique_keys[@]} unique keys"

# --- Ensure CSV path is OK ---
: "${OUT_CSV:?OUT_CSV is not set}"
mkdir -p "$(dirname -- "$OUT_CSV")"

# --- Write header (truncate) ---
echo "sid,creationTime,lastAccessedTime,thisAccessedTime,ttl_seconds,isNew,isValid,maxInactiveInterval,return_to_url" > "$OUT_CSV"

# --- If no keys, exit early with a message ---
if (( ${#unique_keys[@]} == 0 )); then
  echo "No keys matched '$PATTERN'. CSV has only the header."
  exit 0
fi

# --- Debug: show the first few raw keys ---
echo "Example keys:"
printf '  %s\n' "${unique_keys[@]:0:3}"

# --- Iterate and append rows ---
count=0
for key in "${unique_keys[@]}"; do
  ((count++))

  # Extract SID as last colon-delimited token
  sid="${key##*:}"

  # TTL (seconds)
  ttl=$("${REDIS[@]}" TTL "$key" 2>/dev/null || echo "")

  # pull lastAccessedTime from the hash (assuming it's a field)
  lastAccessedTime=""
  #lastAccessedTime=$("${REDIS[@]}" HGET "$key" lastAccessedTime 2>/dev/null || echo "")

  # other fields (examples)
  creationTime=""
  #creationTime=$("${REDIS[@]}" HGET "$key" creationTime 2>/dev/null || echo "")
  thisAccessedTime=""
  #thisAccessedTime=$("${REDIS[@]}" HGET "$key" thisAccessedTime 2>/dev/null || echo "")
  maxInactiveInterval=""
  #maxInactiveInterval=$("${REDIS[@]}" HGET "$key" maxInactiveInterval 2>/dev/null || echo "")
  isNew=$("${REDIS[@]}" HGET "$key" isNew 2>/dev/null || echo "")
  isValid=$("${REDIS[@]}" HGET "$key" isValid 2>/dev/null || echo "")
  return_to_url=$("${REDIS[@]}" HGET "$key" return_to_url 2>/dev/null || echo "")
  # application logic: decide isValid (e.g. ttl > 0)
  #if [[ "$ttl" -gt 0 ]]; then
  #  isValid="true"
  #else
  #  isValid="false"
  #fi

  # Append to CSV
  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$sid" "$creationTime" "$lastAccessedTime" "$thisAccessedTime" "$ttl" "$isNew" "$isValid" "$maxInactiveInterval" "$return_to_url" >> "$OUT_CSV"
done


echo "Wrote $count row(s) to $OUT_CSV"
