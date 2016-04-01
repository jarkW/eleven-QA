class PrintToFile {
   
   // Used for saving debug info
   PrintWriter debugOutput;
   PrintWriter infoOutput;
   boolean okFlag;
   boolean initDone;
   
   StringList existingOutputText;
    
     // constructor/initialise fields
    public PrintToFile()
    {
        okFlag = true;
        initDone = false;
    }
    
    public boolean initPrintToFile()
    {       
                
        // Open debug file
        if (debugLevel > 0)
        {
            // Collecting debug info so open file
            try
            {
                debugOutput = createWriter(workingDir + File.separatorChar + "debug_info.txt");
            }
            catch(Exception e)
            {
                println(e);
                // Cannot write this error to debug file ...
                println("Failed to open debug file");
                return false;
            }
        }
        
        // Open output file
        if (configInfo.readAppendToOutputFile())
        {
            existingOutputText = new StringList(); 
            if (!saveExistingOutputFileText())
            {
                printToFile.printDebugLine(this, "Failed to open output file for append " + configInfo.readOutputFilename(), 3);
                return false;
            }
        }
        
        // Now have saved any existing Output file contents, can open the output file ready for writing     
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

        
        initDone = true;
        
        // Is now save to write back the output file contents if this is a pseudo-append
        if (configInfo.readAppendToOutputFile())
        {
            // Now rewrite back the saved lines to the top of this output file
            for (int i = 0; i < existingOutputText.size(); i++)
            {
                printOutputLine(existingOutputText.get(i));
            }
        }
        
        return true;
    }
    
    public boolean saveExistingOutputFileText()
    {
        // Cannot append to files easily in Processing
        // So if the file exists, open, and read into an array
        File file = new File(configInfo.readOutputFilename());
        if (file.exists())
        {            
            // Read in contents of the file
            BufferedReader reader;
            String line;
            reader = createReader(configInfo.readOutputFilename());

            boolean eof = false;
            while (!eof)
            {
                try 
                {
                    line = reader.readLine();
                } 
                catch (IOException e) 
                {
                    e.printStackTrace();
                    printToFile.printDebugLine(this, "IO exception when reading in existing output file " + configInfo.readOutputFilename(), 3);
                    line = null;
                }
                catch(Exception e)
                {
                    println(e);
                    printToFile.printDebugLine(this, "General exception when reading in existing output file (= ERROR) " + configInfo.readOutputFilename(), 3);
                    return false;
                } 

                if (line == null) 
                {
                    // Stop reading because of an error or file is empty
                    printToFile.printDebugLine(this, configInfo.readOutputFilename() + " is empty or IO exception encountered", 1);
                    eof = true;  
                } 
                else 
                {
                    existingOutputText.append(line);
                }
            }           
        } 
        
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
        
        if (!configInfo.readUseVagrantFlag())
        {
            printOutputLine("Reading/writing files from server " + configInfo.readServerName() + " (** indicate changed JSON files)");
        }
        else
        {
            printOutputLine("Reading/writing files using vagrant file system (** indicate changed JSON files)");
        }
                
        if (configInfo.readWriteJSONsToPersdata())
        {
            printOutputLine("DEBUG Writing JSON files to persdata");
        }
        else
        {
            printOutputLine("DEBUG No JSON filesx being written to persdata");
        }
        
        if (!usingBlackWhiteComparison)
        {
            printOutputLine("DEBUG Using Geo data to change image files");
        }
        else
        {
            printOutputLine("DEBUG Converting images to black/white for compare");
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
                // Used to clearly show if JSON has been updated
                s = "** ";
            }

            switch (itemResults.get(i).readResult())
            {
                case SummaryChanges.SKIPPED:
                    s = s + "SKIPPED " + itemResults.get(i).readItemTSID() + ": " + itemResults.get(i).readItemClassTSID();
                    s = s + Utils.formatItemInfoString(itemResults.get(i).readOrigItemExtraInfo());
                    skippedCount++;
                    break;    
                            
                case SummaryChanges.MISSING:
                    if (itemResults.get(i).readItemClassTSID().equals("quoin"))
                    {
                        s = s + "MISSING quoin " + itemResults.get(i).readItemTSID() + ": " + itemResults.get(i).readItemClassTSID();
                        s = s + "(" + itemResults.get(i).readOrigItemExtraInfo() + "/" + itemResults.get(i).readOrigItemClassName() + ")";
                        s = s + " defaulted to (mystery/placement tester)";
                    }
                    else
                    {
                         s = s + "MISSING " + itemResults.get(i).readItemTSID() + ": " + itemResults.get(i).readItemClassTSID();
                         s = s + Utils.formatItemInfoString(itemResults.get(i).readOrigItemExtraInfo());
                    }
                    missingCount++;
                    break; 
                            
                case SummaryChanges.COORDS_ONLY:
                    s = s + "Changed co-ords " + itemResults.get(i).readItemTSID() + ": " + itemResults.get(i).readItemClassTSID();
                    if (itemResults.get(i).readItemClassTSID().equals("quoin"))
                    {
                        s = s + "(" + itemResults.get(i).readOrigItemExtraInfo() + "/" + itemResults.get(i).readOrigItemClassName() + ")";
                    }
                    else
                    {
                        s = s + Utils.formatItemInfoString(itemResults.get(i).readOrigItemExtraInfo());
                    }
                    break;
                         
                case SummaryChanges.VARIANT_ONLY:
                    s = s + "Changed variant " + itemResults.get(i).readItemTSID() + ": " + itemResults.get(i).readItemClassTSID();
                    if (itemResults.get(i).readItemClassTSID().equals("quoin"))
                    {
                        s = s + "(" + itemResults.get(i).readNewItemExtraInfo() + "/" + itemResults.get(i).readNewItemClassName() + ")";
                        s = s + " (was " + itemResults.get(i).readOrigItemExtraInfo() + "/" + itemResults.get(i).readOrigItemClassName() + ")";
                    }
                    else
                    {
                        s = s + Utils.formatItemInfoString(itemResults.get(i).readNewItemExtraInfo());
                        if (itemResults.get(i).readOrigItemExtraInfo().length() > 0)
                        {
                            s = s + " (was " + Utils.formatItemInfoString(itemResults.get(i).readOrigItemExtraInfo()) + ")";
                        }
                        else
                        {
                            s = s + " (inserted variant field)";
                        }
                    }
                    break;
                            
                case SummaryChanges.VARIANT_AND_COORDS_CHANGED:
                    s = s + "Changed variant & co-ords " + itemResults.get(i).readItemTSID() + ": " + itemResults.get(i).readItemClassTSID();
                    if (itemResults.get(i).readItemClassTSID().equals("quoin"))
                    {
                        s = s + "(" + itemResults.get(i).readNewItemExtraInfo() + "/" + itemResults.get(i).readNewItemClassName() + ")";
                        s = s + " (was " + itemResults.get(i).readOrigItemExtraInfo() + "/" + itemResults.get(i).readOrigItemClassName() + ")";
                    }
                    else
                    {
                        s = s + Utils.formatItemInfoString(itemResults.get(i).readNewItemExtraInfo());
                        if (itemResults.get(i).readOrigItemExtraInfo().length() > 0)
                        {
                            s = s + " (was " + Utils.formatItemInfoString(itemResults.get(i).readOrigItemExtraInfo()) + ")";
                        }
                        else
                        {
                            s = s + " (inserted variant field)";
                        }
                    }
                    break;
                    
                case SummaryChanges.UNCHANGED:
                /*
                    if (itemResults.get(i).readAlreadySetDirField())
                    {
                        // This handles the case of e.g. shrine where x,y unchanged and just inserted the missing dir field
                        // Had to fake up the missing variant field in order to correctly handle images
                        s = s + "Changed variant ";
                        s = s + itemResults.get(i).readItemTSID() + ": " + itemResults.get(i).readItemClassTSID();
                    }
                    else
                    {*/
                        s = s + "Unchanged ";
                        s = s + itemResults.get(i).readItemTSID() + ": " + itemResults.get(i).readItemClassTSID();
                    //}
                    if (itemResults.get(i).readItemClassTSID().equals("quoin"))
                    {
                        s = s + "(" + itemResults.get(i).readOrigItemExtraInfo() + "/" + itemResults.get(i).readOrigItemClassName() + ")";
                    }
                    else
                    {
                        s = s + Utils.formatItemInfoString(itemResults.get(i).readOrigItemExtraInfo());
                    }
                    break;
                            
                default:
                    printDebugLine(this, "Unexpected results type " + itemResults.get(i).readResult(), 3);
                    failNow = true;
                    return false;  
            }
                        
            s = s + " at x,y " + itemResults.get(i).readItemX() + "," + itemResults.get(i).readItemY();
            if (itemResults.get(i).readResult() == SummaryChanges.COORDS_ONLY || itemResults.get(i).readResult() == SummaryChanges.VARIANT_AND_COORDS_CHANGED)
            {
                s = s + " (was " + itemResults.get(i).readOrigItemX() + "," +  itemResults.get(i).readOrigItemY() + ")"; 
            }
            
            printOutputLine(s);

            if (itemResults.get(i).readItemClassTSID().equals("quoin"))
            {
                switch (itemResults.get(i).readNewItemExtraInfo())
                {
                    case "xp":
                        quoinXP++;
                        break;
                        
                    case "energy":
                        quoinEnergy++;
                        break;
                        
                    case "mood":
                        quoinMood++;
                        break;
                        
                    case "currants":
                        quoinCurrants++;
                        break;
                        
                    case "time":
                        quoinTime++;
                        break;
                        
                    case "favor":
                        quoinFavor++;
                        break;
                        
                    case "mystery":
                        quoinMystery++;
                        break;
                        
                    default:
                        printDebugLine(this, "Unexpected quoin type " + itemResults.get(i).readNewItemExtraInfo(), 3);
                        failNow = true;
                        return false;
                }
            }
        }
        
        // Just dump out number of quoins
        s = "\nSkipped " + skippedCount + " items, missing " + missingCount + " items";
        printOutputLine(s);
        
        s = "Quoin count is: XP=" + quoinXP + "   energy=" + quoinEnergy + "   mood=" + quoinMood +
            "   currants=" + quoinCurrants +"   favor=" + quoinFavor +"   time=" + quoinTime +"   mystery=" + quoinMystery +
            " Total=" + (quoinXP + quoinEnergy + quoinMood + quoinCurrants + quoinFavor + quoinTime + quoinMystery);

        printOutputLine(s);
        printOutputLine("\n\n");
        return true;
    }
    
          
    public boolean readOkFlag()
    {
        return (okFlag);
    }
}