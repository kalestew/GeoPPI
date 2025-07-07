#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -N test_env
#$ -l h_rt=00:05:00
#$ -l mem_free=1G
#$ -j y
#$ -o test_env.log

echo "Starting test at: $(date)"
echo "Hostname: $(hostname)"
echo "Current directory: $(pwd)"

# Check if module command exists
echo "Checking module command..."
which module || echo "ERROR: module command not found"

# Try to load miniforge3
echo "Loading miniforge3 module..."
module load CBI miniforge3 2>&1 || echo "ERROR: Failed to load module"

echo "Checking conda..."
which conda || echo "ERROR: conda not found"

echo "Test completed at: $(date)" 