class OutputFile
{
    PrintWriter output;
    boolean initFlag;
    String fname;
    boolean isDebugFile;
        
    public OutputFile(String filename, boolean debugFileFlag)
    {
        output = null;
        initFlag = false;
        fname = filename;
        isDebugFile = debugFileFlag;
    }
        
    public boolean openOutputFile()
    {
        // open the file ready for writing     
        try
        {
            output = createWriter(fname);
        }
        catch(Exception e)
        {
            println(e);
            if (isDebugFile)
            {
                // Cannot write this error to debug file ...
                println("Failed to open debug file");
            }
            else
            {
                printToFile.printDebugLine(this, "Failed to open file " + fname, 3);
            }
            displayMgr.showErrMsg("Failed to open file " + fname, true);
            return false;
        }
        
        initFlag = true;
        return true;
    }
        
    public void writeHeaderInfo(boolean validationFlag)
    {
     
        String s;
        
        // Write header information - which just dumps out the settings in the QABot_config.json file   
        if (!configInfo.readUseVagrantFlag())
        {
            s = "Reading/writing files from server " + configInfo.readServerName();
        }
        else
        {
            s = "Reading/writing files using vagrant file system";
        }
        if (!validationFlag)
        {
            s = s + " (** indicates changed JSON file)";
        }
        printLine(s);
            
        if (configInfo.readWriteJSONsToPersdata())
        {
            s = "Changing";
        }
        else
        {
            s = "Reporting (not changing)";
        }
 
        // construct the string which documents the actions to be taken for persdata-qa and non-persdata-qa streets
        if (configInfo.readStreetInPersdataAction().readChangeXYOnlyFlag())
        {
            if (configInfo.readStreetInPersdataQAAction().readChangeXYOnlyFlag())
            {
                s = "WARNING " + s + " x,y ONLY for items on ALL streets including those in persdata-qa";
            }
            else if (configInfo.readStreetInPersdataQAAction().readChangeXYAndVariantFlag())
            {
                // This is particularly concerning - so flag up
                s = "!!! WARNING !!! " + s + " x,y ONLY for items on streets not in persdata-qa, x,y and variant for streets in persdata-qa";
            }
            else
            {
                s = "WARNING " + s + " x,y ONLY for items on streets not in persdata-qa, skipping streets in persdata-qa";
            }
        }
        else if (configInfo.readStreetInPersdataAction().readChangeXYAndVariantFlag())
        {
            if (configInfo.readStreetInPersdataQAAction().readChangeXYOnlyFlag())
            {
                s = "WARNING " + s + " x,y and variant for items on streets not in persdata-qa, x,y ONLY for streets in persdata-qa"; 
            }
            else if (configInfo.readStreetInPersdataQAAction().readChangeXYAndVariantFlag())
            {
                // This is particularly concerning - so flag up
                s = "!!! WARNING !!! " + s + " x,y and variant for items on ALL streets including those in persdata-qa";
            }
            else
            {
                s = "DEFAULT action - " + s + " x,y and variant for items on streets not in persdata-qa, skipping streets in persdata-qa";
            }
        }
        else
        {
            if (configInfo.readStreetInPersdataQAAction().readChangeXYOnlyFlag())
            {
                s = "WARNING " + s + " skipping items on streets not in persdata-qa, x,y ONLY for streets in persdata-qa"; 
            }
            else if (configInfo.readStreetInPersdataQAAction().readChangeXYAndVariantFlag())
            {
                // This is particularly concerning - so flag up
                s = "!!! WARNING !!! " + s + " skipping items on streets not in persdata-qa, x,y and variant for items in persdata-qa";
            }
            else
            {
                s = "WARNING " + s + " skipping items on ALL streets";
            }
        }
        printLine(s);
        printLine("Using a search radius of " + configInfo.readSearchRadius() + " pixels and a match requirement of " + configInfo.readPercentMatchCriteria() + "%");
        
        if (configInfo.readWriteJSONsToPersdata())
        {
            printLine("Writing JSON files to persdata (see list of changed files below)");
        }
        else
        {
            printLine("WARNING No JSON files being written to persdata");
        }
        
        if (configInfo.readUseMatureItemImagesOnly())
        {
            printLine("Searching using mature/complete images of items such as trees, rocks etc");
        }
        else
        {
            printLine("Searching using images of all stages of items such as trees, rocks etc");
        }
    
        if (configInfo.readDebugRun())
        {
            // Only print out these messages for my use
            if (configInfo.readDebugUseTintedFragment())
            {
                printLine("DEBUG Using Geo data to change item image for B&W comparison");
                printLine("DEBUG NB Wood trees might appear to be matched by an image which is one stage more mature - produces the same x,y (both images have same size/offsets)");
            }
            else
            {
                printLine("DEBUG Using UNTINTED item images for B&W comparison");
            }
        }
    }
    
    public void printLine(String info)
    {
    
        // Do nothing if not yet initialised this object
        if (!initFlag)
        {
            return;
        }
    
        // Output line 
        output.println(info);
        output.flush();
    }
    
    public void writeStreetHeaderInfo()
    {
        String s = "============================================================================================";
        printLine(s);
        s = "\nResults for " + streetInfo.readStreetName() + " (" + streetInfo.readStreetTSID() + ")";
        printLine(s);
           
        // print out information about skipped street snaps
        if (streetInfo.readSkippedStreetSnapCount() > 0)
        {
            for (int i = 0; i < streetInfo.readSkippedStreetSnapCount(); i++)
            {
                s = "Skipped street snap (wrong size): " + streetInfo.readSkippedStreetSnapName(i);
                printLine(s);
            }
        }
        s = "Searched " + streetInfo.readValidStreetSnapCount() + " valid street snaps of correct size " + streetInfo.readGeoWidth() + "x" + streetInfo.readGeoHeight() + " pixels";
        printLine(s);
    
        // Print information about any special quoin defaulting which might have happened e.g. because Ancestral Lands
        // For the default case nothing is printed
        s = streetInfo.readQuoinDefaultingInfo();
        if (s.length() > 0)
        {
            printLine(s);
        }
        // This warning message is only ever written for problems with Rainbow Run where quoins are reset
        s = streetInfo.readQuoinDefaultingWarningMsg();
        if (s.length() > 0)
        {
            printLine(s);
        }
        return;
    }
 
    public boolean printSummaryData(ArrayList<SummaryChanges> itemResults, boolean validationSummaryFlag)
    {
        String s;
        // Now print out the summary array - what is printed depends on the flag
  
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
        int nosChangedItems = 0;
    
        MatchInfo bestMatchInfo;
            
        for (int i = 0; i < itemResults.size(); i++)
        {
            s = "";
            if (!validationSummaryFlag && itemResults.get(i).itemInfo.readSaveChangedJSONfile())
            {
                // Used to clearly show if JSON has been changed
                s = "** ";
            }
        
            switch (itemResults.get(i).readResult())
            {
                case SummaryChanges.SKIPPED:
                    s = s + "SKIPPED " + itemResults.get(i).itemInfo.readItemTSID() + ": " + itemResults.get(i).itemInfo.readItemClassTSID();
                    s = s + Utils.formatItemInfoString(itemResults.get(i).itemInfo.readOrigItemVariant());
                    skippedCount++;
                    break;    
                        
                case SummaryChanges.MISSING:
                case SummaryChanges.MISSING_DUPLICATE:
                    if (itemResults.get(i).itemInfo.readItemClassTSID().equals("quoin"))
                    {
                        s = s + "MISSING quoin " + itemResults.get(i).itemInfo.readItemTSID() + ": " + itemResults.get(i).itemInfo.readItemClassTSID();
                        s = s + "(" + itemResults.get(i).itemInfo.readOrigItemClassName() + ")";
                        if (!streetInfo.readChangeItemXYOnly())
                        {
                            s = s + " defaulted to (mystery/placement tester)";
                        }
                    }
                    else
                    {
                         s = s + "MISSING " + itemResults.get(i).itemInfo.readItemTSID() + ": " + itemResults.get(i).itemInfo.readItemClassTSID();
                         s = s + Utils.formatItemInfoString(itemResults.get(i).itemInfo.readOrigItemVariant());
                    }
                    missingCount++;
                    break; 
                        
                case SummaryChanges.COORDS_ONLY:
                    if (!validationSummaryFlag)
                    {
                        s = s + "Changed co-ords ";
                    }
                    s = s + itemResults.get(i).itemInfo.readItemTSID() + ": " + itemResults.get(i).itemInfo.readItemClassTSID();
                    if (itemResults.get(i).itemInfo.readItemClassTSID().equals("quoin"))
                    {
                        s = s + "(" + itemResults.get(i).itemInfo.readOrigItemClassName() + ")";
                    }
                    else
                    {
                        s = s + Utils.formatItemInfoString(itemResults.get(i).itemInfo.readOrigItemVariant());
                    }
                    nosChangedItems++;
                    break;
                     
                case SummaryChanges.VARIANT_ONLY:
                    if (!validationSummaryFlag)
                    {
                        s = s + "Changed variant ";
                    }
                    s = s + itemResults.get(i).itemInfo.readItemTSID() + ": " + itemResults.get(i).itemInfo.readItemClassTSID();
                    if (itemResults.get(i).itemInfo.readItemClassTSID().equals("quoin"))
                    {
                        s = s + "(" + itemResults.get(i).itemInfo.readNewItemClassName() + ")";
                        if (!validationSummaryFlag)
                        {
                            s = s + " (was " + itemResults.get(i).itemInfo.readOrigItemClassName() + ")";
                        }
                    }
                    else
                    {
                        s = s + Utils.formatItemInfoString(itemResults.get(i).itemInfo.readNewItemVariant());
                    }
                    if (!validationSummaryFlag)
                    {
                        if (itemResults.get(i).itemInfo.readOrigItemVariant().length() > 0)
                        {
                            s = s + " (was " + Utils.formatItemInfoString(itemResults.get(i).itemInfo.readOrigItemVariant()) + ")";
                        }
                        else
                        {
                            s = s + " (inserted variant field)";
                        }
                    }
                    nosChangedItems++;
                    break;
                        
                case SummaryChanges.VARIANT_AND_COORDS_CHANGED:
                    if (!validationSummaryFlag)
                    {
                        s = s + "Changed variant & co-ords ";
                    }
                    s = s + itemResults.get(i).itemInfo.readItemTSID() + ": " + itemResults.get(i).itemInfo.readItemClassTSID();
                    if (itemResults.get(i).itemInfo.readItemClassTSID().equals("quoin"))
                    {
                        s = s + "(" + itemResults.get(i).itemInfo.readNewItemClassName() + ")";
                        if (!validationSummaryFlag)
                        {
                            s = s + " (was " + itemResults.get(i).itemInfo.readOrigItemClassName() + ")";
                        }
                    }
                    else
                    {
                        s = s + Utils.formatItemInfoString(itemResults.get(i).itemInfo.readNewItemVariant());
                        if (!validationSummaryFlag)
                        {
                            if (itemResults.get(i).itemInfo.readOrigItemVariant().length() > 0)
                            {
                                s = s + " (was " + Utils.formatItemInfoString(itemResults.get(i).itemInfo.readOrigItemVariant()) + ")";
                            }
                            else
                            {
                                s = s + " (inserted variant field)";
                            }
                        }
                    }
                    nosChangedItems++;
                    break;
                
                case SummaryChanges.UNCHANGED:
                    s = s + "Unchanged ";
                    s = s + itemResults.get(i).itemInfo.readItemTSID() + ": " + itemResults.get(i).itemInfo.readItemClassTSID();

                    if (itemResults.get(i).itemInfo.readItemClassTSID().equals("quoin"))
                    {
                        s = s + "(" + itemResults.get(i).itemInfo.readOrigItemClassName() + ")";
                    }
                    else
                    {
                        s = s + Utils.formatItemInfoString(itemResults.get(i).itemInfo.readOrigItemVariant());
                    }
                    break;
                        
                default:
                    printToFile.printDebugLine(this, "Unexpected results type " + itemResults.get(i).readResult(), 3);
                    displayMgr.showErrMsg("Unexpected results type " + itemResults.get(i).readResult(), true);
                    failNow = true;
                    return false;  
            }
            
            // In in the co-ordinate information
            s = s + " at x,y " + itemResults.get(i).readItemX() + "," + itemResults.get(i).readItemY();
            
            // Omit the efficiency information in the validation summary file
            if (!validationSummaryFlag)
            {
                if (itemResults.get(i).readResult() == SummaryChanges.COORDS_ONLY || itemResults.get(i).readResult() == SummaryChanges.VARIANT_AND_COORDS_CHANGED)
                {
                    s = s + " (was " + itemResults.get(i).itemInfo.readOrigItemX() + "," +  itemResults.get(i).itemInfo.readOrigItemY() + ")"; 
                }

                // Now add some information about the efficiency of the match
                if (itemResults.get(i).readResult() != SummaryChanges.SKIPPED)
                {
                    bestMatchInfo = itemResults.get(i).itemInfo.readBestMatchInfo();
                    if (!bestMatchInfo.saveBestDiffImageFiles())
                    {
                        // Error has been logged by the function - just return failure case
                        displayMgr.showErrMsg("Unable to save best match images ", true);
                        failNow = true;
                        return false;  
                    }
                    
                    // Print out the match information including the matching image information if relevant
                    s = s + " (match = " + printMatchPercentageInfo(bestMatchInfo);
                    if (itemResults.get(i).readResult() == SummaryChanges.MISSING)
                    {
                        s = s + " for x,y " + bestMatchInfo.matchXYString() + ",";
                        s = s + printMatchInfo(bestMatchInfo.readBestMatchItemImageName(), itemResults.get(i).itemInfo.readItemClassTSID(), itemResults.get(i).readResult());
                        s = s + ")";
                    }
                    else if (itemResults.get(i).readResult() == SummaryChanges.MISSING_DUPLICATE)
                    {
                        s = s + " for duplicate quoin x,y " + bestMatchInfo.matchXYString() + ")";
                    }
                    else
                    {
                        s = s + printMatchInfo(bestMatchInfo.readBestMatchItemImageName(), itemResults.get(i).itemInfo.readItemClassTSID(), itemResults.get(i).readResult());
                        s = s + ")";
                    }
                    
                    if (configInfo.readShowDistFromOrigXY() && ((itemResults.get(i).readResult() == SummaryChanges.COORDS_ONLY) || (itemResults.get(i).readResult() == SummaryChanges.VARIANT_AND_COORDS_CHANGED)))
                    {
                        s = s + " (" + bestMatchInfo.furthestCoOrdDistance(itemResults.get(i).itemInfo.readOrigItemX(), itemResults.get(i).itemInfo.readOrigItemY()) + "px from original x,y)";
                    }
                }// end if !skipped
            }
            // Only print the line for the summary validation file if something was actually changed
            if (validationSummaryFlag)
            {
                switch (itemResults.get(i).readResult())
                {
                    case SummaryChanges.COORDS_ONLY:
                    case SummaryChanges.VARIANT_AND_COORDS_CHANGED:
                    case SummaryChanges.VARIANT_ONLY:
                        printLine(s);
                        break;
                        
                    case SummaryChanges.UNCHANGED:
                    case SummaryChanges.MISSING:
                    case SummaryChanges.MISSING_DUPLICATE:
                    case SummaryChanges.SKIPPED:
                        // Nothing to print
                        break;
                }
            }
            else
            {
                printLine(s);
            }
            // Now print out the JSON Diff info if it exists into the full validation output file (not the summary validation file)
            if (!validationSummaryFlag && configInfo.readDebugValidationRun() && itemResults.get(i).itemInfo.readValidationInfo().length() > 0)
            {
                printLine(itemResults.get(i).itemInfo.readValidationInfo());
            }

            if (itemResults.get(i).itemInfo.readItemClassTSID().equals("quoin") && (itemResults.get(i).readResult() != SummaryChanges.SKIPPED))
            {
                switch (itemResults.get(i).itemInfo.readNewItemVariant())
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
                    // Should never be hit - so just report the error and continue
                    printToFile.printDebugLine(this, "Unexpected quoin type " + itemResults.get(i).itemInfo.readNewItemVariant(), 2);
                    break;
                }
            }
        }
    
        if (validationSummaryFlag)
        {
            s = "Number of changed items = " + nosChangedItems;
        }
        else
        {
            // Dump out the count summary of items missing/skipped/changed                
            s = "\nSkipped " + skippedCount + " items, missing " + missingCount + " items, changed " + nosChangedItems + " items";
            printLine(s);
    
            // Just dump out number of quoins
            s = "Quoin count is: XP=" + quoinXP + "   energy=" + quoinEnergy + "   mood=" + quoinMood +
                "   currants=" + quoinCurrants +"   favor=" + quoinFavor +"   time=" + quoinTime +"   mystery=" + quoinMystery +
                " Total=" + (quoinXP + quoinEnergy + quoinMood + quoinCurrants + quoinFavor + quoinTime + quoinMystery);
        }
        s = s + "\n";
        printLine(s); 
        
        if (!validationSummaryFlag && (nosChangedItems > 0) && configInfo.readWriteJSONsToPersdata() && !streetInfo.readStreetNotInPersdataQA())
        {
            // For streets already in persdata-qa remind user to rerun qasave if items have actually been changed in persdata
            s = " (NB REMEMEMBER TO REDO /QASAVE [WITHGEO] FOR THIS STREET TO SAVE THESE CHANGES)\n";
            printLine(s);
        }
        return true;
    }
    
    String printMatchPercentageInfo(MatchInfo matchInfo)
    {
        String s;
        
        if (configInfo.readDebugShowPercentMatchAsFloat())
        {
            s = matchInfo.matchPercentAsFloatString();
        }
        else
        {
            s = matchInfo.matchPercentString();
        }
        return s;
    }
    
    String printMatchInfo(String imageName, String classTSID, int result)
    {
        // Need to do comparison of the item class TSID and what the match was in order to return sensible information
        // to the user
        String info = "";
        
        if (result == SummaryChanges.MISSING || result == SummaryChanges.MISSING_DUPLICATE)
        {
            // Always want to dump out what was nearest in case it is useful information. Attempt to break down the image name into useful parts
            if (imageName.indexOf(classTSID + "_", 0) == 0)
            {
                // We have a variant that can be extracted
                info = " from " + classTSID + " (" + imageName.replace(classTSID + "_", "") + ")";
            }
            else
            {
                info = " from " + imageName;
            }
        }
        else if (configInfo.readDebugRun()) 
        {
            // Will only dump out information for my purposes as it just makes things complicated for the user and they probably don't care about this information
            // Especially when dealing with tree matches
 
            if (imageName.equals(classTSID))
            {
                // If the class TSID matches the image name, then there is nothing to return as this is an item with no variant, that matches
                // Although for my purposes, dump out the information anyhow
                info = " from " + imageName;
            }
            else if (imageName.indexOf(classTSID + "_", 0) == 0)
            {
                // matching image has a variant of some sort - always dump out the info for my purposes 
                info = " from " + classTSID + " (" + imageName.replace(classTSID + "_", "") + ")";
            }
            else
            {
                // Matching image is a different class to the JSON item - only happens when dealing with trees
                if ((imageName.indexOf("trant_", 0) == 0) || (imageName.indexOf("patch", 0) == 0))
                {
                    // No variant is present, so just return the complete image name to print out.
                    // As this could be confusing to users, only do this for my purposes
                    info = " from " + imageName;
                }
                else if (imageName.indexOf("wood_tree_", 0) == 0)
                {
                    // Wood tree present - return wood_tree and variant (if both image and original were wood trees, then would be caught further up)
                    info = " from wood_tree (" + imageName.replace("wood_tree_", "") + ")";
                }
                else
                {
                    // Should never be reached - so just return the image name
                    info = " from " + imageName;
                }
            }
        }
        return info;
    }
    
    public void closeFile()
    {
        if (!initFlag)
        {
            return;
        }
    
        //flush stream
        try
        {
            output.flush();
        }
        catch (Exception e)
        {
            e.printStackTrace();  
            println("Exception error attempting to flush " + fname);
        }
    
        //close stream
        try
        {
            output.close();
        }
        catch (Exception e)
        {
            e.printStackTrace();  
            println("Exception error attempting to close " + fname);
            return;
        }
        println("Successfully closed file " + fname);
        return;
    }
    
    public boolean readInitFlag()
    {
        return initFlag;
    }
}