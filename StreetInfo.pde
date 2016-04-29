import java.nio.file.Path;

class StreetInfo
{
    boolean okFlag;
    boolean streetProcessingFinished;
    boolean streetInitialisationFinished;
    boolean streetWritingItemsFinished;
    boolean invalidStreet;
    
    // passed to constructor - read in originally from config.json
    String streetTSID;
    
    // Read in from L* file
    JSONArray streetItems;
    String streetName;
    String hubID;
    
    // list of street snaps and associated images
    ArrayList<PNGFile> streetSnaps;
    StringList skippedStreetSnapNames;
    int streetSnapBeingUsed;
    
    // List of item results - so can sort e.g. on skipped items
    ArrayList<SummaryChanges> itemResults;
    int numberTimesResultsSortedSoFar;
    // Need this so don't loop infinitely if things go wrong
    public final static int MAX_SORT_COUNT = 10;
    
    
    // Data read in from each I* file
    int itemBeingProcessed;
    ArrayList<ItemInfo> itemInfo;
    int skippedItemCount;
    
    StringList changedItemJSONs;
    
    // Data read in from G* 
    int geoTintColor;
    int geoContrast;
    int geoTintAmount;
    int geoSaturation;
    int geoBrightness;
    int geoHeight;
    int geoWidth;
       
    // constructor/initialise fields
    public StreetInfo(String tsid)
    {
        okFlag = true;
        
        if (tsid.length() == 0)
        {
            printToFile.printDebugLine(this, "Null street tsid passed to StreetInfo structure - entry " + streetBeingProcessed, 3);
            okFlag = false;
            return;
        }
        
        itemBeingProcessed = 0;
        skippedItemCount = 0;
        streetSnapBeingUsed = 0;
        streetProcessingFinished = false;
        invalidStreet = false;
        streetWritingItemsFinished = false;
        streetInitialisationFinished = false;

        streetTSID = tsid;       
        itemInfo = new ArrayList<ItemInfo>();
        streetSnaps = new ArrayList<PNGFile>();
        itemResults = new ArrayList<SummaryChanges>();
        skippedStreetSnapNames = new StringList();
        changedItemJSONs = new StringList();
        numberTimesResultsSortedSoFar = 0;
         
        geoTintColor = 0;
        geoContrast = 0;
        geoTintAmount = 0;
        geoSaturation = 0;
        geoBrightness = 0;
        geoHeight = 0;
        geoWidth = 0;
    }
    
    boolean readStreetData()
    {
        // Now read in item list and street from L* file - use the version which has been downloaded/copied to OrigJSONs
        String locFileName = workingDir + File.separatorChar + "OrigJSONs" + File.separatorChar+ streetTSID + ".json";
     
        // First check L* file exists - 
        File file = new File(locFileName);
        if (!file.exists())
        {
            // Should never happen - as error would have been reported/handled earlier - so only get here if the file was copied/downloaded OK
            printToFile.printDebugLine(this, "Fail to find street JSON file " + locFileName, 3);
            return false;
        } 
                
        JSONObject json;
        try
        {
            // load L* file
            json = loadJSONObject(locFileName);
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine(this, "Fail to load street JSON file " + locFileName, 3);
            return false;
        } 
        printToFile.printDebugLine(this, "Reading location file " + locFileName, 2);
        
        // Read in street name
                
        streetName = Utils.readJSONString(json, "label", true);
        if (!Utils.readOkFlag() || streetName.length() == 0)
        {
            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
            printToFile.printDebugLine(this, "Fail to read in street name from street JSON file " + locFileName, 3);
            return false;
        }
  
        printToFile.printDebugLine(this, "Street name is " + streetName, 2);
        
        // Read in the region id
        hubID = Utils.readJSONString(json, "hubid", true);
        if (!Utils.readOkFlag() || hubID.length() == 0)
        {
            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
            printToFile.printDebugLine(this, "Fail to read in hub id from street JSON file " + locFileName, 3);
            return false;
        }
        
        printToFile.printDebugLine(this, "Region/hub id is " + hubID, 2);
    
        // Read in the list of street items
        streetItems = Utils.readJSONArray(json, "items", true);
        if (!Utils.readOkFlag())
        {
            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
            printToFile.printDebugLine(this, "Fail to read in item array in street JSON file " + locFileName, 3);
            return false;
        } 
 
         // Everything OK   
        return true;
    }
    
    boolean readStreetItemData()
    {
        String itemTSID = readCurrentItemTSIDBeingProcessed();
        if (itemTSID.length() == 0)
        {
            return false;
        }
        
        printToFile.printDebugLine(this, "Read item TSID " + itemTSID + " from street L file" + streetTSID, 2);  
        
        // First download/copy the I* file
        if (!getJSONFile(itemTSID))
        {
            // This is treated as an error - if the connection is down, no point continuing
            // whereas a missing L* file is not an error as could be due to a type in the list
            printToFile.printDebugLine(this, "ABORTING: Failed to copy/download item JSON file " + itemTSID + ".json" + " on " + streetName, 3);
            printToFile.printOutputLine("ABORTING: Failed to copy/download item JSON file " + itemTSID + ".json" + " on " + streetName);
            displayMgr.showErrMsg("Failed to copy/download item JSON file " + itemTSID + ".json" + " on " + streetName, true);
            return false;
        }
                       
        // First set up basic information for this item - i.e. item TSID
        itemInfo.add(new ItemInfo(streetItems.getJSONObject(itemBeingProcessed))); 
        
        int index = itemInfo.size() - 1;
        
        // Check error flag for this entry that has just been added
        ItemInfo itemData = itemInfo.get(index);     
        if (!itemData.readOkFlag())
        {
           printToFile.printDebugLine(this, "Error parsing item basic TSID information for item " + itemTSID, 3);
           displayMgr.showErrMsg("Error parsing item basic TSID information for item " + itemTSID, true);
           return false;
        }
        
        // Now fill in rest of information from this JSON file
        if (!itemInfo.get(index).initialiseItemInfo())
        {
            // actual error
            printToFile.printDebugLine(this, "Error initialising rest of information for " + itemTSID, 3);
            displayMgr.showErrMsg("Error initialising rest of information for " + itemTSID, true);
            return false;
        }
        
        // Check to see if this is an item we skip e.g. street vendor
        if (itemInfo.get(index).readSkipThisItem())
        {
            skippedItemCount++;
        }   
        
        // Everything OK - so set up ready for next item
        itemBeingProcessed++;
        if (itemBeingProcessed >= streetItems.size())
        {
            // Gone past end of items so now ready to start proper processing - finished loading up street and all item files on this street
            printToFile.printDebugLine(this, " Initialised street = " + streetName + " street TSID = " + streetTSID + " with item count " + str(itemInfo.size()) + " of which " + skippedItemCount + " will be skipped", 2);
            
            // Reset everything ready
            itemBeingProcessed = 0;
            // Clear the itemFinished flag for all items
            initStreetItemVars();
            
            // Reload the first street snap ready to start
            streetSnapBeingUsed = 0;
            if (!loadStreetImage(streetSnapBeingUsed))
            {
                displayMgr.showErrMsg("Unable to load street snap image for street", true);
                failNow = true;
                return false;
            }
            
            // Inform the top level that now OK to move on to street processing
            streetInitialisationFinished = true;
        }

        return true;
    }
    
    boolean uploadStreetItemData()
    {
        String itemTSID = itemInfo.get(itemBeingProcessed).readItemTSID();
        boolean uploadOK = true;
        boolean moveOK = true;
        boolean nothingChanged = false;
        
        printToFile.printDebugLine(this, "Read item TSID " + itemTSID + " from street L file" + streetTSID + ": changed JSON file = " + itemInfo.get(itemBeingProcessed).readSaveChangedJSONfile() + " skip = " + itemInfo.get(itemBeingProcessed).readSkipThisItem(), 2);  
        
        // Only upload changed items
        if (itemInfo.get(itemBeingProcessed).readSaveChangedJSONfile() && !itemInfo.get(itemBeingProcessed).readSkipThisItem())
        {
            // Useful error messages are logged by these 2 functions
            uploadOK = putJSONFile(itemTSID);
            
            if (uploadOK)
            {
                moveOK = moveJSONFile(itemTSID);
            }
        }
        else
        {
            // Item being skipped or is unchanged/missing           
            nothingChanged = true; 
        }
        
        // move on to next item
        itemBeingProcessed++;
        if (itemBeingProcessed >= itemInfo.size())
        {
            // Reached end of item list
            streetWritingItemsFinished = true;
        }
        
        // Report error to users but continue
        if (!uploadOK)
        {
            displayMgr.showErrMsg("Problems " + uploadString.toLowerCase() + " " + itemTSID + ".json to persdata. Check " + workingDir + File.separatorChar + "debug_info.txt for more information", false);
            return false;
        }
        else if (!moveOK)
        {
            displayMgr.showErrMsg("Problems moving " + itemTSID + ".json from NewJSONs to UploadedJSONs directory (actual " + uploadString.toLowerCase().replace("ing","") + " was successful). Check " + workingDir + File.separatorChar + "debug_info.txt for more information", false);
            return false;
        }
        else if (!nothingChanged)
        {
            displayMgr.showInfoMsg(uploadString + " " + itemTSID + ".json to " + configInfo.readPersdataPath());
        }
        
        return true;
    }
    
    boolean readStreetGeoInfo()
    {
        
        // Now read in information about contrast etc from the G* file if it exists - should have been downloaded to OrigJSONs dir
        String geoFileName = workingDir + File.separatorChar + "OrigJSONs" + File.separatorChar + streetTSID.replaceFirst("L", "G") + ".json";  
        
        // First check G* file exists
        File file = new File(geoFileName);
        if (!file.exists())
        {
            // Error - as already handled the case if file not downloaded OK to OrigJSONs dir
            printToFile.printDebugLine(this, "Failed to find geo JSON file " + geoFileName, 3);
            return false;
        } 
                
        JSONObject json;
        try
        {
            // load G* file
            json = loadJSONObject(geoFileName);
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine(this, "Fail to load street geo JSON file " + geoFileName, 3);
            return false;
        } 
        printToFile.printDebugLine(this, "Reading geo file " + geoFileName, 2);

        // Now chain down to get at the fields in the geo file
        geoTintColor = 0;
        geoContrast = 0;
        geoTintAmount = 0;
        geoSaturation = 0;
        geoBrightness = 0;
                
        JSONObject dynamic = Utils.readJSONObject(json, "dynamic", false);
        if (!Utils.readOkFlag() || dynamic == null)
        {
            // the dynamic level is sometimes missing ... so just set it to point at the original json object and continue on
            printToFile.printDebugLine(this, "Reading geo file - failed to read dynamic " + geoFileName, 2);
            if (dynamic == null)
            {
                printToFile.printDebugLine(this, "Reading geo file - dynamic 1 is null " + geoFileName, 2);
            }
            dynamic = json;
            if (dynamic == null)
            {
                printToFile.printDebugLine(this, "Reading geo file - dynamic 2 is null " + geoFileName, 2);
            }
        }
        JSONObject layers = Utils.readJSONObject(dynamic, "layers", true);
        
        if (Utils.readOkFlag() && layers != null)
        {
            JSONObject middleground = Utils.readJSONObject(layers, "middleground", true);
            if (Utils.readOkFlag() && middleground != null)
            {
                // Always read in the w/l values as needed for street snap validation.
                geoWidth = Utils.readJSONInt(middleground, "w", true);
                if (!Utils.readOkFlag() || geoWidth == 0)
                {
                    printToFile.printDebugLine(this, "Failed to read width of street from geo JSON file " + geoFileName, 3);
                    return false;
                }
                geoHeight = Utils.readJSONInt(middleground, "h", true);
                if (!Utils.readOkFlag() || geoHeight == 0)
                {
                    printToFile.printDebugLine(this, "Failed to read height of street from geo JSON file " + geoFileName, 3);
                    return false;
                }
                printToFile.printDebugLine(this, "Geo JSON file " + geoFileName + " gives street snap height " + geoHeight + " snap width " + geoWidth, 1);
                                // Only bother reading in the remaining geo information if not using a black/white comparison method
                if (!usingBlackWhiteComparison)
                {
                    // Don't always have a filtersNew on this layer
                    JSONObject filtersNEW = Utils.readJSONObject(middleground, "filtersNEW", false);
                
                    if (Utils.readOkFlag() && filtersNEW != null)
                    {
                        printToFile.printDebugLine(this, "size of filtersNew is " + filtersNEW.size() + " in " + geoFileName, 2);
                        // extract the fields inside
                        JSONObject filtersNewObject = Utils.readJSONObject(filtersNEW, "tintColor", true);
                        if (Utils.readOkFlag() && filtersNewObject != null)
                        {
                            geoTintColor = filtersNewObject.getInt("value", 0);
                        }
                        filtersNewObject = Utils.readJSONObject(filtersNEW, "contrast", true);
                        if (Utils.readOkFlag() && filtersNewObject != null)
                        {
                            geoContrast = filtersNewObject.getInt("value", 0);
                        }
                        filtersNewObject = Utils.readJSONObject(filtersNEW, "tintAmount", true);
                        if (Utils.readOkFlag() && filtersNewObject != null)
                        {
                            geoTintAmount = filtersNewObject.getInt("value", 0);
                        } 
                        filtersNewObject = Utils.readJSONObject(filtersNEW, "saturation", true);
                        if (Utils.readOkFlag() && filtersNewObject != null)
                        {
                            geoSaturation = filtersNewObject.getInt("value", 0);
                        } 
                        filtersNewObject = Utils.readJSONObject(filtersNEW, "brightness", true);
                        if (Utils.readOkFlag() && filtersNewObject != null)
                        {
                            geoBrightness = filtersNewObject.getInt("value", 0);
                        } 
                    }
                    else
                    {
                        printToFile.printDebugLine(this, "Reading geo file - failed to read filtersNEW " + geoFileName, 2);
                    }
                }// end if !using B&W comparison 
            } // if middleground not null
            else
            {
                // This counts as an error as need the snap size from the file
                 printToFile.printDebugLine(this, "Reading geo file - failed to read middleground " + geoFileName, 3);
                 return false;
            }
         } // layers not null
         else
         {
             printToFile.printDebugLine(this, "Reading geo file - failed to read layers " + geoFileName, 2);
         }
         printToFile.printDebugLine(this, "After reading geo file  " + geoFileName + " TintColor = " + geoTintColor + " TintAmount = " + geoTintAmount +
                                         " geoContrast = " + geoContrast + " geoSaturation = " + geoSaturation + " Brightness = " + geoBrightness, 1);  
          
         // Everything OK   
        return true;
    }
    
    boolean validateStreetSnaps()
    {
        // Using the street name, loads up all the street snaps from the QA snap directory
        // Are only interested in street snaps with the correct h/w which matches the values read from the json geo file
        
        // NB smaller images are removed from the list of snaps automatically
        // Will unload the street snaps immediately - as only interested in the list of valid street snaps for now
        // Work out how many street snaps exist
        String [] snapFilenames = Utils.loadFilenames(configInfo.readStreetSnapPath(), streetName, ".png");

        if (snapFilenames == null || snapFilenames.length == 0)
        {
            printToFile.printDebugLine(this, "SKIPPING STREET - No valid street image files found in " + configInfo.readStreetSnapPath() + " for street " + streetName + " in directory " + configInfo.readStreetSnapPath(), 3);
            printToFile.printOutputLine("\nSKIPPING - No valid street image files found for " + streetName + "(" + streetTSID + ")" + " in directory " + configInfo.readStreetSnapPath() + "\n");
            displayMgr.setSkippedStreetsMsg("Skipping street " + streetName + ": No valid street snaps found in directory " + configInfo.readStreetSnapPath());
            invalidStreet = true;
            return false;
        }
        int i;
        StringList archiveSnapFilenames = new StringList();
 
        for (i = 0; i < snapFilenames.length; i++)
        {
            // Go through each name - only keep valid names for this street.
            // Stripping out files which start with the same name, but which are other streets
            // e.g. Tallish Crest/ Tallish Crest Subway Station. Otherwise the size check later 
            // will fail as these streets are different sizes.

            // First deal with specific cases of towers on streets
            // Aranna: Sabudana Drama - Sabudana Drama Towers - Sabudana Drama Towers Basement (unique) - Sabudana Drama Towers Floor 1-4 (unique)
            // Besara: Egret Taun - Egret Taun Towers - Egret Taun Towers Basement (unique) - Egret Taun Towers Floor 1-3 (unique)
            // Bortola: Hauki Seeks - Hauki Seeks Manor - Hauki Seeks Manor Basement (unique) - Hauki Seeks Manor Floor 1-3 (unique)
            // Groddle Meadow: Gregarious Towers - Gregarious Towers Basement (unique) - Gregarious Towers Floor 1-3 (unique)
            // Muufo: Hakusan Heaps - Hakusan Heaps Towers - Hakusan Heaps Towers Basement (unique) - Hakusan Heaps Towers Floor 1-2 (unique)
            if ((streetName.equals("Sabudana Drama")) || (streetName.equals("Egret Taun")) ||
                (streetName.equals("Hauki Seeks")) || (streetName.equals("Hakusan Heaps")))
            {
                // Need to strip out any of the Tower/Manor streets
                if ((snapFilenames[i].indexOf("Towers") == -1) && (snapFilenames[i].indexOf("Manor") == -1))
                {
                    // Is the actual street we want, so copy
                    archiveSnapFilenames.append(snapFilenames[i]);
                }
            }
            if ((streetName.equals("Sabudana Drama Towers")) || (streetName.equals("Egret Taun Towers")) ||
                (streetName.equals("Hauki Seeks Manor")) || (streetName.equals("Hakusan Heaps Towers")) ||
                (streetName.equals("Gregarious Towers")))
            {
                // Need to strip out the Basement/Floors streets
                if ((snapFilenames[i].indexOf("asement") == -1) && (snapFilenames[i].indexOf("loor") == -1))
                {
                    // Is the actual street we want, so copy
                    archiveSnapFilenames.append(snapFilenames[i]);
                } 
            }       
            else if (streetName.indexOf("Subway") == -1)
            { 
                // Street is not a subway - so remove any subway snaps
                if (snapFilenames[i].indexOf("Subway") == -1)
                {
                    // Snap is not the subway station, so keep
                    archiveSnapFilenames.append(snapFilenames[i]);
                }
                
            }
            else
            {
                // Valid subway street snap so keep
                archiveSnapFilenames.append(snapFilenames[i]);

            }
        }
        
        if (archiveSnapFilenames.size() == 0)
        {
            printToFile.printDebugLine(this, "No files found in rebuilt snap array = BUG for street " + streetName, 3);
            return false;
        } 
        
        // Now load up each of the snaps
        int j = 0;
        for (i = 0; i < archiveSnapFilenames.size(); i++) 
        {
            // This currently never returns an error
            streetSnaps.add(new PNGFile(archiveSnapFilenames.get(i), true));
            
            // load up the image
            if (!streetSnaps.get(j).setupPNGImage())
            {
                printToFile.printDebugLine(this, "Failed to load up image " + archiveSnapFilenames.get(i), 3);
                return false;
            }
            
            if (streetSnaps.get(j).readPNGImageWidth() != geoWidth || streetSnaps.get(j).readPNGImageHeight() != geoHeight)
            {
                printToFile.printDebugLine(this, "Skipping street snap " + streetSnaps.get(j).readPNGImageName() + " because resolution is smaller than " + 
                geoWidth + "x" + geoHeight + "pixels", 3);
                // save this name so can report to user at end
                skippedStreetSnapNames.append(streetSnaps.get(j).readPNGImageName());
                streetSnaps.remove(j);
            }
            else 
            {
                // valid snap - so keep and unload
                streetSnaps.get(j).unloadPNGImage();
                j++;
            }
        }  
        
        // If not found any of the right size - then need to return error
        if (streetSnaps.size() == 0)
        {
            printToFile.printDebugLine(this, "SKIPPING STREET - No valid street image files found in " + configInfo.readStreetSnapPath() + " for street " + streetName + " with resolution " + geoWidth + " x " + geoHeight + " pixels", 3);
            printToFile.printOutputLine("\nSKIPPING - No valid street image files found for " + streetName + "(" + streetTSID + ") with resolution " + geoWidth + " x " + geoHeight + " pixels\n");
            displayMgr.setSkippedStreetsMsg("Skipping street " + streetName + ": No valid street snaps found with resolution " + geoWidth + " x " + geoHeight + " pixels");
            invalidStreet = true;
            return false;
        }
        
        printToFile.printDebugLine(this, "Number of valid street snaps is " + streetSnaps.size(), 1);
        // Everything OK
        return true;
    }
    
    public boolean initialiseStreetData()
    {
        // Need to retrieve the G*/L* files from vagrant/server and copy to OrigJSONs directory
        if (!getJSONFile(streetTSID))
        {
            // Unable to get the L* JSON file
            // This isn't treated as an error - could have been a typo in the TSID list
            printToFile.printDebugLine(this, "Failed to copy/download street L* JSON file so SKIPPING STREET " + streetTSID, 3);
            printToFile.printOutputLine("Failed to copy/download street L* JSON file so SKIPPING STREET " + streetTSID);
            displayMgr.setSkippedStreetsMsg("Skipping street: Failed to copy/download loc file " + streetTSID + ".json");
            invalidStreet = true;
            return true; // continue
        }
        
        // Confirm that this street TSID is not already something that has been QA'd already - i.e. is in persdata-qa.
        // Otherwise we would risk overwriting quoins with mystery types if not present on the snaps. 
        // For this kind of street should only allow change_xy_only option
        if (!streetNotExistInPersdataQA(streetTSID) && !configInfo.readChangeXYOnly())
        {
            // This isn't treated as an error - but don't want to carry on with this street
            printToFile.printDebugLine(this, "SKIPPING STREET because " + streetTSID + " already exists in persdata-qa; use change_xy_only option to change item x,y only", 3);
            printToFile.printOutputLine("SKIPPING STREET because " + streetTSID + " already exists in persdata-qa; use change_xy_only option to change item x,y only");
            displayMgr.setSkippedStreetsMsg("Skipping street: " + streetTSID  + " already exists in persdata-qa; use change_xy_only option to change item x,y only");
            invalidStreet = true;
            return true; // continue
        }        
        
        if (!getJSONFile(streetTSID.replaceFirst("L", "G")))
        {
            // Unable to get the G* JSON file
            printToFile.printDebugLine(this, "Failed to copy/download street G* JSON file so SKIPPING STREET " + streetTSID, 3);
            printToFile.printOutputLine("Failed to copy/download street G* JSON file so SKIPPING STREET " + streetTSID);
            displayMgr.setSkippedStreetsMsg("Skipping street: Failed to copy/download geo file " + streetTSID.replaceFirst("L", "G") + ".json");
            invalidStreet = true;
            return true; // continue
        }       

        // Read in street data - list of item TSIDs 
        if (!readStreetData()) //<>//
        {
            // error - need to stop
            printToFile.printDebugLine(this, "Error in readStreetData", 3);
            okFlag = false;
            return false;
        }

        // Display message giving street name across top of screen
        displayMgr.setStreetName(streetName, streetTSID, streetBeingProcessed + 1, configInfo.readTotalJSONStreetCount());
        displayMgr.showStreetName();
        displayMgr.showStreetProcessingMsg();
        
        // Read in the G* file and load up the contrast settings etc (currently not used as searching on black/white)
        if (!readStreetGeoInfo())
        {
            // error - need to stop
            printToFile.printDebugLine(this, "Error in readStreetGeoInfo", 3);
            okFlag = false;
            return false;
        }
        
        if (!validateStreetSnaps())
        {
            if (invalidStreet)
            {
                // i.e. need to skip this street as missing street snaps for street
                printToFile.printDebugLine(this, "Missing/invalid street snaps so SKIPPING STREET " + streetTSID, 3);
                printToFile.printOutputLine("Missing/invalid street snaps so SKIPPING STREET " + streetTSID);
                return true; // continue
            }
            else
            {
                // error - need to stop
                printToFile.printDebugLine(this, "Error loading up street snaps for " + streetName, 3);
                okFlag = false;
                return false;
            }
        }
        
        // reload the first street snap before start processing item data - FragmentFind creation for each item
        // includes a pointer to the current street snap.
        if (!loadStreetImage(0))
        {
            displayMgr.showErrMsg("Fail to load up first street snap for street " + streetInfo.readStreetName(), true);
            okFlag = false;
            return false;
        }
        
        // Now get ready to start uploading the first item
        itemBeingProcessed = 0;
       
        return true;
    }
    
    boolean streetNotExistInPersdataQA(String streetTSID)
    {

        if (configInfo.readUseVagrantFlag())
        {
            File myDir = new File(configInfo.readPersdataQAPath() + File.separatorChar + streetTSID);
            if (!myDir.exists())
            {
                printToFile.printDebugLine(this, "Street TSID " + streetTSID + " does not exist in persdata-qa", 1);
                return true;
            }
            else
            {
                printToFile.printDebugLine(this, "Street TSID " + streetTSID + " already exists in persdata-qa", 1);
                return false;
            }
        }
        else
        {
            if (!QAsftp.executeCommand("ls", configInfo.readPersdataQAPath() + "/" + streetTSID, "silent"))
            {
                printToFile.printDebugLine(this, "Street TSID " + streetTSID + " does not exist in persdata-qa", 1);
                return true;
            }
            else
            {
                printToFile.printDebugLine(this, "Street TSID " + streetTSID + " already exists in persdata-qa", 1);
                return false;
            }
        }
    }
    
    
    public void processItem()
    {

        // Skip items that we're not interested in, or items which have been already found (and which are not quoins/QQ)
        if (!itemValidToContinueSearchingFor(itemBeingProcessed))
        {
            // Item needs to be skipped/or has already been found
            // Move onto next one
            printToFile.printDebugLine(this, "Skipping item " + itemInfo.get(itemBeingProcessed).readItemClassTSID() + "(" + 
                                       itemInfo.get(itemBeingProcessed).readOrigItemExtraInfo() + ") " + itemInfo.get(itemBeingProcessed).readItemTSID(), 1);
                                       
            // As we just want to pass control back up, don't care about the succes/failure - top level will handle that
            if (moveToNextItem())
            {
            }
            return;
        }
       
        //printToFile.printDebugLine(this, "Enter processItem memory ", 1);
        //memory.printMemoryUsage();
        
        // Does the main work - passes control down to the item structure
        //ItemInfo itemData = itemInfo.get(itemBeingProcessed);      
        
        // Display information
        //displayMgr.setStreetName(streetName, streetTSID, streetBeingProcessed + 1, configInfo.readTotalJSONStreetCount());
        displayMgr.setItemProgress(itemInfo.get(itemBeingProcessed).itemClassTSID, itemInfo.get(itemBeingProcessed).itemTSID, itemBeingProcessed+1, itemInfo.size());
        
        // Search the snap for this image/item
        if (!itemInfo.get(itemBeingProcessed).searchSnapForImage())
        {
             displayMgr.showErrMsg("Error searching the snap for this item", true);
             failNow = true;
             return;
        }
        
        if (itemInfo.get(itemBeingProcessed).readItemFinished())
        {            
            // Move onto next one
            if (!moveToNextItem())
            {
                // Either error condition or at end of street/items - so need to return to top level to start over with new snap/street
                //failNow = true;
                return;
            }
            else
            {
                // Next item is safe to procced to
                       
                // Set up fragFind in item ready to start the next item/streetsnap search combo
                // i.e. loads up pointers to correct street snap and item images
                // Only do this for items we still need to search for
                if (itemValidToContinueSearchingFor(itemBeingProcessed))
                {
                    if (!itemInfo.get(itemBeingProcessed).resetReadyForNewItemSearch())
                    {
                        displayMgr.showErrMsg("Unexpected error getting ready for new item search", true);
                        failNow = true;
                        return;
                    }
                    printToFile.printDebugLine(this, "PROCESSING ITEM " + itemBeingProcessed + " ON STREET SNAP " + streetSnapBeingUsed, 1);
                }
                else
                {
                   printToFile.printDebugLine(this, "Skipping item/item Found " + itemInfo.get(itemBeingProcessed).readItemClassTSID() + "(" + 
                                               itemInfo.get(itemBeingProcessed).readOrigItemExtraInfo() + ") " + 
                                               itemInfo.get(itemBeingProcessed).readItemTSID(), 1); 
                }
            }
            
        }
        //printToFile.printDebugLine(this, "Exit 2 processItem memory ", 1);
        //memory.printMemoryUsage();

    }
    
    boolean moveToNextItem()
    {
        // Handles all the checking to see if past end of of item count, and whether more snaps to process
        // Returns true - if OK to handle the next item on the street
        // Returns false for error conditions, or if moving on to next street/street snap - calling function needs to check failNow flag
        itemBeingProcessed++;
        if (itemBeingProcessed >= itemInfo.size())
        {
            // Finished all items on the street
            // So move onto the next street snap after unloading the current one
            streetSnaps.get(streetSnapBeingUsed).unloadPNGImage();
            
            // reset itemBeingProcessed back to 0
            itemBeingProcessed = 0;
              
            streetSnapBeingUsed++;
            if (streetSnapBeingUsed >= streetSnaps.size() || ifAllItemsFound())
            {
                // Reached end of street snaps so mark street as finished OR all the valid items have been found
                // First need to write all the item changes to file
                for (int i = 0; i < itemInfo.size(); i++)
                {
                    
                    // Now save the item changes
                    if (!itemInfo.get(i).saveItemChanges(false))
                    {
                        displayMgr.showErrMsg("Unexpected error saving item changes to JSON file", true);
                        failNow = true;
                        return false;
                    }
                    // Add info to the results array for subsequent printing out
                    itemResults.add(new SummaryChanges(itemInfo.get(i)));
                }
                // Write output header info for this street so that any warnings produced when cleaning up duplicate quoin locations
                // are recorded below the street title
                printToFile.printSummaryHeader();
                                
                // Need to sort this results array until there are no duplicate x,y entries
                if (!resolveAllItemsAtSameCoOrds())
                {
                   displayMgr.showErrMsg("Unexpected error cleaning up results array to resolve items with duplicate x,y values", true);
                   failNow = true;
                   return false;
                }
 
                // Now print out the summary array
                // The second sorting of item results shouldn't throw up any duplicate x,y - if it happens they'll just be reported as warnings
                if (! printToFile.printSummaryData(itemResults))
                {
                    displayMgr.showErrMsg("Unexpected items in results array with duplicate x,y values - should not happen", true);
                    failNow = true;
                    return false;
                }

                // Mark street as done
                streetProcessingFinished = true;
                
                //printToFile.printDebugLine(this, "Exit 1 processItem memory ", 1);
                //memory.printMemoryUsage();
                return false;
            }
            else
            {
                // Start with the first item again on the new street snap
                if (!loadStreetImage(streetSnapBeingUsed))
                {
                    displayMgr.showErrMsg("Unable to load street snap image for street", true);
                    failNow = true;
                    return false;
                }
                itemBeingProcessed = 0;
                printToFile.printDebugLine(this, "STARTING WITH FIRST ITEM ON STREET SNAP " + streetSnapBeingUsed, 1);
                
                if (itemValidToContinueSearchingFor(itemBeingProcessed))
                {
                    if (!itemInfo.get(itemBeingProcessed).resetReadyForNewItemSearch())
                    {
                        displayMgr.showErrMsg("Unable to reset ready for new item search", true);
                        failNow = true;
                        return false;
                    }
                    printToFile.printDebugLine(this, "PROCESSING ITEM " + itemBeingProcessed + " ON STREET SNAP " + streetSnapBeingUsed, 1);
                }
                
            }
            //return false;
            
        } // if past end of item list
        else
        {
            // Valid next item found - reset ready for the search to happen
            if (itemValidToContinueSearchingFor(itemBeingProcessed))
            {
                if (!itemInfo.get(itemBeingProcessed).resetReadyForNewItemSearch())
                {
                    displayMgr.showErrMsg("Unable to reset ready for new item search", true);
                    failNow = true;
                    return false;
                }
                printToFile.printDebugLine(this, "PROCESSING ITEM " + itemBeingProcessed + " ON STREET SNAP " + streetSnapBeingUsed, 1);
            }
        }
        return true;
    }
    
    boolean resolveAllItemsAtSameCoOrds()
    {
        // Loops through until there are no entries left which have duplicate x,y - or until exceed boundary condition 
        boolean noDuplicatesFound = false;
        for (numberTimesResultsSortedSoFar = 1; numberTimesResultsSortedSoFar <= MAX_SORT_COUNT && !noDuplicatesFound; numberTimesResultsSortedSoFar++)
        {
            // The sort method includes marking some quoins as missing (sets misPlacedQuoin flag) if found to have the same x,y as another
            sortResultsByXY(itemResults);

            // Now go through the results in reverse order - if any indicate that a quoin needs to be reset to missing
            // then delete the entry from the itemResults array, redo the item JSON, save it and then recreate the new 
            // itemResults entry with this mystery quoin.
            // Doing it in reverse order means that entries can be safely deleted as process the array
            boolean checkForDuplicates = false;
            for (int i = itemResults.size(); i > 0; i--)
            {
                if (itemResults.get(i-1).readMisplacedQuoin())
                {
                    // Mark the quoin as missing before saving the new JSON file
                    if (!itemResults.get(i-1).readItemInfo().resetAsMissingQuoin())
                    {
                        // Should never happen
                        return false;
                    }
                       
                    // Now save the new mystery quoin JSON file
                    if (!itemResults.get(i-1).readItemInfo().saveItemChanges(true))
                    {
                        return false;
                    }
                     
                    // OK to add the new entry - will not interfere with deleting the 'bad' entry
                    itemResults.add(new SummaryChanges(itemResults.get(i-1).readItemInfo()));
                        
                    // Now delete this bad array entry 
                    itemResults.remove(i-1);
                    
                    // Show that a duplicate was found this time around
                    checkForDuplicates = true;
                }
            }
            if (!checkForDuplicates)
            {
                // No duplicates found this time through
                noDuplicatesFound = true;
            }
        }
        
        return true;
    }
    
    boolean ifAllItemsFound()
    {
        boolean allFound = true;
        for (int i = 0; i < itemInfo.size(); i++)
        { 
           if (itemValidToContinueSearchingFor(i))
           {
               // Item is valid for searching BUT has not been found
               allFound = false;
           }
        }
        return allFound;
    }
    
    boolean itemValidToContinueSearchingFor(int n)
    {
        //println("itemBeingProcessed is ", n);
        if (itemInfo.get(n).readSkipThisItem())
        {
            // Item is not one we ever search for e.g. street spirit
            return false;
        }
        else if (itemInfo.get(n).readItemFound())
        {
            // Item has been found - for non quoins/QQ, the search ends once it has been found
            if (!itemInfo.get(n).readItemClassTSID().equals("quoin") &&
                    !itemInfo.get(n).readItemClassTSID().equals("marker_qurazy"))
            {
                return false;
            }
        }
        return true;
    }
    
    void sortResultsByXY (ArrayList<SummaryChanges> itemResults)
    {               
        // Sort array by x co-ord so listing items from L to R
        // This will also flag up a warning if any items end up with the 
        // same x,y - which can happen for closely packed quoins
        Collections.sort(itemResults);
        
        // Increase this counter - it is only the first sort which is clear of output errors to the user
        numberTimesResultsSortedSoFar++;
    }
    
    boolean getJSONFile(String TSID)
    {
        String JSONFileName = TSID + ".json";
        String sourcePath; 
        String destPath = workingDir + File.separatorChar + "OrigJSONs" + File.separatorChar + JSONFileName;
        
        if (configInfo.readUseVagrantFlag())
        {
           sourcePath = configInfo.readPersdataPath() + File.separatorChar + JSONFileName;
            // First check file exists in persdata
            File file = new File(sourcePath);
            if (!file.exists())
            {
                // Retrieve from fixtures
                if (TSID.startsWith("L") || TSID.startsWith("G"))
                {
                    sourcePath = configInfo.readFixturesPath() + File.separatorChar + "locations-json" + File.separatorChar + JSONFileName;
                }
                else
                {
                    sourcePath = configInfo.readFixturesPath() + File.separatorChar + "world-items" + File.separatorChar + JSONFileName;
                }
                file = new File(sourcePath);
                if (!file.exists())
                {
                    // Can't get file so give up - error will be reported when do actual processing
                    printToFile.printDebugLine(this, "Unable to find file on vagrant - " + sourcePath, 3);
                    return false;
                }

            }                          
            // copy file to OrigJSONs directory
            if (!copyFile(sourcePath, destPath))
            {
                printToFile.printDebugLine(this, "Unable to copy JSON file - " + sourcePath + " to " + destPath, 3);
                return false;
            }
            printToFile.printDebugLine(this, "Copied JSON file - " + sourcePath + " to " + destPath, 1);
        }
        else
        {
            // Use sftp to download the file from server
            sourcePath = configInfo.readPersdataPath() + "/" + JSONFileName;
            // See if file exists in persdata     
            if (!QAsftp.executeCommand("get", sourcePath, destPath))
            {
                // See if file exists in fixtures
                if (TSID.startsWith("L") || TSID.startsWith("G"))
                {
                    sourcePath = configInfo.readFixturesPath() + "/locations-json/" + JSONFileName;
                }
                else
                {
                    sourcePath = configInfo.readFixturesPath() + "/world-items/" + JSONFileName;
                }
                
                if (!QAsftp.executeCommand("get", sourcePath, destPath))
                {
                    // Can't get JSON file from fixtures either - so give up - error will be reported when do actual processing
                    printToFile.printDebugLine(this, "Unable to find JSON file on server - " + sourcePath, 3);
                    return false;
                }
            } 
            
            printToFile.printDebugLine(this, "Downloaded JSON file - " + sourcePath + " to " + destPath, 1);
        }
        return true;
    }
    
    
    boolean putJSONFile(String TSID)
    {       
        String JSONFileName = TSID + ".json";
        String sourcePath = workingDir + File.separatorChar + "NewJSONs" + File.separatorChar + JSONFileName; 
        
        File sFile = new File(sourcePath);
        if (!sFile.exists())
        {
            // If this does not exist in NewJSONs then there is nothing to upload - return success
            // But should this be an error - as only called if apparently something to upload
            printToFile.printDebugLine(this, "Unable to find saved JSON file - " + sourcePath, 3);
            return false;
        }
        
        if (configInfo.readUseVagrantFlag())
        {
            // Copy file to persdata
            if (!copyFile(sourcePath, configInfo.readPersdataPath() + File.separatorChar + JSONFileName))
            {
                printToFile.printDebugLine(this, "Unable to copy JSON file - " + sourcePath + " to " + configInfo.readPersdataPath() + File.separatorChar + JSONFileName, 3);
                printToFile.printOutputLine("FAILED TO COPY " + TSID + ".json file to " + configInfo.readPersdataPath());
                return false;
            }
            printToFile.printDebugLine(this, "Success copying " + TSID + ".json file to " + configInfo.readPersdataPath(), 3);
            printToFile.printOutputLine("Success copying " + TSID + ".json file to " + configInfo.readPersdataPath());
        }
        else
        {
            // Use sftp to download the file from server  
            if (!QAsftp.executeCommand("put", sourcePath, configInfo.readPersdataPath() + "/" + JSONFileName))
            {
                 printToFile.printDebugLine(this, "Unable to upload JSON file from " + sourcePath + " to persdata on server - " + configInfo.readPersdataPath() + "/" + JSONFileName, 3);
                 printToFile.printOutputLine("FAILED TO UPLOAD " + TSID + ".json file to " + configInfo.readPersdataPath());
                 return false;   
            } 
            
            printToFile.printDebugLine(this, "Success uploading " + TSID + ".json file to " + configInfo.readPersdataPath(), 3);
            printToFile.printOutputLine("Success uploading " + TSID + ".json file to " + configInfo.readPersdataPath());
        }
        
        // Only reach here if file uploaded OK 
        return true;
    } 
    
    boolean moveJSONFile(String TSID)
    {       
        String JSONFileName = TSID + ".json";
        String sourcePath = workingDir + File.separatorChar + "NewJSONs" + File.separatorChar + JSONFileName; 
        String destPath = workingDir + File.separatorChar + "UploadedJSONs" + File.separatorChar + JSONFileName;

        // move file from newJSONs to uploadedJSONs directory
        File sFile = new File(sourcePath);
        if (!sFile.exists())
        {
            printToFile.printDebugLine(this, "Unable to move JSON file from " + sourcePath + " to " + destPath + " - " + sourcePath + " does not exist", 3);
            printToFile.printOutputLine("Unable to move JSON file from " + sourcePath + " to " + destPath + " - " + sourcePath + " does not exist");
            return false;
        }
   
        File dFile = new File(destPath);
        if (!sFile.renameTo(dFile))
        {
            printToFile.printDebugLine(this, "Unable to move JSON file from " + sourcePath + " to " + destPath, 3);
            printToFile.printOutputLine("Warning - unable to move JSON file from " + sourcePath + " to " + destPath);
            return false;
        }

        printToFile.printDebugLine(this, "Moved JSON file " + JSONFileName + " from " + workingDir + File.separatorChar + "NewJSONs" + " to " + workingDir + File.separatorChar + "UploadedJSONs", 1);
        
        return true;
    } 
    
    // Simple functions to read/set variables
    public boolean readStreetProcessingFinished()
    {
        return streetProcessingFinished;
    }
    
    public boolean readOkFlag()
    {
        return okFlag;
    } 
    
    public String readStreetName()
    {
        return streetName;
    }
    
    public String readHubID()
    {
        return hubID;
    }
    
    public String readStreetTSID()
    {
        return streetTSID;
    }
    
    public int readSkippedStreetSnapCount()
    {
        return skippedStreetSnapNames.size();
    }
    
    public String readSkippedStreetSnapName(int i)
    {
        if (i < skippedStreetSnapNames.size())
        {
            return skippedStreetSnapNames.get(i);
        }
        else
        {
            return null;
        }
        
    }
    
    public int readValidStreetSnapCount()
    {
        return streetSnaps.size();
    }
    
    public PNGFile readCurrentStreetSnap()
    {
        if (streetSnaps.get(streetSnapBeingUsed).readPNGImage() == null)
        {
            printToFile.printDebugLine(this, "readCurrentStreetSnap - Null street image pointer for current street snaps " + streetSnapBeingUsed, 3);
        }
        return streetSnaps.get(streetSnapBeingUsed);
    }
    
    public String readCurrentStreetSnapString()
    {
        String s = Integer.toString(streetSnapBeingUsed + 1) + " of " + streetSnaps.size();
        return s;
    }
          
    public boolean loadStreetImage(int n)
    {
        if (!streetSnaps.get(n).loadPNGImage())
        {
            return false;
        }
        if (streetSnaps.get(n).readPNGImage() == null)
        {
            printToFile.printDebugLine(this, "Null street image pointer returned from loadPNGImage for current street snaps " + streetSnapBeingUsed, 3);
            return false;
        }
        return true;
    }
    
    void initStreetItemVars()
    {
        for  (int i = 0; i < itemInfo.size(); i++)
        {
            itemInfo.get(i).initItemVars();
        }
    }
    
    public boolean readInvalidStreet()
    {
        return invalidStreet;
    }
    
    public int readGeoTintColor()
    {
            return geoTintColor;
    }

    public int readGeoContrast()
    {
        return geoContrast;
    }
    
    public int readGeoTintAmount()
    {
        return geoTintAmount;
    }
     
    public int readGeoSaturation()
    {
        return geoSaturation;
    }
    
    public int readGeoBrightness()
    {
        return geoBrightness;
    }
    
    public int readGeoHeight()
    {
        return geoHeight;
    }
    
    public int readGeoWidth()
    {
        return geoWidth;
    }
    
    public int readNumberTimesResultsSortedSoFar()
    {
        return numberTimesResultsSortedSoFar;
    }
    
    public boolean readStreetWritingItemsFinished()
    {
        return streetWritingItemsFinished; 
    }
    
    public boolean readStreetInitialisationFinished()
    {
        return streetInitialisationFinished;
    }
    
    public String readCurrentItemTSIDBeingProcessed()
    {
        if (itemBeingProcessed >= streetItems.size())
        {
            return "";
        }
        else
        {
            String itemTSID = Utils.readJSONString(streetItems.getJSONObject(itemBeingProcessed), "tsid", true);
            if (!Utils.readOkFlag())
            {
                // Failed
                printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                printToFile.printDebugLine(this, "Failed to read Item TSID string from array in street JSON  ", 3);
                return "";
            }
            else
            {
                return (itemTSID);
            }
        }
    }
        
}