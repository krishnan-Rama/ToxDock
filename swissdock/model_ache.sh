#!/bin/bash

#SBATCH --job-name=nAchE_model
#SBATCH --partition=jumbo
#SBATCH --nodes=1            
#SBATCH --tasks-per-node=1     
#SBATCH --cpus-per-task=16      
#SBATCH --mem-per-cpu=20000   

module load python/3.10.5

python ache_model.py
