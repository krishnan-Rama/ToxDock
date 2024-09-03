import matplotlib.pyplot as plt

proteins = list(affinities.keys())
binding_affinities = list(affinities.values())

plt.plot(proteins, binding_affinities, marker='o')
plt.xlabel("Protein Orthologs")
plt.ylabel("Binding Affinity (kcal/mol)")
plt.title("Differential Free Energy Curve")
plt.grid(True)
plt.show()

