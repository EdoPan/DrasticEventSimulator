from math import sqrt
import sys
f = open("run_GPU_optimizzata.txt", "r")

sys.stdout = open('valori.txt', 'a')

v = []

for i in f:
    v.append(float(i.split(" ")[0].replace("\n","")))

f.close()

valori = []

numero_campioni = 19
z = 1.96

blocchi = 1 #1 2 4 8 16 32 64 .. 4096
m = 0 #Va di 6 in 6 (0, 6, 12, ..)
for j in range(0,6): # Gestisce i thread
    if j == 0:
        thread = 32
    else:
        thread = thread * 2
    print("Blocchi: " , str(blocchi) , " Thread: " , str(thread))
    print()
    for k in range(j+m,1481,78):
        valori.append(v[k])
    sommatoria = sum(valori)
    media = sommatoria / numero_campioni
    som = 0
    for z in valori:
        som = som + (z - media)
    s = som / sqrt(numero_campioni - 1)
    interval = (media - ((s / sqrt(numero_campioni)*z)), media + ((s / sqrt(numero_campioni)*z)))
    print("X barra: " + str(media))
    print("S: " + str(s))
    print("Intervall: " + str(interval))
    print()
    valori = []
sys.stdout.close()