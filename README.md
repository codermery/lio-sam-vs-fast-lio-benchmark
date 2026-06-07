# LIO-SAM vs FAST-LIO Benchmark

**A weekend benchmarking study comparing LIO-SAM and FAST-LIO2 on the Newer College Dataset.**

> This is a foundation experiment for my upcoming MSc thesis on 3D multi-robot SLAM at Yıldız Technical University. It is **not** a definitive ranking — just a controlled comparison on one sequence to build intuition and infrastructure.

**Author:** Meryem Koç, MSc Student — Yıldız Technical University (YTU)

---

## Results

| Algorithm | ATE RMSE [m] | ATE Mean [m] | ATE Max [m] | RPE RMSE [m] | RPE Mean [m] |
|-----------|:------------:|:------------:|:-----------:|:------------:|:------------:|
| LIO-SAM   | 0.687       | 0.572       | 1.310      | 6.090       | 5.164       |
| FAST-LIO  | **0.349**   | **0.268**   | **2.857**  | **2.093**   | **1.830**   |

*Alignment: SE(3) Umeyama, correct_scale=False. RPE delta: 10 frames.*

**FAST-LIO achieves ~2x lower ATE and ~3x lower RPE than LIO-SAM on this dataset with a 6-axis IMU.**

### Plot Interpretation

ATE plot shows LIO-SAM with a constant ~1.3m offset in the early trajectory due to initial alignment, then performs comparably to FAST-LIO afterward. FAST-LIO covers the full bag duration with more pose samples (8 Hz vs 2.4 Hz output rate). Headline RMSE numbers favor FAST-LIO, but in steady state both algorithms produce sub-meter ATE.

<details>
<summary>Trajectory Plot (click to expand)</summary>

![Trajectory XY](results/trajectory_xy.png)
</details>

<details>
<summary>ATE Over Time (click to expand)</summary>

![ATE Comparison](results/ate_comparison.png)
</details>

---

## Quick Start

```bash
# 1. Build the Docker image
docker build -t lio-benchmark .

# 2. Run the container
docker run -it --gpus all --network host \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v $(pwd):/ros2_ws/host \
    -v $(pwd)/data:/ros2_ws/data \
    -v $(pwd)/results:/ros2_ws/results \
    --name lio-benchmark lio-benchmark

# 3. Inside the container, build the workspace
./setup_workspace.sh

# 4. Run algorithms (after placing converted bag in /ros2_ws/data/)
./host/scripts/run_lio_sam.sh /ros2_ws/data/01_short_experiment /ros2_ws/results
./host/scripts/run_fast_lio.sh /ros2_ws/data/01_short_experiment /ros2_ws/results

# 5. Evaluate
python3 /ros2_ws/host/scripts/evaluate.py \
    --gt /ros2_ws/data/groundtruth_tum.txt \
    --lio-sam /ros2_ws/results/lio_sam_trajectory.tum \
    --fast-lio /ros2_ws/results/fast_lio_trajectory.tum \
    --output-dir /ros2_ws/results/
```

---

## Methodology

1. **Dataset:** Newer College Dataset — "short_experiment" sequence (~200m path)
   - Sensor: Ouster OS-1 64-beam LiDAR, IMU at 100 Hz
   - Environment: Oxford University campus (structured + vegetation)
   - Ground truth: ICP-registered survey-grade point cloud alignment

2. **Algorithms:**
   - **LIO-SAM** (Shan et al., 2020): Factor-graph-based LiDAR-inertial with GTSAM backend, loop closure via scan context
   - **FAST-LIO2** (Xu et al., 2022): ikd-Tree-based direct LiDAR-inertial with iterated Kalman filter

3. **Evaluation:**
   - SE(3) Umeyama alignment (no scale correction)
   - ATE (Absolute Trajectory Error): full trajectory accuracy
   - RPE (Relative Pose Error): local consistency, delta = 1.0 second
   - Tools: `evo` Python library

4. **Platform:**
   - Docker container with ROS2 Humble
   - Single-threaded bag playback (real-time factor = 1.0)

---

## Limitations

- **Single sequence only** — results may not generalize to other environments
- **No loop closure ablation** — LIO-SAM's loop closure advantage not isolated
- **No runtime profiling** — CPU/memory/latency not measured (planned for next iteration)
- **Default parameters** — both algorithms run with near-default configs for Ouster
- **No degradation analysis** — behavior in featureless/dynamic areas not studied
- **LIO-SAM 6-axis IMU patch** — LIO-SAM was patched to accept 6-axis IMU input (Ouster OS-1 does not publish orientation). This may affect attitude estimation quality compared to a 9-axis IMU setup. FAST-LIO does not require this patch. See [`docs/PATCHES.md`](docs/PATCHES.md) for details.
- **LIO-SAM RPE** — Higher RPE than FAST-LIO due to no orientation initialization from the 6-axis IMU. FAST-LIO handles this natively via its iterated Kalman filter. For 9-axis IMU setups, LIO-SAM may achieve lower RPE.
- **Output rate difference** — LIO-SAM produced only 453 poses vs FAST-LIO's 1338 from the same bag. This is normal — LIO-SAM publishes optimized keyframes, FAST-LIO publishes per-scan odometry. The output rate difference is a design choice, not a bug.

---

## Configuration Notes

### Ouster OS-1 Internal IMU + LIO-SAM

The Ouster OS-1's internal IMU is a 6-axis sensor co-located with the LiDAR. Three critical parameter changes are needed from LIO-SAM's defaults:

```yaml
# Identity — Ouster IMU frame is already aligned with LiDAR frame
extrinsicRot: [1, 0, 0, 0, 1, 0, 0, 0, 1]
extrinsicRPY: [1, 0, 0, 0, 1, 0, 0, 0, 1]

# Zero — 6-axis IMU has no orientation output to trust
imuRPYWeight: 0.0
```

Without these fixes, gravity is projected into the wrong axis, causing IMU preintegration to diverge (ATE > 600m). Full configs: [`configs/lio_sam_newer_college.yaml`](configs/lio_sam_newer_college.yaml)

### FAST-LIO with Ouster OS-1

Only topic names need changing in `ouster64.yaml`:
```yaml
lid_topic: "/os1_cloud_node/points"
imu_topic: "/os1_cloud_node/imu"
```

No extrinsic or IMU patches required. Full config: [`configs/fast_lio_ouster64.yaml`](configs/fast_lio_ouster64.yaml)

---

## Roadmap

- [ ] Add more sequences (quad, park, stairs)
- [ ] Runtime profiling (CPU, memory, per-frame latency)
- [ ] Loop closure ablation for LIO-SAM
- [ ] Multi-robot extension (thesis core)
- [ ] Compare with KISS-ICP, DLO, CT-ICP

---

## Citations

```bibtex
@inproceedings{shan2020liosam,
  title={LIO-SAM: Tightly-coupled Lidar Inertial Odometry via Smoothing and Mapping},
  author={Shan, Tixiao and Englot, Brendan and Meyers, Drew and Wang, Wei and Ratti, Carlo and Rus, Daniela},
  booktitle={IEEE/RSJ International Conference on Intelligent Robots and Systems (IROS)},
  year={2020}
}

@article{xu2022fastlio2,
  title={FAST-LIO2: Fast Direct LiDAR-Inertial Odometry},
  author={Xu, Wei and Cai, Yixi and He, Dongjiao and Lin, Jiarong and Zhang, Fu},
  journal={IEEE Transactions on Robotics},
  year={2022}
}

@inproceedings{ramezani2020newer,
  title={The Newer College Dataset: Handheld LiDAR, Inertial and Vision with Ground Truth},
  author={Ramezani, Milad and Wang, Yiduo and Camurri, Marco and Wisth, David and Mattamala, Matias and Fallon, Maurice},
  booktitle={IEEE/RSJ International Conference on Intelligent Robots and Systems (IROS)},
  year={2020}
}
```

---

## License

This benchmarking infrastructure is released under MIT License.
The algorithms and datasets retain their original licenses.
