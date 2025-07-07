#!/bin/bash

# GeoPPI Installation Check Script

echo "=========================================="
echo "GeoPPI Installation Diagnostic"
echo "=========================================="

# Load miniforge3
module load CBI miniforge3
eval "$(conda shell.bash hook)"

# Check which environments exist
echo -e "\nAvailable conda environments:"
conda env list | grep -E "(ppi|geoppi)"

# Function to check an environment
check_env() {
    local env_name=$1
    echo -e "\n--- Checking environment: $env_name ---"
    
    if ! conda env list | grep -q "^$env_name "; then
        echo "Environment '$env_name' not found"
        return
    fi
    
    conda activate $env_name
    
    if [[ "$CONDA_DEFAULT_ENV" != "$env_name" ]]; then
        echo "Failed to activate environment"
        return
    fi
    
    echo "Python: $(which python)"
    echo "Python version: $(python --version)"
    
    # Check core dependencies
    python -c "
import sys
print(f'Python: {sys.version}')
try:
    import torch
    print(f'✓ PyTorch: {torch.__version__}')
except ImportError as e:
    print(f'✗ PyTorch: {e}')

try:
    import torch_scatter
    print(f'✓ torch-scatter')
except ImportError as e:
    print(f'✗ torch-scatter: {e}')

try:
    import torch_sparse
    print(f'✓ torch-sparse')
except ImportError as e:
    print(f'✗ torch-sparse: {e}')

try:
    import torch_cluster
    print(f'✓ torch-cluster')
except ImportError as e:
    print(f'✗ torch-cluster: {e}')

try:
    import torch_geometric
    print(f'✓ PyTorch Geometric')
except ImportError as e:
    print(f'✗ PyTorch Geometric: {e}')

try:
    import sklearn
    print(f'✓ Scikit-learn: {sklearn.__version__}')
except ImportError as e:
    print(f'✗ Scikit-learn: {e}')

try:
    import numpy
    print(f'✓ NumPy: {numpy.__version__}')
except ImportError as e:
    print(f'✗ NumPy: {e}')

try:
    import pandas
    print(f'✓ Pandas: {pandas.__version__}')
except ImportError as e:
    print(f'✗ Pandas: {e}')
"
    
    # Check for PyMOL
    if command -v pymol &> /dev/null; then
        echo "✓ PyMOL: $(pymol -cq -d 'print(cmd.get_version()[0])' 2>/dev/null | grep -o '[0-9.]*' | head -1)"
    else
        echo "✗ PyMOL: Not found in PATH"
    fi
    
    conda deactivate
}

# Check both possible environments
check_env "ppi"
check_env "geoppi"

# Check for model file
echo -e "\n--- Checking for trained model ---"
if [ -f "trainedmodels/gbt-s4169.pkl" ]; then
    echo "✓ Model file found: trainedmodels/gbt-s4169.pkl"
    echo "  Size: $(ls -lh trainedmodels/gbt-s4169.pkl | awk '{print $5}')"
else
    echo "✗ Model file not found: trainedmodels/gbt-s4169.pkl"
fi

# Check for main script
echo -e "\n--- Checking for main script ---"
if [ -f "run.py" ]; then
    echo "✓ Main script found: run.py"
else
    echo "✗ Main script not found: run.py"
fi

echo -e "\n=========================================="
echo "Diagnostic complete"
echo "==========================================" 