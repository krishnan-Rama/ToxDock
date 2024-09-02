#!/bin/bash

#SBATCH --job-name=raxml
#SBATCH --partition=epyc      
#SBATCH --nodes=1           
#SBATCH --tasks-per-node=1   
#SBATCH --cpus-per-task=16   
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

# Load HMMER module
module load RAxML-NG/v1.2.0 

raxml-ng --msa /mnt/scratch15/c23048124/metal/transpipeline_containerised/outdir/mafft_cyp450/OG0000059_CYP450_cleaned_aligned_sequences_unique.fa --model LG+G+I --prefix result_tree --seed 12345 --threads ${SLURM_CPUS_PER_TASK} --msa-format FASTA

module unload RAxML-NG/v1.2.0
