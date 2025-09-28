import os, random, time, sys, glob

# Configuration
TOTAL_STEPS = 20  # Fixed number of training steps

ckpt_dir = os.environ.get("CKPT_DIR", "./ckpts")
os.makedirs(ckpt_dir, exist_ok=True)

# Find latest checkpoint using realistic checkpoint files
ckpt_pattern = os.path.join(ckpt_dir, "step_*.txt")
ckpt_files = glob.glob(ckpt_pattern)
if ckpt_files:
    # Extract step numbers and find the highest
    steps = []
    for f in ckpt_files:
        try:
            step_num = int(os.path.basename(f).split('_')[1].split('.')[0])
            steps.append(step_num)
        except (IndexError, ValueError):
            continue
    step = max(steps) if steps else 0
    print(f"[train.py] Resuming from checkpoint: step_{step}.txt")
else:
    step = 0
    print(f"[train.py] No checkpoint found, starting from scratch")

# Check if training is already complete
if step >= TOTAL_STEPS:
    print(f"[train.py] Training already complete! ({step}/{TOTAL_STEPS} steps)")
    sys.exit(0)

# Pretend training - run up to 5 steps or until completion

for i in range(step, TOTAL_STEPS):
    time.sleep(1)  # simulate compute
    print(f"[train.py] step {i}")
    
    # Save checkpoint as individual file
    ckpt_file = os.path.join(ckpt_dir, f"step_{i + 1}.txt")
    with open(ckpt_file, "w") as f:
        f.write(f"step={i + 1}\ntotal_steps={TOTAL_STEPS}\ntimestamp={time.time()}")
    print(f"[train.py] Saved checkpoint: {os.path.basename(ckpt_file)}")

    # Random failure injection
    if random.random() < 0.3:  # 30% chance
        print("[train.py] Simulated crash!")
        sys.exit(1)

# Check if we've completed all training
if max_step >= TOTAL_STEPS:
    print(f"[train.py] Training completed successfully! ({TOTAL_STEPS}/{TOTAL_STEPS} steps)")

