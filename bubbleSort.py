import time
import threading
import itertools

# Create a threading lock
lock = threading.Lock()

# Standard BubbleSort function
def bubbleSort(unsorted):
        
    # Acquire a lock for thread
    lock.acquire()
    
    # Get length of list
    n = len(unsorted)
    
    # Perform bubble sort
    for i in range(n):
            swap = False
            for j in range(0, n-i-1):
                if unsorted[j]>unsorted[j+1]:
                    unsorted[j], unsorted[j+1] = unsorted[j+1], unsorted[j]
                    swap = True
            if swap == False:
                break
    
    # Release the lock after calculation
    lock.release()

# Create parallel bubble sort function this function uses normal bubble sort function
def parallelBubbleSort(unsorted): 

    # Get biggest element in the list
    biggestItem = max(unsorted)
    
    # Set number of threads as per the number of cores each core can run 2 threads ideally
    numberOfThreads = 4
    
    # Create sublists as per number of threads
    lists = [[] for _ in range(numberOfThreads)]
    
    # We use a number to divide the list into class intervals for each sublist
    splitFactor = biggestItem//numberOfThreads

    # Split list into sublists as per no of threads
    for j in range(1,len(lists)):
        for i in unsorted:
            if i <= (splitFactor*j):
                lists[j-1].append(i)

                # Remove the element from list after adding to sublist to prevent duplication
                unsorted = [x for x in unsorted if x != i]

        # Include the remaining elements in list in the last sublist
        lists[-1] = unsorted

    # Start all threads for each sublist
    activeThreads = []
    for item in lists:
        t = threading.Thread(target=bubbleSort, args=(item,))
        t.start()
        activeThreads.append(t)
        
    # Stop all active threads
    for thread in activeThreads:
        thread.join()

    # Merge all lists into final list
    sorted = itertools.chain(*lists)
    sorted = list(sorted)
    return sorted

def main ():

    # Start time counter to calculate runtime
    start_time = time.time()

    unsortedFile = open("data/unsorted.txt").read().split()
    unsortedList = []
    for element in unsortedFile:
        unsortedList.append(int(element))
    
    sorted = parallelBubbleSort(unsortedList)
    sortedFile = open("data/sorted.txt", "w")
    for element in sorted:
        sortedFile.write(str(element) + " ")

    sortedFile.close()
    print(sorted)
    end_time = time.time() - start_time
    print("--- Sorted in %s seconds ---" % (end_time))

if __name__ == "__main__":
    main()