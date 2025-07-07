#!/bin/bash

# Fix existing ppi environment

module load CBI miniforge3
eval "$(conda shell.bash hook)"
conda activate ppi

# Install missing dependency
echo "Installing google-drive-downloader..."
pip install --no-cache-dir google-drive-downloader==0.4.0

# Try to install PyMOL with --force-reinstall
echo "Installing PyMOL..."
conda install -c conda-forge pymol-open-source --force-reinstall -y

# Test
echo "Testing..."
python -c "
import torch_geometric
print('✓ PyTorch Geometric working')
"

echo "Fix complete. PyMOL may still have issues due to the conflicts." 