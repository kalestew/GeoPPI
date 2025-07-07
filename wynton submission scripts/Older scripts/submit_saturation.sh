#!/bin/bash

# GeoPPI Saturation Mutagenesis Job Submission Script - Wynton HPC
# Usage: ./submit_saturation.sh <pdbfile> <resid_list> <partner_info>
#
# This script follows Wynton best practices for conda environments:
# - Uses miniforge3 (not miniconda3)
# - Properly activates conda environment (geoppi_clean)
# - Disables user site-packages

if [ $# -ne 3 ]; then
    echo "Usage: $0 <pdbfile> <resid_list> <partner_info>"
    echo "Example: $0 1CZ8.pdb \"KW84 HL112\" WV_HL"
    exit 1
fi

PDBFILE=$1
RESID_LIST=$2
PARTNER_INFO=$3

# Get absolute path of PDB file
PDBFILE_ABS=$(readlink -f "$PDBFILE")

# Verify PDB file exists
if [ ! -f "$PDBFILE_ABS" ]; then
    echo "ERROR: PDB file not found: $PDBFILE"
    exit 1
fi

# Create a job-specific script
JOB_NAME="saturation_$(basename ${PDBFILE%.pdb})"
JOB_SCRIPT="job_${JOB_NAME}.sh"

cat > $JOB_SCRIPT << EOF
#!/bin/bash
#PBS -N ${JOB_NAME}
#PBS -l nodes=1:ppn=1
#PBS -l mem=8gb
#PBS -l walltime=24:00:00
#PBS -e ${JOB_NAME}.err
#PBS -o ${JOB_NAME}.out
#PBS -V

# Wynton best practices: Load miniforge3 (NOT miniconda3)
module load CBI miniforge3

# Initialize conda for this shell session
eval "\$(conda shell.bash hook)"

# Activate the geoppi_clean environment
conda activate geoppi_clean

# Verify environment is activated
if [ "\$CONDA_DEFAULT_ENV" != "geoppi_clean" ]; then
    echo "ERROR: Failed to activate geoppi_clean conda environment"
    exit 1
fi

# Disable user site-packages (Wynton best practice)
export PYTHONNOUSERSITE=1

# Optional: Enable conda-stage for better performance
# export CONDA_STAGE=true

# Log environment info
echo "=========================================="
echo "GeoPPI Saturation Mutagenesis Job"
echo "=========================================="
echo "Hostname: \$(hostname)"
echo "Date: \$(date)"
echo "PBS Job ID: \$PBS_JOBID"
echo "Working directory: \$PBS_O_WORKDIR"
echo "Conda environment: \$CONDA_DEFAULT_ENV"
echo "Python: \$(which python)"
echo "Python version: \$(python --version)"
echo "User site-packages: DISABLED"
echo "=========================================="

# Change to submission directory
cd \$PBS_O_WORKDIR

# Run the saturation mutagenesis
python /wynton/home/craik/kjander/GeoPPI/GeoPPI/batch_saturation_qsub.py "$PDBFILE_ABS" "$RESID_LIST" "$PARTNER_INFO"

# Capture exit code
EXIT_CODE=\$?

echo "=========================================="
echo "Job completed with exit code: \$EXIT_CODE"
echo "End time: \$(date)"
echo "=========================================="

exit \$EXIT_CODE
EOF

echo "Submitting GeoPPI saturation mutagenesis job:"
echo "  PDB: $PDBFILE"
echo "  Positions: $RESID_LIST"
echo "  Partner: $PARTNER_INFO"
echo ""
echo "Job script: $JOB_SCRIPT"
echo ""

# Submit the job
qsub $JOB_SCRIPT

# Save job parameters for reference
cat > ${JOB_NAME}_params.txt << EOF
GeoPPI Saturation Mutagenesis Parameters
========================================
PDB file: $PDBFILE_ABS
Positions: $RESID_LIST
Partner info: $PARTNER_INFO
Job script: $JOB_SCRIPT
Submitted: $(date)
EOF

echo "Job parameters saved to: ${JOB_NAME}_params.txt" 