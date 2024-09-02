#!/bin/bash

#SBATCH --job-name=pdbqt   # Job name
#SBATCH --partition=jumbo                    # Requested queue (replace with actual partition)
#SBATCH --nodes=1                            # Number of nodes to use
#SBATCH --tasks-per-node=1                   # Tasks per node
#SBATCH --cpus-per-task=16                   # Number of CPU cores per task
#SBATCH --mem-per-cpu=10000                  # Memory per CPU in megabytes

echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo "\$SLURM_JOB_ID=${SLURM_JOB_ID}"
echo "\$SLURM_NTASKS=${SLURM_NTASKS}"
echo "\$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}"
echo "\$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}"
echo "\$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}"
echo "\$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}"

# Write jobscript to output file (good for reproducibility)
cat $0

# Load Singularity module
module load singularity/3.8.7

# Define the Singularity image and input/output paths
IMAGE_NAME=autodock:4.2.6--h9f5acd7_2
INPUT_DIR=/mnt/scratch/c23048124/Orthofinder/swissmodel_results/pdb_files
OUTPUT_DIR=/mnt/scratch/c23048124/Orthofinder/swissmodel_results/pdbqt_files

# Create output directory if it does not exist
mkdir -p ${OUTPUT_DIR}

# Set working directory
WORKINGDIR=${pipedir}

# Set folders to bind into container
export BINDS="${BINDS},${WORKINGDIR}:${WORKINGDIR}"

# Check if the Singularity image exists
if [ -f ${pipedir}/singularities/${IMAGE_NAME} ]; then
    echo "Singularity image exists"
else
    echo "Singularity image does not exist"
    wget -O ${pipedir}/singularities/${IMAGE_NAME} https://depot.galaxyproject.org/singularity/$IMAGE_NAME
fi

# Define the Singularity image directory and name
SINGIMAGEDIR=${pipedir}/singularities
SINGIMAGENAME=${IMAGE_NAME}

# Loop through all .pdb.gz files in the input directory
for pdb_gz_file in ${INPUT_DIR}/*.pdb.gz; do
    # Decompress the .pdb.gz file
    pdb_file=$(basename ${pdb_gz_file} .gz)
    gunzip -c ${pdb_gz_file} > ${WORKINGDIR}/${pdb_file}
    
    # Define the output PDBQT file name
    output_pdbqt_file=${OUTPUT_DIR}/$(basename ${pdb_file} .pdb).pdbqt
    
    # Create PDB to PDBQT conversion command for each file
    PDB_TO_PDBQT_COMMAND="prepare_ligand4.py -l ${WORKINGDIR}/${pdb_file} -o ${output_pdbqt_file}"

    # Debug: Print the PDB to PDBQT command
    echo "PDB to PDBQT Conversion Command for ${pdb_file}:"
    echo ${PDB_TO_PDBQT_COMMAND}

    # Execute the conversion command with Singularity
    singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash -c "${PDB_TO_PDBQT_COMMAND}"
    
    # Remove the temporary decompressed PDB file
    rm ${WORKINGDIR}/${pdb_file}
    
    # Confirm completion for the current file
    echo "PDB to PDBQT conversion completed for ${pdb_file}. Output file: ${output_pdbqt_file}"
done

# Confirm completion of all files
echo "All PDB to PDBQT conversions completed."

