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
            printToFile.printDebugLine(this, "Failed to open output file " + configInfo.readOutputFilename(), 3);
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
                // Cannot write this error to debug file ...
                println("Failed to open debug file");
                return false;
            }
        }
        
        initDone = true;
        return true;
    }
 
    // Used to just print debug information - so can filter out minor messages
    // if not needed
    public void printDebugLine(Object callingClass, String lineToWrite, int severity)
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
            String s = callingClass.getClass().getName().replace("sketch_QA_tool$", " ") + "::";
            String methodName = Thread.currentThread().getStackTrace()[2].getMethodName();
            
            // Do we need to print this line to the console
            if (debugToConsole)
            {
                println(s + lineToWrite);
            }
        
            // Output line 
            debugOutput.println(s + methodName + ":\t" + lineToWrite);
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
    
    public boolean printSummary(ArrayList<SummaryChanges> itemResults)
    {
        // Now print out the summary array
        String s = "\nResults for " + streetInfo.readStreetName() + " (" + streetInfo.readStreetTSID() + ")";
        printOutputLine(s);
        
        if (writeJSONsToPersdata)
        {
            printOutputLine("Writing JSON files to persdata");
        }
        else
        {
            printOutputLine("No JSON files being written to persdata");
        }
        
        if (usingGeoInfo)
        {
            printOutputLine("Using Geo data to change image files");
        }
        else
        {
            printOutputLine("Converting images to black/white for compare");
        }
            
                
        // Sort array by x co-ord so listing items from L to R
        Collections.sort(itemResults);
                
        int missingCount = 0;
        int skippedCount = 0;
        int quoinEnergy = 0;
        int quoinMood = 0;
        int quoinCurrants = 0;
        int quoinTime = 0;
        int quoinFavor = 0;
        int quoinXP = 0;
        int quoinMystery = 0;
                
        for (int i = 0; i < itemResults.size(); i++)
        {
            s = "";
            if (itemResults.get(i).readChangedJSON())
            {
                s = "** ";
            }

            switch (itemResults.get(i).readResult())
            {
                case SummaryChanges.SKIPPED:
                    s = s + "SKIPPED ";
                    skippedCount++;
                    break;    
                            
                case SummaryChanges.MISSING:
                    if (itemResults.get(i).readItemClassTSID().equals("quoin"))
                    {
                        s = s + "MISSING QUOIN ";
                    }
                    else
                    {
                         s = s + "MISSING ";
                    }
                    missingCount++;
                    break; 
                            
                case SummaryChanges.COORDS_ONLY:
                    s = s + "CHANGED CO-ORDS ";
                    break;
                         
                case SummaryChanges.VARIANT_ONLY:
                    s = s + "CHANGED VARIANT ";
                    break;
                            
                case SummaryChanges.VARIANT_AND_COORDS_CHANGED:
                    s = s + "CHANGED VARIANT & CO-ORDS ";
                    break;
                    
                case SummaryChanges.UNCHANGED:
                    s = s + "UNCHANGED ";
                    break;
                            
                default:
                    printDebugLine(this, "Unexpected results type " + itemResults.get(i).readResult(), 3);
                    failNow = true;
                    return false;  
            }
                    
            s = s + itemResults.get(i).readItemTSID() + ": " + itemResults.get(i).readItemClassTSID();
            if (itemResults.get(i).readItemExtraInfo().length () > 0)
            {
                s = s + "(" + itemResults.get(i).readItemExtraInfo() + ")";
            }
            s = s + " at " + itemResults.get(i).readItemX() + "," + itemResults.get(i).readItemY();
            printOutputLine(s);

            if (itemResults.get(i).readItemClassTSID().equals("quoin"))
            {
                if (itemResults.get(i).readItemExtraInfo().equals("energy"))
                {
                    quoinEnergy++;
                }
                else if (itemResults.get(i).readItemExtraInfo().equals("mood"))
                {
                    quoinMood++;
                }
                else if (itemResults.get(i).readItemExtraInfo().equals("currants"))
                {
                    quoinCurrants++;
                }
                else if (itemResults.get(i).readItemExtraInfo().equals("time"))
                {
                    quoinTime++;
                }
                else if (itemResults.get(i).readItemExtraInfo().equals("favor"))
                {
                    quoinFavor++;
                }
                else if (itemResults.get(i).readItemExtraInfo().equals("xp"))
                {
                    quoinXP++;
                }
                else if (itemResults.get(i).readItemExtraInfo().equals("mystery"))
                {
                    quoinMystery++;
                }
                else
                {
                    printDebugLine(this, "Unexpected quoin type " + itemResults.get(i).readItemExtraInfo(), 3);
                    failNow = true;
                    return false; 
                }
            }
        }
        
        // Just dump out number of quoins
        s = "Skipped " + skippedCount + " items, missing " + missingCount + " items";
        printOutputLine(s);
        
        s = "Quoin count is: XP (" + quoinXP + ")   energy (" + quoinEnergy + ")   mood (" + quoinMood +
            ")   currants (" + quoinCurrants +")   favor (" + quoinFavor +")   time (" + quoinTime +")   mystery (" + quoinMystery + ")" +
            " Total = " + (quoinXP + quoinEnergy + quoinMood + quoinCurrants + quoinFavor + quoinTime + quoinMystery);

        printOutputLine(s);
        printOutputLine("\n\n");
        return true;
    }
           
    public boolean readOkFlag()
    {
        return (okFlag);
    }
}