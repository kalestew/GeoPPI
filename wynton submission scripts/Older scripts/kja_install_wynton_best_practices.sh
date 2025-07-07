#!/bin/bash

# GeoPPI Installation Script for Wynton HPC - Following Best Practices
# Based on https://wynton.ucsf.edu/hpc/howto/conda.html

echo "=========================================="
echo "GeoPPI Installation for Wynton HPC"
echo "Following Wynton conda best practices"
echo "=========================================="

# 1. Load miniforge3 module (NOT miniconda3 due to licensing)
module load CBI miniforge3

# 2. Initialize conda for this shell session
eval "$(conda shell.bash hook)"

# 3. Use a unique environment name
ENV_NAME="geoppi"

# 4. Check and remove existing environment
if conda env list | grep -q "^${ENV_NAME} "; then
    echo "[GeoPPI] Removing existing '${ENV_NAME}' environment..."
    conda env remove -n ${ENV_NAME} -y
fi

# 5. Create fresh conda environment with conda-forge as default channel
echo "[GeoPPI] Creating '${ENV_NAME}' environment with Python 3.8..."
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

# 10. Install packages using conda where possible (preferred over pip)
echo "[GeoPPI] Installing core dependencies via conda..."

# Install numpy via conda first
conda install -c conda-forge numpy=1.19.5 -y

# 11. Install pip packages with --no-user flag
echo "[GeoPPI] Installing PyTorch and related packages..."

# Install PyTorch CPU version
pip install --no-cache-dir --no-user torch==1.7.0+cpu -f https://download.pytorch.org/whl/torch_stable.html

# Install PyTorch Geometric dependencies
pip install --no-cache-dir --no-user torch-cluster==1.5.8 -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html
pip install --no-cache-dir --no-user torch-scatter==2.0.5 -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html
pip install --no-cache-dir --no-user torch-sparse==0.6.8 -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html

# Install googledrivedownloader (correct package name)
pip install --no-cache-dir --no-user googledrivedownloader

# Install torch-geometric
pip install --no-cache-dir --no-user torch-geometric==1.4.1

# Install other dependencies via conda where possible
echo "[GeoPPI] Installing scientific packages..."
conda install -c conda-forge scipy=1.6.0 pandas=1.2.0 scikit-learn=0.24.1 matplotlib=3.3.4 -y

# Install PyMOL
echo "[GeoPPI] Installing PyMOL..."
conda install -c conda-forge pymol-open-source -y

# 12. Make environment conda-stage compatible
echo "[GeoPPI] Installing conda-pack for environment staging..."
conda install -c conda-forge conda-pack -y

# 13. Test the installation
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
"

# 14. Create activation script with best practices
cat > activate_geoppi.sh << 'EOF'
#!/bin/bash
# Activate GeoPPI environment following Wynton best practices

# Load miniforge3 (not miniconda3)
module load CBI miniforge3

# Initialize conda
eval "$(conda shell.bash hook)"

# Activate environment
conda activate geoppi

# Disable user site-packages
export PYTHONNOUSERSITE=1

# Optional: Enable conda-stage for faster performance
# export CONDA_STAGE=true

echo "GeoPPI environment activated"
echo "Python: $(which python)"
echo "User packages: DISABLED"
EOF
chmod +x activate_geoppi.sh

# 15. Create backup script as recommended
cat > backup_geoppi_env.sh << 'EOF'
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
EOF
chmod +x backup_geoppi_env.sh

# 16. Show summary
echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "To use GeoPPI:"
echo "  source ./activate_geoppi.sh"
echo ""
echo "To backup the environment:"
echo "  ./backup_geoppi_env.sh"
echo ""
echo "To enable conda-stage (for better performance):"
echo "  export CONDA_STAGE=true"
echo ""
echo "Then run GeoPPI with:"
echo "  python run.py [pdb file] [Mutation] [partnerA_partnerB]"
echo ""
echo "Note: Following Wynton best practices:"
echo "  - Using miniforge3 (not miniconda3)"
echo "  - Using conda-forge channel"
echo "  - User site-packages disabled"
echo "  - conda-pack installed for staging"
echo "==========================================" 