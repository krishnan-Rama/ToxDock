import os
import requests
import time

# Define the paths to the input files
fasta_file = "/mnt/scratch15/c23048124/metal/transpipeline_containerised/modules/OrthoFinder_source/ExampleData_2/OrthoFinder/Results_Aug09_2/Orthogroup_Sequences/OG0000059.fa"
pdb_file = "/mnt/scratch15/c23048124/metal/transpipeline_containerised/nAChRalpha1.pdb"

# Define the output directory
output_dir = "/mnt/scratch15/c23048124/metal/transpipeline_containerised/swissmodel_results"
os.makedirs(output_dir, exist_ok=True)

# Your SWISS-MODEL API token
api_token = '6b3267eb8a64579f08c96fa968c39333309ee656'

# Function to submit a sequence to SWISS-MODEL
def submit_to_swissmodel(sequence, pdb_file, project_title):
    with open(pdb_file, 'r') as f:
        template_coordinates = f.read()

    response = requests.post(
        "https://swissmodel.expasy.org/user_template",
        headers={"Authorization": f"Token {api_token}"},
        json={
            "target_sequences": sequence,
            "template_coordinates": template_coordinates,
            "project_title": project_title
        }
    )
    return response

# Function to check job status
def check_job_status(project_id):
    while True:
        time.sleep(10)  # Wait for 10 seconds before checking status
        response = requests.get(
            f"https://swissmodel.expasy.org/project/{project_id}/models/summary/",
            headers={"Authorization": f"Token {api_token}"}
        )
        status = response.json()["status"]
        print('Job status is now', status)
        if status in ["COMPLETED", "FAILED"]:
            return status, response.json()
        
# Read the FASTA file and split into individual sequences
with open(fasta_file, 'r') as file:
    sequences = file.read().split('>')[1:]  # Skip the first empty split

# Iterate over each sequence and submit it to SWISS-MODEL
for idx, seq in enumerate(sequences):
    seq_id = seq.split('\n', 1)[0].strip()
    seq_data = seq.split('\n', 1)[1].replace('\n', '')

    # Submit the sequence to SWISS-MODEL
    print(f"Submitting sequence {seq_id} to SWISS-MODEL...")
    response = submit_to_swissmodel(seq_data, pdb_file, f"Modeling for {seq_id}")

    if response.status_code in [200, 202]:
        project_id = response.json()["project_id"]
        status, result_data = check_job_status(project_id)
        
        if status == "COMPLETED":
            # Save the results if successful
            result_file_path = os.path.join(output_dir, f"model_result_{seq_id}.json")
            with open(result_file_path, 'w') as result_file:
                result_file.write(str(result_data))  # Saving JSON data
            print(f"Model for {seq_id} saved to {result_file_path}.")
        else:
            print(f"Modeling failed for {seq_id}.")
    else:
        print(f"Failed to submit sequence {seq_id}. Status code: {response.status_code}, Message: {response.text}")

print("All sequences processed.")

