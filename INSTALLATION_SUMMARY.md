# GeoPPI Installation Summary

## Environment Details
- **Environment name**: `geoppi_clean`
- **Python version**: 3.8.18
- **Location**: `/wynton/home/craik/kjander/.conda/envs/geoppi_clean`

## Installed Packages
- ✓ PyTorch 1.7.0+cpu
- ✓ PyTorch Geometric 1.4.1
- ✓ Scikit-learn 0.24.1 (matched to trained model)
- ✓ BioPython 1.83
- ✓ NumPy 1.24.4
- ✓ Pandas 2.0.3
- ✓ PyMOL (open-source)

## Usage
1. Activate the environment:
   ```bash
   source ./activate_geoppi_clean.sh
   ```

2. Run GeoPPI:
   ```bash
   cd GeoPPI
   python run.py [pdb file] [Mutation] [partnerA_partnerB]
   ```

   Example:
   ```bash
   python run.py data/testExamples/1PPF.pdb TI17R E_I
   ```

## Key Fixes Applied
1. **google_drive_downloader compatibility**: Created wrapper for torch_geometric 1.4.1
2. **scikit-learn version**: Downgraded to 0.24.1 to match trained model
3. **User packages disabled**: Following Wynton best practices with PYTHONNOUSERSITE=1

## Troubleshooting
If you encounter issues:
1. Make sure you've activated the environment
2. Check that you're using the correct Python: `/wynton/home/craik/kjander/.conda/envs/geoppi_clean/bin/python`
3. Re-download the model if needed:
   ```bash
   wget https://media.githubusercontent.com/media/Liuxg16/largefiles/8167d5c365c92d08a81dffceff364f72d765805c/gbt-s4169.pkl -P trainedmodels/
   ```

## Installation Script
For future installations, use:
```bash
./kja_install_wynton_clean_best_practices.sh
```

This script includes all necessary fixes and follows Wynton HPC best practices. 