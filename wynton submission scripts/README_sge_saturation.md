# SGE Array Job System for GeoPPI Batch Saturation Mutagenesis

This system parallelizes saturation mutagenesis across multiple SGE array tasks on Wynton HPC, with each task handling one residue position.

## Components

1. **`single_residue_saturation.py`** - Runs saturation mutagenesis for a single residue
2. **`prepare_sge_saturation.py`** - Prepares SGE array job scripts
3. **`run_sge_saturation.py`** - Wrapper that integrates with `prepare_batch_saturation.py`

## Quick Start

### Method 1: Direct from prepare_batch_saturation.py output

```bash
# First, prepare your batch saturation job
python3 prepare_batch_saturation.py positions.txt 41D1.pdb AB_C

# Then use the generated command file to submit SGE array job
python run_sge_saturation.py --from-command positions_batch_command.sh --submit
```

### Method 2: Pipe directly

```bash
python3 prepare_batch_saturation.py positions.txt 41D1.pdb AB_C | \
  python run_sge_saturation.py --parse-output --submit
```

### Method 3: Manual parameters

```bash
python run_sge_saturation.py \
  --pdb 41D1.pdb \
  --residues "SB133 GB134 FB135" \
  --partners AB_C \
  --submit
```

## Workflow

1. **Job Preparation**: The system creates:
   - A residue list file (`jobname_residues.txt`)
   - An SGE submission script (`submit_jobname.sh`)
   - A results combination script (`combine_jobname_results.py`)
   - A status check script (`check_jobname_status.sh`)

2. **Job Execution**: Each array task:
   - Reads one residue from the list
   - Runs 19 mutations (all amino acids except wildtype)
   - Saves results to `results/jobname/RESIDUE_saturation.csv`

3. **Result Collection**: After all jobs complete:
   - Run the combination script to merge all CSV files
   - Final output: `jobname_all_results.csv`

## Resource Requirements

Default settings (can be customized):
- Wall time: 1 hour per task
- Memory: 4GB per task
- Tasks run independently in parallel

## Monitoring Jobs

```bash
# Check SGE queue status
qstat -u $USER

# Check job-specific status
./check_jobname_status.sh

# View job output/errors
ls logs/jobname_task_*.log
```

## Customization Options

```bash
# Longer runtime for larger proteins
python run_sge_saturation.py --from-command cmd.sh --time 02:00:00 --submit

# More memory
python run_sge_saturation.py --from-command cmd.sh --mem 8G --submit

# Custom job name
python run_sge_saturation.py --from-command cmd.sh --job-name my_sat_job --submit
```

## Example for 73 Residues

For the example with 73 residues:
- Creates 73 array tasks
- Each task runs 19 mutations
- Total: 1,387 GeoPPI calculations
- With 1-hour limit, all should complete within 1-2 hours wall time

## Troubleshooting

1. **Jobs stuck in queue**: Check resource availability with `qstat -f`
2. **Failed tasks**: Check logs in `logs/` directory
3. **Missing results**: Use status check script to identify failed tasks
4. **Rerun failed tasks**: Submit individual tasks with modified `-t` range

## File Organization

```
.
├── single_residue_saturation.py    # Core worker script
├── prepare_sge_saturation.py       # SGE job generator
├── run_sge_saturation.py           # Main wrapper
├── submit_jobname.sh               # Generated SGE script
├── jobname_residues.txt            # Generated residue list
├── logs/                           # Job output logs
│   └── jobname_task_*.log
├── results/                        # Individual results
│   └── jobname/
│       └── *_saturation.csv
└── jobname_all_results.csv         # Final combined results
``` 