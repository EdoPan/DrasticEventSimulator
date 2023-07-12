for i in {0..29}
do
	for i in {1,2,4,8,16,32,64,128,256,512,1024,2048,4096} # blocks
	do
	for j in {32,64,128,256,512,1024} # thread
		do
    			./a.out $i $j
		done
	done
done