#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -N test_script
#$ -l h_rt=00:10:00
#$ -l mem_free=4G
#$ -j y
#$ -o test_script.log

# Load miniforge3 module (required for conda on Wynton)
module load CBI miniforge3

# Initialize conda
eval "$(conda shell.bash hook)"

# Activate GeoPPI environment
conda activate geoppi_clean

# Show environment
echo "Python: $(which python3)"
echo "Current directory: $(pwd)"

# Test a simple python command
echo "Testing Python..."
python3 -c "print('Python is working')" || echo "ERROR: Python failed"

# Check if script exists
echo "Checking script..."
ls -la single_residue_saturation.py || echo "ERROR: Script not found"

# Run the script with debugging
echo "Running script..."
python3 -u single_residue_saturation.py GeoPPI/41D1/41D1_forGeoPPI.pdb CA23 AB_C test_CA23_debug.csv 2>&1

echo "Exit code: $?"

# Check output
echo "Checking output file..."
ls -la test_CA23_debug.csv 2>&1 || echo "No output file created"

echo "Done at: $(date)" 