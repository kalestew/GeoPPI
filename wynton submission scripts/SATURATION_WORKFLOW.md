# GeoPPI Saturation Mutagenesis Workflow on Wynton HPC

This document describes the complete workflow for running saturation mutagenesis with GeoPPI on Wynton HPC, ensuring proper conda environment activation.

## Prerequisites

1. GeoPPI conda environment (`geoppi_clean`) must be installed
2. Access to Wynton HPC with SGE queue submission privileges
3. A PDB file and positions.txt file for your protein complex

## Complete Workflow

### Step 1: Prepare Input Files

Create a `positions.txt` file with the format:
```
B.S.133 C
A.C.23 C
```
Where:
- First part is `Chain.WildtypeAA.ResidueNumber`
- Second part is the partner chain marker (usually 'C')

### Step 2: Generate Batch Command File

```bash
python3 prepare_batch_saturation.py GeoPPI/41D1/positions.txt GeoPPI/41D1/41D1_forGeoPPI.pdb AB_C
```

This creates:
- `positions_batch_command.sh` - Command to run batch saturation
- `positions_saturation_summary.txt` - Summary of the job

### Step 3: Submit SGE Array Job

```bash
python3 run_sge_saturation.py --from-command GeoPPI/41D1/positions_batch_command.sh --submit
```

This script:
1. Parses the batch command file
2. Runs `prepare_sge_saturation.py` which creates:
   - `submit_job_*_sat.sh` - SGE submission script with proper conda activation
   - `job_*_sat_residues.txt` - List of residues for array job
   - `check_job_*_sat_status.sh` - Status checking script
   - `combine_job_*_sat_results.py` - Result combination script
3. Submits the job to SGE if `--submit` is used

### Step 4: Monitor Job Progress

Check job status:
```bash
qstat -u $USER
```

Or use the generated status script:
```bash
./check_job_41D1_forGeoPPI_sat_status.sh
```

View logs:
```bash
ls -la logs/job_*_sat_task_*.log
```

### Step 5: Combine Results

After all jobs complete:
```bash
python3 combine_job_41D1_forGeoPPI_sat_results.py
```

This creates `job_41D1_forGeoPPI_sat_all_results.csv` with all mutation predictions.

### Step 6: Clean Up (Optional)

To remove all generated files:
```bash
# Preview what will be deleted
python3 cleanup_saturation_files.py --dry-run

# Delete files but keep final results
python3 cleanup_saturation_files.py --keep-results

# Delete everything
python3 cleanup_saturation_files.py
```

## Key Files in the Workflow

### Generated Scripts and Files:

1. **From prepare_batch_saturation.py:**
   - `positions_batch_command.sh` - Batch command file
   - `positions_saturation_summary.txt` - Job summary

2. **From prepare_sge_saturation.py:**
   - `submit_job_*_sat.sh` - SGE submission script
   - `job_*_sat_residues.txt` - Residue list for array tasks
   - `check_job_*_sat_status.sh` - Status monitoring script
   - `combine_job_*_sat_results.py` - Result combination script

3. **During execution:**
   - `logs/job_*_sat_task_*.log` - Individual task logs
   - `results/job_*_sat/*_saturation.csv` - Individual residue results

4. **Final output:**
   - `job_*_sat_all_results.csv` - Combined results for all mutations

## Wynton-Specific Conda Practices

The generated submit scripts include proper Wynton conda activation:

```bash
# Load miniforge3 module (required for conda on Wynton)
module load CBI miniforge3

# Initialize conda
eval "$(conda shell.bash hook)"

# Activate GeoPPI environment
conda activate geoppi_clean

# Disable user site-packages to avoid conflicts
export PYTHONNOUSERSITE=1
```

This ensures:
1. The miniforge3 module is loaded (required on Wynton)
2. Conda is properly initialized in the shell
3. The correct conda environment is activated
4. User site-packages don't interfere with the conda environment

## Troubleshooting

### Common Issues:

1. **Module not found errors**: Ensure you're using the updated scripts that include `module load CBI miniforge3`

2. **Empty results**: Check individual logs in `logs/` directory for specific error messages

3. **FoldX errors**: GeoPPI may fail for certain mutations due to structural issues. Check the log files for "Data processing error" messages.

4. **Job not starting**: Check queue status with `qstat -u $USER` and verify you have sufficient quota

### Manual Testing:

To test a single mutation manually:
```bash
# Load environment
module load CBI miniforge3
eval "$(conda shell.bash hook)"
conda activate geoppi_clean

# Run single mutation
cd GeoPPI
python3 run.py ../41D1_forGeoPPI.pdb IA48C A_B
```

## Script Execution Flow

```
positions.txt
    ↓
prepare_batch_saturation.py
    ↓
positions_batch_command.sh
    ↓
run_sge_saturation.py
    ↓
prepare_sge_saturation.py
    ↓
submit_job_*_sat.sh (with conda activation)
    ↓
SGE Array Job → single_residue_saturation.py (×N tasks)
    ↓
Individual CSV results
    ↓
combine_job_*_sat_results.py
    ↓
Final combined CSV
``` 

Note for sign conventions
The predicted binding affinity change (wildtype-mutant) is -1.76 kcal/mol (destabilizing mutation).