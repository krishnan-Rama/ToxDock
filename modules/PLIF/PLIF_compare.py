import MDAnalysis as mda
import numpy as np
import pandas as pd
import os
import glob
from MDAnalysis.analysis import distances

# File paths
protein_dir = "/mnt/scratch/c23048124/lep_chlorpyrifos/workdir/swissdock/pdbqt_ache_files/aligned/*.pdbqt"
ligand_dir = "/mnt/scratch/c23048124/lep_chlorpyrifos/workdir/swissdock/vina_results/*.pdbqt"
output_file = "plif_comparison_output.csv"

# Define interaction types and distance cutoffs
hydrogen_bond_distance_cutoff = 3.5  # Angstrom
hydrophobic_cutoff = 4.0  # Distance cutoff for hydrophobic interactions

# Function to calculate distances between protein and ligand atoms
def calculate_distances(protein, ligand):
    distances_matrix = distances.distance_array(protein.positions, ligand.positions)
    return distances_matrix

# Detect hydrogen bonds (based on distance between donor and acceptor atoms)
def detect_hydrogen_bonds(protein, ligand, cutoff):
    distances_matrix = calculate_distances(protein, ligand)
    hbond_contacts = np.argwhere(distances_matrix < cutoff)  # Pairs with distances < cutoff
    return hbond_contacts

# Detect hydrophobic interactions (based on distance between hydrophobic atoms)
def detect_hydrophobic_interactions(protein, ligand, cutoff):
    hydrophobic_protein = protein.select_atoms("name CA CB CG CD CE CZ")
    hydrophobic_ligand = ligand.select_atoms("name C CA CB")
    distances_matrix = calculate_distances(hydrophobic_protein, hydrophobic_ligand)
    hydrophobic_contacts = np.argwhere(distances_matrix < cutoff)
    return hydrophobic_contacts

# Generate PLIF
def generate_plif(hbond_contacts, hydrophobic_contacts, protein, ligand):
    plif_dict = {}
    for idx, contact in enumerate(hbond_contacts):
        protein_residue = protein[contact[0]].resname + str(protein[contact[0]].resid)
        ligand_atom = ligand[contact[1]].name
        plif_dict[f'HBond_{idx}'] = f"{protein_residue}-{ligand_atom}"

    for idx, contact in enumerate(hydrophobic_contacts):
        protein_residue = protein[contact[0]].resname + str(protein[contact[0]].resid)
        ligand_atom = ligand[contact[1]].name
        plif_dict[f'Hydrophobic_{idx}'] = f"{protein_residue}-{ligand_atom}"

    return plif_dict

# Compare PLIFs across multiple proteins
def compare_plifs(plif_dicts):
    comparison_matrix = []
    proteins = list(plif_dicts.keys())
    
    for i in range(len(proteins)):
        for j in range(i+1, len(proteins)):
            protein1 = proteins[i]
            protein2 = proteins[j]
            shared_interactions = set(plif_dicts[protein1].values()) & set(plif_dicts[protein2].values())
            comparison_matrix.append({
                "Protein 1": protein1,
                "Protein 2": protein2,
                "Shared Interactions": len(shared_interactions),
                "Total Interactions in Protein 1": len(plif_dicts[protein1]),
                "Total Interactions in Protein 2": len(plif_dicts[protein2])
            })
    
    return pd.DataFrame(comparison_matrix)

# Function to extract the first model from a PDBQT file
def extract_first_model(pdbqt_file):
    with open(pdbqt_file, 'r') as f:
        lines = f.readlines()
    
    first_model = []
    inside_model = False
    for line in lines:
        if line.startswith("MODEL"):
            inside_model = True
        elif line.startswith("ENDMDL"):
            break
        elif inside_model:
            first_model.append(line)
    
    return first_model

# Iterate through all protein PDBQT files and compute PLIFs
plif_dicts = {}

# Loop through each protein PDBQT file
for protein_file in glob.glob(protein_dir):
    # Strip any trailing numeric suffix (e.g., .1, .2, .3) from the protein file name
    protein_name = os.path.basename(protein_file).split(".")[0]
    stripped_protein_name = protein_name.split(".")[0]  # Removes any numeric suffix
    
    print(f"Processing {protein_name}...")
    
    # Construct the correct path to the corresponding ligand file
    corresponding_ligand_file = os.path.join("/mnt/scratch/c23048124/lep_chlorpyrifos/workdir/swissdock/vina_results", stripped_protein_name + ".1_docked.pdbqt")
    
    # Print the corresponding ligand and protein file for debugging
    print(f"Protein file: {protein_file}")
    print(f"Expected ligand file: {corresponding_ligand_file}")
    
    # Ensure the corresponding ligand file exists
    if not os.path.exists(corresponding_ligand_file):
        print(f"Ligand file not found for {protein_name}. Skipping...")
        continue
    
    print(f"Ligand file found: {corresponding_ligand_file}")

    # Load the protein (PDBQT) and docked ligand (PDBQT format)
    u_protein = mda.Universe(protein_file)  # Load the protein structure
    ligand_model_lines = extract_first_model(corresponding_ligand_file)

    # Write the extracted first model to a temporary PDBQT file
    temp_pdbqt = "temp_first_model.pdbqt"
    with open(temp_pdbqt, 'w') as temp_file:
        temp_file.writelines(ligand_model_lines)

    u_ligand = mda.Universe(temp_pdbqt)  # Load the docked ligand

    # Select the protein and ligand atoms
    protein = u_protein.select_atoms("not resname UNL")  # Select all protein atoms (assuming ligand is labeled UNL)
    ligand = u_ligand.select_atoms("resname UNL")  # Select the ligand atoms (resname 'UNL')

    # Ensure that the selections are valid
    if len(protein) == 0 or len(ligand) == 0:
        print(f"Skipping {protein_name}, could not find valid protein or ligand selection.")
        continue

    # Detect interactions
    hbond_contacts = detect_hydrogen_bonds(protein, ligand, hydrogen_bond_distance_cutoff)
    hydrophobic_contacts = detect_hydrophobic_interactions(protein, ligand, hydrophobic_cutoff)

    # Generate PLIF for this protein-ligand complex
    plif_dicts[protein_name] = generate_plif(hbond_contacts, hydrophobic_contacts, protein, ligand)

# Compare PLIFs and save results
comparison_df = compare_plifs(plif_dicts)
comparison_df.to_csv(output_file, index=False)
print(f"Comparison data saved to {output_file}")

# Display the comparison DataFrame
print(comparison_df)

