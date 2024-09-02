#!/bin/bash

#SBATCH --job-name=concat_alignments     
#SBATCH --partition=jumbo     
#SBATCH --nodes=1   
#SBATCH --tasks-per-node=1     
#SBATCH --cpus-per-task=1     
#SBATCH --mem-per-cpu=4000    

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

# Define the directories and file paths
ALIGNMENT_DIR=/mnt/scratch15/c23048124/metal/transpipeline_containerised/outdir/mafft_cyp450
ORTHOGROUP_LIST=/mnt/scratch15/c23048124/metal/transpipeline_containerised/outdir/cyp450.tsv
CONCATENATED_OUTPUT=${ALIGNMENT_DIR}/CYP40_concatenated_alignment.fa

# Remove any existing concatenated file (optional)
rm -f ${CONCATENATED_OUTPUT}

# Loop through each Orthogroup ID and concatenate the alignment files
while IFS= read -r ORTHOGROUP_ID; do
    ALIGNMENT_FILE=${ALIGNMENT_DIR}/${ORTHOGROUP_ID}_aligned.fa

    if [ -f "${ALIGNMENT_FILE}" ]; then
        echo "Concatenating ${ALIGNMENT_FILE} to ${CONCATENATED_OUTPUT}"
        cat ${ALIGNMENT_FILE} >> ${CONCATENATED_OUTPUT}
        echo -e "\n" >> ${CONCATENATED_OUTPUT}  # Add a new line between each alignment
    else
        echo "Warning: ${ALIGNMENT_FILE} not found, skipping..."
    fi

done < ${ORTHOGROUP_LIST}

# Confirm completion
echo "Concatenation completed. Check the output file: ${CONCATENATED_OUTPUT}"

