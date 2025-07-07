#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -N test_single_sat
#$ -l h_rt=00:10:00
#$ -l mem_free=4G
#$ -j y
#$ -o test_single_sat.log

# Load miniforge3 module (required for conda on Wynton)
module load CBI miniforge3

# Initialize conda
eval "$(conda shell.bash hook)"

# Activate GeoPPI environment
conda activate geoppi_clean

# Disable user site-packages
export PYTHONNOUSERSITE=1

echo "===== Environment Setup ====="
echo "Conda environment: $(conda info --envs | grep '*')"
echo "Python: $(which python3)"
echo "Python version: $(python3 --version)"
echo "Current directory: $(pwd)"
echo "============================="

# Test with CA23
RESIDUE="CA23"
PDB_FILE="GeoPPI/41D1/41D1_forGeoPPI.pdb"
PARTNER_INFO="AB_C"
OUTPUT_FILE="test_CA23_sge.csv"

echo "Running single_residue_saturation.py with:"
echo "  PDB: $PDB_FILE"
echo "  Residue: $RESIDUE"
echo "  Partners: $PARTNER_INFO"
echo "  Output: $OUTPUT_FILE"

# Run with explicit error checking
python3 single_residue_saturation.py "$PDB_FILE" "$RESIDUE" "$PARTNER_INFO" "$OUTPUT_FILE"
EXITCODE=$?

echo "Exit code: $EXITCODE"

# Check if output file was created
if [ -f "$OUTPUT_FILE" ]; then
    echo "Output file created successfully"
    echo "File size: $(ls -la $OUTPUT_FILE)"
    echo "First 5 lines:"
    head -5 "$OUTPUT_FILE"
else
    echo "ERROR: Output file was not created"
fi

echo "Job completed at: $(date)" 