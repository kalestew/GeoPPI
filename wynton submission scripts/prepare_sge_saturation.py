#!/usr/bin/env python3
"""
Script to prepare SGE array job for batch saturation mutagenesis on Wynton.

This script:
1. Takes output from prepare_batch_saturation.py
2. Creates a residue list file
3. Generates an SGE array job submission script
4. Generates a result combination script

Usage:
    python prepare_sge_saturation.py <pdb_file> "<residue_list>" <partner_info> [job_name]
    
Example:
    python prepare_sge_saturation.py 41D1_forGeoPPI.pdb "SB133 GB134 FB135" AB_C 41D1_sat
"""

import sys
import os
import textwrap

def create_sge_script(pdb_file, residue_file, partner_info, job_name, num_residues):
    """Generate the SGE array job submission script"""
    
    script_content = textwrap.dedent(f"""#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -N {job_name}
#$ -t 1-{num_residues}
#$ -l h_rt=01:00:00
#$ -l mem_free=4G
#$ -j y

# Create logs directory if it doesn't exist
mkdir -p logs
mkdir -p results/{job_name}

# Redirect all output to task-specific log file
exec > logs/{job_name}_task_${{SGE_TASK_ID}}.log 2>&1

echo "=== SGE Task ${{SGE_TASK_ID}} Started ==="
echo "Job ID: ${{JOB_ID}}"
echo "Hostname: $(hostname)"
echo "Start time: $(date)"

# Load miniforge3 module (required for conda on Wynton)
module load CBI miniforge3

# Initialize conda
eval "$(conda shell.bash hook)"

# Activate GeoPPI environment
conda activate geoppi_clean

# Disable user site-packages
export PYTHONNOUSERSITE=1

# Get the residue for this array task
RESIDUE=$(sed -n "${{SGE_TASK_ID}}p" {residue_file})

echo "Processing residue: $RESIDUE (task ${{SGE_TASK_ID}} of {num_residues})"
echo "Environment: $(conda info --envs | grep '*')"
echo "Python: $(which python3)"

# Create unique scratch directory for this task
SCRATCH_DIR="/scratch/${{USER}}_${{JOB_ID}}_${{SGE_TASK_ID}}"
echo "Using scratch directory: $SCRATCH_DIR"
mkdir -p $SCRATCH_DIR

# Copy necessary files to scratch
echo "Copying files to scratch..."
cp -r GeoPPI $SCRATCH_DIR/
cp {pdb_file} $SCRATCH_DIR/
cp single_residue_saturation.py $SCRATCH_DIR/

# Determine local PDB filename
PDB_LOCAL=$(basename {pdb_file})

# Change to scratch directory
cd $SCRATCH_DIR

# Run saturation mutagenesis for this residue
echo "Running saturation mutagenesis in scratch..."
python3 single_residue_saturation.py \
    $PDB_LOCAL \
    "$RESIDUE" \
    {partner_info} \
    ${{RESIDUE}}_saturation.csv

# Check if output was created
if [ -f "${{RESIDUE}}_saturation.csv" ]; then
    echo "Copying results back to shared filesystem..."
    cp ${{RESIDUE}}_saturation.csv ${{SGE_O_WORKDIR}}/results/{job_name}/
    echo "Results copied successfully"
else
    echo "ERROR: No output file created!"
fi

# Clean up scratch directory
echo "Cleaning up scratch directory..."
cd ${{SGE_O_WORKDIR}}
rm -rf $SCRATCH_DIR

EXITCODE=$?
echo "Script exit code: $EXITCODE"
echo "End time: $(date)"
echo "=== SGE Task ${{SGE_TASK_ID}} Completed ==="
""")
    
    return script_content

def create_combine_script(job_name, num_residues, residue_file, output_file):
    """Generate script to combine all individual CSV results"""
    
    script_content = textwrap.dedent(f"""#!/usr/bin/env python3
import csv
import os
import sys

# Configuration
job_name = "{job_name}"
residue_file = "{residue_file}"
output_file = "{output_file}"
results_dir = f"results/{{job_name}}"

# Read all residues
with open(residue_file, 'r') as f:
    residues = [line.strip() for line in f if line.strip()]

print(f"Combining results for {{len(residues)}} residues...")

# Collect all results
all_results = []
missing_files = []

for residue in residues:
    result_file = os.path.join(results_dir, f"{{residue}}_saturation.csv")
    
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
    
    print(f"Combined results written to {{output_file}}")
    print(f"Total mutations: {{len(all_results)}}")
else:
    print("No results found!")

if missing_files:
    print(f"\\nWarning: {{len(missing_files)}} result files were missing:")
    for mf in missing_files[:5]:  # Show first 5
        print(f"  - {{mf}}")
    if len(missing_files) > 5:
        print(f"  ... and {{len(missing_files)-5}} more")
""")
    
    return script_content

def create_check_status_script(job_name, num_residues, residue_file):
    """Generate script to check job completion status"""
    
    script_content = textwrap.dedent(f"""#!/bin/bash
# Check status of saturation mutagenesis array job

echo "=== Saturation Mutagenesis Job Status ==="
echo "Job name: {job_name}"
echo "Total residues: {num_residues}"
echo ""

# Check how many result files exist
COMPLETED=$(ls -1 results/{job_name}/*_saturation.csv 2>/dev/null | wc -l)
echo "Completed: $COMPLETED / {num_residues}"

# Check for running jobs
RUNNING=$(qstat -u $USER | grep {job_name} | wc -l)
echo "Currently running: $RUNNING"

# List missing results
echo ""
echo "Checking for missing results..."
for i in $(seq 1 {num_residues}); do
    RESIDUE=$(sed -n "${{i}}p" {residue_file})
    if [ ! -f "results/{job_name}/${{RESIDUE}}_saturation.csv" ]; then
        echo "  Missing: $RESIDUE (task $i)"
    fi
done

echo ""
echo "To combine results when all jobs are complete, run:"
echo "  python3 combine_{job_name}_results.py"
""")
    
    return script_content

def main():
    if len(sys.argv) < 4 or len(sys.argv) > 5:
        print("Usage: python prepare_sge_saturation.py <pdb_file> \"<residue_list>\" <partner_info> [job_name]")
        print("Example: python prepare_sge_saturation.py 41D1_forGeoPPI.pdb \"SB133 GB134 FB135\" AB_C 41D1_sat")
        sys.exit(1)
    
    pdb_file = sys.argv[1]
    residue_list = sys.argv[2]
    partner_info = sys.argv[3]
    
    # Generate job name from PDB file if not provided
    if len(sys.argv) == 5:
        job_name = sys.argv[4]
    else:
        job_name = os.path.splitext(os.path.basename(pdb_file))[0] + "_sat"
    
    # Clean job name for SGE (remove special characters)
    job_name = job_name.replace('.', '_').replace('-', '_')
    
    # SGE job names cannot start with a digit - prefix with 'job_' if needed
    if job_name and job_name[0].isdigit():
        job_name = 'job_' + job_name
    
    # Parse residues
    residues = residue_list.split()
    num_residues = len(residues)
    
    if num_residues == 0:
        print("Error: No residues provided")
        sys.exit(1)
    
    # Create necessary directories
    os.makedirs("logs", exist_ok=True)
    os.makedirs(f"results/{job_name}", exist_ok=True)
    
    # Create residue list file
    residue_file = f"{job_name}_residues.txt"
    with open(residue_file, 'w') as f:
        for res in residues:
            f.write(f"{res}\n")
    
    # Create SGE submission script
    sge_script = f"submit_{job_name}.sh"
    with open(sge_script, 'w') as f:
        f.write(create_sge_script(pdb_file, residue_file, partner_info, job_name, num_residues))
    os.chmod(sge_script, 0o755)
    
    # Create combination script
    combine_script = f"combine_{job_name}_results.py"
    output_csv = f"{job_name}_all_results.csv"
    with open(combine_script, 'w') as f:
        f.write(create_combine_script(job_name, num_residues, residue_file, output_csv))
    os.chmod(combine_script, 0o755)
    
    # Create status check script
    status_script = f"check_{job_name}_status.sh"
    with open(status_script, 'w') as f:
        f.write(create_check_status_script(job_name, num_residues, residue_file))
    os.chmod(status_script, 0o755)
    
    # Print summary
    print(f"\n=== SGE Array Job Prepared ===")
    print(f"Job name: {job_name}")
    print(f"PDB file: {pdb_file}")
    print(f"Partner info: {partner_info}")
    print(f"Number of residues: {num_residues}")
    print(f"Number of mutations per residue: 19")
    print(f"Total mutations to calculate: {num_residues * 19}")
    print(f"\nGenerated files:")
    print(f"  - {residue_file} (list of residues)")
    print(f"  - {sge_script} (SGE submission script)")
    print(f"  - {combine_script} (result combination script)")
    print(f"  - {status_script} (job status check script)")
    print(f"\nTo submit the job:")
    print(f"  qsub {sge_script}")
    print(f"\nTo check job status:")
    print(f"  ./{status_script}")
    print(f"\nTo view job logs:")
    print(f"  ls logs/{job_name}_task_*.log")
    print(f"\nTo combine results after completion:")
    print(f"  python3 {combine_script}")
    print(f"\nResults will be saved to: {output_csv}")

if __name__ == "__main__":
    main() 