class StreetInfo
{
    boolean okFlag;
    boolean streetFinished;
    
    // passed to constructor - read in originally from config.json
    String streetTSID;
    
    // Read in from L* file
    JSONArray streetItems;
    String streetName;

    
    // Data read in from each I* file
    int itemBeingProcessed;
    ArrayList<ItemInfo> itemInfoArray = new ArrayList<ItemInfo>();
    
    // constructor/initialise fields
    public StreetInfo(String tsid)
    {
        okFlag = true;
        streetFinished = false;
        streetTSID = tsid;
        itemBeingProcessed = 0;
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
                printToFile.printDebugLine("Missing file - " + locFileName, 3);
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
                printToFile.printDebugLine("Error reading in additional information for item from I* file", 3);
                return false;
            }
        }
 
        // Everything OK
        printToFile.printDebugLine(" Initialised street = " + streetName + " street TSID = " + streetTSID + " with item count " + str(itemInfoArray.size()), 2);  
        return true;
    }
    
    public boolean initialiseStreetData()
    {
        // Read in street data - list of item TSIDs 
        if (!readStreetData())
        {
            printToFile.printDebugLine("Error in readStreetData", 3);
            okFlag = false;
            return false;
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
    
}