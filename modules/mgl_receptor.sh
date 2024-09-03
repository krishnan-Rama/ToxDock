#!/bin/bash

#SBATCH --job-name=PDBQT_rec       # Job name
#SBATCH --partition=jumbo                 # Requested queue (replace with actual partition)
#SBATCH --nodes=1                         # Number of nodes to use
#SBATCH --tasks-per-node=1                # Tasks per node
#SBATCH --cpus-per-task=16                # Number of CPU cores per task
#SBATCH --mem-per-cpu=10000               # Memory per CPU in megabytes

echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo "\$SLURM_JOB_ID=${SLURM_JOB_ID}"
echo "\$SLURM_NTASKS=${SLURM_NTASKS}"
echo "\$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}"
echo "\$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}"
echo "\$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}"
echo "\$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}"

# Write job script to output file (good for reproducibility)
cat $0

# Load Singularity module
module load singularity/3.8.7

# Define the Singularity image and input/output paths
IMAGE_NAME=mgltools:1.5.7--h9ee0642_1
INPUT_DIR=/mnt/scratch/c23048124/Orthofinder/swissmodel_results/pdb_files
OUTPUT_DIR=/mnt/scratch/c23048124/Orthofinder/swissmodel_results/pdbqt_mgl_files

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

# Prepare receptor files
for pdb_file in ${INPUT_DIR}/*.pdb.gz; do
    # Decompress the PDB file
    gunzip ${pdb_file}
    pdb_file_unzipped=${pdb_file%.gz}
    output_file=${OUTPUT_DIR}/$(basename ${pdb_file_unzipped} .pdb).pdbqt

    # Define the command for MGLTools
    MGLTOOLS_COMMAND="prepare_receptor4.py -r ${pdb_file_unzipped} -o ${output_file} -U nphs_lps_waters_metals"

    # Debug: Print the MGLTools command
    echo "MGLTools Command:"
    echo ${MGLTOOLS_COMMAND}

    # Execute the MGLTools command with Singularity
    singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash -c "${MGLTOOLS_COMMAND}"

    # Optionally compress the original PDB file again
    gzip ${pdb_file_unzipped}
done

# Confirm completion
echo "Receptor preparation completed. PDBQT files are in: ${OUTPUT_DIR}"

