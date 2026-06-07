#!/usr/bin/env python3
"""Convert Newer College ground truth CSV to TUM format.

Input CSV format: #sec,nsec,x,y,z,qx,qy,qz,qw
Output TUM format: timestamp tx ty tz qx qy qz qw

Usage: python3 csv_to_tum.py <input.csv> <output.tum>
"""
import csv
import sys


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.csv> <output.tum>")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2]

    lines = []
    with open(input_path) as f:
        reader = csv.reader(f)
        header = next(reader)
        for row in reader:
            sec, nsec = int(row[0]), int(row[1])
            timestamp = sec + nsec * 1e-9
            x, y, z = row[2], row[3], row[4]
            qx, qy, qz, qw = row[5], row[6], row[7], row[8]
            lines.append(f"{timestamp:.9f} {x} {y} {z} {qx} {qy} {qz} {qw}")

    with open(output_path, 'w') as f:
        f.write('\n'.join(lines) + '\n')

    print(f"Converted {len(lines)} poses: {input_path} -> {output_path}")


if __name__ == '__main__':
    main()
