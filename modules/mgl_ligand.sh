#!/bin/bash

#SBATCH --job-name=prepare_ligand       # Job name
#SBATCH --partition=epyc                # Requested queue (replace with actual partition)
#SBATCH --nodes=1                       # Number of nodes to use
#SBATCH --tasks-per-node=1              # Tasks per node
#SBATCH --cpus-per-task=16              # Number of CPU cores per task
#SBATCH --mem-per-cpu=10000             # Memory per CPU in megabytes

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
INPUT_LIGAND_FILE=/mnt/scratch/c23048124/Orthofinder/swissmodel_results/sdf_files/Chlorpyrifos.sdf
OUTPUT_LIGAND_FILE=/mnt/scratch/c23048124/Orthofinder/swissmodel_results/pdbqt_ligand_files/Chlorpyrifos.pdbqt

# Create the output directory if it does not exist
mkdir -p $(dirname ${OUTPUT_LIGAND_FILE})

# Set working directory
WORKINGDIR=/mnt/scratch/c23048124/Orthofinder

# Set folders to bind into container (bind directories, not individual files)
export BINDS="${WORKINGDIR}:${WORKINGDIR}"

# Check if the Singularity image exists
if [ -f ${WORKINGDIR}/singularities/${IMAGE_NAME} ]; then
    echo "Singularity image exists"
else
    echo "Singularity image does not exist"
    wget -O ${WORKINGDIR}/singularities/${IMAGE_NAME} https://depot.galaxyproject.org/singularity/$IMAGE_NAME
fi

# Define the Singularity image directory and name
SINGIMAGEDIR=${WORKINGDIR}/singularities
SINGIMAGENAME=${IMAGE_NAME}

# Prepare the ligand file
MGLTOOLS_LIGAND_COMMAND="prepare_ligand4.py -l ${INPUT_LIGAND_FILE} -o ${OUTPUT_LIGAND_FILE} -U nphs"

# Debug: Print the MGLTools command
echo "MGLTools Ligand Command:"
echo ${MGLTOOLS_LIGAND_COMMAND}

# Execute the MGLTools command with Singularity
singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash -c "${MGLTOOLS_LIGAND_COMMAND}"

# Confirm completion
echo "Ligand preparation completed. PDBQT file is at: ${OUTPUT_LIGAND_FILE}"

