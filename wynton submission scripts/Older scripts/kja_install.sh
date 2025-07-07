#!/bin/bash

# Load miniforge3 module as per Wynton HPC guidelines
module load CBI miniforge3

# Initialize conda for this shell session
eval "$(conda shell.bash hook)"

# Check if geoppi-env environment exists, if not create it
if ! conda env list | grep -q "geoppi-env"; then
    echo "[GeoPPI Installer] Creating geoppi-env conda environment..."
    conda create -n geoppi-env python=3.8 -y
else
    echo "[GeoPPI Installer] geoppi-env environment already exists."
fi

# Activate the geoppi-env Conda environment
conda activate geoppi-env

echo "[GeoPPI Installer] Active environment: $CONDA_DEFAULT_ENV"

# Verify we're in the right environment
if [[ "$CONDA_DEFAULT_ENV" != "geoppi-env" ]]; then
    echo "[GeoPPI Installer] ERROR: Failed to activate geoppi-env environment"
    exit 1
fi

# Re-download the pretrained model if missing
if [ ! -f "trainedmodels/gbt-s4169.pkl" ]; then
    echo "[GeoPPI Installer] Downloading GBT model..."
    mkdir -p trainedmodels
    wget https://media.githubusercontent.com/media/Liuxg16/largefiles/8167d5c365c92d08a81dffceff364f72d765805c/gbt-s4169.pkl -P trainedmodels/
fi

# Install required packages using pip and conda
echo "[GeoPPI Installer] Installing Python packages..."

# First install PyTorch CPU-only version
echo "[GeoPPI Installer] Installing PyTorch (CPU-only)..."
pip install torch==1.7.0+cpu torchvision==0.8.1+cpu torchaudio==0.7.0 -f https://download.pytorch.org/whl/torch_stable.html

# Then install PyTorch Geometric extensions (these need PyTorch to be installed first)
echo "[GeoPPI Installer] Installing PyTorch Geometric extensions..."
pip install torch-scatter==2.0.5 -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html
pip install torch-sparse==0.6.8 -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html
pip install torch-cluster==1.5.8 -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html

# Install PyTorch Geometric
echo "[GeoPPI Installer] Installing PyTorch Geometric..."
pip install torch-geometric==1.4.1

# Install scikit-learn with specific version
echo "[GeoPPI Installer] Installing scikit-learn..."
pip install scikit-learn==0.24.1

# Install PyMOL via conda-forge
echo "[GeoPPI Installer] Installing PyMOL (open source)..."
conda install -c conda-forge pymol-open-source -y

echo "[GeoPPI Installer] Environment setup complete."
echo "[GeoPPI Installer] You can now activate this environment with: conda activate geoppi-env"
