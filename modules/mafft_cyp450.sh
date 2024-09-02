#!/bin/bash

#SBATCH --job-name=MAFFT_CYP450
#SBATCH --partition=jumbo     
#SBATCH --nodes=1   
#SBATCH --tasks-per-node=1     
#SBATCH --cpus-per-task=32     
#SBATCH --mem-per-cpu=10000    

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

# Define the Singularity image
IMAGE_NAME=mafft:7.525--h031d066_1

# Define input and output locations
ORTHOGROUP_SEQUENCE_DIR=/mnt/scratch15/c23048124/metal/transpipeline_containerised/modules/OrthoFinder_source/ExampleData_2/OrthoFinder/Results_Aug09_2/Orthogroup_Sequences
ORTHOGROUP_LIST=/mnt/scratch15/c23048124/metal/transpipeline_containerised/outdir/cyp450.tsv
OUTPUT_DIR=/mnt/scratch15/c23048124/metal/transpipeline_containerised/outdir/mafft_cyp450

# Set working directory
WORKINGDIR=${OUTPUT_DIR}

# Set folders to bind into container
#export BINDS="${WORKINGDIR}:${WORKINGDIR},${ORTHOGROUP_SEQUENCE_DIR}:${ORTHOGROUP_SEQUENCE_DIR}"
export BINDS="${WORKINGDIR}:${WORKINGDIR},${ORTHOGROUP_SEQUENCE_DIR}:${ORTHOGROUP_SEQUENCE_DIR}"

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

# Loop through each Orthogroup ID and run MAFFT
while IFS= read -r ORTHOGROUP_ID; do
    INPUT_FILE=${ORTHOGROUP_SEQUENCE_DIR}/${ORTHOGROUP_ID}.fa
    OUTPUT_FILE=${OUTPUT_DIR}/${ORTHOGROUP_ID}_aligned.fa
    
    # Create MAFFT command
    MAFFT_COMMAND="mafft --auto ${INPUT_FILE} > ${OUTPUT_FILE}"
    
    # Debug: Print the MAFFT command
    echo "Processing Orthogroup: ${ORTHOGROUP_ID}"
    echo "MAFFT Command:"
    echo ${MAFFT_COMMAND}

    # Execute the MAFFT command with Singularity
    singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash -c "${MAFFT_COMMAND}"

    # Confirm completion for this orthogroup
    echo "MAFFT alignment completed for ${ORTHOGROUP_ID}. Output file: ${OUTPUT_FILE}"
    
done < ${ORTHOGROUP_LIST}

# Confirm overall completion
echo "All MAFFT alignments completed. Check the output directory for results."

