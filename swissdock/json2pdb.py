import requests
import gzip
import shutil

# URL from the JSON data
url = "https://swissmodel.expasy.org/project/2ef61c/models/01.pdb.gz"

# Download the gzipped PDB file
response = requests.get(url)
pdb_gz_file = 'model_result_BRAKERAMYP00010002495.1.pdb.gz'

with open(pdb_gz_file, 'wb') as f:
    f.write(response.content)

# Decompress the gzipped PDB file (optional)
with gzip.open(pdb_gz_file, 'rb') as f_in:
    with open('model_result_BRAKERAMYP00010002495.1.pdb', 'wb') as f_out:
        shutil.copyfileobj(f_in, f_out)

print(f"PDB file downloaded and saved as {pdb_gz_file}.")

