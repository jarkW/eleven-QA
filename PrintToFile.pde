class PrintToFile 
{
   
   boolean okFlag;
   String timestamp;
 
   StringList existingOutputText;
    
     // constructor/initialise fields
    public PrintToFile()
    {
        okFlag = true;
        timestamp = nf(day(),2) + "/" + nf(month(),2) + "/" + year() + "   " + nf(hour(),2) + ":" + nf(minute(),2) + ":" + nf(second(),2);
    }
    
    public boolean initPrintToDebugFile()
    { 
        // Open debug file
        debugOutput = new OutputFile(workingDir + File.separatorChar + "debug_info.txt", true);  
        
        // Open debug file
        if (debugLevel > 0)
        {
            // Collecting debug info so open file
            if (!debugOutput.openOutputFile())
            {
                return false;
            }
        } 
        // Print timestamp at top of file
        printDebugLine(this, timestamp, 3);             
        return true;
    }     
    
    public boolean initPrintToOutputFile()
    {   
        // Open output file
        infoOutput = new OutputFile(configInfo.readOutputFilename(), false);
        
        // If file already exists - then rename before creating this output file  
        if (!renameExistingFile(configInfo.readOutputFilename()))
        {
            return false;
        }

        // Now have saved any existing Output file contents, can open the output file ready for writing  
        if (!infoOutput.openOutputFile())
        {
            return false;
        }
        
        // Write header information - which just dumps out the settings in the config.json file 
        printOutputLine(timestamp);      
        infoOutput.writeHeaderInfo(false);
        return true;
    } 
    
    public boolean initPrintToValidationSummaryOutputFile()
    {
        // Used to produce summary of streets for a validation run - to make differences easier to find
        validationSummaryOutput = new OutputFile(configInfo.readDebugValidationPath() + File.separatorChar + "validation_summary.txt", false);
        
        if (!configInfo.readDebugValidationRun())
        {
            // output structure should not not set up, flag remains set to false so will never be written to or closed
            return true;
        }
        // Open output file
        // If file already exists - then rename before creating this validation summary output file
        if (!renameExistingFile(configInfo.readDebugValidationPath() + File.separatorChar + "validation_summary.txt"))
        {
            return false;
        }

        // Now have saved any existing validation file contents, can open the file ready for writing 
        if (!validationSummaryOutput.openOutputFile())
        {
            return false;
        }
        
        // Write header information - which just dumps out the settings in the config.json file   
        printValidationSummaryOutputLine(timestamp);  
        validationSummaryOutput.writeHeaderInfo(true);
        
        // Add in reminder line to file about what is being dumped
        printValidationSummaryOutputLine("Only changed items are being reported in this file - see validation.txt for the full picture");
        return true;
    } 
    
    boolean renameExistingFile(String existingFname)
    {
        // If the file already exists, then rename before continuing on
        
        File f = new File(existingFname);
        if (!f.exists())
        {
            // Does not exist - so OK to continue
            return true;
        }

        // Output file already exists. So rename
        String fileName = f.getName();
        String fileNamePrefix = fileName.replace(".txt", "");
        String fileDir = existingFname.replace(File.separatorChar + fileName, "");
        String [] files = Utils.loadFilenames(fileDir, fileNamePrefix, ".txt");
        if (files.length == 0)
        {
            println("Unexpected error setting up file " + existingFname + " - please remove all versions of the file before retrying");
            displayMgr.showErrMsg("Unexpected error setting up file " + existingFname + " - please remove all versions of the file before retrying", true);
            return false;
        }

        // If outputFile is the only one that exists, then will be renamed to _1 etc etc. 
        // This will fail if the user has manually changed the numbers so e.g. get outputFile and outputFile_2 being present - 
        // the attempt to rename outputFile to outputFile_2 will fail. But this is the simplest way of renaming a file
        // because the loadFilenames function returns files in alphabetical order so outputFile22 is earlier in the list than 
        // outputFile_8 ... 
        String destFilename = fileDir + File.separatorChar + fileNamePrefix + "_" + files.length + ".txt";
        File destFile = new File(destFilename);
        try
        {
            if (!f.renameTo(destFile))
            {
                println("Error attempting to move " + existingFname + " to ", destFilename + " - please remove all versions of the file before retrying");
                displayMgr.showErrMsg("Error attempting to move " + existingFname + " to " + destFilename + " - please remove all versions of the file before retrying", true);
                return false;
            }
        }
        catch (Exception e)
        {
             // if any error occurs
             e.printStackTrace();  
             println("Error attempting to move " + existingFname + " to " + destFilename + " - please remove all versions of the file before retrying");
             displayMgr.showErrMsg("Error attempting to move " + existingFname + " to " + destFilename + " - please remove all versions of the file before retrying", true);
             return false;
        }
        
        println("Moving " + existingFname + " to " + destFilename);
        displayMgr.showInfoMsg("Moving " + existingFname + " to " + destFilename);
        return true;
    }
 
    // Used to just print debug information - so can filter out minor messages
    // if not needed
    public void printDebugLine(Object callingClass, String lineToWrite, int severity)
    {     
        // Do nothing if not collecting debug info
        if (debugLevel == 0)
        {
            return;
        }
        
        if (severity >= debugLevel)
        {
            String s = callingClass.getClass().getName().replace("QABot$", " ") + "::";
            String methodName = Thread.currentThread().getStackTrace()[2].getMethodName();
            
            // Do we need to print this line to the console
            if (debugToConsole)
            {
                println(s + lineToWrite);
            }
        
            // Output line 
            debugOutput.printLine(s + methodName + ":\t" + lineToWrite);
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
        
        // Output line 
        infoOutput.printLine(lineToWrite);
    }

    public void printValidationSummaryOutputLine(String lineToWrite)
    {               
        // Output line 
        validationSummaryOutput.printLine(lineToWrite);
    }
    
    public void closeOutputFile()
    {
        if (infoOutput != null)
        {
            infoOutput.closeFile();
        }
        return;
    }
    
    public void closeDebugFile()
    {
        if (debugOutput != null)
        {
            debugOutput.closeFile();
        }
        return;
    }
    
    public void closevalidationSummaryOutputFile()
    {
        if (validationSummaryOutput != null)
        {
            validationSummaryOutput.closeFile();
        }
        return;
    }
        
    public void printSummaryHeader()
    {
        infoOutput.writeStreetHeaderInfo();
        if (configInfo.readDebugValidationRun())
        {
            validationSummaryOutput.writeStreetHeaderInfo();
        }
        return; 
    }
    
    public boolean printOutputSummaryData(ArrayList<SummaryChanges> itemResults)
    {
        if (!infoOutput.printSummaryData(itemResults, false))
        {
            return false;
        }
        if (configInfo.readDebugValidationRun())
        {
            if (!validationSummaryOutput.printSummaryData(itemResults, true))
            {
                return false;
            }
        }

        return true;
    }   
          
    public boolean readOkFlag()
    {
        return (okFlag);
    }
    
}