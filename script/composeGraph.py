import matplotlib.pyplot as plt
import numpy as np

x = []
y = []

file = ["1 des_mono.txt",
        "2 des_column.txt",
        "3 des.txt",
        "4 des_sequential.txt"]

labels = ["des_mono", 
          "des_column",
          "des",
          "des_sequential"]

execution_label_condition = True
if execution_label_condition:
    execution_label = "Execution time"
else:    
    execution_label = "Speed up"

colors = ['c','m','k','y']
for kk in range(3):
    f = open(file[kk], "r")
    x = []
    y = []
    k = 0
    for j in f:
        if(k == 12) : break
        x.append(float(j.split(" ")[1].replace("\n","")))
        y.append(float(j.split(" ")[0].replace("\n","")))
        k = k+1
         
    single_w = y[0]
    i = 0
    if execution_label_condition != True :
        while i < len(y) and i < 12:
            y[i] = single_w / y[i] 
            i = i+1

    plt.plot(x,y, color = colors[kk],label = labels[kk], marker = 'o')
    
plt.legend()
plt.xlabel('# of threads')
plt.ylabel(execution_label)
plt.title(execution_label+" comparison with 20000 elements")
plt.yscale("linear")
plt.grid()
plt.locator_params(axis="both", integer=True, tight=False)
plt.margins(0.05)
plt.xticks(np.arange(min(x), max(x)+1, 1.0))
plt.yticks(np.arange(0, 50+1, 2.0))
plt.show()