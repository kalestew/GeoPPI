#!/usr/bin/env python3
import csv
import os
import sys

# Configuration
job_name = "job_41D1_forGeoPPI_sat"
residue_file = "job_41D1_forGeoPPI_sat_residues.txt"
output_file = "job_41D1_forGeoPPI_sat_all_results.csv"
results_dir = f"results/{job_name}"

# Read all residues
with open(residue_file, 'r') as f:
    residues = [line.strip() for line in f if line.strip()]

print(f"Combining results for {len(residues)} residues...")

# Collect all results
all_results = []
missing_files = []

for residue in residues:
    result_file = os.path.join(results_dir, f"{residue}_saturation.csv")

    if not os.path.exists(result_file):
        missing_files.append(result_file)
        continue

    with open(result_file, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            all_results.append(row)

# Write combined results
if all_results:
    with open(output_file, 'w', newline='') as f:
        fieldnames = ["Residue", "Wildtype", "Mutation", "DDG (kcal/mol)"]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(all_results)

    print(f"Combined results written to {output_file}")
    print(f"Total mutations: {len(all_results)}")
else:
    print("No results found!")

if missing_files:
    print(f"\nWarning: {len(missing_files)} result files were missing:")
    for mf in missing_files[:5]:  # Show first 5
        print(f"  - {mf}")
    if len(missing_files) > 5:
        print(f"  ... and {len(missing_files)-5} more")
