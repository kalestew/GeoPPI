#!/usr/bin/env python3
"""
Script to generate batch saturation job inputs for GeoPPI from a positions.txt file.

Usage:
    python prepare_batch_saturation.py positions.txt pdb_file
    
This will generate:
    1. A list of residues to mutate for batch_saturation.py
    2. The partner info string for GeoPPI
    3. The complete command to run
"""

import sys
import os
from collections import defaultdict

def parse_positions_file(positions_file):
    """
    Parse positions.txt file with format:
    B.S.133 C
    A.C.23 C
    
    Returns:
        residues: list of residue strings for batch_saturation.py (e.g., ["SA23", "BS133"])
        partner_chains: dict mapping chains to their interaction type
    """
    residues = []
    partner_chains = defaultdict(set)
    antigen_chains = set()
    antibody_chains = set()
    
    with open(positions_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
                
            parts = line.split()
            if len(parts) != 2:
                print(f"Warning: Skipping invalid line: {line}")
                continue
                
            residue_info = parts[0]
            move_chain = parts[1]  # The antigen chain marker
            
            # Parse B.S.133 format
            res_parts = residue_info.split('.')
            if len(res_parts) != 3:
                print(f"Warning: Skipping invalid residue format: {residue_info}")
                continue
                
            chain = res_parts[0]
            wildtype_aa = res_parts[1]
            resnum = res_parts[2]
            
            # Create residue string for batch_saturation.py
            residue_str = f"{wildtype_aa}{chain}{resnum}"
            residues.append(residue_str)
            
            # Track chains - The chain where the residue is located
            # (not the move_chain marker which is always 'C' in this format)
            # We'll need to infer antibody vs antigen from the PDB or user input
            # For now, add all chains and sort them out later
            partner_chains[chain].add(move_chain)
    
    # Get all unique chains from the positions file
    all_chains = set(chain for chain in partner_chains.keys())
    
    # Try to infer antibody vs antigen chains based on common patterns
    # Common antibody chains: H, L, K (kappa), M (lambda)
    # Common antigen chains: A, B, C, P, W, V, X, Y, Z
    antibody_patterns = {'H', 'L', 'K', 'M'}
    antigen_patterns = {'A', 'B', 'C', 'P', 'W', 'V', 'X', 'Y', 'Z'}
    
    # First, try to assign based on common patterns
    for chain in all_chains:
        if chain in antibody_patterns:
            antibody_chains.add(chain)
        elif chain in antigen_patterns:
            antigen_chains.add(chain)
    
    # If we couldn't classify all chains, put remaining in antigen
    unclassified = all_chains - antibody_chains - antigen_chains
    antigen_chains.update(unclassified)
    
    return residues, antibody_chains, antigen_chains


def generate_partner_info(antibody_chains, antigen_chains):
    """
    Generate partner info string for GeoPPI.
    Format: antibody_antigen (e.g., "AB_C" or "HL_WV")
    """
    antibody_str = ''.join(sorted(antibody_chains))
    antigen_str = ''.join(sorted(antigen_chains))
    
    return f"{antibody_str}_{antigen_str}"


def main():
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print("Usage: python3 prepare_batch_saturation.py positions.txt pdb_file [partner_info]")
        print("Example: python3 prepare_batch_saturation.py positions.txt 1CZ8.pdb")
        print("Example with explicit partners: python3 prepare_batch_saturation.py positions.txt 1CZ8.pdb HL_WV")
        print("\nNote: partner_info format is antibody_antigen (e.g., HL_WV means H,L chains bind to W,V chains)")
        print("If not specified, chains will be inferred based on common patterns:")
        print("  Antibody chains: H, L, K, M")
        print("  Antigen chains: A, B, C, P, W, V, X, Y, Z")
        sys.exit(1)
    
    positions_file = sys.argv[1]
    pdb_file = sys.argv[2]
    explicit_partners = sys.argv[3] if len(sys.argv) == 4 else None
    
    if not os.path.exists(positions_file):
        print(f"Error: positions.txt file '{positions_file}' not found")
        sys.exit(1)
        
    if not os.path.exists(pdb_file):
        print(f"Error: PDB file '{pdb_file}' not found")
        sys.exit(1)
    
    # Parse positions file
    residues, antibody_chains, antigen_chains = parse_positions_file(positions_file)
    
    if not residues:
        print("Error: No valid residues found in positions file")
        sys.exit(1)
    
    # If explicit partners provided, override the inferred chains
    if explicit_partners:
        if '_' not in explicit_partners:
            print(f"Error: Invalid partner format '{explicit_partners}'. Expected format: antibody_antigen (e.g., HL_WV)")
            sys.exit(1)
        
        antibody_str, antigen_str = explicit_partners.split('_', 1)
        antibody_chains = set(antibody_str)
        antigen_chains = set(antigen_str)
        partner_info = explicit_partners
    else:
        # Generate partner info from inferred chains
        partner_info = generate_partner_info(antibody_chains, antigen_chains)
    
    # Create residue list string for batch_saturation.py
    residue_list = ' '.join(residues)
    
    # Generate the command
    command = f'python3 batch_saturation.py {pdb_file} "{residue_list}" {partner_info}'
    
    # Output results
    print("\n=== GeoPPI Batch Saturation Job Configuration ===")
    print(f"PDB file: {pdb_file}")
    print(f"Number of positions to mutate: {len(residues)}")
    print(f"Antibody chains: {', '.join(sorted(antibody_chains))}")
    print(f"Antigen chains: {', '.join(sorted(antigen_chains))}")
    print(f"Partner info: {partner_info}")
    print(f"\nResidue list: {residue_list}")
    print(f"\n=== Command to run ===")
    print(command)
    
    # Optionally save command to file
    output_file = os.path.splitext(positions_file)[0] + "_batch_command.sh"
    with open(output_file, 'w') as f:
        f.write("#!/bin/bash\n")
        f.write(f"# Auto-generated batch saturation command from {positions_file}\n")
        f.write(f"{command}\n")
    print(f"\nCommand also saved to: {output_file}")
    
    # Also create a summary file
    summary_file = os.path.splitext(positions_file)[0] + "_saturation_summary.txt"
    with open(summary_file, 'w') as f:
        f.write(f"PDB file: {pdb_file}\n")
        f.write(f"Positions file: {positions_file}\n")
        f.write(f"Number of positions: {len(residues)}\n")
        f.write(f"Antibody chains: {', '.join(sorted(antibody_chains))}\n")
        f.write(f"Antigen chains: {', '.join(sorted(antigen_chains))}\n")
        f.write(f"Partner info: {partner_info}\n")
        f.write(f"\nPositions to mutate:\n")
        for res in residues:
            f.write(f"  {res}\n")
    print(f"Summary saved to: {summary_file}")
    

if __name__ == "__main__":
    main() 