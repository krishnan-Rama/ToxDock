import pandas as pd
import os
import glob
import subprocess

# Paths
protein_files_path = '/mnt/scratch/c23048124/lep_chlorpyrifos/workdir/swissdock/pdb_files/aligned/ucompressed/*.pdb'
docked_files_path_oxon = '/mnt/scratch/c23048124/lep_chlorpyrifos/workdir/swissdock/vina_results/chlorpyrifosoxon/*.pdbqt'
docked_files_path_chlorpyrifos = '/mnt/scratch/c23048124/lep_chlorpyrifos/workdir/swissdock/vina_results/*.pdbqt'
csv_file_path = 'MAPPED_Docking_Data_with_QMEAN_Score.csv'

# Step 1: Load the existing CSV file
df = pd.read_csv(csv_file_path)

# Step 2: Load Docked Files for Chlorpyrifos and Chlorpyrifos-oxon
protein_files = glob.glob(protein_files_path)
docked_files_oxon = glob.glob(docked_files_path_oxon)
docked_files_chlorpyrifos = glob.glob(docked_files_path_chlorpyrifos)

# Step 3: Analyze Binding Pockets using FPocket
def analyze_binding_pockets_with_fpocket(protein_file):
    # Run FPocket on each protein file
    subprocess.run(['fpocket', '-f', protein_file], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    # The output directory will be protein_file_out/
    output_folder = protein_file.replace('.pdb', '_out')
    pockets_folder = os.path.join(output_folder, 'pockets')
    
    # Initialize variables to capture pocket scores
    pocket_scores = []
    
    # Check if pockets folder exists
    if os.path.exists(pockets_folder):
        # Loop over all pocket files in the pockets folder
        for pocket_file in glob.glob(os.path.join(pockets_folder, 'pocket*_atm.pdb')):
            with open(pocket_file, 'r') as f:
                for line in f:
                    # Extract Pocket Score from the header
                    if "Pocket Score" in line:
                        score = float(line.split(":")[1].strip())
                        pocket_scores.append(score)
                        break
    
    # Return the highest pocket score (or 0 if no pockets were found)
    return max(pocket_scores, default=0)

# Step 4: Map Pocket Scores for both Chlorpyrifos-oxon and Chlorpyrifos
pocket_scores_oxon = {}
pocket_scores_chlorpyrifos = {}

for protein_file in protein_files:
    protein_basename = os.path.basename(protein_file)
    
    # Analyze pocket score for Chlorpyrifos-oxon
    pocket_score_oxon = analyze_binding_pockets_with_fpocket(protein_file)
    pocket_scores_oxon[protein_basename] = pocket_score_oxon
    
    # Analyze pocket score for Chlorpyrifos (use the same protein file)
    pocket_score_chlorpyrifos = analyze_binding_pockets_with_fpocket(protein_file)
    pocket_scores_chlorpyrifos[protein_basename] = pocket_score_chlorpyrifos

# Step 5: Update the CSV with the Pocket Scores
def map_pocket_scores_to_csv(df, pocket_scores_oxon, pocket_scores_chlorpyrifos):
    # Map pocket scores for Chlorpyrifos-oxon
    df['Pocket Score - Chlorpyrifos-oxon'] = df['AChE targets'].apply(
        lambda target: pocket_scores_oxon.get(target + '.pdb', None)
    )
    
    # Map pocket scores for Chlorpyrifos
    df['Pocket Score - Chlorpyrifos'] = df['AChE targets'].apply(
        lambda target: pocket_scores_chlorpyrifos.get(target + '.pdb', None)
    )

# Apply the pocket score mapping
map_pocket_scores_to_csv(df, pocket_scores_oxon, pocket_scores_chlorpyrifos)

# Step 6: Save the updated CSV
output_csv_path = 'Updated_MAPPED_Docking_Data_with_Pocket_Scores.csv'
df.to_csv(output_csv_path, index=False)

print(f"Updated CSV file saved at: {output_csv_path}")

