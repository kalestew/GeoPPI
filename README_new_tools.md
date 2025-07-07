# GeoPPI Enhanced Tools

This document describes the new tools for GeoPPI saturation mutagenesis and interface position list generation.

## Wynton HPC Setup Requirements

### Prerequisites
Before using these tools on Wynton HPC, ensure that:

1. **GeoPPI is installed with the Wynton best practices script**:
   ```bash
   ./kja_install_wynton_clean_best_practices.sh
   ```

2. **The `geoppi_clean` conda environment is created** following [Wynton conda best practices](https://wynton.ucsf.edu/hpc/howto/conda.html):
   - Uses `miniforge3` (NOT `miniconda3` due to licensing)
   - Properly configured with conda-forge channel
   - Has conda-pack installed for environment staging
   - Includes all necessary fixes for PyTorch Geometric and scikit-learn compatibility
   - BioPython installed for convenience
   - PyMOL installation may take 5-10 minutes due to its size

3. **Environment activation**:
   After installation, always use the provided activation script:
   ```bash
   source activate_geoppi_clean.sh
   ```

### Installation Summary
The installation script creates a fully functional environment with:
- ✓ Python 3.8.18
- ✓ PyTorch 1.7.0+cpu  
- ✓ PyTorch Geometric 1.4.1 (with google_drive_downloader compatibility fix)
- ✓ Scikit-learn 0.24.1 (downgraded to match trained model)
- ✓ BioPython 1.83
- ✓ PyMOL (open-source)
- ✓ All dependencies properly isolated from user packages

### Verify Installation
To check that everything is properly set up:
```bash
./verify_setup.sh
```

This script will verify:
- Miniforge3 module availability
- geoppi_clean environment exists and is functional
- All required Python packages are installed and importable
- GeoPPI files (foldx, rotabase.txt, models) are in place
- New batch tools are properly installed
- PyTorch Geometric can import successfully (critical!)

### Environment Activation
All scripts automatically handle environment setup by:
- Loading the `CBI miniforge3` module
- Activating the `geoppi_clean` conda environment
- Disabling user site-packages (`PYTHONNOUSERSITE=1`)
- Setting up proper paths for foldx and rotabase.txt

**Important**: Always ensure the environment is activated before running GeoPPI directly:
```bash
source activate_geoppi_clean.sh
cd GeoPPI  
python run.py data/testExamples/1PPF.pdb TI17R E_I
```

### Quick Start
```bash
# 1. Run the example workflow
./example_workflow.sh

# 2. Or run tools individually:
# For interface analysis:
./run_interface_analysis.sh <pdbfile> <chain_pairs> [options]

# For saturation mutagenesis:
./submit_saturation.sh <pdbfile> "<resid_list>" <partner_info>
```

## 1. Batch Saturation Mutagenesis for Qsub

### Overview
`batch_saturation_qsub.py` is an enhanced version of the saturation mutagenesis script designed to run on HPC clusters using the qsub job scheduler (like Wynton).

### Features
- PBS job integration with proper directives
- Automatic path handling for foldx and rotabase.txt
- Progress tracking and detailed logging
- Results saved in job-specific directories
- Error handling and debugging output
- **Wynton-specific**: Automatic conda environment verification and activation
- **Fixed compatibility**: Works with the corrected PyTorch Geometric installation

### Usage

#### Using the submit script (RECOMMENDED):
```bash
./submit_saturation.sh <pdbfile> "<resid_list>" <partner_info>
```

The submit script handles all environment setup automatically, including:
- Loading miniforge3 module
- Activating geoppi_clean environment  
- Setting PYTHONNOUSERSITE=1
- Verifying all dependencies

#### Direct submission (for debugging only):
```bash
# Must activate environment first
source activate_geoppi_clean.sh
python batch_saturation_qsub.py <pdbfile> "<resid_list>" <partner_info>
```

### Examples
```bash
# Saturation mutagenesis of two positions
./submit_saturation.sh 1CZ8.pdb "KW84 HL112" WV_HL

# Single position
./submit_saturation.sh antibody.pdb "HA100" H_L

# Test with the included example
./submit_saturation.sh data/testExamples/1PPF.pdb "TI17" E_I
```

### Output
- CSV file with DDG values for all mutations
- Log file with detailed progress and any errors
- Results directory named `saturation_results_<job_id>`
- Job parameters saved in `saturation_<pdb>_params.txt`

### Job Parameters
- Memory: 8GB
- Walltime: 24 hours
- Nodes: 1 (single core)

## 2. Interface Position List Generator

### Overview
`generate_interface_position_list.py` combines PyMOL interface detection with advanced position selection features from the MutateX position list generator.

### Features
- Automatic interface residue detection using PyMOL
- Sequence motif searching
- Interactive mode for custom selection
- Support for both MutateX and Rosetta output formats
- Distance-based fallback if PyMOL's InterfaceResidues module is unavailable
- **Full integration** with the geoppi_clean environment

### Usage

#### Using the wrapper script (RECOMMENDED):
```bash
./run_interface_analysis.sh <pdbfile> <chain_pairs> [options]
```

#### Direct usage (requires environment activation):
```bash
source activate_geoppi_clean.sh
python generate_interface_position_list.py -p <pdbfile> -c <chain_pairs> [options]
```

### Required Arguments
- `-p, --pdb`: Input PDB file
- `-c, --chains`: Chain pairs for interface (e.g., "AB_CD" for interfaces between chains AB and CD)

### Optional Arguments
- `-o, --output`: Output file name (default: position_list.txt)
- `-f, --format`: Output format - 'mutatex' or 'rosetta' (default: mutatex)
- `-i, --interactive`: Launch interactive mode for custom selection
- `-q, --query`: Search for sequence motif in structure
- `--include-spans`: Additional residue spans to include (e.g., A:30-40 B:50-60)
- `--interface-only`: Only include interface residues
- `--cutoff`: Interface cutoff for PyMOL (default: 1.0)
- `--workdir`: Working directory for temporary files

### Examples

#### Basic interface analysis:
```bash
./run_interface_analysis.sh 1CZ8.pdb AB_CD -o positions.txt
```

#### Interactive mode:
```bash
./run_interface_analysis.sh data/testExamples/1PPF.pdb E_I -i
```

#### Search for CDR regions in antibody interfaces:
```bash
./run_interface_analysis.sh antibody.pdb VW_HL -q DIQMTQ -q EVQLVQ
```

#### Rosetta format output:
```bash
./run_interface_analysis.sh structure.pdb AB_CD -f rosetta -o resfile.txt
```

#### Include additional regions:
```bash
./run_interface_analysis.sh 1CZ8.pdb AB_CD --include-spans A:30-40 B:50-60
```

### Interactive Mode Options
1. **Use all interface residues**: Include all detected interface residues
2. **Filter by chain**: Select interface residues from specific chains
3. **Search for motif**: Find sequence patterns and check overlap with interface
4. **Add manually**: Specify individual residues (e.g., A30,A31,B50)
5. **Generate list**: Create the final position list file

### Output Formats

#### MutateX format:
```
KA100
RL112
YB85
```

#### Rosetta format:
```
100A
112L
85B
```

## Dependencies

Both tools require the `geoppi_clean` conda environment with:
- Python 3.8.18
- BioPython 1.83
- PyMOL (with Python bindings)
- NumPy 1.24.4
- PyTorch 1.7.0+cpu (for GeoPPI predictions)
- PyTorch Geometric 1.4.1 (with compatibility fixes)
- Scikit-learn 0.24.1 (matched to trained model)
- All GeoPPI dependencies properly configured

## Installation Details

### Key Fixes Applied in Current Installation
1. **google_drive_downloader compatibility**: Created wrapper for torch_geometric 1.4.1
2. **scikit-learn version**: Downgraded to 0.24.1 to match trained model format
3. **User packages isolation**: PYTHONNOUSERSITE=1 prevents conflicts
4. **BioPython inclusion**: Added for enhanced sequence analysis capabilities

### Environment Management
The installation creates several helper scripts:
- `activate_geoppi_clean.sh`: Proper environment activation
- `backup_geoppi_clean_env.sh`: Environment backup for disaster recovery
- `verify_setup.sh`: Comprehensive installation verification

## Notes

1. **Module System**: Scripts automatically load `CBI miniforge3` module
2. **Foldx Path**: The scripts automatically use foldx from `/wynton/home/craik/kjander/GeoPPI/GeoPPI/foldx`
3. **Rotabase**: The rotabase.txt file is expected in the same directory as foldx
4. **GPU Usage**: The qsub script will attempt to use GPU if available (CUDA_VISIBLE_DEVICES=0)
5. **Temporary Files**: Both scripts create temporary files/directories that are cleaned up after completion
6. **Environment Staging**: Consider using `export CONDA_STAGE=true` for better performance on Wynton
7. **Trained Model**: The GBT model (299MB) is automatically downloaded during installation

## Troubleshooting

### Common Issues:

1. **"GeoPPI conda environment not activated"**: 
   - Solution: Use `source activate_geoppi_clean.sh` or the wrapper scripts
   - Verify with: `echo $CONDA_DEFAULT_ENV` (should show "geoppi_clean")

2. **"ModuleNotFoundError: No module named 'torch_sparse'"**: 
   - This indicates you're not in the activated environment
   - Solution: Always activate the environment first
   - Check Python path: `which python` should show the conda environment path

3. **"PyTorch Geometric import error"**: 
   - The installation includes a compatibility fix for google_drive_downloader
   - If issues persist, verify: `python -c "import torch_geometric; print('OK')"`

4. **"InconsistentVersionWarning" for scikit-learn**: 
   - This is expected - the trained model was created with scikit-learn 0.24.1
   - The installation automatically uses the correct version

5. **PBS job fails immediately**: 
   - Check that the geoppi_clean environment exists: `conda env list | grep geoppi_clean`
   - Verify PDB file path is correct and accessible
   - Check job error file: `cat saturation_*.err`

6. **No interface residues found**: 
   - Verify the chain pairs are correct (e.g., "AB_CD" not "ABCD")
   - Try with the test file: `./run_interface_analysis.sh data/testExamples/1PPF.pdb E_I`

### Debug Mode:
For debugging, activate the environment manually and run directly:
```bash
source activate_geoppi_clean.sh
python batch_saturation_qsub.py data/testExamples/1PPF.pdb "TI17" E_I
```

### Verification Commands:
```bash
# Check environment activation
source activate_geoppi_clean.sh
echo $CONDA_DEFAULT_ENV  # Should show: geoppi_clean
which python             # Should show: ~/.conda/envs/geoppi_clean/bin/python

# Test all dependencies
python -c "
import torch
import torch_geometric  
import Bio
import sklearn
print('✓ All dependencies loaded successfully')
print(f'PyTorch: {torch.__version__}')
print(f'BioPython: {Bio.__version__}') 
print(f'Scikit-learn: {sklearn.__version__}')
"

# Test GeoPPI functionality
cd GeoPPI
python run.py data/testExamples/1PPF.pdb TI17R E_I
```

### Environment Backup:
The installation creates a backup script. To backup your environment:
```bash
./backup_geoppi_clean_env.sh
```
This creates `geoppi_clean_backup.yml` and `geoppi_clean_requirements.txt` for disaster recovery.

### Fresh Installation:
If you encounter persistent issues, you can always reinstall:
```bash
# Remove old environment
conda env remove -n geoppi_clean -y

# Clean install
./kja_install_wynton_clean_best_practices.sh
```

The installation script includes all necessary fixes and will create a fully functional environment. 