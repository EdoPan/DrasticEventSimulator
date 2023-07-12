import matplotlib.pyplot as plt
import numpy as np

f = open("performance.txt", "r")

x=[]
y=[]

for j in f:
    x.append(float(j.split(" ")[1].replace("\n","")))
    y.append(float(j.split(" ")[0].replace("\n","")))

f.close()

single_t = y[0]
i = 0
while i < len(y):
    y[i] = single_t / y[i] 
    i = i+1

plt.plot(x,y, marker='o')
plt.xlabel('# of threads')
plt.ylabel('speed up')
plt.title("Speed-up sequential des")
plt.yscale("linear")
plt.grid()
plt.locator_params(axis="both", integer=True, tight=False)
plt.margins(0.05)
plt.xticks(np.arange(min(x), max(x)+1, 1.0))
plt.savefig('exectionTime/speedUp_des_100.png')
plt.show()