#!/bin/bash

# Wrapper script to run GeoPPI interface analysis with proper Wynton environment
# This ensures PyMOL and other dependencies are available

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <pdbfile> <chain_pairs> [additional options]"
    echo "Example: $0 1CZ8.pdb VW_HL -o positions.txt"
    echo ""
    echo "This script sets up the proper environment for running:"
    echo "  generate_interface_position_list.py"
    echo ""
    echo "Additional options:"
    echo "  -o OUTPUT     Output file (default: position_list.txt)"
    echo "  -f FORMAT     Output format: mutatex or rosetta (default: mutatex)"
    echo "  -i            Interactive mode"
    echo "  -q QUERY      Search for sequence motif"
    echo "  --interface-only  Only include interface residues"
    exit 1
fi

# Store arguments
PDBFILE=$1
CHAIN_PAIRS=$2
shift 2
ADDITIONAL_ARGS="$@"

# Verify PDB file exists
if [ ! -f "$PDBFILE" ]; then
    echo "ERROR: PDB file not found: $PDBFILE"
    exit 1
fi

echo "=========================================="
echo "GeoPPI Interface Analysis"
echo "=========================================="

# Load miniforge3 (Wynton best practice)
echo "Loading miniforge3 module..."
module load CBI miniforge3

# Initialize conda
eval "$(conda shell.bash hook)"

# Activate the geoppi_clean environment
echo "Activating geoppi_clean environment..."
conda activate geoppi_clean

# Verify environment
if [ "$CONDA_DEFAULT_ENV" != "geoppi_clean" ]; then
    echo "ERROR: Failed to activate geoppi_clean conda environment"
    echo "Please ensure GeoPPI is installed using kja_install_wynton_clean_best_practices.sh"
    exit 1
fi

# Disable user site-packages (Wynton best practice)
export PYTHONNOUSERSITE=1

# Show environment info
echo ""
echo "Environment Info:"
echo "  Conda env: $CONDA_DEFAULT_ENV"
echo "  Python: $(which python)"
echo "  Python version: $(python --version)"
echo ""

# Check if PyMOL is available
python -c "import pymol" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "WARNING: PyMOL not found in environment"
    echo "The script will use distance-based interface detection as fallback"
    echo ""
fi

# Run the interface analysis
echo "Running interface analysis..."
echo "  PDB: $PDBFILE"
echo "  Chains: $CHAIN_PAIRS"
echo ""

python /wynton/home/craik/kjander/GeoPPI/GeoPPI/generate_interface_position_list.py \
    -p "$PDBFILE" \
    -c "$CHAIN_PAIRS" \
    $ADDITIONAL_ARGS

EXIT_CODE=$?

echo ""
echo "=========================================="
echo "Analysis completed with exit code: $EXIT_CODE"
echo "=========================================="

exit $EXIT_CODE 