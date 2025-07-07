#!/usr/bin/env python3
"""
Script to run saturation mutagenesis for a single residue position.
This is designed to be called by an SGE array job.

Usage:
    python single_residue_saturation.py <pdbfile> <mutation> <partner_info> <output_file>
    
Example:
    python single_residue_saturation.py 1CZ8.pdb KW84 WV_HL KW84_saturation.csv
"""

import os
import subprocess
import sys
import csv

# Canonical amino acids (1-letter code)
aa_codes = ['A','R','N','D','C','Q','E','G','H','I',
            'L','K','M','F','P','S','T','W','Y','V']

def run_prediction(pdbfile, mutation, partner_info):
    """Run GeoPPI prediction for a single mutation"""
    # Need to run from GeoPPI directory where the trained models are
    cmd = f"cd GeoPPI && python3 run.py ../{pdbfile} {mutation} {partner_info}"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    output = result.stdout

    ddg = None
    for line in output.splitlines():
        if "The predicted binding affinity change" in line:
            ddg = line.strip().split("is")[1].split("kcal")[0].strip()
            break

    if ddg is None:
        print(f"Warning: Could not extract DDG for {mutation}")
        print(f"--- run.py output ---")
        print(output)
        print("--------------------")

    return ddg, output

def main():
    if len(sys.argv) != 5:
        print("Usage: python single_residue_saturation.py <pdbfile> <residue> <partner_info> <output_file>")
        print("Example: python single_residue_saturation.py 1CZ8.pdb KW84 WV_HL KW84_saturation.csv")
        sys.exit(1)

    pdbfile = sys.argv[1]
    residue = sys.argv[2]      # E.g. KW84
    partner_info = sys.argv[3]
    output_file = sys.argv[4]

    # Parse residue information
    wildtype = residue[0]
    chain = residue[1]
    resid = residue[2:]
    
    print(f"Running saturation mutagenesis for {chain}{resid} (wildtype: {wildtype})")
    
    # Write results to CSV
    with open(output_file, "w", newline='') as outcsv:
        writer = csv.writer(outcsv)
        writer.writerow(["Residue", "Wildtype", "Mutation", "DDG (kcal/mol)"])

        for mutant in aa_codes:
            if mutant == wildtype:
                # Skip wildtype to wildtype mutation
                writer.writerow([f"{chain}{resid}", wildtype, mutant, "0.0"])
                continue
                
            mutation_str = f"{wildtype}{chain}{resid}{mutant}"
            print(f"  Running {mutation_str}...")
            
            ddg, _ = run_prediction(pdbfile, mutation_str, partner_info)
            writer.writerow([f"{chain}{resid}", wildtype, mutant, ddg if ddg else "error"])
            print(f"  {mutation_str}: {ddg}")
    
    print(f"Results saved to {output_file}")

if __name__ == "__main__":
    main() 