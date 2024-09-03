import glob

affinities = {}
for log_file in glob.glob("log_*.txt"):
    with open(log_file) as f:
        for line in f:
            if "REMARK VINA RESULT:" in line:
                affinity = float(line.split()[3])
                protein_name = log_file.split("_")[1].replace(".txt", "")
                affinities[protein_name] = affinity
                break

print(affinities)

