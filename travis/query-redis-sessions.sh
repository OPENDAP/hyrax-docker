#!/bin bash
set -euo pipefail

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

#############################################
# Helpers
#############################################

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# Portable millis->ISO8601 (works on GNU date and macOS/BSD date)
ms_to_iso() {
  local ms="$1"
  [[ -z "$ms" ]] && { echo ""; return; }
  # expect integer millis; if it's JSON like ["java.lang.Long",123], caller strips it
  local sec=$(( ms / 1000 ))
  if have_cmd gdate; then
    gdate -u -d "@$sec" +"%Y-%m-%dT%H:%M:%SZ"
  else
    # Try GNU date first; if it fails, try BSD `date -r`
    if date -u -d "@$sec" +"%Y-%m-%dT%H:%M:%SZ" >/dev/null 2>&1; then
      date -u -d "@$sec" +"%Y-%m-%dT%H:%M:%SZ"
    else
      date -u -r "$sec" +"%Y-%m-%dT%H:%M:%SZ"
    fi
  fi
}

# Extract millis from Redisson JsonJacksonCodec format:
#   ["java.lang.Long", 1757011521010]  -> 1757011521010
#   1757011521010                      -> 1757011521010
extract_millis() {
  local raw="$1"
  [[ -z "$raw" || "$raw" == "(nil)" ]] && { echo ""; return; }
  # If jq present, try JSON path; else strip non-digits
  if have_cmd jq; then
    echo "$raw" | jq -r '
      if type=="array" and length>1 and (.[1]|type=="number") then .[1]
      elif type=="number" then .
      elif type=="string" then
        try (fromjson | if type=="array" and length>1 then .[1] else . end) catch empty
      else empty end
    ' 2>/dev/null || echo ""
  else
    # Fallback: grab longest digit run
    echo "$raw" | tr -cd '0-9'
  fi
}

#############################################
# Fetch keys into an array (safe)
#############################################
echo "Scanning keys with pattern: $PATTERN (host=$REDIS_HOST port=$REDIS_PORT tls=$REDIS_TLS cluster=$REDIS_CLUSTER)"
mapfile -t keys < <("${REDIS[@]}" --scan --pattern "$PATTERN")

# De-duplicate (SCAN may repeat)
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

#############################################
# Emit CSV header
#############################################
echo "sid,creationTime,lastAccessedTime,thisAccessedTime,ttl_seconds,isValid,maxInactiveInterval" > "$OUT_CSV"

#############################################
# Iterate and print
#############################################
count=0
for key in "${unique_keys[@]}"; do
  ((count++))
  # Extract SID as last colon-delimited token
  sid="${key##*:}"


  # Pull fields
  ct_raw=$("${REDIS[@]}" HGET "$key" session:creationTime)
  lat_raw=$("${REDIS[@]}" HGET "$key" session:lastAccessedTime)
  tat_raw=$("${REDIS[@]}" HGET "$key" session:thisAccessedTime)
  mii=$("${REDIS[@]}" HGET "$key" session:maxInactiveInterval)
  valid=$("${REDIS[@]}" HGET "$key" session:isValid)
  return_url=$("${REDIS[@]}" HGET "$key" session:return_to_url)
  ttl=$("${REDIS[@]}" TTL "$key")

  # Parse millis
  ct_ms="$(extract_millis "$ct_raw")"
  lat_ms="$(extract_millis "$lat_raw")"
  tat_ms="$(extract_millis "$tat_raw")"

  # Human ISO8601
  ct_iso="$(ms_to_iso "$ct_ms")"
  lat_iso="$(ms_to_iso "$lat_ms")"
  tat_iso="$(ms_to_iso "$tat_ms")"

  # CSV line
  printf '%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$sid" "$ct_iso" "$lat_iso" "$tat_iso" "${ttl:-}" "${valid:-}" "${mii:-}" "${return_url:-}" \
    >> "$OUT_CSV"

  # Pretty stdout (optional)
  printf '(%d/%d) %s\n  created: %s\n  lastAccessed: %s\n  thisAccessed: %s\n  ttl: %s sec  valid: %s  maxInactive: %s sec\n\n' \
    "$count" "${#unique_keys[@]}" "$key" \
    "${ct_iso:-N/A}" "${lat_iso:-N/A}" "${tat_iso:-N/A}" \
    "${ttl:-N/A}" "${valid:-N/A}" "${mii:-N/A}"
done

echo "Wrote  $OUT_CSV"
CSV 
