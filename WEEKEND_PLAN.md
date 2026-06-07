# Weekend Plan: LIO-SAM vs FAST-LIO Benchmark

**Goal:** Produce a GitHub-ready benchmark with results, plots, and a LinkedIn post by Sunday 21:00 TR.

---

## Saturday

### Morning (09:00 – 12:00) — Infrastructure

| Time | Task | Success Criteria |
|------|------|-----------------|
| 09:00-09:30 | Docker build | Image builds without errors |
| 09:30-10:30 | `setup_workspace.sh` (clone + colcon build) | All packages compile |
| 10:00-11:00 | Download Newer College dataset (parallel) | `01_short_experiment.bag` on disk |
| 11:00-12:00 | `rosbags-convert` + ground truth to TUM | ROS2 bag + `groundtruth_tum.txt` ready |

### Afternoon (13:00 – 18:00) — Algorithm Runs

| Time | Task | Success Criteria |
|------|------|-----------------|
| 13:00-14:30 | Run LIO-SAM on short_experiment | `lio_sam_trajectory.tum` with >1000 poses |
| 14:30-15:00 | Sanity check: quick evo plot of LIO-SAM vs GT | Trajectory roughly overlaps |
| 15:00-16:30 | Run FAST-LIO on short_experiment | `fast_lio_trajectory.tum` with >1000 poses |
| 16:30-17:00 | Sanity check: quick evo plot of FAST-LIO vs GT | Trajectory roughly overlaps |
| 17:00-18:00 | Debug buffer / re-run if needed | Both trajectories valid |

### Evening (19:00 – 21:00) — Buffer

- Fix any remaining issues from afternoon runs
- Re-tune parameters if one algorithm diverged
- Backup results so far

---

## Sunday

### Morning (09:00 – 12:00) — Evaluation

| Time | Task | Success Criteria |
|------|------|-----------------|
| 09:00-10:00 | Run `evaluate.py` | Plots + tables generated |
| 10:00-11:00 | Review numbers, check if they make sense | ATE in expected range (0.05-0.50m) |
| 11:00-12:00 | Polish plots (labels, colors, fonts) | Publication-quality figures |

### Afternoon (14:00 – 17:00) — Visuals & Documentation

| Time | Task | Success Criteria |
|------|------|-----------------|
| 14:00-15:30 | RViz visualization + screen recording | MP4/GIF of both algorithms |
| 15:30-16:30 | README polish + results table | README complete with actual numbers |
| 16:30-17:00 | Final git cleanup + push | Clean repo on GitHub |

### Evening (17:00 – 21:00) — Publication

| Time | Task | Success Criteria |
|------|------|-----------------|
| 17:00-18:00 | Write LinkedIn post with actual numbers | Both versions ready |
| 18:00-19:00 | Record 30-sec video walkthrough (optional) | Quick demo clip |
| 19:00-20:00 | Final review of everything | All links work |
| 20:00-21:00 | **POST TO LINKEDIN** | 🎉 Done! |

---

## Contingency Plans

### Plan B: Docker Build Fails
- **Symptom:** GTSAM PPA unavailable, dependency conflicts
- **Action:** Build GTSAM from source (add 30-40 min), or use pre-built Docker image from `timdhanmern/liosam` as base
- **Time cost:** +1 hour

### Plan C: Dataset Download Issues
- **Symptom:** Newer College server slow/down
- **Action:** Switch to MulRan dataset (Sejong/KAIST sequence) — also has Ouster + IMU
- **Alternate:** Use any rosbag with `/points` + `/imu` topics
- **Time cost:** +30 min for config changes

### Plan D: Algorithms Fail to Run
- **Symptom:** LIO-SAM or FAST-LIO diverges, crashes, or produces empty output
- **Action (LIO-SAM):** Check IMU extrinsics in params.yaml, ensure gravity direction correct
- **Action (FAST-LIO):** Verify point cloud format matches ouster64.yaml expectations
- **Action (both):** Try playing bag at 0.5x speed: `ros2 bag play --rate 0.5`
- **Fallback:** If one algorithm works and other doesn't, publish single-algorithm results with note
- **Time cost:** +2 hours max

### Plan E: Sunday Evening, Nothing Works
- **Reality:** Sometimes weekends don't go as planned
- **Action:** Post what you have — even just the infrastructure (Dockerfile, scripts, methodology) is valuable
- **LinkedIn angle:** "Built the pipeline, dataset issues delayed results — coming next weekend"
- **This is still a win:** Reproducible infrastructure > one-off results

---

## Key Reminders

- [ ] Save intermediate results often (`cp -r results/ results_backup_$(date +%H%M)/`)
- [ ] Git commit after each major milestone
- [ ] Don't spend >30 min on a single bug without stepping back
- [ ] Drink water, take breaks, this is a marathon not a sprint
- [ ] "Done is better than perfect" — ship what you have by 21:00
