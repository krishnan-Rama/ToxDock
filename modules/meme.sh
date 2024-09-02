#!/bin/bash

#SBATCH --job-name=MEME
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

# Load MEME Suite module
module load meme/5.5.5

# Set working directory
WORKINGDIR=${pipedir}/meme

# Create the working directory if it doesn't exist
mkdir -p "$WORKINGDIR"

# Input orthologs file
ORTHOLOGS_FILE="/mnt/scratch15/c23048124/metal/transpipeline_containerised/modules/OrthoFinder_source/ExampleData_2/OrthoFinder/Results_Aug09_2/Orthogroup_Sequences/OG0000059.fa"

# Check if orthologs file exists
if [ ! -f "$ORTHOLOGS_FILE" ]; then
    echo "Orthologs file not found!"
    exit 1
fi

# Extract ortholog sequences into a single FASTA file
awk '/^>/ {if(seq) print seq; print; seq=""; next} {seq=seq $0} END {print seq}' "$ORTHOLOGS_FILE" > ${WORKINGDIR}/orthologs.fasta

# Debug: Print the orthologs file path
echo "Orthologs file: ${WORKINGDIR}/orthologs.fasta"

# Step 1: Run MEME to identify motifs in the extracted ortholog sequences
meme ${WORKINGDIR}/orthologs.fasta -oc ${WORKINGDIR}/meme_output -protein -mod zoops -nmotifs 5 -minw 6 -maxw 50

# Check if MEME completed successfully
if [ $? -ne 0 ]; then
    echo "MEME encountered an error."
    exit 1
fi

# Step 2: Use MAST to scan sequences with identified motifs
mast ${WORKINGDIR}/meme_output/meme.xml ${WORKINGDIR}/orthologs.fasta -oc ${WORKINGDIR}/mast_output

# Step 3: Run GLAM2 for gapped motif discovery
glam2 -r 10 -o ${WORKINGDIR}/glam2_output ${WORKINGDIR}/orthologs.fasta

# Step 4: Align the motifs found by GLAM2 using GLAM2SCAN
glam2scan ${WORKINGDIR}/glam2_output/glam2.txt ${WORKINGDIR}/orthologs.fasta > ${WORKINGDIR}/glam2scan_output.txt

# Optional: Generate logos for motifs identified by GLAM2
weblogo -F png -o ${WORKINGDIR}/glam2_output/glam2_logo.png < ${WORKINGDIR}/glam2_output/glam2.txt

# Optional: Analyze domain conservation using MEME's TOMTOM tool for motif comparison
tomtom -oc ${WORKINGDIR}/tomtom_output ${WORKINGDIR}/meme_output/meme.xml ${WORKINGDIR}/glam2_output/glam2.txt

# Final output paths
echo "MEME motif search results are in: ${WORKINGDIR}/meme_output"
echo "MAST scanning results are in: ${WORKINGDIR}/mast_output"
echo "GLAM2 gapped motif discovery results are in: ${WORKINGDIR}/glam2_output"
echo "GLAM2SCAN alignment results are in: ${WORKINGDIR}/glam2scan_output.txt"
echo "TOMTOM motif comparison results are in: ${WORKINGDIR}/tomtom_output"

