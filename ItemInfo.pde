class ItemInfo
{
    boolean okFlag;
    boolean itemFinished;
    boolean skipThisItem;
    
    // Read in from I* file
    JSONObject itemJSON;
    String itemTSID;
    String itemClassTSID;
    String itemInfo;  // additional info needed for some items
    int    origItemX;
    int    origItemY;
    
    // defaults for fragment
    // Offset from the actual x,y of the item for this fragment
    int fragOffsetX;
    int fragOffsetY;
    int fragHeight;
    int fragWidth;
    
    // Contains the item fragments used to search the snap
    ArrayList<PNGFile> itemImageArray;
    int itemImageBeingUsed;
    
    
    
    // Need to save k i.e. count of how many times move fragment before initiating
    // search. So can see how small k can be to actually work
           
    // constructor/initialise fields
    public ItemInfo(JSONObject item)
    {
        okFlag = true;
        
        itemFinished = false;
        skipThisItem = false;
        itemJSON = null;
        itemInfo = "";
        itemImageBeingUsed = 0;
        itemImageArray = new ArrayList<PNGFile>();
        
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
        
        // Before proceeding any further need to check if this is an item we are
        // scanning for - skip if not
        if (!validItemToCheckFor())
        {
            // NB - safer to keep it in the item array, and check this flag
            // before doing any actual checking/writing
            skipThisItem = true;
            return true;
        }
                          
        // Populate the info field for some items e.g. quoins, dirt etc
        if (!extractItemInfoFromJson())
        {
            // Error populating info field
            printToFile.printDebugLine("Failed to extract info for class_tsid " + itemClassTSID, 3);
            return false;
        }
        
        // Populate the fragment information for this item (deduced using the save_fragments tool)
        if (!setFragmentDefaultsForItem())
        {
            printToFile.printDebugLine("Error defaulting fragment defaults for class_tsid " + itemClassTSID, 3); 
            return false;
        }
        
        // Load up the item images which will be used to search the snap
        if (!loadItemImages())
        {
            printToFile.printDebugLine("Error loading item images for class_tsid " + itemClassTSID, 3); 
            return false;
        }
        
        
        if (itemInfo.length() > 0)
        {
            printToFile.printDebugLine("class_tsid " + itemClassTSID + " info = <" + itemInfo + "> with x,y " + str(origItemX) + "," + str(origItemY), 2); 
        }
        else
        {
            printToFile.printDebugLine("class_tsid " + itemClassTSID + " with x,y " + str(origItemX) + "," + str(origItemY), 2); 
        }
        // print out item images that have been loaded
        for (int i = 0; i < itemImageArray.size(); i++)
        {
            printToFile.printDebugLine("Loaded item image " + itemImageArray.get(i).PNGImageName, 1);
        }
 
        return true;
    } 
    
    boolean validItemToCheckFor()
    {        
        // Returns true if this an item we expect to be scanning for on a snap
        if ((itemClassTSID.indexOf("npc_shrine_", 0) == 0) ||
            (itemClassTSID.indexOf("trant_", 0) == 0) ||
            (itemClassTSID.indexOf("rock_", 0) == 0) ||
            (itemClassTSID.indexOf("peat_", 0) == 0))
        {
            return true;
        }
        
        switch (itemClassTSID)
        {
            case "quoin":
            case "marker_qurazy":
            case "wood_tree":
            case "paper_tree":
            case "npc_mailbox":
            case "dirt_pile":
            case "mortar_barnacle":
            case "jellisac":
            case "ice_knob":
            case "dust_trap":
            case "wall_button":
            case "visiting_stone":              
            case "npc_sloth":
            case "sloth_knocker":
            case "patch":
            case "patch_dark":
            case "party_atm":
            case "race_ticket_dispenser":
                return true;
                
            default:
                // Unexpected class tsid - so skip the item
                printToFile.printDebugLine("Skipping item " + itemTSID + " class tsid " + itemClassTSID, 2);
                return false;
         }
    }
    
    boolean loadItemImages()
    {
        // Using the item class_tsid and info field, load up all the images for this item
        // Depending on the item might need to tweak the order of items
        
        String itemFragmentPNGName;
        PNGFile itemPNG;
        int i;

        if (itemClassTSID.indexOf("visiting_stone", 0) == 0)
        {
            // For visiting stones - load up the correct image using the item JSON x,y to know what is expected
            if (origItemX < 0)
            {
                // visiting stone is on LHS of page - so load up the 'right' image
                itemFragmentPNGName = itemClassTSID + "_right.png";
            }
            else
            {
                // visiting stone is on RHS of page - so load up the 'left' image
                itemFragmentPNGName = itemClassTSID + "_left.png";
            }
            itemImageArray.add(new PNGFile(dataPath(itemFragmentPNGName)));
        }
        else if (itemClassTSID.indexOf("wall_button", 0) == 0)
        {
            // assume left-facing button to start with
            itemImageArray.add(new PNGFile(dataPath(itemClassTSID + "_left.png")));
            itemImageArray.add(new PNGFile(dataPath(itemClassTSID + "_right.png")));
        }
        else if (itemClassTSID.indexOf("quoin", 0) == 0)
        {
            // As we are setting quoins from the snap, load up the most common quoins first
            itemImageArray.add(new PNGFile(dataPath("quoin_xp.png")));
            itemImageArray.add(new PNGFile(dataPath("quoin_energy.png")));
            itemImageArray.add(new PNGFile(dataPath("quoin_mood.png")));
            itemImageArray.add(new PNGFile(dataPath("quoin_currants.png")));
            itemImageArray.add(new PNGFile(dataPath("quoin_favor.png")));
            itemImageArray.add(new PNGFile(dataPath("quoin_time.png")));
        }
        else if ((itemClassTSID.indexOf("wood_tree", 0) == 0) || (itemClassTSID.indexOf("trant_", 0) == 0))
        {
            // Are dealing with a tree. First load the existing tree image and then load the other tree images
            // Finally prune out the duplicate - rather than keep doing if statements
            itemFragmentPNGName = itemClassTSID;
            if (itemInfo.length() > 0)
            {
                itemFragmentPNGName = itemFragmentPNGName + "_" + itemInfo;
            }
            // Add this item image
            itemImageArray.add(new PNGFile(dataPath(itemFragmentPNGName + ".png")));
            // Now add all the trees
            itemImageArray.add(new PNGFile(dataPath("trant_bean.png")));
            itemImageArray.add(new PNGFile(dataPath("trant_fruit.png")));
            itemImageArray.add(new PNGFile(dataPath("trant_bubble.png")));
            itemImageArray.add(new PNGFile(dataPath("trant_spice.png")));
            itemImageArray.add(new PNGFile(dataPath("trant_gas.png")));
            itemImageArray.add(new PNGFile(dataPath("trant_egg.png")));
            itemImageArray.add(new PNGFile(dataPath("wood_tree_1.png")));    
            itemImageArray.add(new PNGFile(dataPath("wood_tree_2.png")));  
            itemImageArray.add(new PNGFile(dataPath("wood_tree_3.png")));  
            itemImageArray.add(new PNGFile(dataPath("wood_tree_4.png")));  
            
            // Now remove the duplicate item image - skip past first image
            boolean duplicateFound = false;
            for (i = 1; i < itemImageArray.size() && !duplicateFound; i++)
            {
                println("this item is ", dataPath(itemFragmentPNGName + ".png"), " array [", i, "] is ",itemImageArray.get(i).PNGImageName);
                if (itemImageArray.get(i).PNGImageName.equals(dataPath(itemFragmentPNGName + ".png")))
                {
                    itemImageArray.remove(i);
                    duplicateFound = true;
                }
            }
            if (!duplicateFound)
            {
                // Should never happen
                printToFile.printDebugLine("Failed to remove duplicate tree item image ", 3);
                return false;
            }            
        }
        else
        {
            // Can search for images based on the class_tsid and info fields
            // npc_shrine_*
            // npc_sloth
            // sloth_knocker
            // patch
            // patch_dark
            // party_atm
            // race_ticket_dispenser
            // rock_*
            // peat_*
            // marker_qurazy
            // paper_tree (as can only ever be a paper tree/not planted by player)
            // npc_mailbox
            // dirt_pile
            // mortar_barnacle
            // jellisac
            // ice_knob
            // dust_trap
            itemFragmentPNGName = itemClassTSID;
            if (itemInfo.length() > 0)
            {
                itemFragmentPNGName = itemFragmentPNGName + "_" + itemInfo;
            }
            
            // Work out how many item images exist
            String [] imageFilenames = null;
            imageFilenames = Utils.loadFilenames(dataPath(""), itemFragmentPNGName);

            if ((imageFilenames == null) || (imageFilenames.length == 0))
            {
                printToFile.printDebugLine("No files found in " + dataPath("") + " for item/info " + itemFragmentPNGName, 3);
                return false;
            }
       
            // Now create am entry for each of the snaps
            for (i = 0; i < imageFilenames.length; i++) 
            {
                // This currently never returns an error
                itemImageArray.add(new PNGFile(dataPath(imageFilenames[i])));
            } 
        }
        
        // Now load up the actual item images
        for (i = 0; i < itemImageArray.size(); i++)
        {
            if (!itemImageArray.get(i).loadPNGImage())
            {
                printToFile.printDebugLine("Failed to load up item image " + itemImageArray.get(i).PNGImageName, 3);
                return false;
            }
        }
        
        return true;
    }
    
    boolean extractItemInfoFromJson()
    {
        JSONObject instanceProps;

        // Extracting information which may be later modified by this tool or which 
        // is needed for other purposes. Typically information which affects the 
        // appearance of an item e.g. the type of quoin or dirtpile
        
        if (itemClassTSID.indexOf("npc_shrine_", 0) == 0)
        {
            // Shorter code rather than adding in class_tsid for all 30 shrines
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
            
            // Currently all shrines are set to 'right' so flag up error if that isn't true
            if (!itemInfo.equals("right"))
            {
                printToFile.printDebugLine("Unexpected dir = left field in shrine JSON file  " + itemTSID, 3);
                return false;
            }
            
            return true;
            
        }

        switch (itemClassTSID)
        {
            case "quoin":
            case "wood_tree":
            case "npc_mailbox":
            case "dirt_pile":
            case "mortar_barnacle":
            case "jellisac":
            case "ice_knob":
            case "dust_trap":
                // Read in the instanceProps array 
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
    
    boolean setFragmentDefaultsForItem()
    {
        JSONObject json;
        JSONArray values;
        JSONObject fragment = null;
        
        // Read in from samples.json file - created by the save_fragments tool. Easier to read in/update
        try
        {
            // Read in stuff from the existing file
            json = loadJSONObject(dataPath("samples.json"));
        }
        catch(Exception e)
        {
            println(e);
            println("Failed to open samples.json file");
            return false;
        }
        values = json.getJSONArray("fragments");
        
        for (int i = 0; i < values.size(); i++) 
        {
            fragment = values.getJSONObject(i);
            if ((fragment.getString("class_tsid").equals(itemClassTSID)) && (fragment.getString("info").equals(itemInfo)))
            {
                // Found fragment for this item
                fragOffsetX = fragment.getInt("offset_x");
                fragOffsetY = fragment.getInt("offset_y");
                fragWidth = fragment.getInt("width");
                fragHeight = fragment.getInt("height");
                return true;
            }
        }
        
        // If we reach here then missing item from json file
        printToFile.printDebugLine("Missing class_tsid " + itemClassTSID + " and/or info field <" + itemInfo + "> in samples.json", 3);
        return false;
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
        //printToFile.printDebugLine("unimplemented searchUsingReference()", 3);
        if (itemInfo.length() > 0)
        {
            printToFile.printDebugLine("Searching item class_tsid " + itemClassTSID + " info = <" + itemInfo + "> with x,y " + str(origItemX) + "," + str(origItemY) + //
            " offset is " + fragOffsetX + "," + fragOffsetY + " size hxw is " + fragHeight + "x" + fragWidth, 2);
                           
        }
        else
        {
            printToFile.printDebugLine("Searching item class_tsid " + itemClassTSID + " with x,y " + str(origItemX) + "," + str(origItemY), 2); 
            printToFile.printDebugLine("Searching item class_tsid " + itemClassTSID + " with x,y " + str(origItemX) + "," + str(origItemY) + //
            " offset is " + fragOffsetX + "," + fragOffsetY + " size hxw is " + fragHeight + "x" + fragWidth, 2);
        }
        itemFinished = true;
        
    }
    
    // Simple functions to read/set variables
    public boolean readItemFinished()
    {
        return itemFinished;
    }
    
    public boolean readSkipThisItem()
    {
        return skipThisItem;
    }
    
    public boolean readOkFlag()
    {
        return okFlag;
    } 
}