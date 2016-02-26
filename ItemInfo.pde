class ItemInfo
{
    boolean okFlag;
    boolean itemFinished;
    boolean skipThisItem;
    
    // Read in from I* file
    JSONObject itemJSON;
    String itemTSID;
    String itemClassTSID;
    String origItemExtraInfo;  // additional info needed for some items
    String origItemClassName;    // used for quoins only/reporting differences at end
    int    origItemX;
    int    origItemY;
    
    // Used to read/set the additional info in item JSON
    String itemExtraInfoKey;

    // Fields which are deduced from snap comparison - and then written to JSON file
    String newItemExtraInfo;  
    String newItemClassName;    // used for quoins only
    int    newItemX;
    int    newItemY;
    
    // show if need to write out changed JSON file
    boolean saveChangedJSONfile;
    boolean alreadySetDirField;
    
    // defaults for fragment
    // Offset from the actual x,y of the item for this fragment
    int fragOffsetX;
    int fragOffsetY;
    
    FragmentFind fragFind;
    
    // Contains the item fragments used to search the snap
    ArrayList<PNGFile> itemImageArray;
    
    // ARE THESE EVER USED HERE?
    //int itemImageBeingUsed;
    //int streetImageBeingUsed;
    
    // Info used to compare size of input/output JSON files
    int sizeOfOriginalJSON;
    int sizeOfFinalJSON;
    int sizeDiffJSONCalc; // calculated 
      
    
    // Need to save k i.e. count of how many times move fragment before initiating
    // search. So can see how small k can be to actually work
           
    // constructor/initialise fields
    public ItemInfo(JSONObject item)
    {
        okFlag = true;
        itemJSON = null;
        origItemExtraInfo = "";
        origItemClassName = "";
        itemExtraInfoKey = "";
        fragFind = null;
        origItemX = 0;
        origItemY = 0;
        newItemX = missCoOrds;
        newItemY = missCoOrds;
        newItemExtraInfo = "";        
        newItemClassName = "";
        
        sizeOfOriginalJSON = 0;
        sizeOfFinalJSON = 0;
        sizeDiffJSONCalc = 0;
        skipThisItem = false;
        saveChangedJSONfile = false;
        alreadySetDirField = false;
        
        initItemVars();

        itemImageArray = new ArrayList<PNGFile>();

        itemTSID = Utils.readJSONString(item, "tsid", true);
        if (!Utils.readOkFlag() || itemTSID.length() == 0)
        {
            printToFile.printDebugLine(Utils.readErrMsg(), 3);
            okFlag = false;
        }
        else
        {
            printToFile.printDebugLine("item tsid is " + itemTSID + "(" + item.getString("label") + ")", 2);
        }
    }
    
    public void initItemVars()
    {
        // These need to be reset after been through the loop of streets
        // as part of initial validation
        itemFinished = false;
        //itemImageBeingUsed = 0;
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
                
        sizeOfOriginalJSON = sizeOfJSONFile(itemFileName);
        printToFile.printDebugLine("Item file name is " + itemFileName + " size " + sizeOfOriginalJSON, 2); 

        // Now read the item JSON file
        itemJSON = null;
        try
        {
            itemJSON = loadJSONObject(itemFileName);
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine("Failed to load the item json file " + itemFileName, 3);
            return false;
        }
        
        printToFile.printDebugLine("Loaded item JSON OK", 1);
        
        // These fields are always present - so if missing = error
        origItemX = Utils.readJSONInt(itemJSON, "x", true);
        if (!Utils.readOkFlag())
        {
            printToFile.printDebugLine(Utils.readErrMsg(), 3);
            return false;
        }
        origItemY = Utils.readJSONInt(itemJSON, "y", true);
        if (!Utils.readOkFlag())
        {
            printToFile.printDebugLine(Utils.readErrMsg(), 3);
            return false;
        }
        itemClassTSID = Utils.readJSONString(itemJSON, "class_tsid", true);
        if (!Utils.readOkFlag() || itemClassTSID.length() == 0)
        {
            printToFile.printDebugLine(Utils.readErrMsg(), 3);
            return false;
        }
        
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
        if (!setupItemImages())
        {
            printToFile.printDebugLine("Error loading item images for class_tsid " + itemClassTSID, 3); 
            return false;
        }      
        
        if (origItemExtraInfo.length() > 0)
        {
            printToFile.printDebugLine("class_tsid " + itemClassTSID + " info = <" + origItemExtraInfo + "> with x,y " + str(origItemX) + "," + str(origItemY), 2); 
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
        
        // Initialise for the item to be searched for
        //itemImageBeingUsed = 0;
        fragFind = new FragmentFind(this);
 
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
            case "subway_gate":
            case "subway_map":
            case "bag_notice_board":
                return true;
                
            default:
                // Unexpected class tsid - so skip the item
                printToFile.printDebugLine("Skipping item " + itemTSID + " class tsid " + itemClassTSID, 2);
                return false;
         }
    }
    
    boolean setupItemImages()
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
            itemImageArray.add(new PNGFile(itemFragmentPNGName, false));
        }
        else if (itemClassTSID.indexOf("wall_button", 0) == 0)
        {
            // assume left-facing button to start with
            itemImageArray.add(new PNGFile(itemClassTSID + "_left.png", false));
            itemImageArray.add(new PNGFile(itemClassTSID + "_right.png", false));
        }
        else if (itemClassTSID.indexOf("npc_mailbox", 0) == 0)
        {
            if (origItemExtraInfo.equals("mailboxRight"))
            {
                itemImageArray.add(new PNGFile(itemClassTSID + "_mailboxRight.png", false));
                itemImageArray.add(new PNGFile(itemClassTSID + "_mailboxLeft.png", false));
            }
            else
            {
                itemImageArray.add(new PNGFile(itemClassTSID + "_mailboxLeft.png", false));
                itemImageArray.add(new PNGFile(itemClassTSID + "_mailboxRight.png", false));
            }
        } 
        else if (itemClassTSID.indexOf("npc_sloth", 0) == 0)
        {
            printToFile.printDebugLine("NEED TO CONFIGURE SLOTH in setupItemImages ", 3);
            return false;
        }
        else if (itemClassTSID.indexOf("quoin", 0) == 0)
        {
            
            if (!configInfo.readChangeXYOnly())
            {
                // As we are setting quoins from the snap, load up the most common quoins first
                itemImageArray.add(new PNGFile("quoin_xp.png", false));
                itemImageArray.add(new PNGFile("quoin_energy.png", false));
                itemImageArray.add(new PNGFile("quoin_mood.png", false));
                itemImageArray.add(new PNGFile("quoin_currants.png", false));
                itemImageArray.add(new PNGFile("quoin_favor.png", false));
                itemImageArray.add(new PNGFile("quoin_time.png", false));
            }
            else
            {
                // As only changing the x,y can just load up the relevant snap (including mystery quoins)
                itemImageArray.add(new PNGFile(itemClassTSID + "_" + origItemExtraInfo + ".png", false));
            }
        }
        else if ((itemClassTSID.indexOf("wood_tree", 0) == 0) || (itemClassTSID.indexOf("trant_", 0) == 0))
        {
            // Are dealing with a tree. First load the existing tree image and then load the other tree images
            // Finally prune out the duplicate - rather than keep doing if statements
            itemFragmentPNGName = itemClassTSID;
            if (origItemExtraInfo.length() > 0)
            {
                itemFragmentPNGName = itemFragmentPNGName + "_" + origItemExtraInfo;
            }
            // Add this item image
            itemImageArray.add(new PNGFile(itemFragmentPNGName + ".png", false));
            // Now add all the trees
            itemImageArray.add(new PNGFile("trant_bean.png", false));
            itemImageArray.add(new PNGFile("trant_fruit.png", false));
            itemImageArray.add(new PNGFile("trant_bubble.png", false));
            itemImageArray.add(new PNGFile("trant_spice.png", false));
            itemImageArray.add(new PNGFile("trant_gas.png", false));
            itemImageArray.add(new PNGFile("trant_egg.png", false));
            itemImageArray.add(new PNGFile("wood_tree_1.png", false));    
            itemImageArray.add(new PNGFile("wood_tree_2.png", false));  
            itemImageArray.add(new PNGFile("wood_tree_3.png", false));  
            itemImageArray.add(new PNGFile("wood_tree_4.png", false));  
            
            // Now remove the duplicate item image - skip past first image
            boolean duplicateFound = false;
            for (i = 1; i < itemImageArray.size() && !duplicateFound; i++)
            {
                if (itemImageArray.get(i).PNGImageName.equals(itemFragmentPNGName + ".png"))
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
            // Rest of items do not have a dir field (or in case of shrines, only ever set to right, so only one image to load
            // npc_shrine_* (will only ever be _right variety)
            // sloth_knocker
            // patch
            // patch_dark
            // party_atm
            // race_ticket_dispenser
            // rock_*
            // peat_*
            // marker_qurazy
            // paper_tree (as can only ever be a paper tree/not planted by player)
            // dirt_pile
            // mortar_barnacle
            // jellisac
            // ice_knob
            // dust_trap
            itemFragmentPNGName = itemClassTSID;
            if (origItemExtraInfo.length() > 0)
            {
                itemFragmentPNGName = itemFragmentPNGName + "_" + origItemExtraInfo;
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
                itemImageArray.add(new PNGFile(imageFilenames[i], false));
            } 
        }
        
        // Now load up the actual item images
        for (i = 0; i < itemImageArray.size(); i++)
        {
            if (!itemImageArray.get(i).setupPNGImage())
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
            
            // As dir may not exist - is not an error
            itemExtraInfoKey = "dir";
            origItemExtraInfo = Utils.readJSONString(itemJSON, itemExtraInfoKey, false);
            if (!Utils.readOkFlag() || origItemExtraInfo.length() == 0)
            {
                // Failed to read this field from JSON file - so need to insert one
                printToFile.printDebugLine("Failed to read dir field from shrine JSON file " + itemTSID, 2);
                
                if (!Utils.setJSONString(itemJSON, itemExtraInfoKey, "right"))
                {
                    // Error occurred - fail
                    printToFile.printDebugLine(Utils.readErrMsg(), 3);
                    printToFile.printDebugLine("Failed to insert new dir field in item JSON file " + itemTSID, 3);
                    return false;
                }

                // save this new dir field - will need to load the shrine picture
                origItemExtraInfo = "right";
                
                // As have just added in a new key - keep track of this expected change to file length
                sizeDiffJSONCalc += Utils.readByteCount();
                printToFile.printDebugLine("Updated JSON file size difference after insert dir field is " + sizeDiffJSONCalc, 1);
                
                // Show JSON file needs saving after processing done
                saveChangedJSONfile = true;
                
                // Set flag so give meaningful msg at end of processing
                alreadySetDirField = true;
            }
            
            // Currently all shrines are set to 'right' so flag up error if that isn't true
            // Putting this in so that if I ever come across a left-shrine, it will cause the code to fail
            // Hence read the value in rather than simply setting to 'right' all the time.
            if (!origItemExtraInfo.equals("right"))
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
                // Read in the instanceProps array - failure is always an error
                instanceProps = Utils.readJSONObject(itemJSON, "instanceProps", true);
                if (!Utils.readOkFlag())
                {
                    printToFile.printDebugLine(Utils.readErrMsg(), 3);
                    printToFile.printDebugLine("Failed to get instanceProps from item JSON file " + itemTSID, 3);
                    return false;
                }
                
                if (itemClassTSID.equals("quoin"))
                {
                    // Save the class_name field for this item - only used when reporting original/changed quoin at end
                    origItemClassName = Utils.readJSONString(instanceProps, "class_name", true);
                    if (!Utils.readOkFlag() || origItemClassName.length() == 0)
                    {
                        printToFile.printDebugLine(Utils.readErrMsg(), 3);
                        printToFile.printDebugLine("Failed to get instanceProps.class_name" + itemExtraInfoKey + " from item JSON file " + itemTSID, 3);
                        return false;
                    }    
                    
                    // Now continue with getting the type field from the json file
                    itemExtraInfoKey = "type";
                }
                else if ((itemClassTSID.equals("wood_tree")) || (itemClassTSID.equals("npc_mailbox")) || (itemClassTSID.equals("dirt_pile")))
                {
                    itemExtraInfoKey = "variant";
                }
                else if ((itemClassTSID.equals("mortar_barnacle")) || (itemClassTSID.equals("jellisac")))
                {
                    itemExtraInfoKey = "blister";
                }
                else if (itemClassTSID.equals("ice_knob"))
                {
                    itemExtraInfoKey = "knob";
                }
                else if (itemClassTSID.equals("dust_trap"))
                {
                    itemExtraInfoKey = "trap_class";
                }
                else
                {
                    printToFile.printDebugLine("Trying to read unexpected field from instanceProps for item class " + itemClassTSID, 3);
                    return false;
                }
                
                // Now read in the additional information using the key
                origItemExtraInfo = Utils.readJSONString(instanceProps, itemExtraInfoKey, true);
                if (!Utils.readOkFlag() || origItemExtraInfo.length() == 0)
                {
                    printToFile.printDebugLine(Utils.readErrMsg(), 3);
                    printToFile.printDebugLine("Failed to get from instanceProps." + itemExtraInfoKey + " from item JSON file " + itemTSID, 3);
                    return false;
                }

                if (origItemExtraInfo.length() == 0)
                {
                    return false;
                }
                break;
   
            case "wall_button":
                // Read in the dir field 
                itemExtraInfoKey = "dir";
                origItemExtraInfo = Utils.readJSONString(itemJSON, itemExtraInfoKey, true);
                if (!Utils.readOkFlag() || origItemExtraInfo.length() == 0)
                {
                    printToFile.printDebugLine(Utils.readErrMsg(), 3);
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
                itemExtraInfoKey = "dir";              
                if (origItemX > 0)
                {
                    // stone is on RHS of screen - so set to 'left'
                    origItemExtraInfo = "left";
                }
                else
                {
                    // stone is on LHS of screen - so set to 'right'
                    origItemExtraInfo = "right";
                }
                
                if (!Utils.setJSONString(itemJSON, itemExtraInfoKey, origItemExtraInfo))
                {
                    // Error occurred - fail
                    printToFile.printDebugLine(Utils.readErrMsg(), 3);
                    printToFile.printDebugLine("Failed to set dir field in item JSON file " + itemTSID, 3);
                    return false;
                }
                
                // As have just added/changed key - keep track of this expected change to file length
                sizeDiffJSONCalc += Utils.readByteCount();
                printToFile.printDebugLine("Updated JSON file size difference after set dir field is " + sizeDiffJSONCalc, 1);
                
                // Also need to check that there is a state field set - don't report an error if missing
                String stateValue = Utils.readJSONString(itemJSON, "state", false);
                if (!Utils.readOkFlag() || stateValue.length() == 0)
                {
                    // It isn't present - so insert
                    if (!Utils.setJSONString(itemJSON, "state", "1"))
                    {
                        // Error occurred - fail
                        printToFile.printDebugLine(Utils.readErrMsg(), 3);
                        printToFile.printDebugLine("Failed to set state field in item JSON file " + itemTSID, 3);
                        return false;
                    }
                    // As have just added key - keep track of this expected change to file length
                    sizeDiffJSONCalc += Utils.readByteCount();
                    printToFile.printDebugLine("Updated JSON file size difference after insert state field is " + sizeDiffJSONCalc, 1);
                }
                             
                // Show JSON file needs saving after processing done
                saveChangedJSONfile = true;
                
                // Set flag so give meaningful msg at end of processing
                alreadySetDirField = true;
                break;
                                
            default:
                // Nothing to extract
                break;
         }

        return true;
    }
    
    boolean setItemInfoInJSON()
    {
        JSONObject instanceProps;
        // Saving information determined from the snap. Typically information which affects the 
        // appearance of an item e.g. the type of quoin or dirtpile    
        if (itemClassTSID.indexOf("npc_shrine_", 0) == 0)
        {
            // Shorter code rather than adding in class_tsid for all 30 shrines
            if (!newItemExtraInfo.equals("right"))
            {
                // Should never happen
                printToFile.printDebugLine("Dir field in shrine " + itemTSID + " is not set to right - is set to " + newItemExtraInfo, 3);
                return false;
            }
            
            // Dir set to right has already been saved in the json and the flag set. So nothing to do
            return true;
        }
        else if (!itemClassTSID.equals("quoin") && newItemExtraInfo.equals(origItemExtraInfo)) 
        {
            // None of the additional information has been changed from the original. 
            // So just return without setting the flag.
            // For quoins this check is done later once the classname has been determined.
            return true;
        }
        
        // Only reach here if the information field has changed for non-quoins. 
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
                // Read in the instanceProps array - failure is always an error
                instanceProps = Utils.readJSONObject(itemJSON, "instanceProps", true);
                if (!Utils.readOkFlag())
                {
                    printToFile.printDebugLine(Utils.readErrMsg(), 3);
                    printToFile.printDebugLine("Failed to get instanceProps from item JSON file " + itemTSID, 3);
                    return false;
                }

                if (itemClassTSID.equals("quoin"))
                {
                    // Now need to set up the type and class_name field in the JSON structure
                    // First determine the default quoin fields assocated with this type
                    QuoinFields quoinInstanceProps = new QuoinFields();                   
                    if (!quoinInstanceProps.defaultFields(streetInfoArray.get(streetBeingProcessed).readHubID(), streetInfoArray.get(streetBeingProcessed).readStreetTSID(), newItemExtraInfo))
                    {
                        printToFile.printDebugLine("Error defaulting fields in quoin instanceProps structure", 3);
                        return false;
                    }
                    newItemClassName = quoinInstanceProps.readClassName();
                    
                    if (newItemClassName.equals(origItemClassName))
                    {
                        // Nothing to save so return without setting flag
                        return true;
                    }
                    
                    // Now save the fields in instanceProps
                    if (!Utils.setJSONString(instanceProps, "type", newItemExtraInfo))
                    {
                        printToFile.printDebugLine(Utils.readErrMsg(), 3);
                        return false;
                    }
                    sizeDiffJSONCalc += Utils.readByteCount();
                    //printToFile.printDebugLine("Updated JSON file size difference after change type field is " + sizeDiffJSONCalc, 1);
                                              
                    if (!Utils.setJSONString(instanceProps, "class_name", newItemClassName))
                    {
                        printToFile.printDebugLine(Utils.readErrMsg(), 3);
                        return false;
                    }
                    sizeDiffJSONCalc += Utils.readByteCount();
                    //printToFile.printDebugLine("Updated JSON file size difference after change class_name field is " + sizeDiffJSONCalc, 1);
                    
                    if (!Utils.setJSONInt(instanceProps, "respawn_time", quoinInstanceProps.readRespawnTime()))
                    {
                        printToFile.printDebugLine(Utils.readErrMsg(), 3);
                        return false;
                    }
                    sizeDiffJSONCalc += Utils.readByteCount();
                    //printToFile.printDebugLine("Updated JSON file size difference after change respawn_time field is " + sizeDiffJSONCalc, 1);
                    
                    if (!Utils.setJSONString(instanceProps, "is_random", quoinInstanceProps.readIsRandom()))
                    {
                        printToFile.printDebugLine(Utils.readErrMsg(), 3);
                        return false;
                    }
                    sizeDiffJSONCalc += Utils.readByteCount();
                    
                    if (!Utils.setJSONString(instanceProps, "benefit", quoinInstanceProps.readBenefit()))
                    {
                        printToFile.printDebugLine(Utils.readErrMsg(), 3);
                        return false;
                    }
                    sizeDiffJSONCalc += Utils.readByteCount();
                    
                    if (!Utils.setJSONString(instanceProps, "benefit_floor", quoinInstanceProps.readBenefitFloor()))
                    {
                        printToFile.printDebugLine(Utils.readErrMsg(), 3);
                        return false;
                    }
                    sizeDiffJSONCalc += Utils.readByteCount();
                    
                    if (!Utils.setJSONString(instanceProps, "benefit_ceil", quoinInstanceProps.readBenefitCeiling()))
                    {
                        printToFile.printDebugLine(Utils.readErrMsg(), 3);
                        return false;
                    }
                    sizeDiffJSONCalc += Utils.readByteCount();
                    
                    if (newItemExtraInfo.equals("favor"))
                    {
                        if (!Utils.setJSONString(instanceProps, "giant", quoinInstanceProps.readGiant()))
                        {
                            printToFile.printDebugLine(Utils.readErrMsg(), 3);
                            return false;
                        }
                        sizeDiffJSONCalc += Utils.readByteCount();
                    }
                                   
                    printToFile.printDebugLine("Updated JSON file size difference after change all quoin fields field is " + sizeDiffJSONCalc, 1);
                }
                else 
                {                            
                    if (!Utils.setJSONString(instanceProps, itemExtraInfoKey, newItemExtraInfo))
                    {
                        printToFile.printDebugLine(Utils.readErrMsg(), 3);
                        return false;
                    }
                    sizeDiffJSONCalc += Utils.readByteCount();
                    printToFile.printDebugLine("Updated JSON file size difference after change " + itemExtraInfoKey + " field is " + sizeDiffJSONCalc, 1);                
                }
                // Don't think I need to set the items array as well???
                break;
   
            case "wall_button":
            case "visiting_stone":
                if (!Utils.setJSONString(itemJSON, itemExtraInfoKey, newItemExtraInfo))
                {
                    printToFile.printDebugLine(Utils.readErrMsg(), 3);
                    return false;
                }
                sizeDiffJSONCalc += Utils.readByteCount();
                printToFile.printDebugLine("Updated JSON file size difference after change " + itemExtraInfoKey + " field is " + sizeDiffJSONCalc, 1);                
                break;
                         
            case "npc_sloth":
                printToFile.printDebugLine("Not sure about sloth - check to see if both dir and instanceProps.dir are set to be the same " + itemTSID, 3);
                return false;
                       
            case "marker_qurazy":
            case "trant_bean":
            case "trant_egg":
            case "trant_bubble":
            case "trant_gas":
            case "trant_spice":
            case "trant_fruit":
            case "paper_tree":
            case "rock_beryl_1":
            case "rock_beryl_2":
            case "rock_beryl_3":
            case "rock_dullite_1":
            case "rock_dullite_2":
            case "rock_dullite_3":
            case "rock_sparkly_1":
            case "rock_sparkly_2":
            case "rock_sparkly_3":
            case "rock_metal_1":
            case "rock_metal_2":
            case "rock_metal_3":
            case "peat_1":
            case "peat_2":
            case "peat_3":            
            case "patch":            
            case "patch_dark":
            case "sloth_knocker":
            case "party_atm":
            case "race_ticket_dispenser":
            case "subway_gate":
            case "subway_map":
            case "bag_notice_board":
                // Don't have any additional information such as 'dir' - so return
                return true;
                 
            default:
                // Should never reach here
                printToFile.printDebugLine("Unrecognised classTSID in setItemInfoInJson - " + itemClassTSID, 3);
                return false;

         }

        // Show JSON file needs saving after processing done - only reach this point if changes needed to be saved
        saveChangedJSONfile = true;
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
            printToFile.printDebugLine("Failed to open samples.json file", 3);
            return false;
        }
        
        values = Utils.readJSONArray(json, "fragments", true);
        if (!Utils.readOkFlag())
        {
            printToFile.printDebugLine(Utils.readErrMsg(), 3);
            printToFile.printDebugLine("Failed to read fragments array in samples.json file", 3);
            return false;
        }
        
        for (int i = 0; i < values.size(); i++) 
        {
            fragment = values.getJSONObject(i);
            String tsid = Utils.readJSONString(fragment, "class_tsid", true);
            if (!Utils.readOkFlag() || tsid.length() == 0)
            {
                printToFile.printDebugLine(Utils.readErrMsg(), 3);
                printToFile.printDebugLine("Failed to read class_tsid in fragments array in samples.json file", 3);
                return false;
            }
            String info = Utils.readJSONString(fragment, "info", true);
            // Is OK if set to ""
            if (!Utils.readOkFlag())
            {
                printToFile.printDebugLine(Utils.readErrMsg(), 3);
                printToFile.printDebugLine("Failed to read info in fragments array in samples.json file", 3);
                return false;
            }
            
            if ((tsid.equals(itemClassTSID)) && (info.equals(origItemExtraInfo)))
            {
                // Found fragment for this item
                fragOffsetX = Utils.readJSONInt(fragment, "offset_x", true);
                if (!okFlag)
                {
                    printToFile.printDebugLine(Utils.readErrMsg(), 3);
                    printToFile.printDebugLine("Failed to read offset_x in fragments array in samples.json file", 3);
                    return false;
                }
                fragOffsetY = Utils.readJSONInt(fragment, "offset_y", true);
                if (!okFlag)
                {
                    printToFile.printDebugLine(Utils.readErrMsg(), 3);
                    printToFile.printDebugLine("Failed to read offset_y in fragments array in samples.json file", 3);
                    return false;
                }
                return true;
            }
        }
        
        // If we reach here then missing item from json file
        printToFile.printDebugLine("Missing class_tsid " + itemClassTSID + " and/or info field <" + origItemExtraInfo + "> in samples.json", 3);
        return false;
    }
       
    public void searchUsingReference()
    {

        if (fragFind.readSearchDone())
        {
            String s;
            
            // Search has completed - either run out of streets or was successful
            newItemX = fragFind.readNewItemX();
            newItemY = fragFind.readNewItemY();
            newItemExtraInfo = fragFind.readNewItemExtraInfo();
            
            if (!fragFind.readItemFound() && newItemX == missCoOrds)
            {
                // Item wasn't found on the snaps (quoins handled differently)
                // So don't update the JSON at all in this case (even though inserted dir in shrines for example earlier) - discard any changes
                s = "Item NOT FOUND (";
                s = s + itemTSID + ") " + itemClassTSID + " x,y = " + origItemX + "," + origItemY;             
                if (origItemExtraInfo.length() > 0)
                {
                    s = s + " " + itemExtraInfoKey + " = " + origItemExtraInfo;
                }
                printToFile.printOutputLine(s);
                printToFile.printDebugLine(s, 2);

                itemFinished = true;
                return;
            }
            
            // The Utils functions will update the expected change in length of JSON file counter
            // automatically          
            if (newItemX != origItemX)
            {
                if (!Utils.setJSONInt(itemJSON, "x", newItemX))
                {
                    printToFile.printDebugLine(Utils.readErrMsg(), 3);
                    failNow = true;
                    return;
                }
                // Show JSON file needs saving after processing done
                saveChangedJSONfile = true;
            }
            
            if (newItemY != origItemY)
            {
                if (!Utils.setJSONInt(itemJSON, "y", newItemY))
                {
                    printToFile.printDebugLine(Utils.readErrMsg(), 3);
                    failNow = true;
                    return;
                }
                // Show JSON file needs saving after processing done
                saveChangedJSONfile = true;
            }
            
            // Sets up the special fields e.g. 'dir' or 'type' fields based on ExtraInfo field
            // Only do this if not doing an x,y_only kind of search - which leaves the special fields
            // as originally set
            if (!configInfo.readChangeXYOnly())
            {
                if (!setItemInfoInJSON())
                {
                        failNow = true;
                        return;
                }
            }

            if (saveChangedJSONfile)
            {
                 s = "Changed item (" + itemTSID + ") " + itemClassTSID;
                if (newItemExtraInfo.length() > 0)
                {
                    if (newItemExtraInfo.equals(origItemExtraInfo) && newItemClassName.equals(origItemClassName))
                    {
                        s = s + " " + itemExtraInfoKey + " = " + origItemExtraInfo;
                        if (itemClassTSID.equals("quoin"))
                        {
                            s = s + " (" + origItemClassName + ")";
                        }
                    }
                    else
                    {
                        s = s + " changed " + itemExtraInfoKey + " = " + origItemExtraInfo;
                        if (itemClassTSID.equals("quoin"))
                        {
                            s = s + " (" + origItemClassName + ")";
                        }
                        s = s + " to " + newItemExtraInfo;
                        if (itemClassTSID.equals("quoin"))
                        {
                            s = s + " (" + newItemClassName + ")";
                        }
                    }
                }
                if ((origItemX == newItemX) && (origItemY == newItemY))
                {
                    s = s + " with unchanged x,y = " + origItemX + "," + origItemY;
                }
                else
                {
                    s = s + " with changed x,y = " + origItemX + "," + origItemY + " to " + newItemX + "," + newItemY;
                }
                
                if (alreadySetDirField)
                {
                    s = s + " (inserting/updating  dir field in JSON file)";
                }
                printToFile.printOutputLine(s);
                printToFile.printDebugLine(s, 2);
                
                // Write the JSON file out to temporary place before checking that the new file length = old one plus calculated diff
                try
                {
                    saveJSONObject(itemJSON, dataPath("") + "/temp/" + itemTSID + ".json");
                }
                catch(Exception e)
                {
                    println(e);
                    printToFile.printDebugLine("Error writing " + itemTSID + ".json file to " + dataPath("") + "/temp/", 3);
                    printToFile.printOutputLine("ERROR WRITING " + itemTSID + ".json file to " + dataPath("") + "/temp/");
                    failNow = true;
                    return;
                }
                
                // Double check the file length is as expected               
                sizeOfFinalJSON = sizeOfJSONFile(dataPath("") + "/temp/" + itemTSID + ".json");               
                if (sizeOfFinalJSON != (sizeOfOriginalJSON + sizeDiffJSONCalc))
                {
                    s = "Unexpected size difference in new " + itemTSID + ".json file: Original file = " + sizeOfOriginalJSON + 
                    " bytes, expected change in bytes =  " + sizeDiffJSONCalc + " New file = " + sizeOfFinalJSON + " bytes";
                    printToFile.printDebugLine(s, 3);
                    printToFile.printOutputLine(s);
                    failNow = true;
                    return;
                }
                
                // File is valid so write to persdata and then delete the one in the temporary directory
                if (writeJSONsToPersdata)
                {
                    try
                    {
                        saveJSONObject(itemJSON, configInfo.readPersdataPath() + "/" + itemTSID + ".json");
                    }    
                    catch(Exception e)
                    {
                        println(e);
                        printToFile.printDebugLine("Error writing " + itemTSID + ".json file to " + configInfo.readPersdataPath(), 3);
                        printToFile.printOutputLine("ERROR WRITING " + itemTSID + ".json file to " + configInfo.readPersdataPath());
                        failNow = true;
                        return;
                    }
                    
                    printToFile.printDebugLine("SUCCESS WRITING " + itemTSID + ".json file to " + configInfo.readPersdataPath(), 3);
                    printToFile.printOutputLine("SUCCESS WRITING " + itemTSID + ".json file to " + configInfo.readPersdataPath());
                    
                    // Now remove the file from the temporary directory.

                    File f = new File(dataPath("") + "/temp/" + itemTSID + ".json");
                    if (f.exists())
                    {
                        f.delete();
                    }
                }
            }
            else
            {
                if (fragFind.readItemFound())
                {
                    s = "Unchanged (found) item (";
                }
                else
                {
                    s = "Unchanged (not found) item (";
                }
                s = s + itemTSID + ") " + itemClassTSID + " x,y = " + origItemX + "," + origItemY;             
                if (origItemExtraInfo.length() > 0)
                {
                    s = s + " " + itemExtraInfoKey + " = " + origItemExtraInfo;
                    if (itemClassTSID.equals("quoin"))
                    {
                        s = s + " (" + origItemClassName + ")";
                    }
                }
                printToFile.printOutputLine(s);
                printToFile.printDebugLine(s, 2);
            }
            itemFinished = true;
                     
            // If an item was found, then delay the image for a second before continuing - for debug onl
            if (doDelay && newItemX != missCoOrds)
            {
                delay(1000);
            }
        }
        else
        {
            fragFind.searchForFragment();
        }
    }
    
        
    int sizeOfJSONFile (String fname)
    {
        String lines[] = loadStrings(fname);
        int fnameLength = 0;
        String strippedLine = "";
        
        okFlag = true;
        
        for (int i = 0 ; i < lines.length; i++) 
        {
            strippedLine = lines[i];
            // strip of trailing/leading white space
            strippedLine = strippedLine.trim();
            fnameLength += strippedLine.length();
        }
        return fnameLength;
    }
    
    // Simple functions to read/set variables
    public boolean readItemFinished()
    {
        return itemFinished;
    }
    
    public ArrayList<PNGFile> readItemImageArray()
    {
        return itemImageArray;
    }
    
    public PNGFile readItemImage(int n)
    {
        if (n < itemImageArray.size())
        {
            return itemImageArray.get(n);
        }
        else
        {
            return null;
        }
        
    }
       
    public boolean loadItemImages()
    {
        for (int i = 0; i < itemImageArray.size(); i++)
        {
            if (!itemImageArray.get(i).loadPNGImage())
            {
                return false;
            }
        }
        return true;
    }
    
    public boolean unloadItemImages()
    {
        for (int i = 0; i < itemImageArray.size(); i++)
        {
            itemImageArray.get(i).unloadPNGImage();
        }
        return true;
    }   
    
    public String readOrigItemExtraInfo()
    {
        return origItemExtraInfo;
    }
    
    public int readOrigItemX()
    {
        return origItemX;
    }
    public int readOrigItemY()
    {
        return origItemY;
    }
    public String readItemClassTSID()
    {
        return itemClassTSID;
    }
    public String readItemTSID()
    {
        return itemTSID;
    }
    
    public int readFragOffsetX()
    {
        return fragOffsetX;
    }
    public int readFragOffsetY()
    {
        return fragOffsetY;
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