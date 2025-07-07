#!/bin/bash
# Backup GeoPPI environment (Wynton best practice)

module load CBI miniforge3
eval "$(conda shell.bash hook)"

echo "Creating environment backup..."
conda env export --name geoppi_clean | grep -v "^prefix: " > geoppi_clean_backup.yml
echo "Backup saved to: geoppi_clean_backup.yml"

# Also create minimal pip requirements
conda activate geoppi_clean
export PYTHONNOUSERSITE=1
pip freeze > geoppi_clean_requirements.txt
echo "Requirements saved to: geoppi_clean_requirements.txt"
