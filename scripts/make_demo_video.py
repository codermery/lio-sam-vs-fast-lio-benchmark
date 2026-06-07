#!/usr/bin/env python3
"""Generate animated demo video of trajectory comparison.

Renders frames with matplotlib and assembles into MP4/GIF with ffmpeg.
Usage: python3 make_demo_video.py [--results-dir ./results] [--fps 20] [--frames 300]
"""
import argparse
import os
import shutil
import subprocess
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

from evo.tools import file_interface
from evo.core import sync, metrics
from evo.core.metrics import PoseRelation
import copy


def load_tum(path):
    return file_interface.read_tum_trajectory_file(path)


def compute_ate_errors(ref, est):
    ref_sync, est_sync = sync.associate_trajectories(ref, est)
    est_aligned = copy.deepcopy(est_sync)
    est_aligned.align(ref_sync, correct_scale=False)
    ape = metrics.APE(PoseRelation.translation_part)
    ape.process_data((ref_sync, est_aligned))
    return ape.error, ref_sync, est_aligned


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--results-dir', default='./results')
    parser.add_argument('--fps', type=int, default=20)
    parser.add_argument('--frames', type=int, default=300)
    args = parser.parse_args()

    gt_path = os.path.join(args.results_dir, 'ground_truth.tum')
    ls_path = os.path.join(args.results_dir, 'lio_sam_trajectory.tum')
    fl_path = os.path.join(args.results_dir, 'fast_lio_trajectory.tum')

    print("[video] Loading trajectories...")
    gt_traj = load_tum(gt_path)
    ls_traj = load_tum(ls_path)
    fl_traj = load_tum(fl_path)

    # Compute aligned trajectories and ATE
    print("[video] Computing ATE...")
    ls_errors, gt_sync_ls, ls_aligned = compute_ate_errors(gt_traj, ls_traj)
    fl_errors, gt_sync_fl, fl_aligned = compute_ate_errors(gt_traj, fl_traj)

    gt_xy_ls = gt_sync_ls.positions_xyz[:, :2]
    ls_xy = ls_aligned.positions_xyz[:, :2]
    gt_xy_fl = gt_sync_fl.positions_xyz[:, :2]
    fl_xy = fl_aligned.positions_xyz[:, :2]

    # Determine axis limits
    all_x = np.concatenate([gt_xy_ls[:, 0], gt_xy_fl[:, 0], ls_xy[:, 0], fl_xy[:, 0]])
    all_y = np.concatenate([gt_xy_ls[:, 1], gt_xy_fl[:, 1], ls_xy[:, 1], fl_xy[:, 1]])
    x_margin = (all_x.max() - all_x.min()) * 0.1
    y_margin = (all_y.max() - all_y.min()) * 0.1
    xlim = (all_x.min() - x_margin, all_x.max() + x_margin)
    ylim = (all_y.min() - y_margin, all_y.max() + y_margin)

    max_ate = max(ls_errors.max(), fl_errors.max()) * 1.2
    max_poses = max(len(ls_errors), len(fl_errors))

    # Render frames
    frame_dir = '/tmp/video_frames'
    if os.path.exists(frame_dir):
        shutil.rmtree(frame_dir)
    os.makedirs(frame_dir)

    n_frames = args.frames
    print(f"[video] Rendering {n_frames} frames...")

    for i in range(n_frames):
        frac = (i + 1) / n_frames

        # Indices for each trajectory
        n_ls = int(frac * len(ls_xy))
        n_fl = int(frac * len(fl_xy))
        n_gt_ls = int(frac * len(gt_xy_ls))
        n_gt_fl = int(frac * len(gt_xy_fl))
        n_ls_err = int(frac * len(ls_errors))
        n_fl_err = int(frac * len(fl_errors))

        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))

        # LEFT: Trajectory XY
        ax1.plot(gt_xy_fl[:n_gt_fl, 0], gt_xy_fl[:n_gt_fl, 1],
                 'k-', linewidth=2.5, label='Ground Truth', alpha=0.7)
        ax1.plot(ls_xy[:n_ls, 0], ls_xy[:n_ls, 1],
                 'b-', linewidth=2.0, label='LIO-SAM')
        ax1.plot(fl_xy[:n_fl, 0], fl_xy[:n_fl, 1],
                 'r-', linewidth=2.0, label='FAST-LIO')

        ax1.set_xlim(xlim)
        ax1.set_ylim(ylim)
        ax1.set_xlabel('X [m]', fontsize=11)
        ax1.set_ylabel('Y [m]', fontsize=11)
        ax1.set_title('Trajectory (Top-Down XY)', fontsize=13, fontweight='bold')
        ax1.legend(loc='upper right', fontsize=10)
        ax1.set_aspect('equal')
        ax1.grid(True, alpha=0.3)

        # RIGHT: ATE over poses
        if n_ls_err > 0:
            ax2.plot(range(n_ls_err), ls_errors[:n_ls_err],
                     'b-', linewidth=1.5, label=f'LIO-SAM (RMSE={np.sqrt(np.mean(ls_errors**2)):.3f}m)')
        if n_fl_err > 0:
            ax2.plot(range(n_fl_err), fl_errors[:n_fl_err],
                     'r-', linewidth=1.5, label=f'FAST-LIO (RMSE={np.sqrt(np.mean(fl_errors**2)):.3f}m)')

        ax2.set_xlim(0, max_poses)
        ax2.set_ylim(0, max_ate)
        ax2.set_xlabel('Pose Index', fontsize=11)
        ax2.set_ylabel('ATE [m]', fontsize=11)
        ax2.set_title('Absolute Trajectory Error', fontsize=13, fontweight='bold')
        ax2.legend(loc='upper right', fontsize=10)
        ax2.grid(True, alpha=0.3)

        # Suptitle
        fig.suptitle('LIO-SAM vs FAST-LIO on Newer College Dataset',
                     fontsize=14, fontweight='bold', y=0.98)

        # Watermark
        fig.text(0.98, 0.02, 'Meryem Koç · github.com/codermery/lio-sam-vs-fast-lio-benchmark',
                 fontsize=7, color='gray', ha='right', va='bottom', alpha=0.7)

        plt.tight_layout(rect=[0, 0.03, 1, 0.95])
        plt.savefig(os.path.join(frame_dir, f'frame_{i:04d}.png'), dpi=100,
                    facecolor='white', bbox_inches='tight')
        plt.close()

        if (i + 1) % 50 == 0:
            print(f"  [{i+1}/{n_frames}] frames rendered")

    print(f"[video] All {n_frames} frames rendered.")

    # Assemble MP4
    mp4_path = os.path.join(args.results_dir, 'demo.mp4')
    print(f"[video] Assembling MP4: {mp4_path}")
    subprocess.run([
        'ffmpeg', '-y', '-framerate', str(args.fps),
        '-i', os.path.join(frame_dir, 'frame_%04d.png'),
        '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '23',
        '-vf', 'scale=1280:720',
        mp4_path
    ], check=True, capture_output=True)

    # Assemble GIF
    gif_path = os.path.join(args.results_dir, 'demo.gif')
    print(f"[video] Assembling GIF: {gif_path}")
    subprocess.run([
        'ffmpeg', '-y', '-i', mp4_path,
        '-vf', 'fps=10,scale=640:-1:flags=lanczos',
        '-loop', '0',
        gif_path
    ], check=True, capture_output=True)

    # Cleanup frames
    shutil.rmtree(frame_dir)

    # Report
    mp4_size = os.path.getsize(mp4_path) / (1024 * 1024)
    gif_size = os.path.getsize(gif_path) / (1024 * 1024)
    print(f"\n[video] Done!")
    print(f"  MP4: {mp4_path} ({mp4_size:.1f} MB)")
    print(f"  GIF: {gif_path} ({gif_size:.1f} MB)")


if __name__ == '__main__':
    main()
