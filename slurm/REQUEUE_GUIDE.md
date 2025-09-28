# SLURM Requeue System Guide

This document explains how the SLURM requeue system works, with detailed explanations of the bash script logic.

## Overview

The system automatically resubmits failed SLURM jobs with checkpointing, allowing long-running training jobs to resume where they left off after failures.

## File Structure

```
demo_exp/
├── config.sh          # Configuration variables
├── requeue.sh          # Main requeue logic (bash script)
├── job.sh              # SLURM job script
├── train.py            # Training script with checkpointing
├── chkpts/             # Checkpoint directory
│   ├── step_1.txt      # Individual checkpoint files
│   ├── step_5.txt      # Each contains step info + metadata
│   └── step_10.txt     # Realistic checkpoint approach
└── logs/
    ├── retries.txt     # Retry counter
    ├── train_*.out     # SLURM job outputs
    └── train_*.err     # SLURM job errors
```

## Configuration (config.sh)

```bash
MAX_RETRIES=5                                    # Maximum retry attempts
CHECKPOINT_DIR=/home/datacrunch_paul/demo_exp    # Where checkpoints are stored
SBATCH_FILE=./job.sh                           # SLURM job script to run
```

These variables are sourced by `requeue.sh` using `. ./config.sh`.

## Main Script Breakdown (requeue.sh)

### 1. Script Header & Safety

```bash
#!/usr/bin/env bash
set -euo pipefail
```

- `#!/usr/bin/env bash`: Shebang line - tells system to use bash
- `set -euo pipefail`: Safety options
  - `-e`: Exit on any command failure
  - `-u`: Exit on undefined variables
  - `-o pipefail`: Fail if any command in a pipeline fails

### 2. Load Configuration

```bash
. ./config.sh 
mkdir -p "$CHECKPOINT_DIR"
```

- `. ./config.sh`: Sources (loads) variables from config.sh
- `mkdir -p`: Creates directory if it doesn't exist (`-p` = no error if exists)

### 3. Retry Counter Management

```bash
# Retry counter file - reset for each requeue.sh run
mkdir -p logs
RETRIES_FILE="logs/retries.txt"
retries=0

LOG_RETRIES() {
  echo "${1:?}" > "$RETRIES_FILE"
}
```

- **Function Definition**: `LOG_RETRIES()` saves retry count to file
- `"${1:?}"`: First argument to function, error if missing
- `>`: Redirects output to file (overwrites)
- `retries=0`: Always start fresh (reset between runs)

### 4. Utility Functions

#### stdout tee helper
```bash
set -o pipefail
exec 3>&1
TEE_STDOUT() { tee >(cat >&3); }
```

- `exec 3>&1`: Creates file descriptor 3 pointing to original stdout
- `TEE_STDOUT()`: Function that duplicates output to both stdout and pipeline
- `tee >(cat >&3)`: Sends input to both the pipeline and original stdout

#### Job ID Parser
```bash
PARSE_JOB_ID() {
  head -1 | sed -E 's/^Submitted batch job ([[:digit:]]+)$/\1/; t; Q1' \
  | grep '^[[:digit:]]\+' || echo "ERROR"
}
```

- `head -1`: Takes only first line
- `sed -E`: Extended regex mode
- `'s/^Submitted batch job ([[:digit:]]+)$/\1/; t; Q1'`:
  - `s///`: Substitute command
  - `^Submitted batch job ([[:digit:]]+)$`: Match full line with job ID in parentheses
  - `\1`: Replace with captured group (the job ID)
  - `t`: If substitution succeeded, skip to end
  - `Q1`: If substitution failed, quit with exit code 1
- `grep '^[[:digit:]]\+'`: Extract numbers only
- `|| echo "ERROR"`: If parsing fails, output "ERROR"

### 5. Main Retry Loop

```bash
while [ "$retries" -le "$MAX_RETRIES" ]; do
```

**Loop Condition**: Continue while retries ≤ MAX_RETRIES

#### Retry Message Display
```bash
if [ "$retries" -ne 0 ]; then
  printf 'Job failed; restarting. %d attempts left.\n' "$(( MAX_RETRIES - retries ))"
fi
```

- `[ "$retries" -ne 0 ]`: If not the first attempt
- `printf`: More reliable than echo for formatted output
- `$(( MAX_RETRIES - retries ))`: Arithmetic expansion for remaining attempts

#### Increment Retry Counter
```bash
LOG_RETRIES "$((++retries))"
```

- `$((++retries))`: Pre-increment retries and use new value
- Calls `LOG_RETRIES` function to save count

#### Job Submission
```bash
echo "Submitting job..."
JOB_ID="$( sbatch --wait -- "$SBATCH_FILE" | PARSE_JOB_ID | TEE_STDOUT )" && {
  echo "Job $JOB_ID finished successfully."
  exit 0
}

echo "Submitted job $JOB_ID"
```

**Step by step**:
1. `sbatch --wait -- "$SBATCH_FILE"`: Submit job and wait for completion
   - `--wait`: Block until job finishes
   - `--`: Separates sbatch options from job script
2. `| PARSE_JOB_ID`: Extract job ID from sbatch output
3. `| TEE_STDOUT`: Display job ID while capturing it
4. `JOB_ID="$(...)"`: Capture the job ID in variable
5. `&& { ... }`: If sbatch succeeded (exit code 0), execute success block
6. If successful: print success message and exit
7. If failed: continue to error handling

#### Error Handling
```bash
if [ "$JOB_ID" = "ERROR" ]; then
  echo "ERROR: Could not parse job id."
  break
fi
```

If job ID parsing failed, exit the retry loop.

#### Job State Analysis
```bash
JOB_STATE="$( sacct -j "$JOB_ID" --format=State --noheader -XP 2>/dev/null || true )"
[ -z "$JOB_STATE" ] && { echo "No state for job $JOB_ID"; break; }
```

- `sacct -j "$JOB_ID"`: Query job accounting info
- `--format=State --noheader -XP`: Get only the state, no headers, parseable format
- `2>/dev/null`: Suppress error messages
- `|| true`: Don't fail if sacct fails
- `[ -z "$JOB_STATE" ]`: If state is empty
- `&& { ...; }`: Execute commands if condition is true

#### State-Based Retry Logic
```bash
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
```

**Case Statement Logic**:
- **FAILED*/NODE_FAIL***: Temporary failures → retry
- **TIMEOUT*/OUT_OF_MEMORY*/etc.**: Permanent failures → don't retry
- **COMPLETED***: Success (shouldn't reach here) → exit
- **Default**: Unknown state → stop trying

### 6. Loop Exit
```bash
echo "Job failed after exceeding $MAX_RETRIES attempts."
exit 1
```

If loop exits normally (all retries exhausted), report failure.

## How It All Works Together

1. **Start**: User runs `./requeue.sh`
2. **Setup**: Load config, reset retry counter, create directories
3. **Submit**: Submit SLURM job and wait
4. **Check**: If job succeeds → exit with success
5. **Analyze**: If job fails → check failure type
6. **Retry**: If retriable failure → increment counter and loop
7. **Give up**: If non-retriable failure or max retries → exit with failure

## Key Bash Concepts Used

### Command Substitution
```bash
JOB_ID="$( sbatch ... )"    # Capture command output in variable
```

### Arithmetic Expansion
```bash
$(( MAX_RETRIES - retries ))    # Perform math operations
```

### Conditional Execution
```bash
command && { success_actions; }    # Run block only if command succeeds
command || fallback_command        # Run fallback if command fails
```

### Functions
```bash
FUNCTION_NAME() {
  # function body
  echo "${1:?}"    # First argument, error if missing
}
```

### File Descriptors & Redirection
```bash
exec 3>&1           # Duplicate stdout to fd 3
echo "text" > file  # Redirect to file (overwrite)
2>/dev/null        # Redirect stderr to null (suppress)
```

### String Testing
```bash
[ "$var" = "value" ]     # String equality
[ -z "$var" ]           # True if string is empty
[ -f "$file" ]          # True if file exists
```

This system provides robust job management with automatic retry logic and proper checkpointing for long-running computational tasks.