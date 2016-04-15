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
                displayMgr.showErrMsg("Failed to open debug file");
                return false;
            }
        }
        
        // Open output file
        // If file already exists - then rename before creating this output file  
        if (!renameExistingOutputFile())
        {
            return false;
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
            displayMgr.showErrMsg("Failed to open output file " + configInfo.readOutputFilename());
            return false;
        }

        
        initDone = true;        
        return true;
    } 
    
    boolean renameExistingOutputFile()
    {
        // If the output file already exists, then rename before continuing on
        
        File f = new File(configInfo.readOutputFilename());
        if (!f.exists())
        {
            // Does not exist - so OK to continue
            return true;
        }
        
        // Output file already exists. So rename
        String outputFileName = f.getName();
        String outputFileNamePrefix = outputFileName.replace(".txt", "");
        String outputFileDir = configInfo.readOutputFilename().replace(File.separatorChar + outputFileName, "");
        String [] outputFiles = Utils.loadFilenames(outputFileDir, outputFileNamePrefix, ".txt");
        if (outputFiles.length == 0)
        {
            println("Unexpected error setting up outputfile ", configInfo.readOutputFilename(), " - please remove all versions of the outputfile before retrying");
            displayMgr.showErrMsg("Unexpected error setting up outputfile " + configInfo.readOutputFilename() + " - please remove all versions of the outputfile before retrying");
            return false;
        }

        // If outputFile is the only one that exists, then will be renamed to _1 etc etc. 
        // This will fail if the user has manually changed the numbers so e.g. get outputFile and outputFile_2 being present - 
        // the attempt to rename outputFile to outputFile_2 will fail. But this is the simplest way of renaming a file
        // because the loadFilenames function returns files in alphabetical order so outputFile22 is earlier in the list than 
        // outputFile_8 ... 
        String destFilename = outputFileDir + File.separatorChar + outputFileNamePrefix + "_" + outputFiles.length + ".txt";;
        File destFile = new File(destFilename);
        try
        {
            if (!f.renameTo(destFile))
            {
                println("Error attempting to move ", configInfo.readOutputFilename(), " to ", destFilename, " - please remove all versions of the outputfile before retrying");
                displayMgr.showErrMsg("Error attempting to move " + configInfo.readOutputFilename() + " to " + destFilename + " - please remove all versions of the outputfile before retrying");
                return false;
            }
        }
        catch (Exception e)
        {
             // if any error occurs
             e.printStackTrace();  
             println("Error attempting to move ", configInfo.readOutputFilename(), " to ", destFilename, " - please remove all versions of the outputfile before retrying");
             displayMgr.showErrMsg("Error attempting to move " + configInfo.readOutputFilename() + " to " + destFilename + " - please remove all versions of the outputfile before retrying");
             return false;
        }
        
        println("Moving ", configInfo.readOutputFilename(), " to ", destFilename);
        displayMgr.showErrMsg("Moving " + configInfo.readOutputFilename() + " to " + destFilename);
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
    
    public void printSummaryHeader()
    {
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
            printOutputLine("DEBUG No JSON files being written to persdata");
        }
        
        if (!usingBlackWhiteComparison)
        {
            printOutputLine("DEBUG Using Geo data to change image files");
        }
        else
        {
            printOutputLine("DEBUG Converting images to black/white for compare");
        }
    }
    
    public boolean printSummaryData(ArrayList<SummaryChanges> itemResults)
    {
        String s;
        // Now print out the summary array
  
        // Sort array by x co-ord so listing items from L to R
        // There won't be any colocated items because these have already been resolved
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
            if (itemResults.get(i).itemInfo.readSaveChangedJSONfile())
            {
                // Used to clearly show if JSON has been updated
                s = "** ";
            }

            switch (itemResults.get(i).readResult())
            {
                case SummaryChanges.SKIPPED:
                    s = s + "SKIPPED " + itemResults.get(i).itemInfo.readItemTSID() + ": " + itemResults.get(i).itemInfo.readItemClassTSID();
                    s = s + Utils.formatItemInfoString(itemResults.get(i).itemInfo.readOrigItemExtraInfo());
                    skippedCount++;
                    break;    
                            
                case SummaryChanges.MISSING:
                    if (itemResults.get(i).itemInfo.readItemClassTSID().equals("quoin"))
                    {
                        s = s + "MISSING quoin " + itemResults.get(i).itemInfo.readItemTSID() + ": " + itemResults.get(i).itemInfo.readItemClassTSID();
                        s = s + "(" + itemResults.get(i).itemInfo.readOrigItemExtraInfo() + "/" + itemResults.get(i).itemInfo.readOrigItemClassName() + ")";
                        s = s + " defaulted to (mystery/placement tester)";
                    }
                    else
                    {
                         s = s + "MISSING " + itemResults.get(i).itemInfo.readItemTSID() + ": " + itemResults.get(i).itemInfo.readItemClassTSID();
                         s = s + Utils.formatItemInfoString(itemResults.get(i).itemInfo.readOrigItemExtraInfo());
                    }
                    missingCount++;
                    break; 
                            
                case SummaryChanges.COORDS_ONLY:
                    s = s + "Changed co-ords " + itemResults.get(i).itemInfo.readItemTSID() + ": " + itemResults.get(i).itemInfo.readItemClassTSID();
                    if (itemResults.get(i).itemInfo.readItemClassTSID().equals("quoin"))
                    {
                        s = s + "(" + itemResults.get(i).itemInfo.readOrigItemExtraInfo() + "/" + itemResults.get(i).itemInfo.readOrigItemClassName() + ")";
                    }
                    else
                    {
                        s = s + Utils.formatItemInfoString(itemResults.get(i).itemInfo.readOrigItemExtraInfo());
                    }
                    break;
                         
                case SummaryChanges.VARIANT_ONLY:
                    s = s + "Changed variant " + itemResults.get(i).itemInfo.readItemTSID() + ": " + itemResults.get(i).itemInfo.readItemClassTSID();
                    if (itemResults.get(i).itemInfo.readItemClassTSID().equals("quoin"))
                    {
                        s = s + "(" + itemResults.get(i).itemInfo.readNewItemExtraInfo() + "/" + itemResults.get(i).itemInfo.readNewItemClassName() + ")";
                        s = s + " (was " + itemResults.get(i).itemInfo.readOrigItemExtraInfo() + "/" + itemResults.get(i).itemInfo.readOrigItemClassName() + ")";
                    }
                    else
                    {
                        s = s + Utils.formatItemInfoString(itemResults.get(i).itemInfo.readNewItemExtraInfo());
                        if (itemResults.get(i).itemInfo.readOrigItemExtraInfo().length() > 0)
                        {
                            s = s + " (was " + Utils.formatItemInfoString(itemResults.get(i).itemInfo.readOrigItemExtraInfo()) + ")";
                        }
                        else
                        {
                            s = s + " (inserted variant field)";
                        }
                    }
                    break;
                            
                case SummaryChanges.VARIANT_AND_COORDS_CHANGED:
                    s = s + "Changed variant & co-ords " + itemResults.get(i).itemInfo.readItemTSID() + ": " + itemResults.get(i).itemInfo.readItemClassTSID();
                    if (itemResults.get(i).itemInfo.readItemClassTSID().equals("quoin"))
                    {
                        s = s + "(" + itemResults.get(i).itemInfo.readNewItemExtraInfo() + "/" + itemResults.get(i).itemInfo.readNewItemClassName() + ")";
                        s = s + " (was " + itemResults.get(i).itemInfo.readOrigItemExtraInfo() + "/" + itemResults.get(i).itemInfo.readOrigItemClassName() + ")";
                    }
                    else
                    {
                        s = s + Utils.formatItemInfoString(itemResults.get(i).itemInfo.readNewItemExtraInfo());
                        if (itemResults.get(i).itemInfo.readOrigItemExtraInfo().length() > 0)
                        {
                            s = s + " (was " + Utils.formatItemInfoString(itemResults.get(i).itemInfo.readOrigItemExtraInfo()) + ")";
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
                        s = s + itemResults.get(i).itemInfo.readItemTSID() + ": " + itemResults.get(i).itemInfo.readItemClassTSID();
                    }
                    else
                    {*/
                        s = s + "Unchanged ";
                        s = s + itemResults.get(i).itemInfo.readItemTSID() + ": " + itemResults.get(i).itemInfo.readItemClassTSID();
                    //}
                    if (itemResults.get(i).itemInfo.readItemClassTSID().equals("quoin"))
                    {
                        s = s + "(" + itemResults.get(i).itemInfo.readOrigItemExtraInfo() + "/" + itemResults.get(i).itemInfo.readOrigItemClassName() + ")";
                    }
                    else
                    {
                        s = s + Utils.formatItemInfoString(itemResults.get(i).itemInfo.readOrigItemExtraInfo());
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
                s = s + " (was " + itemResults.get(i).itemInfo.readOrigItemX() + "," +  itemResults.get(i).itemInfo.readOrigItemY() + ")"; 
            }
            
            printOutputLine(s);

            if (itemResults.get(i).itemInfo.readItemClassTSID().equals("quoin"))
            {
                switch (itemResults.get(i).itemInfo.readNewItemExtraInfo())
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
                        printDebugLine(this, "Unexpected quoin type " + itemResults.get(i).itemInfo.readNewItemExtraInfo(), 3);
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