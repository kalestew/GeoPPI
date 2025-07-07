import os
import subprocess
import sys
import csv

# Canonical amino acids (1-letter code)
aa_codes = ['A','R','N','D','C','Q','E','G','H','I',
            'L','K','M','F','P','S','T','W','Y','V']

def run_prediction(pdbfile, mutation, partner_info):
    cmd = f"python run.py {pdbfile} {mutation} {partner_info}"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    output = result.stdout

    ddg = None
    for line in output.splitlines():
        if "The predicted binding affinity change" in line:
            ddg = line.strip().split("is")[1].split("kcal")[0].strip()
            break

    if ddg is None:
        print(f"--- run.py output for {mutation} ---")
        print(output)
        print("------------------------------------")

    return ddg, output

def main():
    if len(sys.argv) != 4:
        print("Usage: python batch_mutagenesis.py <pdbfile> <resid_list> <partner_info>")
        print("Example: python batch_mutagenesis.py 1CZ8.pdb \"KW84 HL112\" WV_HL")
        sys.exit(1)

    pdbfile = sys.argv[1]
    mutations = sys.argv[2].split()   # E.g. KW84 HL112
    partner_info = sys.argv[3]

    outname = os.path.basename(pdbfile).split('.')[0] + "_saturation_ddg.csv"
    with open(outname, "w", newline='') as outcsv:
        writer = csv.writer(outcsv)
        writer.writerow(["Residue", "Mutation", "DDG (kcal/mol)"])

        for mut in mutations:
            wildtype = mut[0]
            chain = mut[1]
            resid = mut[2:]
            for mutant in aa_codes:
                if mutant == wildtype:
                    continue
                mutation_str = f"{wildtype}{chain}{resid}{mutant}"
                ddg, _ = run_prediction(pdbfile, mutation_str, partner_info)
                writer.writerow([f"{chain}{resid}", mutant, ddg if ddg else "error"])
                print(f"{mutation_str}: {ddg}")

if __name__ == "__main__":
    main()
