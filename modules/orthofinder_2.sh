#!/bin/bash

#SBATCH --job-name=Orthofinder
#SBATCH --partition=epyc       # the requested queue
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=16      # reduced CPU count for better utilization
#SBATCH --mem-per-cpu=10000     # reduced memory per CPU to better match actual usage

echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo \$SLURM_JOB_ID=${SLURM_JOB_ID}
echo \$SLURM_NTASKS=${SLURM_NTASKS}
echo \$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}
echo \$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
echo \$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}
echo \$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}

# Record start time
START_TIME=$(date +%s)

# Write jobscript to output file (good for reproducibility)
cat $0

# load singularity module
module load singularity/3.8.7

IMAGE_NAME=orthofinder:2.5.5--hdfd78af_1

if [ -f ${pipedir}/singularities/${IMAGE_NAME} ]; then
    echo "Singularity image exists"
else
    echo "Singularity image does not exist"
    wget -O ${pipedir}/singularities/${IMAGE_NAME} https://depot.galaxyproject.org/singularity/$IMAGE_NAME
fi

SINGIMAGEDIR=${pipedir}/singularities
SINGIMAGENAME=${IMAGE_NAME}

# Convert memory from MB to GB
TOTAL_RAM=$((SLURM_MEM_PER_NODE / 1024))

# Set working directory
WORKINGDIR=${pipedir}

# set folders to bind into container
export BINDS="${BINDS},${WORKINGDIR}:${WORKINGDIR}"

############# SOURCE COMMANDS ##################################
cat >${log}/orthofinder_${SLURM_JOB_ID}.sh <<EOF

orthofinder -f ${moduledir}/OrthoFinder_source/ExampleData_2 -t ${SLURM_CPUS_PER_TASK}

EOF
################ END OF SOURCE COMMANDS ######################

# Use GNU time (gtime) if available, otherwise fallback to basic time command
if command -v gtime &> /dev/null; then
    gtime -v singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/orthofinder_${SLURM_JOB_ID}.sh
elif command -v /usr/bin/time &> /dev/null; then
    /usr/bin/time -v singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/orthofinder_${SLURM_JOB_ID}.sh
else
    echo "Detailed time command is not available, running without detailed time measurement"
    singularity exec --contain --bind ${BINDS} --pwd ${WORKINGDIR} ${SINGIMAGEDIR}/${SINGIMAGENAME} bash ${log}/orthofinder_${SLURM_JOB_ID}.sh
fi

# Record end time
END_TIME=$(date +%s)

# Calculate elapsed time
ELAPSED_TIME=$((END_TIME - START_TIME))

# Convert elapsed time to a human-readable format
ELAPSED_HOURS=$((ELAPSED_TIME / 3600))
ELAPSED_MINUTES=$((ELAPSED_TIME % 3600 / 60))
ELAPSED_SECONDS=$((ELAPSED_TIME % 60))

echo "Job completed in ${ELAPSED_HOURS} hours, ${ELAPSED_MINUTES} minutes, and ${ELAPSED_SECONDS} seconds."

# Print out SLURM resource usage
echo "SLURM Job Stats:"
echo "================"
sacct --format=JobID,JobName,Partition,MaxRSS,Elapsed,State -j ${SLURM_JOB_ID}

# Optionally, capture this data to a file for further analysis
sacct --format=JobID,JobName,Partition,MaxRSS,Elapsed,State -j ${SLURM_JOB_ID} | tail -n +3 >> job_stats.csv
