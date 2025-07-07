#!/bin/bash
# Backup GeoPPI environment (Wynton best practice)

module load CBI miniforge3
eval "$(conda shell.bash hook)"

echo "Creating environment backup..."
conda env export --name geoppi | grep -v "^prefix: " > geoppi_backup.yml
echo "Backup saved to: geoppi_backup.yml"

# Also create minimal pip requirements
conda activate geoppi
pip freeze > geoppi_requirements.txt
echo "Requirements saved to: geoppi_requirements.txt"
