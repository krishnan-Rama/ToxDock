import os

# Directory where your JSON files are located
directory = "."

# Function to rename files
def rename_files_in_directory(directory):
    for filename in os.listdir(directory):
        if filename.startswith("'") and filename.endswith(".json'"):
            # Remove the quotes around the filename
            new_filename = filename.strip("'")
            
            # Replace '|' with '_'
            new_filename = new_filename.replace('|', '_')
            
            # Rename the file
            old_file_path = os.path.join(directory, filename)
            new_file_path = os.path.join(directory, new_filename)
            
            os.rename(old_file_path, new_file_path)
            print(f"Renamed: {filename} -> {new_filename}")
        elif '|' in filename and filename.endswith(".json"):
            # Replace '|' with '_'
            new_filename = filename.replace('|', '_')
            
            # Rename the file
            old_file_path = os.path.join(directory, filename)
            new_file_path = os.path.join(directory, new_filename)
            
            os.rename(old_file_path, new_file_path)
            print(f"Renamed: {filename} -> {new_filename}")

# Run the function to rename files
rename_files_in_directory(directory)

print("All files have been renamed.")

