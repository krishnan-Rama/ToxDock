from Bio import SeqIO

def extract_motifs(input_fasta, output_fasta, positions_file):
    """
    Extracts motifs from sequences based on positions from the HMMER output.
    
    input_fasta: path to the aligned fasta file
    output_fasta: path to the output fasta file for extracted motifs
    positions_file: path to the hmmsearch result file with start and end positions
    """
    with open(positions_file, 'r') as positions, open(output_fasta, 'w') as output:
        for line in positions:
            if line.startswith('#') or not line.strip():
                continue  # Skip comment or empty lines
            
            columns = line.split()
            seq_id = columns[0]
            
            # Check if the start and end positions are valid integers
            try:
                start = int(columns[17])  # Sequence start position (1-based index)
                end = int(columns[18])    # Sequence end position (1-based index)
            except ValueError:
                print(f"Skipping invalid entry for {seq_id} with start and end values: {columns[17]}, {columns[18]}")
                continue  # Skip this entry if start/end positions are not valid integers

            # Search for the corresponding sequence in the input FASTA file
            for record in SeqIO.parse(input_fasta, "fasta"):
                if record.id == seq_id or seq_id in record.description:
                    motif_seq = record.seq[start-1:end]  # Python uses 0-based indexing
                    output.write(f">{record.id}_{start}_{end}\n{motif_seq}\n")
                    break

extract_motifs(
    input_fasta="/mnt/scratch15/c23048124/metal/transpipeline_containerised/clipkit/OG0000059.fa",
    output_fasta="/mnt/scratch15/c23048124/metal/transpipeline_containerised/extracted_motifs.fa",
    positions_file="/mnt/scratch15/c23048124/metal/transpipeline_containerised/hmmer_results.txt"
)

