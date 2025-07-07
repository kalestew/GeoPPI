#!/usr/bin/env python3
#PBS -N GeoPPI_saturation
#PBS -l nodes=1:ppn=1
#PBS -l mem=8gb
#PBS -l walltime=24:00:00
#PBS -e saturation.err
#PBS -o saturation.out
#PBS -V

"""
GeoPPI Saturation Mutagenesis - Wynton HPC Version
Runs saturation mutagenesis for specified positions using GeoPPI on Wynton cluster
Following Wynton best practices for conda environments
"""

import os
import subprocess
import sys
import csv
import shutil

# Set up environment paths
GEOPPI_PATH = "/wynton/home/craik/kjander/GeoPPI/GeoPPI"
FOLDX_EXEC = os.path.join(GEOPPI_PATH, "foldx")
ROTABASE = os.path.join(GEOPPI_PATH, "rotabase.txt")

# Canonical amino acids (1-letter code)
aa_codes = ['A','R','N','D','C','Q','E','G','H','I',
            'L','K','M','F','P','S','T','W','Y','V']

def setup_wynton_environment():
    """Setup Wynton-specific environment following best practices"""
    # Check if we're in the conda environment
    if os.environ.get('CONDA_DEFAULT_ENV') != 'geoppi_clean':
        print("ERROR: GeoPPI conda environment not activated!")
        print("Expected environment: geoppi_clean")
        print("Current environment:", os.environ.get('CONDA_DEFAULT_ENV', 'None'))
        print("This script should be run through submit_saturation.sh which handles environment setup")
        sys.exit(1)
    
    # Ensure user site-packages are disabled (Wynton best practice)
    os.environ['PYTHONNOUSERSITE'] = '1'
    
    # Change to GeoPPI directory for execution
    os.chdir(GEOPPI_PATH)
    
    # Verify critical files exist
    if not os.path.exists(FOLDX_EXEC):
        print(f"ERROR: foldx not found at {FOLDX_EXEC}")
        sys.exit(1)
    
    if not os.path.exists(ROTABASE):
        print(f"ERROR: rotabase.txt not found at {ROTABASE}")
        sys.exit(1)

def run_prediction(pdbfile, mutation, partner_info):
    """Run GeoPPI prediction for a single mutation"""
    # Copy PDB file to current directory if needed
    if not os.path.exists(os.path.basename(pdbfile)):
        shutil.copy(pdbfile, ".")
        pdbfile = os.path.basename(pdbfile)
    
    # Create symlink to foldx in current directory if not exists
    if not os.path.exists("./foldx"):
        os.symlink(FOLDX_EXEC, "./foldx")
    
    # Ensure rotabase.txt is available
    if not os.path.exists("./rotabase.txt"):
        os.symlink(ROTABASE, "./rotabase.txt")
    
    cmd = f"python {GEOPPI_PATH}/run.py {pdbfile} {mutation} {partner_info}"
    
    # Set environment for CUDA if available
    env = os.environ.copy()
    if 'CUDA_VISIBLE_DEVICES' not in env:
        env['CUDA_VISIBLE_DEVICES'] = '0'  # Use GPU 0 if available
    
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True, env=env)
    output = result.stdout
    error = result.stderr

    ddg = None
    for line in output.splitlines():
        if "The predicted binding affinity change" in line:
            ddg = line.strip().split("is")[1].split("kcal")[0].strip()
            break

    if ddg is None:
        print(f"--- run.py output for {mutation} ---")
        print("STDOUT:", output)
        print("STDERR:", error)
        print("------------------------------------")

    return ddg, output

def main():
    # Setup Wynton environment
    setup_wynton_environment()
    
    # Check if running under PBS
    if 'PBS_O_WORKDIR' in os.environ:
        original_dir = os.environ['PBS_O_WORKDIR']
        os.chdir(original_dir)
    else:
        original_dir = os.getcwd()
    
    if len(sys.argv) != 4:
        print("Usage: python batch_saturation_qsub.py <pdbfile> <resid_list> <partner_info>")
        print("Example: python batch_saturation_qsub.py 1CZ8.pdb \"KW84 HL112\" WV_HL")
        sys.exit(1)

    pdbfile = os.path.abspath(sys.argv[1])
    mutations = sys.argv[2].split()   # E.g. KW84 HL112
    partner_info = sys.argv[3]

    # Create output directory based on job ID if available
    job_id = os.environ.get('PBS_JOBID', 'local_run')
    output_dir = os.path.join(original_dir, f"saturation_results_{job_id.split('.')[0]}")
    os.makedirs(output_dir, exist_ok=True)
    
    outname = os.path.join(output_dir, os.path.basename(pdbfile).split('.')[0] + "_saturation_ddg.csv")
    log_file = os.path.join(output_dir, "saturation_log.txt")
    
    # Log environment info
    with open(log_file, "w") as log:
        log.write(f"GeoPPI Saturation Mutagenesis - Wynton HPC\n")
        log.write(f"{'='*60}\n")
        log.write(f"Environment Info:\n")
        log.write(f"  Conda env: {os.environ.get('CONDA_DEFAULT_ENV', 'N/A')}\n")
        log.write(f"  Python: {sys.executable}\n")
        log.write(f"  Working dir: {os.getcwd()}\n")
        log.write(f"  GeoPPI path: {GEOPPI_PATH}\n")
        log.write(f"  Job ID: {job_id}\n")
        log.write(f"{'='*60}\n\n")
        log.write(f"PDB: {pdbfile}\n")
        log.write(f"Partner Info: {partner_info}\n")
        log.write(f"Positions: {mutations}\n")
        log.write(f"{'='*60}\n\n")
    
    with open(outname, "w", newline='') as outcsv, open(log_file, "a") as log:
        writer = csv.writer(outcsv)
        writer.writerow(["Residue", "Wildtype", "Mutation", "DDG (kcal/mol)", "Effect"])
        
        total_mutations = len(mutations) * (len(aa_codes) - 1)
        completed = 0
        
        for mut in mutations:
            wildtype = mut[0]
            chain = mut[1]
            resid = mut[2:]
            
            log.write(f"\nProcessing position {chain}{resid} (wildtype: {wildtype})\n")
            
            for mutant in aa_codes:
                if mutant == wildtype:
                    continue
                
                mutation_str = f"{wildtype}{chain}{resid}{mutant}"
                print(f"Running {mutation_str} ({completed+1}/{total_mutations})")
                log.write(f"  {mutation_str}: ")
                log.flush()
                
                ddg, _ = run_prediction(pdbfile, mutation_str, partner_info)
                
                if ddg:
                    try:
                        ddg_val = float(ddg)
                        if ddg_val < -0.5:
                            effect = "destabilizing"
                        elif ddg_val > 0.5:
                            effect = "stabilizing"
                        else:
                            effect = "neutral"
                    except:
                        effect = "error"
                        ddg_val = ddg
                else:
                    effect = "error"
                    ddg_val = "error"
                
                writer.writerow([f"{chain}{resid}", wildtype, mutant, ddg_val, effect])
                log.write(f"{ddg} kcal/mol ({effect})\n")
                completed += 1
        
        log.write(f"\n{'='*60}\n")
        log.write(f"Completed {completed} mutations\n")
        log.write(f"Results saved to: {outname}\n")

    print(f"\nSaturation mutagenesis complete!")
    print(f"Results saved to: {outname}")
    print(f"Log file: {log_file}")
    
    # Clean up symlinks if created
    if os.path.islink("./foldx"):
        os.unlink("./foldx")
    if os.path.islink("./rotabase.txt"):
        os.unlink("./rotabase.txt")

if __name__ == "__main__":
    main() 