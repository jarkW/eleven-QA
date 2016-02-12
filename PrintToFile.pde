class PrintToFile {
   
   // Used for saving debug info
   PrintWriter debugOutput;
   PrintWriter infoOutput;
   boolean okFlag;
   boolean initDone;
    
     // constructor/initialise fields
    public PrintToFile()
    {
        okFlag = true;
        initDone = false;
    }
    
    public boolean initPrintToFile()
    {       
        // Open output file
        try
        {
            infoOutput = createWriter(configInfo.readOutputFilename());
        }
        catch(Exception e)
        {
            println(e);
            println("Failed to open output file ", configInfo.readOutputFilename());
            return false;
        }
        
        // Open debug file
        if (debugLevel > 0)
        {
            // Collecting debug info so open file
            try
            {
                debugOutput = createWriter("debug_info.txt");
            }
            catch(Exception e)
            {
                println(e);
                println("Failed to open debug file");
                return false;
            }
        }
        else
        {
            println("Debug file not opened as debugLevel is 0");
        }
        
        initDone = true;
        return true;
    }
 
    // Used to just print debug information - so can filter out minor messages
    // if not needed
    public void printDebugLine(String lineToWrite, int severity)
    {
        // Do nothing if not yet initialised this object
        if (!initDone)
        {
            return;
        }
       
        // Do nothing if not collecting debug info
        if (debugLevel == 0)
        {
            return;
        }
        
        if (severity >= debugLevel)
        {
            // Do we need to print this line to the console
            if (debugToConsole)
            {
                println(lineToWrite);
            }
        
            // Output line 
            debugOutput.println(lineToWrite);
            debugOutput.flush();
        }
        
    }
    
    // prints out line to file which tells the user what the tool actually did/found
    public void printOutputLine(String lineToWrite)
    {
               
        // Do we need to print this line to the console
        if (debugToConsole)
        {
            println(lineToWrite);
        }
        
        // Do nothing if not yet initialised this object
        if (!initDone)
        {
            return;
        }
        
        // Output line 
        infoOutput.println(lineToWrite);
        infoOutput.flush();
    }
           
    public boolean readOkFlag()
    {
        return (okFlag);
    }
}