
import os
import json
import requests
import time

# Directory where your JSON files are located
json_dir = "."  # Assuming you're running this script in the directory with the JSON files

# Output directory where you want to save the PDB files
output_dir = "./pdb_files"
os.makedirs(output_dir, exist_ok=True)

# Function to download a PDB file given its URL with retry mechanism
def download_pdb_file(pdb_url, pdb_file_name, max_retries=5):
    retries = 0
    while retries < max_retries:
        response = requests.get(pdb_url)
        if response.status_code == 200:
            pdb_file_path = os.path.join(output_dir, pdb_file_name)
            with open(pdb_file_path, 'wb') as pdb_file:
                pdb_file.write(response.content)
            print(f"PDB file saved to {pdb_file_path}.")
            return
        elif response.status_code == 429:
            retries += 1
            wait_time = 2 ** retries  # Exponential backoff
            print(f"Rate limit reached. Retrying in {wait_time} seconds...")
            time.sleep(wait_time)
        else:
            print(f"Failed to download PDB file from {pdb_url}. Status code: {response.status_code}")
            return

# Iterate through each JSON file in the directory
for json_file_name in os.listdir(json_dir):
    if json_file_name.endswith(".json"):
        json_file_path = os.path.join(json_dir, json_file_name)
        with open(json_file_path, 'r') as json_file:
            try:
                # Read the file content
                file_content = json_file.read()

                # Replace single quotes with double quotes
                file_content = file_content.replace("'", '"')

                # Load the JSON data
                data = json.loads(file_content)
                
                # Extract the PDB URL
                pdb_url = data['models'][0]['coordinates_url']
                
                # Create the PDB file name by removing "model_result_" and changing extension to .pdb.gz
                pdb_file_name = json_file_name.replace('model_result_', '').replace('.json', '.pdb.gz')
                
                # Download the PDB file with retry mechanism
                download_pdb_file(pdb_url, pdb_file_name)
            
            except (KeyError, IndexError, json.JSONDecodeError) as e:
                print(f"Error processing {json_file_name}: {e}")

print("All PDB files have been downloaded.")

