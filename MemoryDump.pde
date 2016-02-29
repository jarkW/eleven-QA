public class MemoryDump {
 
    public void printMemoryUsage() {
 
        int mb = 1024 * 1024; 
 
        // get Runtime instance
        Runtime instance = Runtime.getRuntime();
 
        printToFile.printDebugLine("***** Heap utilization statistics [MB] *****\n", 1);
 
        // available memory
        printToFile.printDebugLine("Total Memory: " + instance.totalMemory() / mb + 
                                    "  Free Memory: " + instance.freeMemory() / mb +
                                    "  Used Memory: " + (instance.totalMemory() - instance.freeMemory()) / mb +
                                    "   Max Memory: " + instance.maxMemory() / mb + (instance.totalMemory() - instance.freeMemory()) / mb, 1);
    }
}