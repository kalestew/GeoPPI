#!/bin/bash

# GeoPPI Installation Script for Wynton HPC - Clean Install
# Creates a fresh environment to avoid conflicts

echo "[GeoPPI Wynton Installer] Starting clean installation..."

# Load miniforge3 module as per Wynton HPC guidelines
module load CBI miniforge3

# Initialize conda for this shell session
eval "$(conda shell.bash hook)"

# Use a unique environment name for GeoPPI
ENV_NAME="geoppi"

# Remove existing environment if it exists
if conda env list | grep -q "^${ENV_NAME} "; then
    echo "[GeoPPI Wynton Installer] Removing existing '${ENV_NAME}' environment..."
    conda env remove -n ${ENV_NAME} -y
fi

# Create fresh conda environment
echo "[GeoPPI Wynton Installer] Creating fresh '${ENV_NAME}' conda environment with Python 3.8..."
conda create -n ${ENV_NAME} python=3.8 -y

# Activate the environment
echo "[GeoPPI Wynton Installer] Activating '${ENV_NAME}' environment..."
conda activate ${ENV_NAME}

# Verify activation
if [[ "$CONDA_DEFAULT_ENV" != "${ENV_NAME}" ]]; then
    echo "[GeoPPI Wynton Installer] ERROR: Failed to activate '${ENV_NAME}' environment"
    exit 1
fi

echo "[GeoPPI Wynton Installer] Active environment: $CONDA_DEFAULT_ENV"
echo "[GeoPPI Wynton Installer] Python location: $(which python)"
echo "[GeoPPI Wynton Installer] Pip location: $(which pip)"

# Download the pretrained model if missing
if [ ! -f "trainedmodels/gbt-s4169.pkl" ]; then
    echo "[GeoPPI Wynton Installer] Downloading GBT model..."
    mkdir -p trainedmodels
    wget https://media.githubusercontent.com/media/Liuxg16/largefiles/8167d5c365c92d08a81dffceff364f72d765805c/gbt-s4169.pkl -P trainedmodels/
fi

# Install dependencies in the correct order
echo "[GeoPPI Wynton Installer] Installing dependencies..."

# First install PyTorch CPU version (matching original GeoPPI requirements)
echo "[GeoPPI Wynton Installer] Installing PyTorch 1.7.0 CPU..."
pip install --no-cache-dir torch==1.7.0+cpu -f https://download.pytorch.org/whl/torch_stable.html

# Verify PyTorch installation
echo "[GeoPPI Wynton Installer] Verifying PyTorch installation..."
python -c "import torch; print(f'PyTorch version: {torch.__version__}')"

# Install PyTorch Geometric and its dependencies
echo "[GeoPPI Wynton Installer] Installing PyTorch Geometric extensions..."
pip install --no-cache-dir torch-cluster==1.5.8 -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html
pip install --no-cache-dir torch-scatter==2.0.5 -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html
pip install --no-cache-dir torch-sparse==0.6.8 -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html

# Install google-drive-downloader (required by torch-geometric)
pip install --no-cache-dir google-drive-downloader==0.4.0

# Install torch-geometric
pip install --no-cache-dir torch-geometric==1.4.1

# Install scikit-learn
echo "[GeoPPI Wynton Installer] Installing scikit-learn..."
pip install --no-cache-dir scikit-learn==0.24.1

# Install PyMOL from conda-forge (more reliable than schrodinger channel)
echo "[GeoPPI Wynton Installer] Installing PyMOL (open source)..."
conda install -c conda-forge pymol-open-source -y

# Additional dependencies that might be needed
echo "[GeoPPI Wynton Installer] Installing additional dependencies..."
pip install --no-cache-dir numpy==1.19.5  # Compatible with Python 3.8 and PyTorch 1.7
pip install --no-cache-dir scipy==1.6.0
pip install --no-cache-dir pandas==1.2.0
pip install --no-cache-dir matplotlib==3.3.4

# Test the installation
echo "[GeoPPI Wynton Installer] Testing installation..."
python -c "
import torch
print(f'✓ PyTorch {torch.__version__}')
import torch_geometric
print('✓ PyTorch Geometric')
import sklearn
print(f'✓ Scikit-learn {sklearn.__version__}')
import numpy
print(f'✓ NumPy {numpy.__version__}')
print('All core dependencies installed successfully!')
"

echo ""
echo "[GeoPPI Wynton Installer] Installation complete!"
echo ""
echo "=========================================="
echo "To use GeoPPI, activate the environment:"
echo "  module load CBI miniforge3"
echo "  conda activate ${ENV_NAME}"
echo ""
echo "Then run GeoPPI with:"
echo "  python run.py [pdb file] [Mutation] [partnerA_partnerB]"
echo ""
echo "Note: The original GeoPPI expects 'ppi' environment."
echo "You may need to update run.py if it has hardcoded paths."
echo "==========================================" 