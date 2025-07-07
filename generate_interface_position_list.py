#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GeoPPI Interface Position List Generator
Combines PyMOL interface detection with advanced position list generation
Features:
- Automatic interface residue detection
- Sequence motif searching
- Interactive mode for residue selection
- Compatible with MutateX/Rosetta format output
"""

import argparse
import sys
import os
import glob
from Bio import PDB
from Bio.Data.IUPACData import protein_letters_3to1
from collections import namedtuple
from pymol import cmd

# Reverse mapping for 3-letter to 1-letter AA codes
three_to_one = {k.upper(): v for k, v in protein_letters_3to1.items()}

# Named tuple for sequence matches
Match = namedtuple("Match", ["chain_id", "start_resnum", "end_resnum", "mismatches", "sequence"])

def extract_interface_residues(pdbfile, chains_info, workdir='temp_interface', cutoff=1.0):
    """Extract interface residues using PyMOL"""
    # Parse pdb name
    namepdb = os.path.basename(pdbfile)
    name = namepdb.split('.')[0]
    
    # Create temp directory
    if not os.path.exists(workdir):
        os.makedirs(workdir)
    
    # Load structure in PyMOL
    cmd.reinitialize()
    cmd.load(pdbfile)
    
    # Parse chains
    chainsAB = chains_info.replace('_', '')
    interfaces = []
    
    # Find all interfaces between specified chains
    for i in range(len(chainsAB)):
        for j in range(i+1, len(chainsAB)):
            cha, chb = chainsAB[i], chainsAB[j]
            if cha == chb:
                continue
            
            # Import InterfaceResidues module if available
            try:
                import InterfaceResidues
                cmd.do(f'interfaceResidues {name}, chain {cha}, chain {chb}')
                
                mapp = {'chA': cha, 'chB': chb}
                temp_file = f'{workdir}/temp_{cha}_{chb}.txt'
                
                if os.path.exists('temp/temp.txt'):
                    with open('temp/temp.txt', 'r') as f:
                        for line in f:
                            linee = line.strip().split('_')
                            if len(linee) >= 2:
                                resid = linee[0]
                                chainn = mapp.get(linee[1], linee[1])
                                inter = f'{cha}_{chb}_{chainn}_{resid}'
                                if inter not in interfaces:
                                    interfaces.append(inter)
                    os.remove('temp/temp.txt')
            except ImportError:
                print("Warning: InterfaceResidues module not found. Using distance-based method.")
                interfaces.extend(find_interface_by_distance(pdbfile, cha, chb, cutoff=5.0))
    
    # Write interface file
    interface_file = f'{workdir}/interface.txt'
    with open(interface_file, 'w') as f:
        for x in interfaces:
            f.write(x + '\n')
    
    cmd.delete('all')
    return interface_file, interfaces

def find_interface_by_distance(pdbfile, chain1, chain2, cutoff=5.0):
    """Fallback method to find interface residues by distance"""
    parser = PDB.PDBParser(QUIET=True)
    structure = parser.get_structure("protein", pdbfile)
    model = structure[0]
    
    interfaces = []
    
    if chain1 not in model or chain2 not in model:
        return interfaces
    
    ch1 = model[chain1]
    ch2 = model[chain2]
    
    # Find residues within cutoff distance
    for res1 in ch1:
        if res1.id[0] != ' ':
            continue
        for res2 in ch2:
            if res2.id[0] != ' ':
                continue
            
            # Check atom distances
            for atom1 in res1:
                for atom2 in res2:
                    dist = atom1 - atom2
                    if dist < cutoff:
                        interfaces.append(f'{chain1}_{chain2}_{chain1}_{res1.id[1]}')
                        interfaces.append(f'{chain1}_{chain2}_{chain2}_{res2.id[1]}')
                        break
                else:
                    continue
                break
    
    return list(set(interfaces))

def parse_interface_file(interface_file, target_chains=None):
    """Parse interface file and extract residue information"""
    interface_residues = []
    
    with open(interface_file, 'r') as f:
        for line in f:
            parts = line.strip().split('_')
            if len(parts) >= 4:
                chain_pair = f"{parts[0]}_{parts[1]}"
                chain = parts[2]
                resid = parts[3]
                
                if target_chains is None or chain in target_chains:
                    interface_residues.append((chain, int(resid)))
    
    return list(set(interface_residues))

def extract_chain_sequence(chain):
    """Extract sequence and residue numbers from a PDB chain"""
    sequence = []
    res_nums = []
    
    for res in chain:
        if res.id[0] != ' ':  # Skip heteroatoms/waters
            continue
        resname = res.resname.upper()
        if resname in three_to_one:
            sequence.append(three_to_one[resname])
        else:
            sequence.append('X')  # Unknown residue
        res_nums.append(res.id[1])
    
    return sequence, res_nums

def find_sequence_matches(structure, query, max_mismatches=0):
    """Find all occurrences of a query sequence in the PDB structure"""
    model = structure[0]
    query = query.upper()
    matches = []
    
    for chain in model:
        chain_id = chain.id
        sequence, res_nums = extract_chain_sequence(chain)
        
        if not sequence or len(sequence) < len(query):
            continue
        
        # Search for matches with sliding window
        for i in range(len(sequence) - len(query) + 1):
            window = sequence[i:i+len(query)]
            mismatches = sum(a != b for a, b in zip(query, window))
            
            if mismatches <= max_mismatches:
                start_res = res_nums[i]
                end_res = res_nums[i + len(query) - 1]
                matched_seq = ''.join(window)
                matches.append(Match(chain_id, start_res, end_res, mismatches, matched_seq))
    
    return matches

def generate_position_list(structure, positions, output_file, format='mutatex'):
    """Generate position list in MutateX or Rosetta format"""
    model = structure[0]
    pos_entries = []
    
    for chain_id, resnum in positions:
        if chain_id not in model:
            continue
        
        chain = model[chain_id]
        for res in chain:
            if res.id[0] != ' ' or res.id[1] != resnum:
                continue
            
            res_3letter = res.resname.capitalize()
            if res_3letter not in three_to_one:
                continue
            
            one_letter = three_to_one[res_3letter]
            
            if format == 'mutatex':
                pos_entry = f"{one_letter}{chain_id}{resnum}"
            else:  # rosetta format
                pos_entry = f"{resnum}{chain_id}"
            
            pos_entries.append(pos_entry)
            break
    
    # Remove duplicates and sort
    pos_entries = sorted(list(set(pos_entries)))
    
    # Write output file
    with open(output_file, 'w') as f:
        for entry in pos_entries:
            f.write(entry + "\n")
    
    return pos_entries

def interactive_mode(structure, interface_residues=None):
    """Interactive mode for exploring and selecting positions"""
    model = structure[0]
    
    print("\n=== Interactive Mode ===")
    
    # Show interface residues if available
    if interface_residues:
        print(f"\nFound {len(interface_residues)} interface residues:")
        by_chain = {}
        for chain, resnum in interface_residues:
            if chain not in by_chain:
                by_chain[chain] = []
            by_chain[chain].append(resnum)
        
        for chain in sorted(by_chain.keys()):
            resnums = sorted(by_chain[chain])
            print(f"  Chain {chain}: {len(resnums)} residues")
            if len(resnums) <= 10:
                print(f"    Residues: {', '.join(map(str, resnums))}")
            else:
                print(f"    Residues: {', '.join(map(str, resnums[:5]))} ... {', '.join(map(str, resnums[-5:]))}")
    
    positions = []
    
    while True:
        print("\nOptions:")
        print("  1. Use all interface residues")
        print("  2. Filter interface residues by chain")
        print("  3. Search for sequence motif in interface")
        print("  4. Add specific residues manually")
        print("  5. Done - generate position list")
        
        choice = input("\nSelect option (1-5): ").strip()
        
        if choice == '1':
            if interface_residues:
                positions.extend(interface_residues)
                print(f"Added {len(interface_residues)} interface residues")
            else:
                print("No interface residues available")
        
        elif choice == '2':
            if not interface_residues:
                print("No interface residues available")
                continue
            
            chains = sorted(set(chain for chain, _ in interface_residues))
            print(f"\nAvailable chains: {', '.join(chains)}")
            selected = input("Select chains (comma-separated): ").strip().upper()
            
            if selected:
                selected_chains = [c.strip() for c in selected.split(',')]
                filtered = [(c, r) for c, r in interface_residues if c in selected_chains]
                positions.extend(filtered)
                print(f"Added {len(filtered)} residues from chain(s) {', '.join(selected_chains)}")
        
        elif choice == '3':
            query = input("Enter sequence to search (1-letter code): ").strip().upper()
            if not query:
                continue
            
            matches = find_sequence_matches(structure, query)
            if not matches:
                print(f"No matches found for '{query}'")
            else:
                print(f"\nFound {len(matches)} match(es):")
                for i, match in enumerate(matches):
                    # Check overlap with interface
                    overlap = []
                    if interface_residues:
                        for resnum in range(match.start_resnum, match.end_resnum + 1):
                            if (match.chain_id, resnum) in interface_residues:
                                overlap.append(resnum)
                    
                    overlap_info = f" (interface: {len(overlap)} residues)" if overlap else ""
                    print(f"  {i+1}. Chain {match.chain_id}: {match.start_resnum}-{match.end_resnum} [{match.sequence}]{overlap_info}")
                
                selected = input("\nSelect matches (comma-separated numbers, or 'all'): ").strip()
                if selected.lower() == 'all':
                    for match in matches:
                        for resnum in range(match.start_resnum, match.end_resnum + 1):
                            positions.append((match.chain_id, resnum))
                elif selected:
                    indices = [int(x.strip()) - 1 for x in selected.split(',') if x.strip().isdigit()]
                    for i in indices:
                        if 0 <= i < len(matches):
                            match = matches[i]
                            for resnum in range(match.start_resnum, match.end_resnum + 1):
                                positions.append((match.chain_id, resnum))
        
        elif choice == '4':
            residues = input("Enter residues (e.g., A30,A31,B50): ").strip().upper()
            if residues:
                for res in residues.split(','):
                    res = res.strip()
                    if len(res) >= 2:
                        chain = res[0]
                        try:
                            resnum = int(res[1:])
                            positions.append((chain, resnum))
                        except ValueError:
                            print(f"Invalid residue format: {res}")
        
        elif choice == '5':
            break
    
    return list(set(positions))

def main():
    parser = argparse.ArgumentParser(
        description="Generate position lists from GeoPPI interface analysis",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic interface analysis
  %(prog)s -p structure.pdb -c AB_CD -o positions.txt
  
  # Interactive mode
  %(prog)s -p structure.pdb -c AB_CD -i
  
  # Include non-interface residues
  %(prog)s -p structure.pdb -c AB_CD --include-spans A:30-40 B:50-60
  
  # Search for motif in interfaces
  %(prog)s -p structure.pdb -c AB_CD -q EVQLVQ
  
  # Rosetta format output
  %(prog)s -p structure.pdb -c AB_CD -f rosetta -o resfile.txt
        """
    )
    
    parser.add_argument("-p", "--pdb", required=True, help="Input PDB file")
    parser.add_argument("-c", "--chains", required=True, help="Chain pairs for interface (e.g., AB_CD for interfaces between AB and CD)")
    parser.add_argument("-o", "--output", default="position_list.txt", help="Output file name")
    parser.add_argument("-f", "--format", choices=['mutatex', 'rosetta'], default='mutatex', 
                       help="Output format (default: mutatex)")
    parser.add_argument("-i", "--interactive", action='store_true', help="Interactive mode")
    parser.add_argument("-q", "--query", help="Search for sequence motif in structure")
    parser.add_argument("--include-spans", nargs='+', help="Additional residue spans to include")
    parser.add_argument("--interface-only", action='store_true', help="Only include interface residues")
    parser.add_argument("--cutoff", type=float, default=1.0, help="Interface cutoff for PyMOL (default: 1.0)")
    parser.add_argument("--workdir", default="temp_interface", help="Working directory for temporary files")
    
    args = parser.parse_args()
    
    print(f"Analyzing interfaces in {args.pdb}")
    print(f"Chain pairs: {args.chains}")
    
    # Extract interface residues
    interface_file, interface_raw = extract_interface_residues(
        args.pdb, args.chains, args.workdir, args.cutoff
    )
    
    # Parse interface residues
    interface_residues = parse_interface_file(interface_file)
    print(f"Found {len(interface_residues)} interface residues")
    
    # Load structure for further analysis
    pdb_parser = PDB.PDBParser(QUIET=True)
    structure = pdb_parser.get_structure("protein", args.pdb)
    
    # Collect positions
    positions = []
    
    # Add interface residues by default unless --interface-only is False
    if args.interface_only or not (args.include_spans or args.query or args.interactive):
        positions.extend(interface_residues)
    
    # Interactive mode
    if args.interactive:
        selected = interactive_mode(structure, interface_residues)
        positions.extend(selected)
    
    # Query sequence search
    if args.query:
        matches = find_sequence_matches(structure, args.query)
        print(f"\nFound {len(matches)} matches for '{args.query}':")
        for match in matches:
            print(f"  Chain {match.chain_id}: {match.start_resnum}-{match.end_resnum}")
            for resnum in range(match.start_resnum, match.end_resnum + 1):
                positions.append((match.chain_id, resnum))
    
    # Additional spans
    if args.include_spans:
        for span in args.include_spans:
            if ':' in span and '-' in span:
                chain, rng = span.split(':')
                start, end = map(int, rng.split('-'))
                for resnum in range(start, end + 1):
                    positions.append((chain, resnum))
    
    # Remove duplicates
    positions = list(set(positions))
    
    # Generate position list
    if positions:
        pos_entries = generate_position_list(structure, positions, args.output, args.format)
        print(f"\nGenerated {len(pos_entries)} positions")
        print(f"Output saved to: {args.output}")
    else:
        print("\nNo positions selected!")
    
    # Clean up
    if os.path.exists(args.workdir) and not args.interactive:
        import shutil
        shutil.rmtree(args.workdir)

if __name__ == "__main__":
    main() 