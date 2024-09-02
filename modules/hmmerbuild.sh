#!/bin/bash

#SBATCH --job-name=HMMER_BUILD
#SBATCH --partition=epyc       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=16     #
#SBATCH --mem-per-cpu=10000    # in megabytes, unless unit explicitly stated

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

# Load HMMER module
module load hmmer/3.1b2

# Set working directory 
WORKINGDIR=${pipedir}

# HMMER-specific variables
ALIGNMENT_FILE="${WORKINGDIR}/clipkit/output_OG0000059.fa"
HMM_FILE="${WORKINGDIR}/acetylcholinesterase.hmm"
OUTPUT_FILE="${WORKINGDIR}/hmmer_results_clipkit.txt"

# Ensure necessary commands are installed
for cmd in hmmbuild hmmsearch; do
    if ! command -v $cmd &> /dev/null; then
        echo "$cmd is not installed. Please install it."
        exit 1
    fi
done

# Check if alignment file exists
if [ ! -f "$ALIGNMENT_FILE" ]; then
    echo "Alignment file not found!"
    exit 1
fi

# Build the HMM profile from the alignment
echo "Building HMM profile..."
hmmbuild "$HMM_FILE" "$ALIGNMENT_FILE"

# Run hmmsearch to find conserved motifs across the sequences
echo "Running hmmsearch..."
hmmsearch --tblout "${OUTPUT_FILE}" "${HMM_FILE}" "$ALIGNMENT_FILE"

# Debug: Print the results location
echo "HMMER search completed. Results are saved in ${OUTPUT_FILE}"

