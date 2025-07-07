#!/bin/bash
# Example workflow for GeoPPI interface analysis and saturation mutagenesis
# This workflow follows Wynton HPC best practices

echo "=========================================="
echo "GeoPPI Workflow Example - Wynton HPC"
echo "=========================================="
echo ""
echo "This workflow demonstrates:"
echo "1. Identifying interface residues"
echo "2. Running saturation mutagenesis on interface positions"
echo ""

# Example parameters
PDB_FILE="data/testExamples/1PPF.pdb"
CHAIN_PAIRS="E_I"  # Interface between E and I

# Verify PDB file exists
if [ ! -f "$PDB_FILE" ]; then
    echo "ERROR: PDB file not found: $PDB_FILE"
    echo "Please provide a valid PDB file"
    exit 1
fi

echo "Input parameters:"
echo "  PDB file: $PDB_FILE"
echo "  Chain pairs: $CHAIN_PAIRS"
echo ""

# Step 1: Setup environment (if not already done)
echo "Step 1: Setting up environment..."
echo "Loading miniforge3 module..."
module load CBI miniforge3

# Initialize conda
eval "$(conda shell.bash hook)"

# Check if geoppi_clean environment exists
if ! conda env list | grep -q "^geoppi_clean "; then
    echo "ERROR: geoppi_clean conda environment not found!"
    echo "Please run the installation script first:"
    echo "  ./kja_install_wynton_clean_best_practices.sh"
    exit 1
fi

echo "Environment ready!"
echo ""

# Step 2: Generate interface position list
echo "Step 2: Identifying interface residues..."
./run_interface_analysis.sh ${PDB_FILE} ${CHAIN_PAIRS} -o interface_positions.txt --interface-only

if [ ! -f "interface_positions.txt" ]; then
    echo "ERROR: Failed to generate interface positions"
    exit 1
fi

echo ""
echo "Interface positions saved to: interface_positions.txt"
echo "Contents:"
head -10 interface_positions.txt
echo ""

# Step 3: Convert position list for batch saturation
echo "Step 3: Preparing positions for saturation mutagenesis..."

# Read the position list and format for batch_saturation
POSITIONS=""
while IFS= read -r line; do
    # Skip empty lines
    if [[ -n "$line" ]]; then
        # Extract positions (already in format like "KW84")
        POSITIONS="${POSITIONS} ${line}"
    fi
done < interface_positions.txt

# Trim leading/trailing spaces
POSITIONS=$(echo "$POSITIONS" | xargs)

if [ -z "$POSITIONS" ]; then
    echo "ERROR: No positions found in interface_positions.txt"
    exit 1
fi

echo "Found positions: ${POSITIONS}"
echo ""

# Step 4: Submit saturation mutagenesis job
echo "Step 4: Submitting saturation mutagenesis job..."
./submit_saturation.sh ${PDB_FILE} "${POSITIONS}" ${CHAIN_PAIRS}

echo ""
echo "=========================================="
echo "Workflow complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Check job status: qstat -u $USER"
echo "2. Results will be in: saturation_results_<job_id>/"
echo ""
echo "For interactive interface analysis, you can also run:"
echo "  ./run_interface_analysis.sh ${PDB_FILE} ${CHAIN_PAIRS} -i"
echo ""
echo "To run saturation mutagenesis locally (not recommended for large jobs):"
echo "  source activate_geoppi_clean.sh  # Or manually: module load CBI miniforge3 && conda activate geoppi_clean"
echo "  python batch_saturation_qsub.py ${PDB_FILE} \"${POSITIONS}\" ${CHAIN_PAIRS}" 