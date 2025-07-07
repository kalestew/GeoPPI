# GeoPPI
Deep Geometric Representations for Modeling Effects of Mutations on Protein-Protein Binding Affinity

- [GeoPPI](#GeoPPI)
  - [Overview](#overview)
  - [Installation](#installation)
    - [For Wynton HPC (Recommended)](#for-wynton-hpc-recommended)
    - [General Linux Installation](#general-linux-installation)
  - [Quick Example](#quick-example)
  - [Enhanced Tools](#enhanced-tools)
  - [Running on your own structure](#running-on-your-own-structure)
  - [Troubleshooting](#troubleshooting)
  - [Contact](#contact)

## Overview
GeoPPI is a deep learning based framework that uses deep geometric representations of protein complexes to model the effects of mutations on the binding affinity. To achieve both the powerful expressive capacity for geometric structures and the robustness of prediction, GeoPPI sequentially employs two components, namely a geometric encoder (excelling in extracting graphical features) and a gradient-boosting tree (GBT, excelling in avoiding overfitting). The geometric encoder is a graph neural network that performs neural message passing on the neighboring atoms for updating representations of the center atom. It is trained via a novel self-supervised learning scheme to produce deep geometric representations for protein structures. Based on these learned representations of both a complex and its mutant, the GBT learns from the mutation data to predict the corresponding binding affinity change.

Thanks to the above design, GeoPPI enjoys accurate predictive power, strong generalizability, and high inference speed for the estimation of the mutation impact.

<p align="center">
<img src="data/fig/overview.png" width="900">
</p>

## Installation

This source code is tested with `Python 3.8` on `Ubuntu 20.04` and optimized for Wynton HPC at UCSF.

### For Wynton HPC (Recommended)

#### Step 1: Clone the GitHub repository
```bash
git clone https://github.com/Liuxg16/GeoPPI.git
cd GeoPPI
```

#### Step 2: Install with Wynton best practices
Use the optimized installation script that follows [Wynton conda best practices](https://wynton.ucsf.edu/hpc/howto/conda.html):

```bash
./kja_install_wynton_clean_best_practices.sh
```

This script will:
- Create a `geoppi_clean` conda environment with Python 3.8.18
- Install all dependencies including PyTorch, PyTorch Geometric, and BioPython  
- Apply compatibility fixes for torch_geometric and scikit-learn
- Download the trained model (299MB)
- Create activation and backup scripts
- Follow Wynton HPC best practices (miniforge3, conda-forge, conda-pack)

#### Step 3: Download FoldX (Already included)
FoldX v4.0 binary is already included in the repository. The rotabase.txt file is also included.

#### Step 4: Verify installation
```bash
./verify_setup.sh
```

**You're ready to use GeoPPI!**

### General Linux Installation

For non-Wynton systems, you can still use the conda-based installation:

#### Step 1: Clone the repository
```bash
git clone https://github.com/Liuxg16/GeoPPI.git
cd GeoPPI
```

#### Step 2: Create conda environment
```bash
conda create -n geoppi_clean python=3.8 -y
conda activate geoppi_clean
```

#### Step 3: Install dependencies
```bash
# Install via conda where possible
conda install -c conda-forge numpy=1.19.5 scipy=1.6.0 pandas=1.2.0 matplotlib=3.3.4 -y

# Install PyTorch
pip install torch==1.7.0+cpu -f https://download.pytorch.org/whl/torch_stable.html

# Install PyTorch Geometric dependencies
pip install torch-cluster==1.5.8 -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html
pip install torch-scatter==2.0.5 -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html
pip install torch-sparse==0.6.8 -f https://pytorch-geometric.com/whl/torch-1.7.0+cpu.html

# Install other packages
pip install googledrivedownloader torch-geometric==1.4.1
pip install scikit-learn==0.24.1 biopython
```

#### Step 4: Download trained model
```bash
mkdir -p trainedmodels
wget https://media.githubusercontent.com/media/Liuxg16/largefiles/8167d5c365c92d08a81dffceff364f72d765805c/gbt-s4169.pkl -P trainedmodels/
```

## Quick Example

### Activation
Always activate the environment before using GeoPPI:

**On Wynton HPC:**
```bash
source activate_geoppi_clean.sh
```

**On other systems:**
```bash
conda activate geoppi_clean
export PYTHONNOUSERSITE=1  # Prevent user package conflicts
```

### Basic Usage
```bash
python run.py [pdb file] [Mutation] [partnerA_partnerB]
```

where:
- `[pdb file]` is the complex structure of interest
- `[Mutation]` denotes the mutation information  
- `[partnerA_partnerB]` describes the two interaction partners

**Format of [Mutation]**: The mutation information includes WT residue, chain, residue index and mutant residue, such as "TI17F", which stands for mutating the 17th amino acid at the I chain from threonine (T) to phenylalanine (F).

**Format of [partnerA_partnerB]**: The chains of the two binding partners. For example, if chain E interacts with chain I, use "E_I". For multiple chains, use "HL_WV" where chains H,L interact with chains W,V.

**Program output**: GeoPPI returns the binding affinity change:

<p align="center">
<img src="https://latex.codecogs.com/svg.latex?\Large&space;\Delta\Delta%20G=\Delta%20G_{wildtype}-\Delta%20G_{mutant}" title="ddg" />
</p>

Positive values indicate stabilizing mutations (higher binding affinity), negative values indicate destabilizing mutations.

### Example Commands
```bash
# Test with included examples
python run.py data/testExamples/1PPF.pdb TI17R E_I
# Expected output: The predicted binding affinity change (wildtype-mutant) is -2.8 kcal/mol (destabilizing mutation).

python run.py data/testExamples/1CZ8.pdb KW84A WV_HL
python run.py data/testExamples/1CSE.pdb LI38I E_I  
python run.py data/testExamples/3SGB.pdb KI7L E_I
python run.py data/testExamples/3BT1.pdb PU149A U_A
```

## Enhanced Tools

GeoPPI includes enhanced tools for batch processing and interface analysis:

### 1. Saturation Mutagenesis
Run saturation mutagenesis on specific positions:
```bash
./submit_saturation.sh <pdbfile> "<resid_list>" <partner_info>

# Examples:
./submit_saturation.sh data/testExamples/1PPF.pdb "TI17" E_I
./submit_saturation.sh 1CZ8.pdb "KW84 HL112" WV_HL
```

### 2. Interface Analysis
Identify interface residues and generate position lists:
```bash
./run_interface_analysis.sh <pdbfile> <chain_pairs> [options]

# Examples:
./run_interface_analysis.sh data/testExamples/1PPF.pdb E_I
./run_interface_analysis.sh 1CZ8.pdb AB_CD -i  # Interactive mode
```

### 3. Example Workflow
Try the complete workflow:
```bash
./example_workflow.sh
```

For detailed documentation on enhanced tools, see [README_new_tools.md](README_new_tools.md).

## Running on your own structure

1. **Prepare your PDB file**: Ensure your PDB file is clean and contains the protein complex of interest

2. **Identify chain partners**: Determine which chains form the binding interface

3. **Activate environment**: 
   ```bash
   source activate_geoppi_clean.sh  # On Wynton
   # OR
   conda activate geoppi_clean      # On other systems
   ```

4. **Run GeoPPI**:
   ```bash
   python run.py your_structure.pdb MUTATION PARTNERS
   ```

5. **Optional - Find interface residues first**:
   ```bash
   ./run_interface_analysis.sh your_structure.pdb PARTNERS -i
   ```

## Troubleshooting

### Common Issues

1. **Import errors (torch_sparse, torch_geometric)**:
   - Make sure you've activated the conda environment
   - Check: `echo $CONDA_DEFAULT_ENV` should show "geoppi_clean"
   - Check: `which python` should point to the conda environment

2. **"GeoPPI conda environment not activated"**:
   - Use: `source activate_geoppi_clean.sh` (Wynton) or `conda activate geoppi_clean`

3. **Scikit-learn version warnings**:
   - Expected behavior - the trained model uses scikit-learn 0.24.1
   - The installation automatically uses the correct version

4. **File not found errors**:
   - Ensure you're in the GeoPPI directory: `cd GeoPPI`
   - Check PDB file path is correct

### Verification Commands
```bash
# Check environment
source activate_geoppi_clean.sh
echo $CONDA_DEFAULT_ENV  # Should show: geoppi_clean

# Test dependencies  
python -c "
import torch, torch_geometric, Bio, sklearn
print('✓ All dependencies working')
print(f'PyTorch: {torch.__version__}')
print(f'Scikit-learn: {sklearn.__version__}')
"

# Test GeoPPI
python run.py data/testExamples/1PPF.pdb TI17R E_I
```

### Fresh Installation
If problems persist:
```bash
# Remove environment and reinstall
conda env remove -n geoppi_clean -y
./kja_install_wynton_clean_best_practices.sh
```

### Environment Backup
Create a backup of your working environment:
```bash
./backup_geoppi_clean_env.sh
```

## Contact

If you encounter any problems during setup or execution:

- **For Wynton HPC specific issues**: Create an issue with "Wynton" in the title
- **For general questions**: Contact [liuxg16@mails.tsinghua.edu.cn](mailto:liuxg16@mails.tsinghua.edu.cn)  
- **GitHub Issues**: [https://github.com/Liuxg16/GeoPPI](https://github.com/Liuxg16/GeoPPI)

When reporting issues, please include:
- Your operating system and Python version
- The exact command that failed
- The full error message
- Output of `conda env list | grep geoppi`

**Installation Summary**: See [INSTALLATION_SUMMARY.md](INSTALLATION_SUMMARY.md) for detailed information about the current installation.

Cheers!
