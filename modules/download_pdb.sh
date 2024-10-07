#!/bin/bash

#SBATCH --job-name=PDB_DOWN
#SBATCH --partition=epyc
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=10000

module load python/3.10.5

python ${moduledir}/download.py

