#!/usr/bin/env python3
"""
Evaluate LIO-SAM and FAST-LIO trajectories against ground truth.
Uses the evo library Python API for ATE (APE) and RPE metrics.

Usage:
    python3 evaluate.py \
        --gt groundtruth_tum.txt \
        --lio-sam lio_sam_trajectory.tum \
        --fast-lio fast_lio_trajectory.tum \
        --output-dir results/
"""

import argparse
import os
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from evo.core import metrics, sync
from evo.core.metrics import PoseRelation, Unit
from evo.core.trajectory import PoseTrajectory3D
from evo.tools import file_interface


def load_trajectory(path: str) -> PoseTrajectory3D:
    """Load a TUM-format trajectory file."""
    return file_interface.read_tum_trajectory_file(path)


def compute_ate(ref: PoseTrajectory3D, est: PoseTrajectory3D):
    """Compute Absolute Trajectory Error (APE, translation part)."""
    ref_sync, est_sync = sync.associate_trajectories(ref, est)

    est_aligned = est_sync.copy()
    est_aligned.align(ref_sync, correct_scale=False)

    ape_metric = metrics.APE(PoseRelation.translation_part)
    ape_metric.process_data((ref_sync, est_aligned))

    return ape_metric, ref_sync, est_aligned


def compute_rpe(ref: PoseTrajectory3D, est: PoseTrajectory3D, delta: float = 1.0):
    """Compute Relative Pose Error (translation, delta=1.0s)."""
    ref_sync, est_sync = sync.associate_trajectories(ref, est)

    est_aligned = est_sync.copy()
    est_aligned.align(ref_sync, correct_scale=False)

    rpe_metric = metrics.RPE(
        PoseRelation.translation_part,
        delta=delta,
        delta_unit=Unit.seconds,
        all_pairs=False
    )
    rpe_metric.process_data((ref_sync, est_aligned))

    return rpe_metric


def plot_trajectories(gt: PoseTrajectory3D,
                      lio_sam_aligned: PoseTrajectory3D,
                      fast_lio_aligned: PoseTrajectory3D,
                      output_path: str):
    """Plot top-down XY trajectory comparison."""
    fig, ax = plt.subplots(1, 1, figsize=(10, 10))

    gt_xyz = gt.positions_xyz
    ls_xyz = lio_sam_aligned.positions_xyz
    fl_xyz = fast_lio_aligned.positions_xyz

    ax.plot(gt_xyz[:, 0], gt_xyz[:, 1], 'k-', linewidth=2, label='Ground Truth')
    ax.plot(ls_xyz[:, 0], ls_xyz[:, 1], 'b-', linewidth=1.5, label='LIO-SAM', alpha=0.8)
    ax.plot(fl_xyz[:, 0], fl_xyz[:, 1], 'r-', linewidth=1.5, label='FAST-LIO', alpha=0.8)

    ax.set_xlabel('X [m]', fontsize=12)
    ax.set_ylabel('Y [m]', fontsize=12)
    ax.set_title('Trajectory Comparison (Top-Down XY)', fontsize=14)
    ax.legend(fontsize=12)
    ax.set_aspect('equal')
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"[evaluate] Saved trajectory plot: {output_path}")


def plot_ate_over_poses(lio_sam_ape: metrics.APE,
                        fast_lio_ape: metrics.APE,
                        output_path: str):
    """Plot ATE over pose index for both algorithms."""
    fig, ax = plt.subplots(1, 1, figsize=(12, 5))

    ls_errors = lio_sam_ape.error
    fl_errors = fast_lio_ape.error

    ax.plot(range(len(ls_errors)), ls_errors, 'b-', linewidth=1, label='LIO-SAM', alpha=0.8)
    ax.plot(range(len(fl_errors)), fl_errors, 'r-', linewidth=1, label='FAST-LIO', alpha=0.8)

    ax.set_xlabel('Pose Index', fontsize=12)
    ax.set_ylabel('ATE [m]', fontsize=12)
    ax.set_title('Absolute Trajectory Error Over Time', fontsize=14)
    ax.legend(fontsize=12)
    ax.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"[evaluate] Saved ATE plot: {output_path}")


def build_metrics_table(lio_sam_ape, fast_lio_ape, lio_sam_rpe, fast_lio_rpe):
    """Build a comparison DataFrame."""
    data = {
        'Algorithm': ['LIO-SAM', 'FAST-LIO'],
        'ATE RMSE [m]': [
            lio_sam_ape.get_statistic(metrics.StatisticsType.rmse),
            fast_lio_ape.get_statistic(metrics.StatisticsType.rmse),
        ],
        'ATE Mean [m]': [
            lio_sam_ape.get_statistic(metrics.StatisticsType.mean),
            fast_lio_ape.get_statistic(metrics.StatisticsType.mean),
        ],
        'ATE Max [m]': [
            lio_sam_ape.get_statistic(metrics.StatisticsType.max),
            fast_lio_ape.get_statistic(metrics.StatisticsType.max),
        ],
        'RPE RMSE [m]': [
            lio_sam_rpe.get_statistic(metrics.StatisticsType.rmse),
            fast_lio_rpe.get_statistic(metrics.StatisticsType.rmse),
        ],
        'RPE Mean [m]': [
            lio_sam_rpe.get_statistic(metrics.StatisticsType.mean),
            fast_lio_rpe.get_statistic(metrics.StatisticsType.mean),
        ],
    }
    return pd.DataFrame(data)


def main():
    parser = argparse.ArgumentParser(description='Evaluate LIO-SAM vs FAST-LIO')
    parser.add_argument('--gt', required=True, help='Ground truth TUM file')
    parser.add_argument('--lio-sam', required=True, help='LIO-SAM trajectory TUM file')
    parser.add_argument('--fast-lio', required=True, help='FAST-LIO trajectory TUM file')
    parser.add_argument('--output-dir', required=True, help='Output directory for plots and tables')
    args = parser.parse_args()

    os.makedirs(args.output_dir, exist_ok=True)

    print("[evaluate] Loading trajectories...")
    gt_traj = load_trajectory(args.gt)
    ls_traj = load_trajectory(args.lio_sam)
    fl_traj = load_trajectory(args.fast_lio)

    print(f"[evaluate] GT poses: {gt_traj.num_poses}")
    print(f"[evaluate] LIO-SAM poses: {ls_traj.num_poses}")
    print(f"[evaluate] FAST-LIO poses: {fl_traj.num_poses}")

    # ATE (APE translation)
    print("[evaluate] Computing ATE...")
    ls_ape, gt_sync_ls, ls_aligned = compute_ate(gt_traj, ls_traj)
    fl_ape, gt_sync_fl, fl_aligned = compute_ate(gt_traj, fl_traj)

    # RPE (translation, delta=1.0s)
    print("[evaluate] Computing RPE (delta=1.0s)...")
    ls_rpe = compute_rpe(gt_traj, ls_traj, delta=1.0)
    fl_rpe = compute_rpe(gt_traj, fl_traj, delta=1.0)

    # Plots
    print("[evaluate] Generating plots...")
    plot_trajectories(
        gt_sync_ls, ls_aligned, fl_aligned,
        os.path.join(args.output_dir, 'trajectory_xy.png')
    )
    plot_ate_over_poses(
        ls_ape, fl_ape,
        os.path.join(args.output_dir, 'ate_comparison.png')
    )

    # Metrics table
    df = build_metrics_table(ls_ape, fl_ape, ls_rpe, fl_rpe)

    print("\n" + "=" * 60)
    print("BENCHMARK RESULTS: LIO-SAM vs FAST-LIO")
    print("Dataset: Newer College - short_experiment")
    print("=" * 60)
    print(df.to_string(index=False))
    print("=" * 60 + "\n")

    # Save CSV
    csv_path = os.path.join(args.output_dir, 'metrics_table.csv')
    df.to_csv(csv_path, index=False)
    print(f"[evaluate] Saved CSV: {csv_path}")

    # Save Markdown
    md_path = os.path.join(args.output_dir, 'metrics_table.md')
    with open(md_path, 'w') as f:
        f.write("# Benchmark Results: LIO-SAM vs FAST-LIO\n\n")
        f.write("**Dataset:** Newer College - short_experiment (Ouster OS-1 64-beam)\n\n")
        f.write(df.to_markdown(index=False))
        f.write("\n\n*Alignment: SE(3) Umeyama, correct_scale=False*\n")
        f.write("*RPE delta: 1.0 seconds*\n")
    print(f"[evaluate] Saved Markdown: {md_path}")


if __name__ == '__main__':
    main()
