# LinkedIn Post Drafts

## Version 1: Short & Punchy (4-5 lines)

---

🚀 Weekend benchmark complete: LIO-SAM vs FAST-LIO2 on the Newer College Dataset (Ouster OS-1, 64-beam).

Results: FAST-LIO ATE RMSE = [XX.X] cm | LIO-SAM ATE RMSE = [XX.X] cm

Both are excellent — the difference is in where they shine. Building on this for my multi-robot 3D SLAM thesis at YTU.

Full code + methodology: [GitHub link]

#SLAM #LiDAR #ROS2 #Robotics #AutonomousSystems #MSc #Research

---

## Version 2: Story Format (Long)

---

**From 2D to 3D: My first LiDAR-Inertial SLAM benchmark** 🗺️

For the past year I've worked with 2D SLAM (gmapping, cartographer) in multi-robot setups. Now, transitioning to 3D for my MSc thesis at Yıldız Technical University, I asked myself:

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
| ATE RMSE | [XX.X] cm | [XX.X] cm |
| RPE RMSE | [XX.X] cm | [XX.X] cm |

**What I learned:**
- [Key insight 1 about the algorithms' behavior]
- [Key insight 2 about failure modes or strengths]
- Building reproducible infrastructure is half the battle

**What's next:**
This benchmark is the foundation layer. My thesis extends this to multi-robot cooperative SLAM — merging submaps from multiple agents running these algorithms in parallel.

The full pipeline (Docker, scripts, evaluation code) is open source: [GitHub link]

---

*Important caveat: This is one sequence with default parameters. Not a definitive ranking — just a starting point for informed decisions.*

---

#SLAM #LiDAR #ROS2 #Robotics #3DSLAM #MultiRobotSLAM #MSc #YTU #Research #OpenSource #LIO #AutonomousSystems

---

## Posting Notes

- **Best time to post:** Sunday evening ~21:00 TR (Monday morning feed in EU/US)
- **Add:** 1-2 images (trajectory plot, ATE comparison plot)
- **Tag:** Original paper authors if they're on LinkedIn
- **First comment:** Add the GitHub link in the first comment for better engagement
