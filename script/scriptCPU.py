from math import sqrt
f = open("des_mono.txt", "r")

v = []

for i in f:
    v.append(float(i.split(" ")[0].replace("\n","")))

f.close()

valori = []
# Numero campioni per des_mono è 10 per i restanti 30
numero_campioni = 10
z = 1.96

for j in range(0,12):
    # Range per des_mono 107 per gli altri 347
    for k in range(j,107,12):
        valori.append(v[k])
    sommatoria = sum(valori)
    media = sommatoria / numero_campioni
    som = 0
    for z in valori:
        som = som + (z - media)
    s = som / sqrt(numero_campioni - 1)
    interval = (media - ((s / sqrt(numero_campioni)*z)), media + ((s / sqrt(numero_campioni)*z)))
    print("Valori per " + str(j+1) + " thread")
    print("X barra: " + str(media))
    print("S: " + str(s))
    print("Intervall: " + str(interval))
    valori = []