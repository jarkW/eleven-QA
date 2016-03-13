public class Memory {
 
    public void printMemoryUsage() {
 
        int mb = 1024 * 1024; 
 
        // get Runtime instance
        Runtime instance = Runtime.getRuntime();
 
        //printToFile.printDebugLine(this, "***** Heap utilization statistics [MB] *****\n", 1);
 
        // available memory
        printToFile.printDebugLine(this, "Total Memory: " + instance.totalMemory() / mb + 
                                    "  Free Memory: " + instance.freeMemory() / mb +
                                    "  Used Memory: " + (instance.totalMemory() - instance.freeMemory()) / mb +
                                    //"  Used Memory: " + (instance.totalMemory() - instance.freeMemory()) +
                                    "   Max Memory: " + instance.maxMemory() / mb + (instance.totalMemory() - instance.freeMemory()) / mb, 3);
    }
}