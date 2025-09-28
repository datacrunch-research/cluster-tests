#!/usr/bin/env bash
set -euo pipefail

. ./config.sh 
# Config (mirrors config.yaml for simplicity)
mkdir -p "$CHECKPOINT_DIR"

# Retry counter file - reset for each requeue.sh run
mkdir -p logs
RETRIES_FILE="logs/retries.txt"
retries=0

LOG_RETRIES() {
  echo "${1:?}" > "$RETRIES_FILE"
}

# stdout tee helper
set -o pipefail
exec 3>&1
TEE_STDOUT() { tee >(cat >&3); }

# job id parser
PARSE_JOB_ID() {
  head -1 | sed -E 's/^Submitted batch job ([[:digit:]]+)$/\1/; t; Q1' \
  | grep '^[[:digit:]]\+' || echo "ERROR"
}

# Main loop
while [ "$retries" -le "$MAX_RETRIES" ]; do
  if [ "$retries" -ne 0 ]; then
    printf 'Job failed; restarting. %d attempts left.\n' "$(( MAX_RETRIES - retries ))"
  fi

  LOG_RETRIES "$((++retries))"

  echo "Submitting job..."
  JOB_ID="$( sbatch --wait -- "$SBATCH_FILE" | PARSE_JOB_ID | TEE_STDOUT )" && {
    echo "Job $JOB_ID finished successfully."
    exit 0
  }
  
  echo "Submitted job $JOB_ID"

  if [ "$JOB_ID" = "ERROR" ]; then
    echo "ERROR: Could not parse job id."
    break
  fi

  JOB_STATE="$( sacct -j "$JOB_ID" --format=State --noheader -XP 2>/dev/null || true )"
  [ -z "$JOB_STATE" ] && { echo "No state for job $JOB_ID"; break; }

  case "$JOB_STATE" in
    FAILED*|NODE_FAIL*)
      echo "State=$JOB_STATE -> retrying."
      ;;
    TIMEOUT*|OUT_OF_MEMORY*|CANCELLED*|PREEMPTED*|SUSPENDED*|BOOT_FAIL*|DEADLINE*)
      echo "State=$JOB_STATE -> not retrying."
      break
      ;;
    COMPLETED*)
      echo "State=$JOB_STATE -> completed (unexpected path)."
      exit 0
      ;;
    *)
      echo "State=$JOB_STATE -> unrecognized."
      break
      ;;
  esac
done

echo "Job failed after exceeding $MAX_RETRIES attempts."
exit 1
