#!/bin/bash
#SBATCH --job-name=clipkit
#SBATCH --partition=jumbo
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=3000
#SBATCH --output=clipkit_output_%j.txt   # Standard output
#SBATCH --error=clipkit_error_%j.txt     # Standard error

# Debugging info
echo "Job started on $(date)"

# Clone the repository (optional, better to do once and reuse)
git clone https://github.com/JLSteenwyk/ClipKIT.git
cd ClipKIT/

# Create virtual environment (only if not already done)
python -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install ClipKIT (only if not already installed)
make install

# Run ClipKIT
clipkit ../OG0000059.fa 

# Deactivate virtual environment
deactivate

# Debugging info
echo "Job finished on $(date)"

