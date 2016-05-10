class PrintToFile {
   
   // Used for saving debug info
   PrintWriter debugOutput;
   PrintWriter infoOutput;
   boolean okFlag;
   boolean initDebugFileDone;
   boolean initOutputFileDone;
   
   StringList existingOutputText;
    
     // constructor/initialise fields
    public PrintToFile()
    {
        okFlag = true;
        initDebugFileDone = false;
        initOutputFileDone = false;
    }
    
    public boolean initPrintToDebugFile()
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
                displayMgr.showErrMsg("Failed to open debug file", true);
                return false;
            }
        }

        initDebugFileDone = true;        
        return true;
    } 
    
    public boolean initPrintToOutputFile()
    {       
                        
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
            displayMgr.showErrMsg("Failed to open output file " + configInfo.readOutputFilename(), true);
            return false;
        }

        
        initOutputFileDone = true;
        
        // Write header information - which just dumps out the settings in the config.json file   
        if (!configInfo.readUseVagrantFlag())
        {
            printOutputLine("Reading/writing files from server " + configInfo.readServerName() + " (** indicates changed JSON file)");
        }
        else
        {
            printOutputLine("Reading/writing files using vagrant file system (** indicates changed JSON file)");
        }
                
        if (configInfo.readWriteJSONsToPersdata())
        {
            printOutputLine("Writing JSON files to persdata (see list of changed files below)");
        }
        else
        {
            printOutputLine("WARNING No JSON files being written to persdata");
        }
        
        if (!configInfo.readChangeXYOnly())
        {
            printOutputLine("Changing x,y and variants of items using a search radius of " + configInfo.readSearchRadius() + " pixels and a match requirement of " + configInfo.readPercentMatchCriteria() + "%");
        }
        else
        {
            printOutputLine("WARNING Changing x,y ONLY of items using a search radius of " + configInfo.readSearchRadius() + " pixels and a match requirement of " + configInfo.readPercentMatchCriteria() + "%");
        }
        
        if (!usingBlackWhiteComparison)
        {
            printOutputLine("DEBUG Using Geo data to change image files");
        }
        else
        {
            printOutputLine("DEBUG Converting images to black/white for compare");
        }

    
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
            displayMgr.showErrMsg("Unexpected error setting up outputfile " + configInfo.readOutputFilename() + " - please remove all versions of the outputfile before retrying", true);
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
                displayMgr.showErrMsg("Error attempting to move " + configInfo.readOutputFilename() + " to " + destFilename + " - please remove all versions of the outputfile before retrying", true);
                return false;
            }
        }
        catch (Exception e)
        {
             // if any error occurs
             e.printStackTrace();  
             println("Error attempting to move ", configInfo.readOutputFilename(), " to ", destFilename, " - please remove all versions of the outputfile before retrying");
             displayMgr.showErrMsg("Error attempting to move " + configInfo.readOutputFilename() + " to " + destFilename + " - please remove all versions of the outputfile before retrying", true);
             return false;
        }
        
        println("Moving ", configInfo.readOutputFilename(), " to ", destFilename);
        displayMgr.showInfoMsg("Moving " + configInfo.readOutputFilename() + " to " + destFilename);
        return true;
    }
 
    // Used to just print debug information - so can filter out minor messages
    // if not needed
    public void printDebugLine(Object callingClass, String lineToWrite, int severity)
    {
        // Do nothing if not yet initialised this object
        if (!initDebugFileDone)
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
        if (!initOutputFileDone)
        {
            return;
        }
        
        // Output line 
        infoOutput.println(lineToWrite);
        infoOutput.flush();
    }
    
    public void printSummaryHeader()
    {
        String s = "============================================================================================";
        printOutputLine(s);
        s = "\nResults for " + streetInfo.readStreetName() + " (" + streetInfo.readStreetTSID() + ")";
        printOutputLine(s);
               
        // print out information about skipped street snaps
        if (streetInfo.readSkippedStreetSnapCount() > 0)
        {
            for (int i = 0; i < streetInfo.readSkippedStreetSnapCount(); i++)
            {
                s = "Skipped street snap (wrong size): " + streetInfo.readSkippedStreetSnapName(i);
                printOutputLine(s);
            }
        }
        s = "Searched " + streetInfo.readValidStreetSnapCount() + " valid street snaps of correct size " + streetInfo.readGeoWidth() + "x" + streetInfo.readGeoHeight() + " pixels";
        printOutputLine(s);
        
        // Print information about any special quoin defaulting which might have happened e.g. because Ancestral Lands
        // For the default case nothing is printed
        s = streetInfo.readQuoinDefaultingInfo();
        if (s.length() > 0)
        {
            printOutputLine(s);
        }
        // This warning message is only ever written for problems with Rainbow Run where quoins are reset
        s = streetInfo.readQuoinDefaultingWarningMsg();
        if (s.length() > 0)
        {
            printOutputLine(s);
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
        
        MatchInfo bestMatchInfo;
                
        for (int i = 0; i < itemResults.size(); i++)
        {
            s = "";
            if (itemResults.get(i).itemInfo.readSaveChangedJSONfile())
            {
                // Used to clearly show if JSON has been changed
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
                    displayMgr.showErrMsg("Unexpected results type " + itemResults.get(i).readResult(), true);
                    failNow = true;
                    return false;  
            }
                        
            s = s + " at x,y " + itemResults.get(i).readItemX() + "," + itemResults.get(i).readItemY();
            if (itemResults.get(i).readResult() == SummaryChanges.COORDS_ONLY || itemResults.get(i).readResult() == SummaryChanges.VARIANT_AND_COORDS_CHANGED)
            {
                s = s + " (was " + itemResults.get(i).itemInfo.readOrigItemX() + "," +  itemResults.get(i).itemInfo.readOrigItemY() + ")"; 
            }

            // Now add some information about the efficiency of the match
            if (itemResults.get(i).readResult() != SummaryChanges.SKIPPED)
            {
                bestMatchInfo = itemResults.get(i).itemInfo.readBestMatchInfo();
                switch (itemResults.get(i).readResult())
                {
                    case SummaryChanges.COORDS_ONLY:
                    case SummaryChanges.VARIANT_AND_COORDS_CHANGED:
                        // Just print out the match information - as the new co-ordinates have already been given
                        s = s + " (match = " + bestMatchInfo.matchPercentString() + ")";
                        s = s + " (" + bestMatchInfo.furthestCoOrdDistance(itemResults.get(i).itemInfo.readOrigItemX(), itemResults.get(i).itemInfo.readOrigItemY()) + "px from original x,y)";
                        break;
                        
                    case SummaryChanges.VARIANT_ONLY:
                    case SummaryChanges.UNCHANGED:
                        // Just print out the match information - as the new co-ordinates have already been given
                        s = s + " (match = " + bestMatchInfo.matchPercentString() + ")";
                        break;
                
                    case SummaryChanges.MISSING:
                        // Give the match data and the x,y this pertains to.
                        s = s + " (match = " + bestMatchInfo.matchPercentString() + " for x,y " + bestMatchInfo.matchXYString() +")";
                        break;
                }
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
                        displayMgr.showErrMsg("Unexpected quoin type " + itemResults.get(i).itemInfo.readNewItemExtraInfo(), true);
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
        printOutputLine("\n");
        return true;
    }
    
          
    public boolean readOkFlag()
    {
        return (okFlag);
    }
}