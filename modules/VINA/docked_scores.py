import os
import csv
import re

# Function to extract the top affinity and Rmsd values from MODEL 1
def extract_affinity_and_rmsd(file_path):
    affinity = None
    rmsd_lb = None
    rmsd_ub = None
    with open(file_path, 'r') as f:
        for line in f:
            if line.startswith("MODEL 1"):
                next_line = next(f)
                if "REMARK VINA RESULT" in next_line:
                    parts = next_line.split()
                    affinity = parts[3]  # Affinity value
                    rmsd_lb = parts[4]   # Rmsd L.B.
                    rmsd_ub = parts[5]   # Rmsd U.B.
                break  # Only need MODEL 1, stop after finding it
    return affinity, rmsd_lb, rmsd_ub

# Function to extract organism and protein mappings from the OG0002602_tree.txt file
def parse_organism_tree(tree_file):
    organism_map = {}
    
    with open(tree_file, 'r') as f:
        tree_data = f.read()
        # This regex will match the species-protein format, handling both BRAKER and ENS* patterns
        matches = re.findall(r'([A-Za-z_]+(?:-GCA_[\d_]+)?)\S+pep\S+?(XP_[\d|\.]+|ENS\w+|BRAKER\w+|sp\|[\w]+)', tree_data)
        for match in matches:
            species = match[0].replace('_', ' ')  # Extract species name and replace underscores with spaces
            protein_id = match[1].replace('|', '_')  # Adjust formatting to match IDs in CSV
            organism_map[protein_id] = species
    return organism_map

# Function to update the CSV with the organism column
def update_csv_with_organisms(csv_file, organism_map):
    updated_rows = []
    
    # Read the CSV file and append the organism column
    with open(csv_file, 'r', newline='') as infile:
        reader = csv.reader(infile)
        header = next(reader)
        header.append('Organism')  # Add a new header for Organism
        updated_rows.append(header)
        
        for row in reader:
            protein_id = row[0]  # First column contains protein IDs
            organism = organism_map.get(protein_id, "Unknown")  # Get organism from the map or default to "Unknown"
            row.append(organism)
            updated_rows.append(row)
    
    # Write the updated CSV file
    with open(f'updated_{csv_file}', 'w', newline='') as outfile:
        writer = csv.writer(outfile)
        writer.writerows(updated_rows)

# Main function to process all docked PDBQT files and update the CSV with organism data
def process_docking_results(directory, tree_file):
    csv_file = "docked_scores_with_rmsd.csv"
    
    # Create a CSV file to store the results
    with open(csv_file, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        # Write header row
        writer.writerow(['File Name', 'Top Affinity (kcal/mol)', 'Dist from Rmsd L.B.', 'Dist from Rmsd U.B.'])

        # Loop through files in the directory
        for filename in os.listdir(directory):
            if filename.endswith("_docked.pdbqt"):
                file_path = os.path.join(directory, filename)
                base_name = filename.split('_docked.pdbqt')[0]  # Extract file name before *_docked.pdbqt
                affinity, rmsd_lb, rmsd_ub = extract_affinity_and_rmsd(file_path)
                if affinity is not None:
                    # Write file name, affinity, and Rmsd values to the CSV
                    writer.writerow([base_name, affinity, rmsd_lb, rmsd_ub])

    # Parse organism information from the tree file
    organism_map = parse_organism_tree(tree_file)

    # Update the CSV file with the organism information
    update_csv_with_organisms(csv_file, organism_map)

    print(f"Data has been written to updated_{csv_file}")


# Define the paths
directory = "."  # Path to the directory containing docked files
tree_file = "/mnt/scratch/c23048124/lep_chlorpyrifos/raw_data/orthofinder_files/OG0004829_tree.txt"  # Path to the tree file

# Run the process
process_docking_results(directory, tree_file)

