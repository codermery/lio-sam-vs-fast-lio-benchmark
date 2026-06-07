# LinkedIn Post Drafts

## Version 1: Short & Punchy (4-5 lines)

---

Weekend benchmark done: LIO-SAM vs FAST-LIO2 on the Newer College Dataset (Ouster OS-1 64-beam, 6-axis IMU).

Both algorithms achieved sub-meter ATE. FAST-LIO showed better global accuracy (0.35m vs 0.69m RMSE) and higher output rate (8 Hz vs 2.4 Hz), while LIO-SAM's steady-state accuracy was comparable. For Ouster's 6-axis IMU, both needed configuration tuning — documented in the repo.

Full code + methodology + Docker: [GitHub link]

#SLAM #LiDAR #ROS2 #Robotics #AutonomousSystems #MSc #Research

---

## Version 2: Story Format (Long)

---

**From 2D to 3D: My first LiDAR-Inertial SLAM benchmark**

For the past year I've worked with 2D SLAM (gmapping, cartographer) in multi-robot setups. Now, transitioning to 3D for my MSc thesis at Yildiz Technical University, I asked myself:

*"Which LiDAR-inertial odometry should I build my multi-robot system on?"*

So I set up a controlled benchmark this weekend:

**Setup:**
- Dataset: Newer College (Oxford) — Ouster OS-1 64-beam, 100Hz IMU
- Algorithms: LIO-SAM (factor graph + GTSAM) vs FAST-LIO2 (iterated Kalman + ikd-Tree)
- Evaluation: ATE + RPE using the `evo` library, SE(3) alignment
- Infrastructure: Docker + ROS2 Humble, fully reproducible

**Key findings:**
| Metric | LIO-SAM | FAST-LIO |
|--------|---------|----------|
| ATE RMSE | 0.69 m | 0.35 m |
| RPE RMSE | 6.09 m | 2.09 m |
| Output rate | 2.4 Hz | 8.0 Hz |

**What I learned:**
- Both algorithms achieve sub-meter ATE when correctly configured. FAST-LIO is more accurate globally (0.35m vs 0.69m), but in steady state they're comparable.
- FAST-LIO handles 6-axis IMUs (like Ouster's internal sensor) out of the box. LIO-SAM officially requires 9-axis.
- Getting LIO-SAM to work with Ouster required: a source patch for orientation handling + identity extrinsics + imuRPYWeight=0. Wrong extrinsics alone caused 600m drift — configuration matters more than algorithm choice.
- FAST-LIO outputs at 8 Hz (per-scan odometry) vs LIO-SAM at 2.4 Hz (keyframes). Different design philosophies, not a flaw.

**What's next:**
This benchmark is the foundation layer. My thesis extends this to multi-robot cooperative SLAM — merging submaps from multiple agents running these algorithms in parallel.

The full pipeline (Docker, scripts, evaluation code, configs) is open source: [GitHub link]

---

*Important caveat: Single sequence, 6-axis IMU. Not a definitive ranking — LIO-SAM may perform differently with a 9-axis IMU and loop closures enabled.*

---

#SLAM #LiDAR #ROS2 #Robotics #3DSLAM #MultiRobotSLAM #MSc #YTU #Research #OpenSource #LIO #AutonomousSystems

---

## Posting Notes

- **Best time to post:** Sunday evening ~21:00 TR (Monday morning feed in EU/US)
- **Add:** 1-2 images (trajectory plot, ATE comparison plot)
- **Tag:** Original paper authors if they're on LinkedIn
- **First comment:** Add the GitHub link in the first comment for better engagement
