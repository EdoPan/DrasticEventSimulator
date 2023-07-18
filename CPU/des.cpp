#include <iostream>
#include <iomanip>
#include <unistd.h>
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

#define sizes 5000 // size of side of the game map
#define num_execution 1 // number of execution for each simulation

#define event_power 30 // coefficient of destruction
#define x_event 9 //x-coordinates of the event
#define y_event 9 //y-coordinates of the event

#define verbose 1 //to print to the console more information
#define write_performance_result 1 // to save performance result to a file

#define print 0//0 -> nothing, 1 -> devastation, 2 -> solidity, 3-> distance 
#define debug 0 // to print debug info
#define path_performance "./performance.txt" //path to save the execution time

const std::string red("\033[0;31m");
const std::string green("\033[1;32m");
const std::string yellow("\033[1;33m");
const std::string cyan("\033[0;36m");
const std::string magenta("\033[0;35m");
const std::string reset("\033[0m");

//a block is a piece of the map
struct Block{
	int solidity; // rappresents the capacity of the block to resist [0,10]
	int devastation; // rappresents the effects of the strike [0,10]
	Block(){solidity = 0;devastation = 0;}; //constructor
};
    
struct Simulation{
    int next_block;
	Block** map;
    mutex mtx;
	int gx; // x-coordinate of ground zero
	int gy; // y-coordinate of ground zero
    Simulation(){gx=0;gy=0;map = NULL;next_block = 0;};
};

double distance(int px,int py,int gx,int gy){
	return floor(sqrt( pow((px-gx),2) + pow((py-gy),2) ));
}

int destr_eval(int solidity,int px,int py, int gx, int gy){
	int temp = ( (event_power-solidity) /distance(px,py,gx,gy));
	if(debug){
		cout<<"<========================>"<<endl;
		cout<<"solidity:"<<solidity<<endl<<"distance:"<<distance(px,py,gx,gy)<<endl<<"temp:"<<temp<<"(px,py):"<<px<<","<<py<<".(gx,gy):"<<gx<<","<<gy<<endl;
	}
	return temp >= 0 ? temp >=  10 ? 9 : temp : 0;
}


int pos_arr(int row,int col){ // size is the lenght of the side of the matrix
	return row*sizes+col;
}

int x_from_pos(int pos){// size is the lenght of the side of the matrix and pos is the index on the array
	return pos/sizes;
}

int y_from_pos(int pos){// size is the lenght of the side of the matrix and pos is the index on the array
	return pos-(pos/sizes)*sizes;
}

void* simulate(void* data){

	Simulation* sim = reinterpret_cast<Simulation*>(data);
	int selected_ground_zero = 0;
	while(1){
		sim->mtx.lock();
		if(sim->next_block >= (sizes*sizes)-1){
			sim->mtx.unlock();
			pthread_exit(NULL);
			return 0;
		}
		selected_ground_zero = sim-> next_block;
		sim -> next_block += sizes-1;
		sim->mtx.unlock();

		int row,col;
		for(int i = 0; i < sizes; i++){
			row = x_from_pos(selected_ground_zero+i);
			col = y_from_pos(selected_ground_zero+i);
			sim->map[row][col].devastation = destr_eval(
					sim->map[row][col].solidity,
					row,
					col,
					3,
					3
				);
		}
	}
	pthread_exit(NULL);
	return 0;
}

void initialization(Simulation* sim){
	for(int i = 0; i < sizes; i++)
		for(int j = 0; j < sizes; j++)
			sim->map[i][j].devastation = 0;
}

void print_solidity(Simulation* sim,int size){
	for(int i = 0; i < size; i++){
		for(int j = 0; j < size; j++){
			if(i == 0 && j == 0)
				cout << "X ";
			else
				cout << sim->map[i][j].solidity<< " ";
		}
		cout <<endl;
	}
}

void print_distance(int size,int gx,int gy){
	for(int i = 0; i < size; i++){
		for(int j = 0; j < size; j++){
			cout <<"|" <<distance(i,j,gx,gy)<< " ";
		}
		cout <<"|"<<endl;
	}
}

void print_devastation(Simulation* sim,int size){
	for(int i = 0; i < size; i++){
		for(int j = 0; j < size; j++){
			int dev = sim -> map[i][j].devastation;
			if(dev == 0){
				cout <<green << dev << reset <<" ";
				continue;
			}
			if(dev <= 4 ) {
				cout <<yellow << dev << reset <<" ";
				continue;
			}
			if(dev <= 7){
				cout <<magenta << dev << reset <<" ";
				continue;
			}
			if(dev <= 9){
				cout <<red << dev << reset <<" ";
			}
			else{
				cout<<reset<<dev<<reset<<" ";
			}
		}
		cout <<endl;
	}
}

int main(int argc, char *argv[]){


	cout<<setprecision(2)<<fixed;
	srand(2);
	Simulation sim;
	sim.map = new Block*[sizes];
	for(int i = 0; i < sizes; i++)
		sim.map[i] = new Block[sizes];
	int n = 0;

	for(int i = 0; i < sizes; i++)
		for(int j = 0; j < sizes; j++)
			sim.map[i][j].solidity = rand()%10 +1;
			
	vector<double> times;	
	int activated_threads = stoi(argv[1]);
	ofstream f;

	

		int iteration = 0;
		if(verbose)
			cout<<"Creation of World ("<<sizes<<"*"<<sizes<<") with "<<activated_threads << " threads."<<endl<<endl;
		
		vector<thread> threads(activated_threads);
		double l_interval = 100;
		while( iteration++ < num_execution){
			initialization(&sim);
			sim.next_block = 0;
			steady_clock::time_point begin = steady_clock::now();

			for (int i = 0; i < activated_threads;i++)
			{
				threads[i] = thread(simulate,&sim);
			}
			for(auto& t : threads){
				t.join();
			}

			steady_clock::time_point end = steady_clock::now();
			double interval = duration_cast<microseconds>(end - begin).count();
			if (interval/pow(10,6) < l_interval){
				l_interval = interval;
			}
		}
		times.push_back(l_interval);
        if(write_performance_result)
            f.open(path_performance,ios::app);
		cout<<setprecision(7);
        for(int interval : times){
			if(verbose)
            	cout << "Execution time = " <<interval/pow(10,6) << " s"<< " using "<< activated_threads <<" threads with "<<sizes<<" element." << endl;
            if(write_performance_result)
                f<< interval/pow(10,6) << " "<< activated_threads << endl;
        }
		cout<<setprecision(2);

		times.clear();
		f.close();	
        switch (print){
			case 1:
					print_devastation(&sim,sizes);
					break;
			case 2:
					print_solidity(&sim,sizes);
					break;
			case 3:
					cout<<setprecision(2);
					print_distance(sizes,0,0);//groundx,groundy
					cout<<setprecision(7);
					break;
			default:
					break;
		}
		cout<<setprecision(7);
	
	return 0;
}
