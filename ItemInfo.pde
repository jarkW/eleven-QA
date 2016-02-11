class ItemInfo
{
    boolean okFlag;
    boolean itemFinished;
    
    // Read in from I* file
    JSONObject itemJSON;
    String itemTSID;
    String itemClassTSID;
    String itemInfo;  // additional info needed for some items
    int    origItemX;
    int    origItemY;
    
    
    
    // Need to save k i.e. count of how many times move fragment before initiating
    // search. So can see how small k can be to actually work
           
    // constructor/initialise fields
    public ItemInfo(JSONObject item)
    {
        okFlag = true;
        itemFinished = false;
        itemJSON = null;
        
        itemTSID = item.getString("tsid");
        printToFile.printDebugLine("item tsid is " + itemTSID + "(" + item.getString("label") + ")", 2); 
    }
      
    public boolean initialiseItemInfo()
    {
        // Now open the relevant I* file from the appropriate place - try persdata first
        String itemFileName = configInfo.readPersdataPath() + "/" + itemTSID + ".json";
        File file = new File(itemFileName);
        if (!file.exists())
        {
            // Retrieve from fixtures
            itemFileName = configInfo.readFixturesPath() + "/world-items/" + itemTSID + ".json";
            file = new File(itemFileName);
            if (!file.exists())
            {
                printToFile.printDebugLine("Missing file - " + itemFileName, 3);
                return false;
            }
        } 
        
        printToFile.printDebugLine("Item file name is " + itemFileName, 2); 

        // Now read the item JSON file
        itemJSON = null;
        try
        {
            itemJSON = loadJSONObject(itemFileName);
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine("Failed load the item json file " + itemFileName, 3);
            return false;
        }
        
        printToFile.printDebugLine("Loaded item JSON OK", 1);
        
        origItemX = itemJSON.getInt("x");
        origItemY = itemJSON.getInt("y");
        itemClassTSID = itemJSON.getString("class_tsid");
        printToFile.printDebugLine("class_tsid " + itemClassTSID +" with x,y " + str(origItemX) + "," + str(origItemY), 2);              
              
        // Populate the info field for some items e.g. quoins, dirt etc
        if (!extractItemInfoFromJson())
        {
            // Error populating info field
            return false;
        }
        
        return true;
    } 
    
    boolean extractItemInfoFromJson()
    {
        JSONObject instanceProps;
        
        // As shrines are always configured to have dir = right, so no need to
        // extract this information. So ignore that field.
        
        // Extracting information which may be later modified by this tool or which 
        // is needed for other purposes. Typically information which affects the 
        // appearance of an item e.g. the type of quoin or dirtpile

        switch (itemClassTSID)
        {
            case "quoin":
            case "wood_tree":
            case "npc_mailbox":
            case "dirt_pile":
                // Read in the instanceProps array to get the quoin type
                instanceProps = null;
                try
                {
                    instanceProps = itemJSON.getJSONObject("instanceProps");
                }
                catch(Exception e)
                {
                    println(e);
                    printToFile.printDebugLine("Failed to get instanceProps from item JSON file " + itemTSID, 3);
                    return false;
                } 
                if (itemClassTSID.equals("quoin"))
                {
                    itemInfo = readJSONString(instanceProps, "type");
                }
                else if ((itemClassTSID.equals("wood_tree")) || (itemClassTSID.equals("npc_mailbox")) || (itemClassTSID.equals("dirt_pile")))
                {
                    itemInfo = readJSONString(instanceProps, "variant");
                }
                else if ((itemClassTSID.equals("mortar_barnacle")) || (itemClassTSID.equals("jellisac")))
                {
                    itemInfo = readJSONString(instanceProps, "blister");
                }
                else if (itemClassTSID.equals("ice_knob"))
                {
                    itemInfo = readJSONString(instanceProps, "knob");
                }
                else if (itemClassTSID.equals("dust_trap"))
                {
                    itemInfo = readJSONString(instanceProps, "trap_class");
                }               
                else
                {
                    printToFile.printDebugLine("Trying to read unexpected field from instanceProps for item class " + itemClassTSID, 3);
                    return false;
                }
                if (itemInfo.length() == 0)
                {
                    return false;
                }
                break;
   
            case "wall_button":
                // Read in the dir field 
                try
                {
                    itemInfo = itemJSON.getString("dir");
                }
                catch(Exception e)
                {
                    println(e);
                    printToFile.printDebugLine("Failed to read dir field from item JSON file " + itemTSID, 3);
                    return false;
                } 
                break;
                         
            case "npc_sloth":
                printToFile.printDebugLine("Not sure about sloth - check to see if both dir and instanceProps.dir are set to be the same " + itemTSID, 3);
                return false;
            
            case "visiting_stone":
                // Read in the dir field 
                // NB The dir field is not always set in visiting_stones - and often set wrong.
                // Therefore default the direction depending on what side of the screen it is
                //
                if (origItemX > 0)
                {
                    // stone is on RHS of screen - so set to 'left'
                    itemInfo = "left";
                }
                else
                {
                    // stone is on LHS of screen - so set to 'right'
                    itemInfo = "right";
                }
                               
                String tempInfo;
                // Insert dir field if not already present.
                try
                {
                    tempInfo = itemJSON.getString("dir");
                }
                catch(Exception e)
                {
                    // The dir field is often missing - so just insert now
                    printToFile.printDebugLine("Failed to read dir field from item JSON file - so insert " + itemTSID, 3);
                    itemJSON.setString("dir", itemInfo);
                    // Check that also have state field set
                    try
                    {
                        tempInfo = itemJSON.getString("state");
                    }
                    catch(Exception e2)
                    {
                        printToFile.printDebugLine("Failed to read STATE field from item JSON file - so insert set to 1 " + itemTSID, 3);
                        itemJSON.setString("state", "1");
                    }

                }               
                break;
                                
            default:
                // Nothing to extract
                break;
         }

        
        return true;
    } 
    
    String readJSONString(JSONObject jsonFile, String key)
    {
        String readString = "";
        try
        {
            if (jsonFile.isNull(key) == true) 
            {
                println("Missing key ", key, " in json file");
                okFlag = false;
                return "";
            }
            readString = jsonFile.getString(key, "");
        }
        catch(Exception e)
        {
            println(e);
            println("Failed to read string from json file with key ", key);
            okFlag = false;
            return "";
        }
        if (readString.length() == 0)
        {
            println("Null field returned for key", key);
            okFlag = false;
            return "";
        }
        return readString;
    }
    
    public void searchUsingReference()
    {
        // Does the actual matching of images/snap?
        printToFile.printDebugLine("unimplemented searchUsingReference()", 3);
    }
    
    // Simple functions to read/set variables
    public boolean readItemFinished()
    {
        return itemFinished;
    }
    
    public boolean readOkFlag()
    {
        return okFlag;
    } 
}