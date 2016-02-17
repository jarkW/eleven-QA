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
    
    // list of street snaps and associated images
    ArrayList<PNGFile> streetSnapArray;
    int streetSnapBeingUsed;
    
    // Data read in from each I* file
    int itemBeingProcessed;
    ArrayList<ItemInfo> itemInfoArray;
    
    // constructor/initialise fields
    public StreetInfo(String tsid)
    {
        okFlag = true;
        
        initStreetVars();

        streetTSID = tsid;       
        itemInfoArray = new ArrayList<ItemInfo>();
        streetSnapArray = new ArrayList<PNGFile>();
    }
    
    public void initStreetVars()
    {
        // These need to be reset after been through the loop of streets
        // as part of initial validation
        itemBeingProcessed = 0;
        streetSnapBeingUsed = 0;
        streetFinished = false;
        invalidStreet = false;
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
        streetName = "";
        try
        {
            streetName = json.getString("label");
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine("Fail to read in street name from street JSON file " + locFileName, 3);
            return false;
        } 
        printToFile.printDebugLine("Street name is " + streetName, 2);
    
        // Read in the list of street items
        streetItems = null;
        try
        {
            streetItems = json.getJSONArray("items");
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine("Fail to read in item array in street JSON file " + locFileName, 3);
            return false;
        } 
 
         // Everything OK   
        return true;
    }
    
    
    boolean readStreetItemData()
    {
        println("Read item TSID from street L file");   
        // First set up basic information for each street - i.e. item TSID
        for (int i = 0; i < streetItems.size(); i++) 
        {
            itemInfoArray.add(new ItemInfo(streetItems.getJSONObject(i)));
            
            // Now read the error flag for the last street item array added
            int total = itemInfoArray.size();
            ItemInfo itemData = itemInfoArray.get(total-1);
                       
            if (!itemData.readOkFlag())
            {
               printToFile.printDebugLine("Error parsing item basic TSID information", 3);
               return false;
            }
            
        }
        
        // Now fill in the all the rest of the item information for this street
        for (int i = 0; i < streetItems.size(); i++) 
        {                                  
            if (!itemInfoArray.get(i).initialiseItemInfo())
            {
                // actual error
                printToFile.printDebugLine("Error reading in additional information for item from I* file", 3);
                return false;
            }
        }
 
        // Everything OK
        printToFile.printDebugLine(" Initialised street = " + streetName + " street TSID = " + streetTSID + " with item count " + str(itemInfoArray.size()), 2);  
        return true;
    }
    
    boolean loadArchiveStreetSnaps()
    {
        // Using the street name, loads up all the street snaps from the QA snap directory
        // NB Need to makes sure these are all the same size - if not, then bomb out with error message
        
        // Work out how many street snaps exist
        String [] SnapFilenames = Utils.loadFilenames(configInfo.readStreetSnapPath(), streetName);

        if (SnapFilenames.length == 0)
        {
            printToFile.printDebugLine("SKIPPING STREET - No street image files found in " + configInfo.readStreetSnapPath() + " for street " + streetName, 3);
            display.setSkippedStreetsMsg("Skipping street " + streetName + ": No street snaps found");
            invalidStreet = true;
            return false;
        }
       

        int i;
        StringList archiveSnapFilenames = new StringList();
 
        for (i = 0; i < SnapFilenames.length; i++)
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
                if ((SnapFilenames[i].indexOf("Towers") == -1) && (SnapFilenames[i].indexOf("Manor") == -1))
                {
                    // Is the actual street we want, so copy
                    archiveSnapFilenames.append(SnapFilenames[i]);
                }
            }
            if ((streetName.equals("Sabudana Drama Towers")) || (streetName.equals("Egret Taun Towers")) ||
                (streetName.equals("Hauki Seeks Manor")) || (streetName.equals("Hakusan Heaps Towers")) ||
                (streetName.equals("Gregarious Towers")))
            {
                // Need to strip out the Basement/Floors streets
                if ((SnapFilenames[i].indexOf("asement") == -1) && (SnapFilenames[i].indexOf("loor") == -1))
                {
                    // Is the actual street we want, so copy
                    archiveSnapFilenames.append(SnapFilenames[i]);
                } 
            }       
            else if (streetName.indexOf("Subway") == -1)
            { 
                // Street is not a subway - so remove any subway snaps
                if (SnapFilenames[i].indexOf("Subway") == -1)
                {
                    // Snap is not the subway station, so keep
                    archiveSnapFilenames.append(SnapFilenames[i]);
                }
                
            }
            else
            {
                // Valid subway street snap so keep
                archiveSnapFilenames.append(SnapFilenames[i]);

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
            streetSnapArray.add(new PNGFile(archiveSnapFilenames.get(i), true));
            
            // load up the image
            if (!streetSnapArray.get(i).setupPNGImage())
            {
                printToFile.printDebugLine("Failed to load up image " + archiveSnapFilenames.get(i), 3);
                return false;
            }
            
            // Keep track of the largest snap size - most likely to be the FSS e.g. zoi/cleops
            if (streetSnapArray.get(i).readPNGImageWidth() > maxImageWidth)
            {
                maxImageWidth = streetSnapArray.get(i).PNGImageWidth;
            }
            if (streetSnapArray.get(i).readPNGImageHeight() > maxImageHeight)
            {
                maxImageHeight = streetSnapArray.get(i).PNGImageHeight;
            } 
        }
        
        // Work backwards so always removing from the end, not the top
        for (i = streetSnapArray.size()-1; i >= 0; i--)
        {
            if ((streetSnapArray.get(i).readPNGImageWidth() != maxImageWidth) || (streetSnapArray.get(i).readPNGImageHeight() != maxImageHeight))
            {
                printToFile.printDebugLine("Skipping street snap " + streetSnapArray.get(i).readPNGImageName() + " because resolution is smaller than " + 
                maxImageWidth + "x" + maxImageHeight + "pixels", 3);
                streetSnapArray.remove(i);
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
            println("readStreetData failed");
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
        
        if (!loadArchiveStreetSnaps())
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
        ItemInfo itemData = itemInfoArray.get(itemBeingProcessed);
        
        // Display information
        display.clearDisplay();
        display.setStreetName(streetName, streetTSID, streetBeingProcessed + 1, configInfo.readTotalJSONStreetCount());
        display.setItemProgress(itemData.itemClassTSID, itemData.itemTSID, itemBeingProcessed+1, itemInfoArray.size());

        itemData.searchUsingReference();
        
        if (itemData.readItemFinished())
        {
            // Item has been successfully located, so move onto next one
            itemBeingProcessed++;
            if (itemBeingProcessed >= itemInfoArray.size())
            {
                // Finished all items on the street, mark street as done
                streetFinished = true;
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
    
    public String readStreetTSID()
    {
        return streetTSID;
    }
    
    public PNGFile readStreetSnap(int n)
    {
        if (n < streetSnapArray.size())
        {
            return streetSnapArray.get(n);
        }
        else
        {
            return null;
        }
    }
  
    // IS THIS USED?
    public void incrStreetSnapBeingUsed ()
    {
        streetSnapBeingUsed++;
        
        if (streetSnapBeingUsed >= streetSnapArray.size())
        {
            streetSnapBeingUsed = 0;
        }
    }
    
    public ArrayList<PNGFile> getStreetImageArray ()
    {
        return (streetSnapArray);
    }
    
    public boolean loadStreetImages()
    {
        for (int i = 0; i < streetSnapArray.size(); i++)
        {
            if (!streetSnapArray.get(i).loadPNGImage())
            {
                return false;
            }
        }
        return true;
    }
    
    public boolean unloadStreetImages()
    {
        for (int i = 0; i < streetSnapArray.size(); i++)
        {
            streetSnapArray.get(i).unloadPNGImage();
        }
        return true;
    }   
    
    public boolean unloadAllItemImages()
    {
        for  (int i = 0; i < itemInfoArray.size(); i++)
        {
            itemInfoArray.get(i).unloadItemImages();
        }
        return true;
    }
    
    public boolean loadAllItemImages()
    {
        for  (int i = 0; i < itemInfoArray.size(); i++)
        {
            if (!itemInfoArray.get(i).loadItemImages())
            {
                return false;
            }
        }
        return true;
        
    }
    
    public void initStreetItemVars()
    {
        for  (int i = 0; i < itemInfoArray.size(); i++)
        {
            itemInfoArray.get(i).initItemVars();
        }
    }
    
    public boolean readInvalidStreet()
    {
        return invalidStreet;
    }
    
    
    
    
    
}