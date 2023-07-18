#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <iostream>
#include <iomanip>
#include <cmath>
#include <math.h>
#include <math.h>
#include <chrono>
#include <thread>
#include <vector>
#include <fstream>
#include <mutex>
using namespace std;
using namespace std::chrono;

#define sizes 5000// size of side of the game map

#define event_power 5000 // coefficient of destruction
#define x_event 3//x-coordinates of the event
#define y_event 3 //y-coordinates of the event

#define verbose 0 //to print to the console more information

#define print 0//0 -> nothing, 1 -> devastation, 2 -> solidity, 3-> distance 
#define debug 0 // to print debug info
#define print_file 0
#define compact_matrix 1 // this to compact the matrix in order to visualized it better

//usefull for errore handling
#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
   if (code != cudaSuccess) 
   {
      fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
      if (abort) exit(code);
   }
}

__device__ __constant__ int gx;
__device__ __constant__ int gy;

struct Block {
	char solidity; // rappresents the capacity of the block to resist [0,10]
	char devastation; // rappresents the effects of the strike [0,10]
	Block() { solidity = 0; devastation = 0; }; //constructor
};

struct Simulation {
	int next_block;
	Block* map;
	mutex mtx;
	int gx; // x-coordinate of ground zero
	int gy; // y-coordinate of ground zero
	Simulation() { gx = 0; gy = 0; map = NULL; next_block = 0; };
};

void print_mat(Simulation* sim){
	if(print_file){
		ofstream f;
		f.open("performance.txt",ios::trunc);
		for (int i = 0; i < sizes * sizes; i++) {
			if ( i % sizes == 0 && i != 0)
				f <<  endl;
			f << sim->map[i].devastation << " ";
		}
		f.close();
	}
	if(compact_matrix){
		ofstream f;
		f.open("matrix_compatted.txt",ios::trunc);
		//for printing the matrix in compact way
		int valore=0;
		int dimensione_sotto_matrice = 100;
		int dimensione_matrice = sizes;

		for(int row =0; row<dimensione_matrice; row+=dimensione_sotto_matrice){
			for(int col=0; col<dimensione_matrice; col += dimensione_sotto_matrice){
				for(int i=row; i<row+dimensione_sotto_matrice;i++){
					for(int j=col; j<col+dimensione_sotto_matrice; j++){
						if((i*sizes+j) <=  (sizes*sizes))
							valore += sim->map[i*sizes+j].devastation;
					}
				}
				float valore_new = valore/(dimensione_sotto_matrice*dimensione_sotto_matrice);
				f << round(valore_new) ;
				f << " ";
				valore = 0;
			}
			f << "\n";
			
		}
		f.close();
	}
	if(!verbose)
		return;
	for ( int i = 0; i < sizes * sizes ; i++) {
		if ( i % sizes == 0 && i != 0)
			cout <<  endl;
		cout << sim->map[i].devastation << " ";
	}
}


__global__ void DES(Block* map, int blocchi, int thread) {

	int id_x = threadIdx.x + blockIdx.x * blockDim.x;
    int num_totale_thread = blocchi*thread;
    int slice = sizes*sizes / num_totale_thread +1 ;

		for(int i = 0 ; i<slice;i++){
            
            int index = id_x * slice +i;
            int row = index / sizes;
	        int col = index - (index/sizes)*sizes;

            if (row < sizes && col < sizes) {
                __syncthreads();
				float xx = __powf(__fsub_rn(row, gx), 2);
        		float y = __fsub_rn(col, gy);
				float sum_xx_yy = __fmaf_rn(y, y , xx);
				int distance_evaluation = floor(__fsqrt_rn(sum_xx_yy));

        		int evaluation = ((event_power - (int)map[row * sizes + col].solidity) / distance_evaluation);
        		char destr_eval_var = 0;
        		if (evaluation > 0 )
        			if(evaluation > 10)
        				destr_eval_var = 9;
        			else
        				destr_eval_var = (char)evaluation;
        		else
        			destr_eval_var = 0;
        		map[row * sizes + col].devastation = destr_eval_var;
        	}
		}

}

void initialization(Simulation* sim) {
	for ( int i = 0; i < sizes*sizes; i++)
		sim->map[i].devastation = 0;
}


int main(int argc, char *argv[]) {

    int num_blocchi = stoi(argv[1]);
    int num_thread = stoi(argv[2]);

	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	cudaEvent_t start_simulation, stop_simulation;
	cudaEventCreate(&start_simulation);
	cudaEventCreate(&stop_simulation);

	ofstream f;
	f.open("performance.txt",ios::app);

	srand(2);
	Simulation sim;
	sim.map = new Block[sizes*sizes];

	for (int i = 0; i < sizes; i++)
		for (int j = 0; j < sizes; j++)
			sim.map[i*sizes+j].solidity = rand() % 10;

	sim.next_block = 0;

	int* gx_host = (int*)malloc(sizeof(int));
	*gx_host = x_event;
	int* gy_host = (int*)malloc(sizeof(int));
	*gy_host = y_event;

	
	long size_map = sizeof(Block) * sizes * sizes;
	Block* copy_map;

	cudaEventRecord(start);

	cudaMemcpyToSymbol(gx,gx_host,sizeof(int));
	cudaMemcpyToSymbol(gy,gy_host,sizeof(int));
	
	cudaMalloc((void**)&copy_map, size_map);
	steady_clock::time_point begin = steady_clock::now();
	cudaMemcpy(copy_map, sim.map, size_map, cudaMemcpyHostToDevice);
	steady_clock::time_point end = steady_clock::now();

    cudaEventRecord(start_simulation);
	DES <<<  num_blocchi, num_thread >>> (copy_map,num_blocchi,num_thread);
	cudaEventRecord(stop_simulation);

	gpuErrchk( cudaPeekAtLastError() );
	gpuErrchk( cudaDeviceSynchronize() );
	
	cudaMemcpy(sim.map, copy_map, size_map, cudaMemcpyDeviceToHost);

	cudaEventRecord(stop);
	cudaEventSynchronize(stop);

	print_mat(&sim);
    cout<<endl;

	float milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, start, stop);
	cout <<  setprecision(7) << "Total simulation time " << milliseconds/pow(10,3);

	cudaEventElapsedTime(&milliseconds, start_simulation, stop_simulation);
	cout << endl << setprecision(7) << "Simulation time " << milliseconds/pow(10,3);

	cout << endl << "Copy device to host time: " << duration_cast<microseconds>(end - begin).count() / pow(10, 6)<<endl;
		
	f<<	milliseconds/pow(10,3)<< " ("<<num_blocchi<<","<<num_thread<<")"<<endl;
    f.close();
	
	cudaEventDestroy(start);
	cudaEventDestroy(stop);
	cudaEventDestroy(start_simulation);
	cudaEventDestroy(stop_simulation);

	return 0;
}