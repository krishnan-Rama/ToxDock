#!/bin/bash

#SBATCH --job-name=autodock_vina_docking      # Job name
#SBATCH --partition=epyc                     # Requested queue (replace with actual partition)
#SBATCH --nodes=1                             # Number of nodes to use
#SBATCH --tasks-per-node=1                    # Tasks per node
#SBATCH --cpus-per-task=32                    # Number of CPU cores per task
#SBATCH --mem-per-cpu=8000                   # Memory per CPU in megabytes

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

# Define the Singularity image
IMAGE_NAME=autodock-vina:1.1.2--h9ee0642_3

# Set the original working directory and input/output paths
WORKINGDIR=/mnt/scratch/c23048124/Orthofinder

# Set the model directory where the PDBQT files are located
MODELDIR=${WORKINGDIR}/swissmodel_results
PDBQT_DIR=${MODELDIR}/pdbqt_files
LIGAND_FILE=${MODELDIR}/sdf_files/Chlorpyrifos.pdbqt
OUTPUT_DIR=${MODELDIR}/vina_results

# Create output directory if it doesn't exist
mkdir -p ${OUTPUT_DIR}

# Set folders to bind into container
export BINDS="${PDBQT_DIR}:${PDBQT_DIR},${OUTPUT_DIR}:${OUTPUT_DIR},,${MODELDIR}:${MODELDIR}"

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

# Loop through all protein PDBQT files and perform docking
for PROTEIN_FILE in ${PDBQT_DIR}/*.pdbqt; do
    PROTEIN_NAME=$(basename ${PROTEIN_FILE} .pdbqt)
    OUTPUT_FILE=${OUTPUT_DIR}/${PROTEIN_NAME}_docked.pdbqt
    LOG_FILE=${OUTPUT_DIR}/${PROTEIN_NAME}_docking.log

    # Define Vina command
    VINA_COMMAND="vina --receptor ${PROTEIN_FILE} --ligand ${LIGAND_FILE} --out ${OUTPUT_FILE} --log ${LOG_FILE} --center_x 0 --center_y 0 --center_z 0 --size_x 20 --size_y 20 --size_z 20"

    # Debug: Print the Vina command
    echo "Vina Command for ${PROTEIN_NAME}:"
    echo ${VINA_COMMAND}

    # Execute the Vina command with Singularity
    singularity exec --contain --bind ${BINDS} --pwd ${MODELDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash -c "${VINA_COMMAND}"
done

# Confirm completion
echo "AutoDock Vina docking completed for all orthologs. Results are in: ${OUTPUT_DIR}"

