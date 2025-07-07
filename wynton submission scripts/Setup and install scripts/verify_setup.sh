#!/bin/bash

# Verify GeoPPI setup for Wynton HPC
# This script checks that all components are properly installed and configured

echo "=========================================="
echo "GeoPPI Setup Verification"
echo "=========================================="
echo ""

# Check for miniforge3 module
echo "1. Checking for miniforge3 module..."
module list 2>&1 | grep -q miniforge3
if [ $? -eq 0 ]; then
    echo "   ✓ miniforge3 already loaded"
else
    echo "   Loading miniforge3..."
    module load CBI miniforge3
    if [ $? -eq 0 ]; then
        echo "   ✓ miniforge3 loaded successfully"
    else
        echo "   ✗ Failed to load miniforge3 module"
        exit 1
    fi
fi

# Initialize conda
eval "$(conda shell.bash hook)"

# Check for geoppi_clean environment
echo ""
echo "2. Checking for geoppi_clean environment..."
conda env list | grep -q "^geoppi_clean "
if [ $? -eq 0 ]; then
    echo "   ✓ geoppi_clean environment found"
else
    echo "   ✗ geoppi_clean environment not found"
    echo "   Please run: ./kja_install_wynton_clean_best_practices.sh"
    exit 1
fi

# Check for activation script
echo ""
echo "3. Checking for activation script..."
if [ -f "activate_geoppi_clean.sh" ]; then
    echo "   ✓ activate_geoppi_clean.sh found"
else
    echo "   ✗ activate_geoppi_clean.sh not found"
fi

# Activate environment
echo ""
echo "4. Activating geoppi_clean environment..."
conda activate geoppi_clean
if [ "$CONDA_DEFAULT_ENV" == "geoppi_clean" ]; then
    echo "   ✓ Environment activated successfully"
else
    echo "   ✗ Failed to activate environment"
    exit 1
fi

# Check Python packages
echo ""
echo "5. Checking Python packages..."
echo -n "   PyTorch: "
python -c "import torch; print('✓ version', torch.__version__)" 2>/dev/null || echo "✗ not installed"

echo -n "   PyTorch Geometric: "
python -c "import torch_geometric; print('✓ installed')" 2>/dev/null || echo "✗ not installed or import error"

echo -n "   PyMOL: "
python -c "import pymol; print('✓ installed')" 2>/dev/null || echo "✗ not installed"

echo -n "   BioPython: "
python -c "import Bio; print('✓ version', Bio.__version__)" 2>/dev/null || echo "✗ not installed"

echo -n "   NumPy: "
python -c "import numpy; print('✓ version', numpy.__version__)" 2>/dev/null || echo "✗ not installed"

echo -n "   Scikit-learn: "
python -c "import sklearn; print('✓ version', sklearn.__version__)" 2>/dev/null || echo "✗ not installed"

# Check GeoPPI files
echo ""
echo "6. Checking GeoPPI files..."
GEOPPI_PATH="/wynton/home/craik/kjander/GeoPPI/GeoPPI"

echo -n "   foldx: "
if [ -f "$GEOPPI_PATH/foldx" ]; then
    echo "✓ found"
else
    echo "✗ not found at $GEOPPI_PATH/foldx"
fi

echo -n "   rotabase.txt: "
if [ -f "$GEOPPI_PATH/rotabase.txt" ]; then
    echo "✓ found"
else
    echo "✗ not found at $GEOPPI_PATH/rotabase.txt"
fi

echo -n "   run.py: "
if [ -f "$GEOPPI_PATH/run.py" ]; then
    echo "✓ found"
else
    echo "✗ not found at $GEOPPI_PATH/run.py"
fi

echo -n "   Trained model: "
if [ -f "$GEOPPI_PATH/trainedmodels/gbt-s4169.pkl" ]; then
    echo "✓ found"
else
    echo "✗ not found at $GEOPPI_PATH/trainedmodels/gbt-s4169.pkl"
fi

# Check new tools
echo ""
echo "7. Checking new batch tools..."
echo -n "   batch_saturation_qsub.py: "
if [ -f "batch_saturation_qsub.py" ]; then
    echo "✓ found"
else
    echo "✗ not found"
fi

echo -n "   submit_saturation.sh: "
if [ -x "submit_saturation.sh" ]; then
    echo "✓ found and executable"
else
    echo "✗ not found or not executable"
fi

echo -n "   generate_interface_position_list.py: "
if [ -f "generate_interface_position_list.py" ]; then
    echo "✓ found"
else
    echo "✗ not found"
fi

echo -n "   run_interface_analysis.sh: "
if [ -x "run_interface_analysis.sh" ]; then
    echo "✓ found and executable"
else
    echo "✗ not found or not executable"
fi

# Summary
echo ""
echo "=========================================="
echo "Verification Complete"
echo "=========================================="
echo ""
echo "If all checks passed (✓), your GeoPPI setup is ready!"
echo "You can now run the example workflow:"
echo "  ./example_workflow.sh"
echo ""
echo "Or use the tools directly:"
echo "  ./run_interface_analysis.sh <pdb> <chains>"
echo "  ./submit_saturation.sh <pdb> \"<positions>\" <partners>" 