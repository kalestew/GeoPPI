#!/bin/bash
# Activate GeoPPI environment following Wynton best practices

# Load miniforge3 (not miniconda3)
module load CBI miniforge3

# Initialize conda
eval "$(conda shell.bash hook)"

# Activate environment
conda activate geoppi_clean

# Disable user site-packages
export PYTHONNOUSERSITE=1

# Optional: Enable conda-stage for faster performance
# export CONDA_STAGE=true

echo "GeoPPI environment activated: geoppi_clean"
echo "Python: $(which python)"
echo "User packages: DISABLED"
