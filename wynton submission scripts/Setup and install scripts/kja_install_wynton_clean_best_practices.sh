#!/bin/bash

# GeoPPI Installation Script for Wynton HPC - Clean Install with Best Practices
# Based on https://wynton.ucsf.edu/hpc/howto/conda.html

echo "=========================================="
echo "GeoPPI Clean Installation for Wynton HPC"
echo "Following Wynton conda best practices"
echo "=========================================="

# 1. Load miniforge3 module (NOT miniconda3 due to licensing)
module load CBI miniforge3

# 2. Initialize conda for this shell session
eval "$(conda shell.bash hook)"

# 3. Use a unique environment name to avoid conflicts
ENV_NAME="geoppi_clean"

# 4. Ensure complete removal of any existing environment
if conda env list | grep -q "^${ENV_NAME} "; then
    echo "[GeoPPI] Removing existing '${ENV_NAME}' environment..."
    conda deactivate 2>/dev/null || true
    conda env remove -n ${ENV_NAME} -y
    # Also remove the directory to ensure complete cleanup
    rm -rf "$HOME/.conda/envs/${ENV_NAME}"
fi

# 5. Create fresh conda environment with conda-forge as default channel
echo "[GeoPPI] Creating fresh '${ENV_NAME}' environment with Python 3.8..."
conda create -n ${ENV_NAME} -c conda-forge python=3.8 -y

# 6. Activate the environment
echo "[GeoPPI] Activating '${ENV_NAME}' environment..."
conda activate ${ENV_NAME}

# Verify activation
if [[ "$CONDA_DEFAULT_ENV" != "${ENV_NAME}" ]]; then
    echo "[GeoPPI] ERROR: Failed to activate '${ENV_NAME}' environment"
    exit 1
fi

# 7. Configure conda to use conda-forge by default (best practice)
conda config --add channels conda-forge
conda config --set channel_priority strict

# 8. Disable user site-packages to prevent conflicts
export PYTHONNOUSERSITE=1
export PIP_NO_WARN_SCRIPT_LOCATION=0

echo "[GeoPPI] Environment info:"
echo "  Active environment: $CONDA_DEFAULT_ENV"
echo "  Python: $(which python)"
echo "  Python version: $(python --version)"
echo "  User site-packages: DISABLED"

# 9. Download the pretrained model if missing
if [ ! -f "trainedmodels/gbt-s4169.pkl" ]; then
    echo "[GeoPPI] Downloading GBT model..."
    mkdir -p trainedmodels
    wget https://media.githubusercontent.com/media/Liuxg16/largefiles/8167d5c365c92d08a81dffceff364f72d765805c/gbt-s4169.pkl -P trainedmodels/
fi

# 10. Install packages in the correct order
echo "[GeoPPI] Installing dependencies..."

# Install numpy first via conda
echo "[GeoPPI] Installing NumPy via conda..."
conda install -c conda-forge numpy=1.19.5 -y

# Install PyTorch CPU version via pip (not available in conda-forge for this old version)
echo "[GeoPPI] Installing PyTorch 1.7.0 CPU..."
pip install --no-cache-dir --no-user torch==1.7.0+cpu -f https://download.pytorch.org/whl/torch_stable.html

# Install scipy via conda before PyTorch Geometric
echo "[GeoPPI] Installing SciPy via conda..."
conda install -c conda-forge scipy=1.6.0 -y

# Install PyTorch Geometric dependencies via pip
echo "[GeoPPI] Installing PyTorch Geometric extensions..."
pip install --no-cache-dir --no-user torch-cluster==1.5.8 -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html
pip install --no-cache-dir --no-user torch-scatter==2.0.5 -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html
pip install --no-cache-dir --no-user torch-sparse==0.6.8 -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html

# Install googledrivedownloader
pip install --no-cache-dir --no-user googledrivedownloader

# Install torch-geometric
pip install --no-cache-dir --no-user torch-geometric==1.4.1

# Fix google_drive_downloader compatibility issue with torch_geometric 1.4.1
echo "[GeoPPI] Fixing google_drive_downloader compatibility..."
SITE_PACKAGES=$(python -c "import site; print(site.getsitepackages()[0])")
mkdir -p "$SITE_PACKAGES/google_drive_downloader"
cat > "$SITE_PACKAGES/google_drive_downloader/__init__.py" << 'EOFIX'
# Wrapper to fix compatibility with torch_geometric 1.4.1
from googledrivedownloader.download import download_file_from_google_drive

class GoogleDriveDownloader:
    @staticmethod
    def download_file_from_google_drive(file_id, dest_path, overwrite=True, unzip=False):
        download_file_from_google_drive(file_id, dest_path, overwrite=overwrite, unzip=unzip)

# Also export the function directly
__all__ = ['GoogleDriveDownloader', 'download_file_from_google_drive']
EOFIX

# Install other dependencies via conda where possible
echo "[GeoPPI] Installing remaining scientific packages via conda..."
conda install -c conda-forge pandas=1.2.0 scikit-learn=0.24.1 matplotlib=3.3.4 -y

# Install BioPython
echo "[GeoPPI] Installing BioPython..."
pip install --no-cache-dir --no-user biopython

# Install PyMOL
echo "[GeoPPI] Installing PyMOL..."
conda install -c conda-forge pymol-open-source -y

# 11. Make environment conda-stage compatible
echo "[GeoPPI] Installing conda-pack for environment staging..."
conda install -c conda-forge conda-pack -y

# 12. Test the installation
echo "[GeoPPI] Testing installation..."
python -c "
import sys
print(f'Python: {sys.version}')
print(f'User site-packages disabled: {sys.flags.no_user_site}')

try:
    import torch
    print(f'✓ PyTorch {torch.__version__}')
except ImportError as e:
    print(f'✗ PyTorch: {e}')

try:
    import torch_scatter
    print('✓ torch-scatter')
    import torch_sparse
    print('✓ torch-sparse')
    import torch_cluster
    print('✓ torch-cluster')
except ImportError as e:
    print(f'✗ PyTorch extensions: {e}')

try:
    import torch_geometric
    print('✓ PyTorch Geometric')
except ImportError as e:
    print(f'✗ PyTorch Geometric: {e}')

try:
    import sklearn
    print(f'✓ Scikit-learn {sklearn.__version__}')
except ImportError as e:
    print(f'✗ Scikit-learn: {e}')

try:
    import numpy
    print(f'✓ NumPy {numpy.__version__}')
except ImportError as e:
    print(f'✗ NumPy: {e}')

try:
    import pandas
    print(f'✓ Pandas {pandas.__version__}')
except ImportError as e:
    print(f'✗ Pandas: {e}')

try:
    import Bio
    print(f'✓ BioPython {Bio.__version__}')
except ImportError as e:
    print(f'✗ BioPython: {e}')

print('\\nAll core dependencies installed successfully!')
"

# 13. Create activation script with best practices
cat > activate_geoppi_clean.sh << EOF
#!/bin/bash
# Activate GeoPPI environment following Wynton best practices

# Load miniforge3 (not miniconda3)
module load CBI miniforge3

# Initialize conda
eval "\$(conda shell.bash hook)"

# Activate environment
conda activate ${ENV_NAME}

# Disable user site-packages
export PYTHONNOUSERSITE=1

# Optional: Enable conda-stage for faster performance
# export CONDA_STAGE=true

echo "GeoPPI environment activated: ${ENV_NAME}"
echo "Python: \$(which python)"
echo "User packages: DISABLED"
EOF
chmod +x activate_geoppi_clean.sh

# 14. Create backup script as recommended
cat > backup_geoppi_clean_env.sh << EOF
#!/bin/bash
# Backup GeoPPI environment (Wynton best practice)

module load CBI miniforge3
eval "\$(conda shell.bash hook)"

echo "Creating environment backup..."
conda env export --name ${ENV_NAME} | grep -v "^prefix: " > ${ENV_NAME}_backup.yml
echo "Backup saved to: ${ENV_NAME}_backup.yml"

# Also create minimal pip requirements
conda activate ${ENV_NAME}
export PYTHONNOUSERSITE=1
pip freeze > ${ENV_NAME}_requirements.txt
echo "Requirements saved to: ${ENV_NAME}_requirements.txt"
EOF
chmod +x backup_geoppi_clean_env.sh

# 15. Show summary
echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Environment name: ${ENV_NAME}"
echo ""
echo "To use GeoPPI:"
echo "  source ./activate_geoppi_clean.sh"
echo ""
echo "To backup the environment:"
echo "  ./backup_geoppi_clean_env.sh"
echo ""
echo "To enable conda-stage (for better performance):"
echo "  export CONDA_STAGE=true"
echo ""
echo "Then run GeoPPI with:"
echo "  cd GeoPPI"
echo "  python run.py [pdb file] [Mutation] [partnerA_partnerB]"
echo ""
echo "Note: Following Wynton best practices:"
echo "  - Using miniforge3 (not miniconda3)"
echo "  - Using conda-forge channel"
echo "  - User site-packages disabled"
echo "  - conda-pack installed for staging"
echo "  - Clean environment (no conflicts)"
echo "==========================================" 