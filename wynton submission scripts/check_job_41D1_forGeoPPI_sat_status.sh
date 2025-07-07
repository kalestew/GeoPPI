#!/bin/bash
# Check status of saturation mutagenesis array job

echo "=== Saturation Mutagenesis Job Status ==="
echo "Job name: job_41D1_forGeoPPI_sat"
echo "Total residues: 73"
echo ""

# Check how many result files exist
COMPLETED=$(ls -1 results/job_41D1_forGeoPPI_sat/*_saturation.csv 2>/dev/null | wc -l)
echo "Completed: $COMPLETED / 73"

# Check for running jobs
RUNNING=$(qstat -u $USER | grep job_41D1_forGeoPPI_sat | wc -l)
echo "Currently running: $RUNNING"

# List missing results
echo ""
echo "Checking for missing results..."
for i in $(seq 1 73); do
    RESIDUE=$(sed -n "${i}p" job_41D1_forGeoPPI_sat_residues.txt)
    if [ ! -f "results/job_41D1_forGeoPPI_sat/${RESIDUE}_saturation.csv" ]; then
        echo "  Missing: $RESIDUE (task $i)"
    fi
done

echo ""
echo "To combine results when all jobs are complete, run:"
echo "  python3 combine_job_41D1_forGeoPPI_sat_results.py"
