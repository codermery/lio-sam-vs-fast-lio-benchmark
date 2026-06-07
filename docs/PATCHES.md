# Patches Applied

## LIO-SAM 6-Axis IMU Patch

**File:** `patches/lio_sam_6axis_imu.patch`  
**Target:** `LIO-SAM/include/lio_sam/utility.hpp` (line ~336)

### Problem

The Newer College Dataset uses an Ouster OS-1 64-beam LiDAR with an **internal 6-axis IMU**. This IMU outputs only linear acceleration and angular velocity — it does **not** provide orientation (quaternion).

LIO-SAM officially requires a 9-axis IMU with orientation output. When the orientation quaternion is all zeros `[0, 0, 0, 0]` (norm < 0.1), LIO-SAM logs an error and shuts down:

```cpp
// Original code (utility.hpp, line ~338)
RCLCPP_ERROR(get_logger(), "Invalid quaternion, please use a 9-axis IMU!");
rclcpp::shutdown();
```

### Fix

Replace the crash with a fallback to identity orientation `[0, 0, 0, 1]`:

```cpp
// Patched code
imu_out.orientation.x = 0.0;
imu_out.orientation.y = 0.0;
imu_out.orientation.z = 0.0;
imu_out.orientation.w = 1.0;
```

This allows LIO-SAM to initialize and run, relying on the IMU preintegration module to estimate orientation from angular velocity over time.

### How to Apply

```bash
cd /path/to/LIO-SAM
git apply /path/to/patches/lio_sam_6axis_imu.patch
```

### Impact on Results

- LIO-SAM loses the initial attitude estimate from orientation, which means the first few frames may have less accurate roll/pitch initialization
- In practice, the IMU preintegration converges quickly after a few seconds of motion
- FAST-LIO does **not** require this patch — it handles 6-axis IMUs natively via its iterated Kalman filter

### Configuration Fixes for Ouster OS-1 Internal IMU

In addition to the source patch above, three `params.yaml` parameters must be changed from their defaults:

| Parameter | Default (Microstrain) | Ouster OS-1 Fix | Why |
|-----------|----------------------|-----------------|-----|
| `extrinsicRot` | `[-1,0,0, 0,1,0, 0,0,-1]` | `[1,0,0, 0,1,0, 0,0,1]` (identity) | Ouster's internal IMU frame is already aligned with the LiDAR frame |
| `extrinsicRPY` | `[0,-1,0, 1,0,0, 0,0,1]` | `[1,0,0, 0,1,0, 0,0,1]` (identity) | Same reason — no frame rotation needed |
| `imuRPYWeight` | `0.01` | `0.0` | 6-axis IMU has no orientation output; don't trust the identity quaternion fallback |

**Without these fixes**, IMU preintegration diverges immediately (gravity projected into wrong axis), producing ATE > 600m and constant "Large velocity, reset IMU-preintegration!" warnings.

The full working config is saved at [`configs/lio_sam_newer_college.yaml`](../configs/lio_sam_newer_college.yaml).

### Known Community Discussion

This is a well-known limitation of LIO-SAM:

- [LIO-SAM README (official)](https://github.com/TixiaoShan/LIO-SAM#notes): *"LIO-SAM does not work with the internal 6-axis IMU of Ouster lidar."*
- [GitHub Issue #6](https://github.com/TixiaoShan/LIO-SAM/issues/6): Early discussion on IMU requirements
- [GitHub Issue #88](https://github.com/TixiaoShan/LIO-SAM/issues/88): Ouster OS-1 compatibility
- Community forks (e.g., `koide3/lio-sam-ouster`) implement similar workarounds

### Ouster OS-1 IMU Characteristics

| Property | Value |
|----------|-------|
| Axes | 6 (3 accel + 3 gyro) |
| Rate | 100 Hz |
| Orientation output | None (quaternion = [0,0,0,0]) |
| Topic | `/os1_cloud_node/imu` |
| Message type | `sensor_msgs/msg/Imu` |
