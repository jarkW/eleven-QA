import java.nio.file.Path;

class StreetInfo
{
    boolean okFlag;
    boolean streetProcessingFinished;
    boolean streetInitialisationFinished;
    boolean streetWritingItemsFinished;
    boolean invalidStreet;
    boolean skipStreet;
    
    // passed to constructor - read in originally from QABot_config.json
    String streetTSID;
    
    // Read in from L* file
    JSONArray streetItems;
    String streetName;
    String hubID;
    
    // Matrix which is used to adjusts image pixels to match the street colour/saturation etc
    ColorMatrix cm;
    
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
    
    // Data read in from G* which is used elsewhere in class
    int geoHeight;
    int geoWidth;
    int geoTopEdgeY;
    int geoBottomEdgeY;
    int geoLeftSideX;
    int geoRightSideX;
    
    // Info about special quoin settings e.g. because party space or Ancestral Lands
    String quoinDefaultingInfo; 
    String quoinDefaultingWarningMsg;
    
    // Action for items on this street
    boolean changeItemXYOnly;
    
    // Saved information about whether or not this street has already been saved in persdata-qa - for logging only
    boolean streetNotInPersdataQA;
    
    // Keep a count of the number of JSON files copied to persdata
    int persdataJSONFileCount;
    
    final static int ITEM_FOUND_COLOUR = #0000FF; // blue
    final static int ITEM_MISSING_COLOUR = #FF0000; // red
       
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
        skipStreet = false;
        streetWritingItemsFinished = false;
        streetInitialisationFinished = false;
        streetNotInPersdataQA = true;
        changeItemXYOnly = false;
        persdataJSONFileCount = 0;

        streetTSID = tsid;       
        itemInfo = new ArrayList<ItemInfo>();
        streetSnaps = new ArrayList<PNGFile>();
        itemResults = new ArrayList<SummaryChanges>();
        skippedStreetSnapNames = new StringList();
        changedItemJSONs = new StringList();
        numberTimesResultsSortedSoFar = 0;
         
        geoHeight = 0;
        geoWidth = 0;
        geoTopEdgeY = 0;
        geoBottomEdgeY = 0;
        geoLeftSideX = 0;
        geoRightSideX = 0;
        
        quoinDefaultingInfo = "";
        quoinDefaultingWarningMsg = "";
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
        
        printToFile.printDebugLine(this, "Read item TSID " + itemTSID + " from street L file " + streetTSID, 2);  
        
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
        JSONObject thisItem = Utils.readJSONObjectFromJSONArray(streetItems, itemBeingProcessed, true); 
        if (!Utils.readOkFlag())
        {
            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
            return false;
        }
        itemInfo.add(new ItemInfo(thisItem)); 
        
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
        
        // move on to next item
        itemBeingProcessed++;
        if (itemBeingProcessed >= itemInfo.size())
        {
            // Reached end of item list
            streetWritingItemsFinished = true;
            
            // If the user didn't want the detailed list of files copied, just indicate here the number copied for completeness sake
            if(!configInfo.readOutputListJSONsWrittenToPersdata())
            {
                String s;
                if (configInfo.readUseVagrantFlag())
                {
                    s = "Successfully copied ";
                }
                else
                {
                   s = "Successfully uploaded ";
                }
                s = s + persdataJSONFileCount + " changed JSON files to " + configInfo.readPersdataPath();
                printToFile.printDebugLine(this, s, 2);
                printToFile.printOutputLine(s);
            }
        }
        
        return true;
    }
    
    boolean readStreetGeoInfo()
    {
        int geoTintColor = 0;
        int geoContrast = 0;
        int geoTintAmount = 0;
        int geoSaturation = 0;
        int geoBrightness = 0;
        
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
        JSONObject dynamic = Utils.readJSONObject(json, "dynamic", false);
        if (!Utils.readOkFlag() || dynamic == null)
        {
            // the dynamic level is sometimes missing ... so just set it to point at the original json object and continue on
            printToFile.printDebugLine(this, "Reading geo file - failed to read dynamic key, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 2);
            if (dynamic == null)
            {
                printToFile.printDebugLine(this, "Reading geo file - dynamic is null " + geoFileName, 2);
            }
            dynamic = json;
            if (dynamic == null)
            {
                // This should never happen as json should not be null at this point
                printToFile.printDebugLine(this, "Reading geo file - unexpected error as reset dynamic pointer is null " + geoFileName, 3);
                return false;
            }
        }
        
        // Extract the values of the top/bottom and left/right limits of the street - which equate to the min/max x,y
        // values. Turns out that some tall streets have the y value go from -height/2 to height/2 rather than -height to 0. 
        // These values will either be found in the top level, or inside the dynamic structure. So read
        // them in now.
        geoTopEdgeY = Utils.readJSONInt(dynamic, "t", true);
        if (!Utils.readOkFlag())
        {
            printToFile.printDebugLine(this, "Failed to read top (t) of street from geo JSON file, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 3);
            return false;
        }
        geoBottomEdgeY = Utils.readJSONInt(dynamic, "b", true);
        if (!Utils.readOkFlag())
        {
            printToFile.printDebugLine(this, "Failed to read bottom (b) of street from geo JSON file, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 3);
            return false;
        }
        geoLeftSideX = Utils.readJSONInt(dynamic, "l", true);
        if (!Utils.readOkFlag())
        {
            printToFile.printDebugLine(this, "Failed to read left side (l) of street from geo JSON file, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 3);
            return false;
        }
        geoRightSideX = Utils.readJSONInt(dynamic, "r", true);
        if (!Utils.readOkFlag())
        {
            printToFile.printDebugLine(this, "Failed to read right side (r) of street from geo JSON file, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 3);
            return false;
        }
        printToFile.printDebugLine(this, "Geo JSON file " + geoFileName + " gives street top (t) " + geoTopEdgeY + " bottom (b) " + geoBottomEdgeY + " left (l) " + geoLeftSideX + " right (r) " + geoRightSideX, 1);
        
        // So are either reading layers from the dynamic or higher level json objects, depending on whether dynamic had been found
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
                    printToFile.printDebugLine(this, "Failed to read width of street from geo JSON file, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 3);
                    return false;
                }
                geoHeight = Utils.readJSONInt(middleground, "h", true);
                if (!Utils.readOkFlag() || geoHeight == 0)
                {
                    printToFile.printDebugLine(this, "Failed to read height of street from geo JSON file, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 3);
                    return false;
                }
                
                // Just do a sanity check that the width/height is consistent with the values read in just before
                if (geoHeight != (geoBottomEdgeY - geoTopEdgeY))
                {
                    printToFile.printDebugLine(this, "Geo JSON inconsistency in " + geoFileName + " - height of snap (h=" + geoHeight + ") is different to difference between bottom edge (b) and top edge (t) (=" + (geoBottomEdgeY - geoTopEdgeY) + ")", 3);
                    return false;
                }
                if (geoWidth != (geoRightSideX - geoLeftSideX))
                {
                    printToFile.printDebugLine(this, "Geo JSON inconsistency in " + geoFileName + " - width of snap (h=" + geoWidth + ") is different to difference between right edge (r) and left edge (l) (=" + (geoRightSideX - geoLeftSideX) + ")", 3);
                    return false;
                }
                
                printToFile.printDebugLine(this, "Geo JSON file " + geoFileName + " gives street snap height " + geoHeight + " snap width " + geoWidth, 1);
                
                // Read in the remaining geo information even if not using a black/white comparison method because might be useful debug info later when dump out images

                // Don't always have a filtersNew on this layer - if absent, will just use the default values of 0 set up earlier
                JSONObject filtersNEW = Utils.readJSONObject(middleground, "filtersNEW", false);
                
                if (Utils.readOkFlag() && filtersNEW != null)
                {
                    printToFile.printDebugLine(this, "size of filtersNew is " + filtersNEW.size() + " in " + geoFileName, 2);
                        
                    // extract the fields inside
                    // If filtersNew is present, then will report missing values, but still carry on using defaults of 0
                                                
                    JSONObject filtersNewObject = Utils.readJSONObject(filtersNEW, "tintAmount", true);
                    if (Utils.readOkFlag() && filtersNewObject != null)
                    {                           
                        geoTintAmount = Utils.readJSONInt(filtersNewObject, "value", true);
                        if (!Utils.readOkFlag())
                        {
                            printToFile.printDebugLine(this, "Failed to read value from tintAmount in filtersNEW in geo JSON file, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 2);
                            geoTintAmount = 0;
                        }
                    }
                    else
                    {
                        printToFile.printDebugLine(this, "Failed to read tintAmount from filtersNEW in geo JSON file, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 2);
                        geoTintAmount = 0;
                    }
                        
                    filtersNewObject = Utils.readJSONObject(filtersNEW, "tintColor", true);
                    if (Utils.readOkFlag() && filtersNewObject != null)
                    {                           
                        geoTintColor = Utils.readJSONInt(filtersNewObject, "value", true);
                        if (!Utils.readOkFlag())
                        {
                            printToFile.printDebugLine(this, "Failed to read value from tintColor in filtersNEW in geo JSON file, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 2);
                            geoTintColor = 0;
                            geoTintAmount = 0;
                        }
                    }
                    else
                    {
                        printToFile.printDebugLine(this, "Failed to read tintColor from filtersNEW in geo JSON file, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 2);
                        geoTintColor = 0;
                        geoTintAmount = 0;
                    }
                    
                    filtersNewObject = Utils.readJSONObject(filtersNEW, "contrast", true);
                    if (Utils.readOkFlag() && filtersNewObject != null)
                    {                           
                        geoContrast = Utils.readJSONInt(filtersNewObject, "value", true);
                        if (!Utils.readOkFlag())
                        {
                            printToFile.printDebugLine(this, "Failed to read value from contrast in filtersNEW in geo JSON file, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 2);
                            geoContrast = 0;
                        }
                    }
                    else
                    {
                        printToFile.printDebugLine(this, "Failed to read contrast from filtersNEW in geo JSON file, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 2);
                        geoContrast = 0;
                    }                        
                     
                    filtersNewObject = Utils.readJSONObject(filtersNEW, "saturation", true);
                    if (Utils.readOkFlag() && filtersNewObject != null)
                    {                           
                        geoSaturation = Utils.readJSONInt(filtersNewObject, "value", true);
                        if (!Utils.readOkFlag())
                        {
                            printToFile.printDebugLine(this, "Failed to read value from saturation in filtersNEW in geo JSON file, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 2);
                            geoSaturation = 0;
                        }
                    }
                    else
                    {
                        printToFile.printDebugLine(this, "Failed to read saturation from filtersNEW in geo JSON file, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 2);
                        geoSaturation = 0;
                    }
                     
                    filtersNewObject = Utils.readJSONObject(filtersNEW, "brightness", true);
                    if (Utils.readOkFlag() && filtersNewObject != null)
                    {                           
                        geoBrightness = Utils.readJSONInt(filtersNewObject, "value", true);
                        if (!Utils.readOkFlag())
                        {
                            printToFile.printDebugLine(this, "Failed to read value from brightness in filtersNEW in geo JSON file, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 2);
                            geoBrightness = 0;
                        }
                    }
                    else
                    {
                        printToFile.printDebugLine(this, "Failed to read brightness from filtersNEW in geo JSON file, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 2);
                        geoBrightness = 0;
                    }
                }
                else
                {
                    // This is not an error - but report anyhow 
                    printToFile.printDebugLine(this, "Reading geo file - failed to read filtersNEW " + geoFileName, 2);
                }
            } // if middleground not null
            else
            {
                // This counts as an error as need the snap size from the file
                 printToFile.printDebugLine(this, "Reading geo file - failed to read middleground, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 3);
                 return false;
            }
         } // layers not null
         else
         {
             // Failed to read the layers structure from geo file - which means we don't have the snap size from the file - so counts as error
             printToFile.printDebugLine(this, "Reading geo file - failed to read layers, err msg ='" + Utils.readErrMsg() + "' " +  geoFileName, 3);
             return false;
         }
         printToFile.printDebugLine(this, "After reading geo file  " + geoFileName + " TintColor = " + geoTintColor + " TintAmount = " + geoTintAmount +
                                         " geoContrast = " + geoContrast + " geoSaturation = " + geoSaturation + " Brightness = " + geoBrightness, 1);  
          
         // Everything OK 
         
         // Set up the ColorMatrix which contains the matrix transformation needed to convert pixels in the item fragment so that they are coloured the same as the street
         cm = new ColorMatrix(geoTintColor, geoTintAmount, geoContrast, geoSaturation, geoBrightness);
         // Dump out the matrix
         cm.dumpMatrix();

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
            printToFile.printOutputLine("============================================================================================\n");
            printToFile.printOutputLine("SKIPPING - No valid street image files found for " + streetName + "(" + streetTSID + ")" + " in directory " + configInfo.readStreetSnapPath() + "\n");
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
                printToFile.printDebugLine(this, "Skipping street snap " + streetSnaps.get(j).readPNGImageName() + " because resolution is not " + 
                geoWidth + "x" + geoHeight + " pixels", 3);
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
            printToFile.printOutputLine("============================================================================================\n");
            printToFile.printOutputLine("SKIPPING - No valid street image files found for " + streetName + "(" + streetTSID + ") with resolution " + geoWidth + " x " + geoHeight + " pixels\n");
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
            printToFile.printOutputLine("============================================================================================\n");
            printToFile.printOutputLine("Failed to copy/download street L* JSON file so SKIPPING STREET " + streetTSID + "\n");
            displayMgr.setSkippedStreetsMsg("Skipping street: Failed to copy/download loc file " + streetTSID + ".json");
            invalidStreet = true;
            return true; // continue
        }
        
        // Read in street data - list of item TSIDs 
        // As this also reads in the street name, done here so that we can output that information if we skip the street because no G* file or in persdata-qa
        if (!readStreetData())  //<>//
        {
            // error - need to stop //<>//
            printToFile.printDebugLine(this, "Error in readStreetData", 3);
            okFlag = false;
            return false;
        } 
        
        // Work out what action to take with the items on this street
        // The user will have set up a flag indicating what to do with streets which are are in/outside persdata-qa
        // If no action is to be taken, then just skip the street without flagging it as an error
        streetNotInPersdataQA = streetNotExistInPersdataQA(streetTSID);
        
        if (streetNotInPersdataQA)
        {
            if (configInfo.readStreetInPersdataAction().readDoNothingFlag())
            {
                // Skip this street - is not an error
                // This flag is never defaulted to this value - so is only ever set by the user
                printToFile.printDebugLine(this, "SKIPPING STREET " + streetTSID + " (" + streetName + ") because skip_street flag set in persdata_streets_action in QABot_config.json", 2);
                printToFile.printOutputLine("============================================================================================\n");
                printToFile.printOutputLine("SKIPPING STREET " + streetTSID + " (" + streetName + ") because skip_street flag set in persdata_streets_action in QABot_config.json\n");
                displayMgr.setSkippedStreetsMsg("Skipping street: " + streetTSID + " (" + streetName + ") because skip_street flag set in persdata_streets_action in QABot_config.json");
                skipStreet = true;
                return true; // continue
            }
            else if (configInfo.readStreetInPersdataAction().readChangeXYOnlyFlag())
            {
                // Reset the flag to true - is false by default, implying change everything
                changeItemXYOnly = true;
            }            
        }
        else
        {
            if (configInfo.readStreetInPersdataQAAction().readDoNothingFlag())
            {
                // Skip this street - is not an error
                String s;
                // If the structure is missing, then this field may be have been defaulted by the program - so give different error message
                if (configInfo.readStreetInPersdataQAAction().readUsingDefaultedValues())
                {
                    s = " = default action for street found in persdata-qa (missing persdata_qa_streets_action in QABot_config.json)"; 
                }
                else
                {
                    s = " because skip_street flag set in persdata_qa_streets_action in QABot_config.json";
                }
                printToFile.printDebugLine(this, "SKIPPING STREET " + streetTSID + " (" + streetName + ")" + s, 2);    
                printToFile.printOutputLine("============================================================================================\n");
                printToFile.printOutputLine("SKIPPING STREET " + streetTSID + " (" + streetName + ")" + s + "\n");
                displayMgr.setSkippedStreetsMsg("Skipping street: " + streetTSID + " (" + streetName + ")"  + s);
                skipStreet = true;
                return true; // continue
            }
            else if (configInfo.readStreetInPersdataQAAction().readChangeXYOnlyFlag())
            {
                // Reset the flag to true - is false by default, implying change everything
                changeItemXYOnly = true;
            }   
        }      
        
        if (!getJSONFile(streetTSID.replaceFirst("L", "G")))
        {
            // Unable to get the G* JSON file
            printToFile.printDebugLine(this, "Failed to copy/download street G* JSON file so SKIPPING STREET " + streetTSID + "(" + streetName + ")", 3);
            printToFile.printOutputLine("============================================================================================\n");
            printToFile.printOutputLine("Failed to copy/download street G* JSON file so SKIPPING STREET " + streetTSID + "(" + streetName + ")\n");
            displayMgr.setSkippedStreetsMsg("Skipping street: Failed to copy/download geo file " + streetTSID.replaceFirst("L", "G") + ".json" + "(" + streetName + ")");
            invalidStreet = true;
            return true; // continue
        }       
 //<>// //<>//
        // If street does not contain any items then continue to next street
        if (streetItems.size() <= 0)
        {
            // This isn't treated as an error - but don't want to carry on with this street as it doesn't contain anything that can be handled
            printToFile.printDebugLine(this, "SKIPPING STREET because " + streetTSID + "(" + streetName + ") does not contain any items which can be QA'd by this tool", 3);
            printToFile.printOutputLine("============================================================================================\n");
            printToFile.printOutputLine("SKIPPING STREET because " + streetTSID + "(" + streetName + ") does not contain any items which can be QA'd by this tool\n");
            displayMgr.setSkippedStreetsMsg("SKIPPING STREET because " + streetTSID + "(" + streetName + ") does not contain any items which can be QA'd by this tool");
            skipStreet = true;
            return true; // continue
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
                // output message already given in validateStreetSnaps()
                printToFile.printDebugLine(this, "Missing/invalid street snaps so SKIPPING STREET " + streetTSID, 3);
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

        if (configInfo.readDebugValidationRun())
        {
            // For validation runs we never write to persdata, so doesn't matter if the
            // street already exists in persdata-qa - irrelevant
            printToFile.printDebugLine(this, "Skip persdata-qa test for street TSID " + streetTSID, 1);
            return true;
        }
        
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
            String s = "Skipping item " + itemInfo.get(itemBeingProcessed).readItemClassTSID();
            if (itemInfo.get(itemBeingProcessed).readOrigItemVariant().length() > 0)
            {
                s = s + " (" + itemInfo.get(itemBeingProcessed).readOrigItemVariant() + ")";
            }
            s = s + " " + itemInfo.get(itemBeingProcessed).readItemTSID();           
            printToFile.printDebugLine(this, s, 1);
                                       
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
                return;
            }
            else
            {
                // Next item is safe to procced to
                if (itemValidToContinueSearchingFor(itemBeingProcessed))
                {
                    printToFile.printDebugLine(this, "PROCESSING ITEM " + itemBeingProcessed + "(" + itemInfo.get(itemBeingProcessed).readItemTSID() + ") ON STREET SNAP " + streetSnapBeingUsed, 1);
                }
                else
                {
                   printToFile.printDebugLine(this, "Skipping item/item Found " + itemInfo.get(itemBeingProcessed).readItemClassTSID() + "(" + 
                                               itemInfo.get(itemBeingProcessed).readOrigItemVariant() + ") " + 
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
            
            // But first need to null the FragFind structure in the structure for the last item - as it contains a reference to the street snap
            // which means the call below to unload the street snap won't work - and then memory hell ensues.
            itemInfo.get(itemBeingProcessed-1).clearFragFind();
            
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
                    // Add info to the results array for subsequent printing out - as this is the first time through, the 'duplicateQuoin' flag will be false
                    itemResults.add(new SummaryChanges(itemInfo.get(i), false));
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
                // The second sorting of item results shouldn't throw up any duplicate x,y - if it happens they'll just be reported as warnings.
                // Any actual errors are reported from within printOutputSummaryData
                if (!printToFile.printOutputSummaryData(itemResults))
                {
                    failNow = true;
                    return false;
                }
                
                // Save an image of the street  - with items marked with different coloured squares to show if found/missing
                // Allows the user to quickly see what was found/missing against a street snap
                if (!saveStreetFoundSummaryAsPNG(itemResults))
                {
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
                printToFile.printDebugLine(this, "STARTING WITH FIRST ITEM (" + itemInfo.get(itemBeingProcessed).readItemTSID() + ") ON STREET SNAP " + streetSnapBeingUsed, 1);
                if (itemValidToContinueSearchingFor(itemBeingProcessed))
                {
                    if (!itemInfo.get(itemBeingProcessed).resetReadyForNewItemSearch())
                    {
                        displayMgr.showErrMsg("Unable to reset ready for new item search", true);
                        failNow = true;
                        return false;
                    }
                    printToFile.printDebugLine(this, "PROCESSING ITEM " + itemBeingProcessed + " (" + itemInfo.get(itemBeingProcessed).readItemTSID() + ") ON STREET SNAP " + streetSnapBeingUsed, 1);
                }
                
            }
            
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
                printToFile.printDebugLine(this, "PROCESSING ITEM " + itemBeingProcessed + " (" + itemInfo.get(itemBeingProcessed).readItemTSID() + ") ON STREET SNAP " + streetSnapBeingUsed, 1);
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
            // The sort method includes marking some items as missing (sets duplicateItemXY flag) if found to have the same x,y as another
            sortResultsByXY(itemResults);

            // Now go through the results in reverse order - if any indicate that an item needs to be reset to missing
            // then delete the entry from the itemResults array, redo the item JSON, save it and then recreate the new 
            // itemResults entry with this mystery quoin.
            // Doing it in reverse order means that entries can be safely deleted as process the array
            boolean checkForDuplicates = false;  
            
            for (int i = itemResults.size(); i > 0; i--)
            {
                if (itemResults.get(i-1).readDuplicateItemXY())
                {
                    // Mark the item as missing before saving the new JSON file
                    itemResults.get(i-1).readItemInfo().resetDuplicateAsMissingItem();
                    
                    // OK to add the new entry - will not interfere with deleting the 'bad' entry - indicate this this change is because we have a duplicate item problem
                    itemResults.add(new SummaryChanges(itemResults.get(i-1).readItemInfo(), true));
                       
                    // Now save the new JSON file - have to do this after add the new entry, otherwise itemResults sets things up as 'VARIANT_CHANGED' instead of 'MISSING'
                    if (!itemResults.get(i-1).readItemInfo().saveItemChanges(true))
                    {
                        return false;
                    }
                        
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
            // Item has been found - for non quoins/QQ, the search ends once a perfect match has been found
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
        // same x,y - which can happen for closely packed quoins/items such as jellisacs
        Collections.sort(itemResults);
        
        // Increase this counter - it is only the first sort which is clear of output errors to the user
        numberTimesResultsSortedSoFar++;
    }
    
    boolean saveStreetFoundSummaryAsPNG(ArrayList<SummaryChanges> itemResults)
    {
        // Loops through the item results and draws in the matching fragments on a street PNG
        // Skipped items are ignored
        MatchInfo bestItemMatchInfo;
        int i;
        int j;
        int locItem;
        int locStreet;
        int topX;
        int topY;
        int bottomX;
        int bottomY;
        
        // At this stage the street snap might have been unloaded - so just reload the first street snap
        if (!streetSnaps.get(0).loadPNGImage())
        {
            // Failed to load up street snap so return failure
            printToFile.printDebugLine(this, "Unexpected error - failed to load first street snap " + streetSnaps.get(0).readPNGImageName() + " for street " + streetName, 3);
            return false;
        }
        
        if (streetSnaps.get(0).readPNGImage() == null)
        {
            // Failed to load up street snap so return failure
            printToFile.printDebugLine(this, "Unexpected null error - failed to load first street snap " + streetSnaps.get(0).readPNGImageName() + " for street " + streetName, 3);
            return false;
        }
        
        PImage summaryStreetSnap = streetSnaps.get(0).readPNGImage().get(0, 0, geoWidth, geoHeight);
        summaryStreetSnap.loadPixels();
            
        for (int n = 0; n < itemResults.size(); n++)
        {   
            if (itemResults.get(n).readResult() > SummaryChanges.SKIPPED)
            {
                // Only draw a square for items which are found/missing
                bestItemMatchInfo = itemResults.get(n).readItemInfo().readBestMatchInfo();
                                
                PImage bestFragment = bestItemMatchInfo.readColourItemFragment();
                
                if (bestFragment == null)
                {
                    printToFile.printDebugLine(this, "Unexpected error - failed to load best match colour/tinted item fragment " + bestItemMatchInfo.readBestMatchItemImageName(), 3);
                    return false;
                }
                
                // Need to account for the offset of the item image from item x,y in JSON
                // The results array list contains the final x,y - whether original x,y (missing) or the new x,y (found)               
                topX = convertJSONXToProcessingX(itemResults.get(n).readItemX() + bestItemMatchInfo.readItemImageXOffset());
                topY = convertJSONYToProcessingY(itemResults.get(n).readItemY() + bestItemMatchInfo.readItemImageYOffset());
                
                String s = itemResults.get(n).readResultAsText() + " " + itemResults.get(n).readItemInfo().readItemClassTSID() + " " + itemResults.get(n).readItemInfo().readItemTSID() + " at " + itemResults.get(n).readItemX() + "," + itemResults.get(n).readItemY();
                s = s + " matchXOffset= " + bestItemMatchInfo.readItemImageXOffset() + " matchYOffset= " + bestItemMatchInfo.readItemImageYOffset() + " gives box top LH corner at " + topX + "," + topY;
                printToFile.printDebugLine(this, s, 1);
                
                // Now copy the pixels of the fragment into the correct place - so can see mismatches easily
                float a;
                int boxColour;
                int boxHeight;
                int boxWidth;
                int lineWidth;
                                                             
                // If this is a missing item - then draw a red box around the item to show unsure - print %match also?
                // For all other items draw a black box to show found
                if (itemResults.get(n).readResult() == SummaryChanges.MISSING || itemResults.get(n).readResult() == SummaryChanges.MISSING_DUPLICATE)
                {
                    // Centre it on the original startX/StartY and have the size of the search radius
                    boxColour = ITEM_MISSING_COLOUR;
                    
                    // Put a 9 pixel dot at the centre of the box
                    locStreet = (topX-1) + ((topY-1) * geoWidth);
                    setPixel(summaryStreetSnap, locStreet, boxColour);
                    setPixel(summaryStreetSnap, locStreet+1, boxColour);
                    setPixel(summaryStreetSnap, locStreet+2, boxColour);
                    locStreet = (topX-1) + ((topY) * geoWidth);
                    setPixel(summaryStreetSnap, locStreet, boxColour);
                    setPixel(summaryStreetSnap, locStreet+1, boxColour);
                    setPixel(summaryStreetSnap, locStreet+2, boxColour);
                    locStreet = (topX-1) + ((topY+1) * geoWidth);
                    setPixel(summaryStreetSnap, locStreet, boxColour);
                    setPixel(summaryStreetSnap, locStreet+1, boxColour);
                    setPixel(summaryStreetSnap, locStreet+2, boxColour);
                    boxHeight = configInfo.readSearchRadius() * 2;
                    boxWidth = configInfo.readSearchRadius() * 2;
                    topX = topX - configInfo.readSearchRadius();
                    topY = topY - configInfo.readSearchRadius();      
                    lineWidth = 3;
                }
                else
                {
                    boxColour = ITEM_FOUND_COLOUR;
                    boxHeight = bestFragment.height;
                    boxWidth = bestFragment.width;
                    lineWidth = 1;
                }
                bottomX = topX + boxWidth;
                bottomY = topY + boxHeight;
                
                printToFile.printDebugLine(this, "Top x,y " + topX + "," + topY + " Bottom x,y " + bottomX + "," + bottomY + " boxHeight " + boxHeight + " boxWidth " + boxWidth + " lineWidth " + lineWidth, 1);
                // Draw out the box
                drawBox(summaryStreetSnap, topX-lineWidth, topY-lineWidth, bottomX+lineWidth, bottomY+lineWidth, lineWidth, boxColour);
                
                // Now fill in the fragment - for found items - it is inside the red box. But for missing items need to be to the side of the red box
                int x;
                int y;
                if (itemResults.get(n).readResult() == SummaryChanges.MISSING || itemResults.get(n).readResult() == SummaryChanges.MISSING_DUPLICATE)
                {
                    // Ideally - going to draw a red box on top of the not-found box. But need to check this won't conflict with edge of street
                    // in which case it will need to be moved
                    boxHeight = bestFragment.height;
                    boxWidth = bestFragment.width;
                    int fragmentBoxLineWidth = 1;
                    y = topY - bestFragment.height - fragmentBoxLineWidth;
                    x = convertJSONXToProcessingX(itemResults.get(n).readItemX() + bestItemMatchInfo.readItemImageXOffset()) - bestFragment.width/2 - fragmentBoxLineWidth;
                    if (y < 0)
                    {
                        // Box won't fit on the top - so move to the bottom - this will always be OK to do safely
                        y = bottomY + lineWidth + fragmentBoxLineWidth;
                    }
                    if (x < 0)
                    {
                        // Box is too far off to LHS - move to edge of screen
                        x = fragmentBoxLineWidth;
                    }
                    else if ((x + bestFragment.width/2 + fragmentBoxLineWidth) > geoWidth)
                    {
                        // Box will be too far off the RHS when drawn - so move to edge of screen
                        x = geoWidth - bestFragment.width - (2*fragmentBoxLineWidth);
                    }
                    // Draw red box for this sample
                    drawBox(summaryStreetSnap, x-fragmentBoxLineWidth, y-fragmentBoxLineWidth, x + boxWidth +fragmentBoxLineWidth, y + boxHeight+fragmentBoxLineWidth, fragmentBoxLineWidth, boxColour);
                }
                else
                {
                    // In the found case, it matches the top corner of the box. No need to draw additional box
                    x = topX;
                    y = topY;
                }
                
                for (i = 0; i < bestFragment.height; i++) 
                {
                    for (j = 0; j < bestFragment.width; j++)
                    {
                        locItem = j + (i * bestFragment.width);
                        locStreet = (x + j) + ((y + i) * geoWidth);
                        
                        a = alpha(bestFragment.pixels[locItem]);
                
                        // Copy across the pixel to the street summary if it is not transparent
                        if (a == 255)
                        {
                            // Copy across the pixel to the street summary image
                            setPixel(summaryStreetSnap, locStreet, bestFragment.pixels[locItem]);
                        }
                    }        
                }
            }
        } 
        
         summaryStreetSnap.updatePixels();
     
         // save in work/named directory
         String fname;
         
         fname = configInfo.readOutputStreetImagesPath() + File.separatorChar + streetName + "_summary.png";

         printToFile.printDebugLine(this, "Saving summary image to " + fname, 1);
         if (!summaryStreetSnap.save(fname))
         {
             printToFile.printDebugLine(this, "Unexpected error - failed to save street summary image to " + fname, 3);
             return false;
         }
         
         // Clean up this variable as no longer needed
         summaryStreetSnap = null;
         System.gc();

         return true;   
        
    }
    
    void drawBox(PImage street, int topX, int topY, int bottomX, int bottomY, int lineWidth, int lineColour)
    {
        // Draws a box at the specified co-ordinates - of the top LH corner/bottom RH corner. 
        // Box is drawn inside the co-ordinates, so calling function must allow for line width
        // Skip parts of box that are outside the street - have negative values
        int i;
        int j;
        int loc;
               
        printToFile.printDebugLine(this, "Passing in top x,y " + topX + "," + topY + " bottom x,y " + bottomX + "," + bottomY, 1);
               
        // Draw top/bottom horizontal lines
        
        // NB Don't really need to check that the Y co-ord is sensible because if we're too far off top/bottom, then the 
        // setPixel function will ignore anything outside the range (0 - geoWidth*geoHeight).
        // However do need to check that x co-ord is sensible as that can't be detected by setPixel().

        // Draw horizontal line
        for (i = 0; i < bottomX - topX + 1; i++)
        {         
            if ((topX + i > 0) && (topX - i < geoWidth))
            {
                // OK to start on LHS of top horizontal line
                for (j = 0; j < lineWidth; j++)
                {
                    if (topY + j > 0)
                    {
                        loc = topX + i + ((topY + j) * geoWidth);
                        setPixel(street, loc, lineColour);
                        //printToFile.printDebugLine(this, "Printing top horizontal line of box at " + (topX + i) + "," + (topY + j), 1);
                    }
                }
            }
            
            if ((bottomX - i > 0) && (bottomX - i < geoWidth))
            {
                // OK to start on RHS of bottom horizontal line
                for (j = 0; j < lineWidth; j++)
                {
                    if (bottomY - j < geoHeight)
                    {
                        loc = bottomX - i + ((bottomY - j) * geoWidth);
                        setPixel(street, loc, lineColour);
                        //printToFile.printDebugLine(this, "Printing bottom horizontal line of box at " + (bottomX - i) + "," + (bottomY - j), 1);
                    }
                }
            } 
        }

        // Draw vertical lines
        for (i = 0; i < bottomY - topY + 1; i++)
        {
            if ((topY + i > 0) && (topY + i < geoHeight))
            {
                // OK to start at top of LH vertical line
                for (j = 0; j < lineWidth; j++)
                {
                    if (topX + j > 0)
                    {
                        loc = topX + j + ((topY + i) * geoWidth);
                        setPixel(street, loc, lineColour);
                        //printToFile.printDebugLine(this, "Printing LH vertical line of box at " + (topX + j) + "," + (topY + i), 1);
                    }
                }
            }
            
            if ((bottomY - i > 0) && (bottomY - i < geoHeight))
            {
                // OK to start on bottom of RH vertical line
                for (j = 0; j < lineWidth; j++)
                {
                    if (bottomX - j < geoWidth)
                    {
                        loc = bottomX - j + ((bottomY - i) * geoWidth);
                        setPixel(street, loc, lineColour);
                        //printToFile.printDebugLine(this, "Printing RH vertical line of box at " + (bottomX - j) + "," + (bottomY - i), 1);
                    }
                }
            }
        }
    }
    
    void setPixel(PImage image, int loc, int colour)
    {
        // Only attempt to copy across the pixel if it in a valid place
        // Only need to use this function when generating boxes around items as usually
        // we know we are in range
        if ((loc > 0) && (loc < image.height * image.width))
        {
            // Is valid pixel
            image.pixels[loc] = colour;
                      
            // print out the Processing x,y for this loc
            /*
            int x = loc % geoWidth;
            int y = loc / geoWidth;
            printToFile.printDebugLine(this, "Writing pixel at loc " + loc + " (Processing x,y " + x + "," + y + ")", 1);
            */
        }
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
                if (configInfo.readDebugValidationRun())
                {
                    // Should never reach this point - file should have been read from the special validation JSON directory
                    printToFile.printDebugLine(this, "Unable to find validation JSON file on vagrant - " + sourcePath, 3);
                    return false;
                }
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
            
            // Successful copying
            persdataJSONFileCount++;
            printToFile.printDebugLine(this, "Success copying " + TSID + ".json file to " + configInfo.readPersdataPath(), 3);
            // Only print out the name of the file copied if that is what the user has requested
            if(configInfo.readOutputListJSONsWrittenToPersdata())
            {
                printToFile.printOutputLine("Success copying " + TSID + ".json file to " + configInfo.readPersdataPath());
            }
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
            // Successful uploading
            persdataJSONFileCount++;
            printToFile.printDebugLine(this, "Success uploading " + TSID + ".json file to " + configInfo.readPersdataPath(), 3);
            // Only print out the name of the file copied if that is what the user has requested
            if(configInfo.readOutputListJSONsWrittenToPersdata())
            {
                printToFile.printOutputLine("Success uploading " + TSID + ".json file to " + configInfo.readPersdataPath());
            }
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
    
    public boolean readStreetNotInPersdataQA()
    {
        return streetNotInPersdataQA;
    }
    
    public boolean readChangeItemXYOnly()
    {
        return changeItemXYOnly;
    }
    
    public boolean readInvalidStreet()
    {
        return invalidStreet;
    }
    
    public boolean readSkipStreet()
    {
        return skipStreet;
    }
   
    public int readGeoHeight()
    {
        return geoHeight;
    }
    
    public int readGeoWidth()
    {
        return geoWidth;
    }
    
    // These four functions convert to/from Processing x,y which assumes 0,0 in top LH corner, all positive values
    // and street co-ords which usually have x from -width/2 to width/2 and y = -height to 0. But as some streets
    // disobey this rule (tall streets in Ilmenski Deeps) then need to base it off the top/bottom, left/right
    // values. NB When reading these in, the program aborts if there is a mismatch between the calculated
    // width/height using the edge values compared to the stated h/w values in the JSON file (should never happen)
    public int convertProcessingXToJSONX(int x)
    {
        float jX = map(x, 0, geoWidth, geoLeftSideX, geoRightSideX);
        return (round(jX));
    }
    
    public int convertProcessingYToJSONY(int y)
    {
        float jY = map(y, 0, geoHeight, geoTopEdgeY, geoBottomEdgeY);
        return (round(jY));
    }
    
    public int convertJSONXToProcessingX(int x)
    {
        float pX = map(x, geoLeftSideX, geoRightSideX, 0, geoWidth);
        return (round(pX));
    }
    
    public int convertJSONYToProcessingY(int y)
    {
        float pY = map(y, geoTopEdgeY, geoBottomEdgeY, 0, geoHeight);
        return (round(pY));
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
            JSONObject thisItem = Utils.readJSONObjectFromJSONArray(streetItems, itemBeingProcessed, true); 
            if (!Utils.readOkFlag())
            {
                printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                return "";
            }

            String itemTSID = Utils.readJSONString(thisItem, "tsid", true);
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
    
    public String readQuoinDefaultingInfo()
    {
        return quoinDefaultingInfo;
    }
    
    public void setQuoinDefaultingInfo(String info)
    {
        // Only need to save a message once, for the first non-standard quoin on the street
        if ((quoinDefaultingInfo.length() == 0) && (info.length() > 0))
        {
            quoinDefaultingInfo = info;
        }
    }
    
    public String readQuoinDefaultingWarningMsg()
    {
        return quoinDefaultingWarningMsg;
    }
    
    public void setQuoinDefaultingWarningMsg(String info)
    {
        // Concatenate any warning messages that have been logged by the quoin defaulting functions - should only happen for Rainbow Run so v. rare/unlikely
        if (info.length() > 0)
        {
            if (quoinDefaultingWarningMsg.length() > 0)
            {
                quoinDefaultingWarningMsg = quoinDefaultingWarningMsg + "\n" + info;
            }
            else
            {
                quoinDefaultingWarningMsg = info;
            }
        }
    }
    
    public ColorMatrix readCM()
    {
        return cm;
    }
}