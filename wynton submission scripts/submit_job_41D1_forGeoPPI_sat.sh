#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -N job_41D1_forGeoPPI_sat
#$ -t 1-73
#$ -l h_rt=01:00:00
#$ -l mem_free=4G
#$ -j y

# Create logs directory if it doesn't exist
mkdir -p logs
mkdir -p results/job_41D1_forGeoPPI_sat

# Redirect all output to task-specific log file
exec > logs/job_41D1_forGeoPPI_sat_task_${SGE_TASK_ID}.log 2>&1

echo "=== SGE Task ${SGE_TASK_ID} Started ==="
echo "Job ID: ${JOB_ID}"
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
RESIDUE=$(sed -n "${SGE_TASK_ID}p" job_41D1_forGeoPPI_sat_residues.txt)

echo "Processing residue: $RESIDUE (task ${SGE_TASK_ID} of 73)"
echo "Environment: $(conda info --envs | grep '*')"
echo "Python: $(which python3)"

# Create unique scratch directory for this task
SCRATCH_DIR="/scratch/${USER}_${JOB_ID}_${SGE_TASK_ID}"
echo "Using scratch directory: $SCRATCH_DIR"
mkdir -p $SCRATCH_DIR

# Copy necessary files to scratch
echo "Copying files to scratch..."
cp -r GeoPPI $SCRATCH_DIR/
cp GeoPPI/41D1/41D1_forGeoPPI.pdb $SCRATCH_DIR/
cp single_residue_saturation.py $SCRATCH_DIR/

# Determine local PDB filename
PDB_LOCAL=$(basename GeoPPI/41D1/41D1_forGeoPPI.pdb)

# Change to scratch directory
cd $SCRATCH_DIR

# Run saturation mutagenesis for this residue
echo "Running saturation mutagenesis in scratch..."
python3 single_residue_saturation.py     $PDB_LOCAL     "$RESIDUE"     AB_C     ${RESIDUE}_saturation.csv

# Check if output was created
if [ -f "${RESIDUE}_saturation.csv" ]; then
    echo "Copying results back to shared filesystem..."
    cp ${RESIDUE}_saturation.csv ${SGE_O_WORKDIR}/results/job_41D1_forGeoPPI_sat/
    echo "Results copied successfully"
else
    echo "ERROR: No output file created!"
fi

# Clean up scratch directory
echo "Cleaning up scratch directory..."
cd ${SGE_O_WORKDIR}
rm -rf $SCRATCH_DIR

EXITCODE=$?
echo "Script exit code: $EXITCODE"
echo "End time: $(date)"
echo "=== SGE Task ${SGE_TASK_ID} Completed ==="
