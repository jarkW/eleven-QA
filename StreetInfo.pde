class StreetInfo
{
    boolean okFlag;
    boolean streetFinished;
    boolean invalidStreet;
    
    // passed to constructor - read in originally from config.json
    String streetTSID;
    
    // Read in from L* file
    JSONArray streetItems;
    String streetName;
    String hubID;
    
    // list of street snaps and associated images
    ArrayList<PNGFile> streetSnaps;
    int streetSnapBeingUsed;
    
    // Data read in from each I* file
    int itemBeingProcessed;
    ArrayList<ItemInfo> itemInfo;
    
    // constructor/initialise fields
    public StreetInfo(String tsid)
    {
        okFlag = true;
        
        itemBeingProcessed = 0;
        streetSnapBeingUsed = 0;
        streetFinished = false;
        invalidStreet = false;

        streetTSID = tsid;       
        itemInfo = new ArrayList<ItemInfo>();
        streetSnaps = new ArrayList<PNGFile>();
    }
    
    boolean readStreetData()
    {
        // Now read in item list and street from L* file
        String locFileName = configInfo.readPersdataPath() + "/" + streetTSID + ".json";
   
        // First check L* file exists
        File file = new File(locFileName);
        if (!file.exists())
        {
            // Retrieve from fixtures
            locFileName = configInfo.readFixturesPath() + "/locations-json/" + streetTSID + ".json";
            file = new File(locFileName);
            if (!file.exists())
            {
                printToFile.printDebugLine("SKIPPING MISSING street location file - " + locFileName, 3);
                display.setSkippedStreetsMsg("Skipping street - Missing location JSON file for TSID " + streetTSID);
                invalidStreet = true;
                return false;
            }
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
            printToFile.printDebugLine("Fail to load street JSON file " + locFileName, 3);
            return false;
        } 
        printToFile.printDebugLine("Reading location file " + locFileName, 2);
        
        // Read in street name
                
        streetName = Utils.readJSONString(json, "label", true);
        if (!Utils.readOkFlag() || streetName.length() == 0)
        {
            printToFile.printDebugLine(Utils.readErrMsg(), 3);
            printToFile.printDebugLine("Fail to read in street name from street JSON file " + locFileName, 3);
            return false;
        }
  
        printToFile.printDebugLine("Street name is " + streetName, 2);
        
        // Read in the region id
        hubID = Utils.readJSONString(json, "hubid", true);
        if (!Utils.readOkFlag() || hubID.length() == 0)
        {
            printToFile.printDebugLine(Utils.readErrMsg(), 3);
            printToFile.printDebugLine("Fail to read in hub id from street JSON file " + locFileName, 3);
            return false;
        }
        
        printToFile.printDebugLine("Region/hub id is " + hubID, 2);
    
        // Read in the list of street items
        streetItems = Utils.readJSONArray(json, "items", true);
        if (!Utils.readOkFlag())
        {
            printToFile.printDebugLine(Utils.readErrMsg(), 3);
            printToFile.printDebugLine("Fail to read in item array in street JSON file " + locFileName, 3);
            return false;
        } 
 
         // Everything OK   
        return true;
    }
    
    
    boolean readStreetItemData()
    {
        printToFile.printDebugLine("Read item TSID from street L file", 2);   
        // First set up basic information for each street - i.e. item TSID
        for (int i = 0; i < streetItems.size(); i++) 
        {
            itemInfo.add(new ItemInfo(streetItems.getJSONObject(i))); 
            
            // Now read the error flag for the last street item array added
            int total = itemInfo.size();
            ItemInfo itemData = itemInfo.get(total-1);
                       
            if (!itemData.readOkFlag())
            {
               printToFile.printDebugLine("Error parsing item basic TSID information", 3);
               return false;
            }
            
        }
        
        // Now fill in the all the rest of the item information for this street
        for (int i = 0; i < streetItems.size(); i++) 
        {                                  
            if (!itemInfo.get(i).initialiseItemInfo())
            {
                // actual error
                printToFile.printDebugLine("Error reading in additional information for item from I* file", 3);
                return false;
            }
        }
 
        // Everything OK
        printToFile.printDebugLine(" Initialised street = " + streetName + " street TSID = " + streetTSID + " with item count " + str(itemInfo.size()), 2);  
        return true;
    }
    
    boolean validateStreetSnaps()
    {
        // Using the street name, loads up all the street snaps from the QA snap directory
        // NB Need to makes sure these are all the same size - so smaller images are removed from the list of snaps automatically
        // Will unload the street snaps immediately - as only interested in the list of valid street snaps for now
        // Work out how many street snaps exist
        String [] snapFilenames = Utils.loadFilenames(configInfo.readStreetSnapPath(), streetName);

        if (snapFilenames.length == 0)
        {
            printToFile.printDebugLine("SKIPPING STREET - No street image files found in " + configInfo.readStreetSnapPath() + " for street " + streetName, 3);
            display.setSkippedStreetsMsg("Skipping street " + streetName + ": No street snaps found");
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
            printToFile.printDebugLine("No files found in rebuilt snap array = BUG for street " + streetName, 3);
            return false;
        } 
        
        // Now load up each of the snaps
        int maxImageWidth = 0;
        int maxImageHeight = 0;
        for (i = 0; i < archiveSnapFilenames.size(); i++) 
        {
            // This currently never returns an error
            streetSnaps.add(new PNGFile(archiveSnapFilenames.get(i), true));
            
            // load up the image
            if (!streetSnaps.get(i).setupPNGImage())
            {
                printToFile.printDebugLine("Failed to load up image " + archiveSnapFilenames.get(i), 3);
                return false;
            }
            
            // Keep track of the largest snap size - most likely to be the FSS e.g. zoi/cleops
            if (streetSnaps.get(i).readPNGImageWidth() > maxImageWidth)
            {
                maxImageWidth = streetSnaps.get(i).PNGImageWidth;
            }
            if (streetSnaps.get(i).readPNGImageHeight() > maxImageHeight)
            {
                maxImageHeight = streetSnaps.get(i).PNGImageHeight;
            } 
            
            // Now unload the image
            streetSnaps.get(i).unloadPNGImage();
        }
        
        // Work backwards so always removing from the end, not the top
        for (i = streetSnaps.size()-1; i >= 0; i--)
        {
            if ((streetSnaps.get(i).readPNGImageWidth() != maxImageWidth) || (streetSnaps.get(i).readPNGImageHeight() != maxImageHeight))
            {
                printToFile.printDebugLine("Skipping street snap " + streetSnaps.get(i).readPNGImageName() + " because resolution is smaller than " + 
                maxImageWidth + "x" + maxImageHeight + "pixels", 3);
                streetSnaps.remove(i);
            }
        }        
       
        // Everything OK
        return true;
    }
    
    public boolean initialiseStreetData()
    {

        // Read in street data - list of item TSIDs 
        if (!readStreetData()) //<>//
        {
            if (invalidStreet)
            {
                // i.e. need to skip this street as location information not available
                printToFile.printDebugLine("Skipping missing location JSON file", 3);
                return true; // continue
            }
            else
            {
                // error - need to stop
                printToFile.printDebugLine("Error in readStreetData", 3);
                okFlag = false;
                return false;
            }
        }

        display.setStreetName(streetName, streetTSID, streetBeingProcessed + 1, configInfo.readTotalJSONStreetCount());
        
        if (!validateStreetSnaps())
        {
            if (invalidStreet)
            {
                // i.e. need to skip this street as missing street snaps for street
                printToFile.printDebugLine("Skipping street - missing/invalid street snaps", 3);
                return true; // continue
            }
            else
            {
                // error - need to stop
                printToFile.printDebugLine("Error loading up street snaps for " + streetName, 3);
                okFlag = false;
                return false;
            }
        }

        if (!readStreetItemData())
        {
            printToFile.printDebugLine("Error in readStreetItemData", 3);
            okFlag = false;
            return false;
        }
       
        return true;
    }
    
    public void processItem()
    {
        // Does the main work - passes control down to the item structure
        ItemInfo itemData = itemInfo.get(itemBeingProcessed);
        
        // Display information
        display.clearDisplay();
        display.setStreetName(streetName, streetTSID, streetBeingProcessed + 1, configInfo.readTotalJSONStreetCount());
        display.setItemProgress(itemData.itemClassTSID, itemData.itemTSID, itemBeingProcessed+1, itemInfo.size());

        itemData.searchSnapForImage();
        if (failNow)
        {
            return;
        }
        
        if (itemData.readItemFinished())
        {            
            // Move onto next one
            itemBeingProcessed++;
            if (itemBeingProcessed >= itemInfo.size())
            {
                // Finished all items on the street
                // So move onto the next street snap after unloading the current one
                streetSnaps.get(streetSnapBeingUsed).unloadPNGImage();
               
                streetSnapBeingUsed++;
                if (streetSnapBeingUsed >= streetSnaps.size())
                {
                    // Reached end of street snaps so mark street as finished
                    // First need to write all the item changes to file
                    for (int i = 0; i < itemInfo.size(); i++)
                    {
                        if (!itemInfo.get(i).saveItemChanges())
                        {
                            failNow = true;
                            return; 
                        }
                    }
                    streetFinished = true;
                    return;
                }
                else
                {
                    // Start with the first item again on the new street snap
                    if (!loadStreetImage(streetSnapBeingUsed))
                    {
                        failNow = true;
                        return;
                    }
                    itemBeingProcessed = 0;
                }
            }
            
            // Set up fragFind in item ready to start the next item/streetsnap search combo
            // i.e. loads up pointers to correct street snap and item images
            // Only do this for items we still need to search for
            if (!itemInfo.get(itemBeingProcessed).readSkipThisItem())
            {
                if (!itemInfo.get(itemBeingProcessed).resetReadyForNewItemSearch())
                {
                    failNow = true;
                    return;
                }
            }
            else
            {
               printToFile.printDebugLine("Skipping item " + itemInfo.get(itemBeingProcessed).readItemClassTSID() + "(" + 
                                           itemInfo.get(itemBeingProcessed).readOrigItemExtraInfo() + ") " + 
                                           itemInfo.get(itemBeingProcessed).readItemTSID(), 1); 
            }
            
        }
    }
    
    
    // Simple functions to read/set variables
    public boolean readStreetFinished()
    {
        return streetFinished;
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
    
    public PNGFile readCurrentStreetSnap()
    {
        return streetSnaps.get(streetSnapBeingUsed);
    }
          
    public boolean loadStreetImage(int n)
    {
        return true;
        /*
        if (!streetSnaps.get(n).loadPNGImage())
        {
            return false;
        }
        return true; */
    }
    
    public void initStreetItemVars()
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
    
    /*
    public ArrayList<PNGFile> getItemImages(String itemClassTSID)
    {
         // Passes this down to the item image handler
         return (itemImagesHashMap.getItemImages(itemClassTSID));
    }
    
    public boolean loadItemImages(String itemClassTSID)
    {
         // Passes this down to the item image handler
         return (itemImagesHashMap.loadItemImages(itemClassTSID));
    }
    */
    
    
    
}