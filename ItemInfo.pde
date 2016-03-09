class ItemInfo
{
    boolean okFlag;
    boolean itemFinished; // searched the street snap for this item - could be success or failure
    
    boolean skipThisItem; // Item we are not scanning for
    boolean itemFound;
    
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
      
    FragmentFind fragFind;
    
    // Contains the item fragments used to search the snap
    ArrayList<PNGFile> itemImages;
    
    // ARE THESE EVER USED HERE?
    //int itemImageBeingUsed;
    //int streetImageBeingUsed;
           
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
        
        skipThisItem = false;
        itemFound = false;
        saveChangedJSONfile = false;
        alreadySetDirField = false;
        
        initItemVars();

        itemImages = null;

        itemTSID = Utils.readJSONString(item, "tsid", true);
        if (!Utils.readOkFlag() || itemTSID.length() == 0)
        {
            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
            okFlag = false;
        }
        else
        {
            printToFile.printDebugLine(this, "ItemInfo constructor item tsid is " + itemTSID + "(" + item.getString("label") + ")", 2);
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
                printToFile.printDebugLine(this, "Missing file - " + itemFileName, 3);
                return false;
            }
        } 
                
        printToFile.printDebugLine(this, "Item file name is " + itemFileName, 2); 

        // Now read the item JSON file
        itemJSON = null;
        try
        {
            itemJSON = loadJSONObject(itemFileName);
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine(this, "Failed to load the item json file " + itemFileName, 3);
            return false;
        }
        
        printToFile.printDebugLine(this, "Loaded item JSON OK", 1);
        
        // Make a copy of the original JSON - so that is can be compared against the final one              
        try
        {
            saveJSONObject(itemJSON, dataPath("") + "/OrigJSONs/" + itemTSID + ".json");
        }    
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine(this, "Error writing " + itemTSID + ".json file to " + dataPath("") + "/OrigJSONs/", 3);
            return false;
        }
        
        // These fields are always present - so if missing = error
        origItemX = Utils.readJSONInt(itemJSON, "x", true);
        if (!Utils.readOkFlag())
        {
            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
            return false;
        }
        origItemY = Utils.readJSONInt(itemJSON, "y", true);
        if (!Utils.readOkFlag())
        {
            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
            return false;
        }
        itemClassTSID = Utils.readJSONString(itemJSON, "class_tsid", true);
        if (!Utils.readOkFlag() || itemClassTSID.length() == 0)
        {
            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
            return false;
        }
        
        // Before proceeding any further need to check if this is an item we are
        // scanning for - skip if not
        if (!validItemToCheckFor())
        {
            // NB - safer to keep it in the item array, and check this flag
            // before doing any actual checking/writing
            printToFile.printDebugLine(this, "Skipping item (" + itemTSID + ") class_tsid " + itemClassTSID, 1);
            skipThisItem = true;
            return true;
        }
                          
        // Populate the info field for some items e.g. quoins, dirt etc
        if (!extractItemInfoFromJson())
        {
            // Error populating info field
            printToFile.printDebugLine(this, "Failed to extract info for class_tsid " + itemClassTSID, 3);
            return false;
        }
                
        // Point to the item images which will be used to search the snap
        if (!getThisItemImages())
        {
            printToFile.printDebugLine(this, "Error getting item images for class_tsid " + itemClassTSID, 3); 
            return false;
        }      
        
        if (origItemExtraInfo.length() > 0)
        {
            printToFile.printDebugLine(this, "class_tsid " + itemClassTSID + " info = <" + origItemExtraInfo + "> with x,y " + str(origItemX) + "," + str(origItemY), 2); 
        }
        else
        {
            printToFile.printDebugLine(this, "class_tsid " + itemClassTSID + " with x,y " + str(origItemX) + "," + str(origItemY), 2); 
        }
        // print out item images that have been loaded
        for (int i = 0; i < itemImages.size(); i++)
        {
            //printToFile.printDebugLine(this, "Can see item image " + itemImages.get(i).PNGImageName, 1);
        }
        
        // Initialise for the item to be searched for
        //itemImageBeingUsed = 0;
        
        if (!resetReadyForNewItemSearch())
        {
            return false;
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
            case "subway_gate":
            case "subway_map":
            case "bag_notice_board":
                return true;
                
            default:
                // Unexpected class tsid - so skip the item
                printToFile.printDebugLine(this, "Skipping item " + itemTSID + " class tsid " + itemClassTSID, 2);
                return false;
         }
    }
    
    boolean getThisItemImages()
    {
        // Using the item class_tsid, get the pointer to the images for this item
        // Depending on the item might need to tweak the order of items - TO DO???? 
        
        if ((itemClassTSID.indexOf("trant", 0) == 0) || (itemClassTSID.indexOf("wood", 0) == 0))
        {
            itemImages = allItemImages.getItemImages("trees");
        }
        else
        {
            itemImages = allItemImages.getItemImages(itemClassTSID);
        }
        
        if (itemImages == null)
        {
            // return error
            printToFile.printDebugLine(this, "Null itemImages returned for " + itemClassTSID, 3);
            return false;
        }
        
        // Reorder some of the fields so searching on the existing version of the item first
        // Only needed for visiting stones, trees, xy_only quoins

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
                printToFile.printDebugLine(this, "Failed to read dir field from shrine JSON file " + itemTSID, 2);
                
                if (!Utils.setJSONString(itemJSON, itemExtraInfoKey, "right"))
                {
                    // Error occurred - fail
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    printToFile.printDebugLine(this, "Failed to insert new dir field in item JSON file " + itemTSID, 3);
                    return false;
                }

                // save this new dir field - will need to load the shrine picture
                origItemExtraInfo = "right";
                
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
                printToFile.printDebugLine(this, "Unexpected dir = left field in shrine JSON file  " + itemTSID, 3);
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
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    printToFile.printDebugLine(this, "Failed to get instanceProps from item JSON file " + itemTSID, 3);
                    return false;
                }
                
                if (itemClassTSID.equals("quoin"))
                {
                    // Save the class_name field for this item - only used when reporting original/changed quoin at end
                    origItemClassName = Utils.readJSONString(instanceProps, "class_name", true);
                    if (!Utils.readOkFlag() || origItemClassName.length() == 0)
                    {
                        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                        printToFile.printDebugLine(this, "Failed to get instanceProps.class_name" + itemExtraInfoKey + " from item JSON file " + itemTSID, 3);
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
                    printToFile.printDebugLine(this, "Trying to read unexpected field from instanceProps for item class " + itemClassTSID, 3);
                    return false;
                }
                
                // Now read in the additional information using the key
                origItemExtraInfo = Utils.readJSONString(instanceProps, itemExtraInfoKey, true);
                if (!Utils.readOkFlag() || origItemExtraInfo.length() == 0)
                {
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    printToFile.printDebugLine(this, "Failed to get from instanceProps." + itemExtraInfoKey + " from item JSON file " + itemTSID, 3);
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
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    printToFile.printDebugLine(this, "Failed to read dir field from item JSON file " + itemTSID, 3);
                    return false;
                }
                break;
                         
            case "npc_sloth":
                printToFile.printDebugLine(this, "Not sure about sloth - check to see if both dir and instanceProps.dir are set to be the same " + itemTSID, 3);
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
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    printToFile.printDebugLine(this, "Failed to set dir field in item JSON file " + itemTSID, 3);
                    return false;
                }
                
                // Also need to check that there is a state field set - don't report an error if missing
                String stateValue = Utils.readJSONString(itemJSON, "state", false);
                if (!Utils.readOkFlag() || stateValue.length() == 0)
                {
                    // It isn't present - so insert
                    if (!Utils.setJSONString(itemJSON, "state", "1"))
                    {
                        // Error occurred - fail
                        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                        printToFile.printDebugLine(this, "Failed to set state field in item JSON file " + itemTSID, 3);
                        return false;
                    }
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
                printToFile.printDebugLine(this, "Dir field in shrine " + itemTSID + " is not set to right - is set to " + newItemExtraInfo, 3);
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
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    printToFile.printDebugLine(this, "Failed to get instanceProps from item JSON file " + itemTSID, 3);
                    return false;
                }

                if (itemClassTSID.equals("quoin"))
                {
                    // Now need to set up the type and class_name field in the JSON structure
                    // First determine the default quoin fields assocated with this type
                    QuoinFields quoinInstanceProps = new QuoinFields();                   
                    if (!quoinInstanceProps.defaultFields(streetInfo.readHubID(), streetInfo.readStreetTSID(), newItemExtraInfo))
                    {
                        printToFile.printDebugLine(this, "Error defaulting fields in quoin instanceProps structure", 3);
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
                        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                        return false;
                    }
                                            
                    if (!Utils.setJSONString(instanceProps, "class_name", newItemClassName))
                    {
                        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                        return false;
                    }
                    
                    if (!Utils.setJSONInt(instanceProps, "respawn_time", quoinInstanceProps.readRespawnTime()))
                    {
                        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                        return false;
                    }
                    
                    if (!Utils.setJSONString(instanceProps, "is_random", quoinInstanceProps.readIsRandom()))
                    {
                        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                        return false;
                    }
                    
                    if (!Utils.setJSONString(instanceProps, "benefit", quoinInstanceProps.readBenefit()))
                    {
                        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                        return false;
                    }
                    
                    if (!Utils.setJSONString(instanceProps, "benefit_floor", quoinInstanceProps.readBenefitFloor()))
                    {
                        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                        return false;
                    }
                    
                    if (!Utils.setJSONString(instanceProps, "benefit_ceil", quoinInstanceProps.readBenefitCeiling()))
                    {
                        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                        return false;
                    }
                    
                    if (newItemExtraInfo.equals("favor"))
                    {
                        if (!Utils.setJSONString(instanceProps, "giant", quoinInstanceProps.readGiant()))
                        {
                            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                            return false;
                        }
                    }                    
                                   
                }
                else 
                {                            
                    if (!Utils.setJSONString(instanceProps, itemExtraInfoKey, newItemExtraInfo))
                    {
                        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                        return false;
                    }             
                }
                break;
   
            case "wall_button":
            case "visiting_stone":
                if (!Utils.setJSONString(itemJSON, itemExtraInfoKey, newItemExtraInfo))
                {
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    return false;
                }          
                break;
                         
            case "npc_sloth":
                printToFile.printDebugLine(this, "Not sure about sloth - check to see if both dir and instanceProps.dir are set to be the same " + itemTSID, 3);
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
                printToFile.printDebugLine(this, "Unrecognised classTSID in setItemInfoInJson - " + itemClassTSID, 3);
                return false;

         }

        // Show JSON file needs saving after processing done - only reach this point if changes needed to be saved
        saveChangedJSONfile = true;
        return true;
    } 
        
    public boolean saveItemChanges()
    {
        // Called once all the street snaps have been searched for this item
        String s;
        File f;

        // Need to handle the missing items first
        if (newItemX == missCoOrds)
        {
            if (!itemClassTSID.equals("quoin"))
            {
                // For all non-quoins, items that are not found/skipped will not cause any file changes - so clean up and return here
                s = "No changes written - ";
                if (skipThisItem)
                {
                    s = s + "SKIPPED item (";
                }
                else if (!itemFound)
                {
                    s = s + "MISSING item (";
                }
                else
                {
                    s = s + "UNRECOGNISED REASON (";
                }
    
                s = s + itemTSID + ") " + itemClassTSID + " x,y = " + origItemX + "," + origItemY;             
                if (origItemExtraInfo.length() > 0)
                {
                    s = s + " " + itemExtraInfoKey + " = " + origItemExtraInfo;
                }
                printToFile.printOutputLine(s);
                printToFile.printDebugLine(this, s, 2);         
                if (!configInfo.readDebugSaveOrigAndNewJSONs())
                {
                    // Now remove the file from the temporary directories.
                    f = new File(dataPath("") + "/OrigJSONs/" + itemTSID + ".json");
                    if (f.exists())
                    {
                        f.delete();
                    }
                }
                // nothing else to do for these missing/skipped items
                return true;
            }
            else
            {
                 // Reset the quoin type if the x,y was not found - set to mystery, with the existing x,y
                 printToFile.printDebugLine(this, "Set missing quoin " + itemTSID + " to be type = mystery", 1);
                newItemX = origItemX;
                newItemY = origItemY;
                newItemExtraInfo = "mystery";
                
                // OK to then carry on in this function
            }
        }    

        // Item has been found or has been reset as mystery quoin - so changes to write
        if (newItemX != origItemX)
        {
            if (!Utils.setJSONInt(itemJSON, "x", newItemX))
            {
                printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                return false;
            }
            // Show JSON file needs saving after processing done
            saveChangedJSONfile = true;
        }
            
        if (newItemY != origItemY)
        {
            if (!Utils.setJSONInt(itemJSON, "y", newItemY))
            {
                printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                return false;
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
                return false;
            }
        }

        // Note that the saveChangedJSONFile flag may have been set earlier when the JSON file was read in and dir/state fields
        // were found to be missing, and so added to the item JSON in advance of the searches happening
        if (saveChangedJSONfile)
        {
            // First tell the user what has changed
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
            printToFile.printDebugLine(this, s, 2);
                
            // Write the JSON file out to temporary place before checking that the new file length = old one plus calculated diff
            try
            {
                saveJSONObject(itemJSON, dataPath("") + "/NewJSONs/" + itemTSID + ".json");
            }
            catch(Exception e)
            {
                println(e);
                printToFile.printDebugLine(this, "Error writing " + itemTSID + ".json file to " + dataPath("") + "/NewJSONs/", 3);
                printToFile.printOutputLine("ERROR WRITING " + itemTSID + ".json file to " + dataPath("") + "/NewJSONs/");
                return false;
            }
                
            // Double check the new file is reasonable - has to be done by eye by looking at output from a diff comparison tool
            JSONDiff jsonDiff = new JSONDiff(itemTSID, dataPath("") + "/OrigJSONs/" + itemTSID + ".json", dataPath("") + "/NewJSONs/" + itemTSID + ".json");
            if (!jsonDiff.compareJSONFiles())
            {
                // Error during the diff process
                // Display all the messages and then return
                jsonDiff.displayInfoMsg();
                return false;
            }
            // Displays message to user in both debug/output files
            jsonDiff.displayInfoMsg();
                                
            // Write to persdata and then delete the one in the temporary directory
            if (writeJSONsToPersdata)
            {
                try
                {
                    saveJSONObject(itemJSON, configInfo.readPersdataPath() + "/" + itemTSID + ".json");
                }    
                catch(Exception e)
                {
                    println(e);
                    printToFile.printDebugLine(this, "Error writing " + itemTSID + ".json file to " + configInfo.readPersdataPath(), 3);
                    printToFile.printOutputLine("ERROR WRITING " + itemTSID + ".json file to " + configInfo.readPersdataPath());
                    return false;
                }
                
                printToFile.printDebugLine(this, "SUCCESS WRITING " + itemTSID + ".json file to " + configInfo.readPersdataPath(), 3);
                printToFile.printOutputLine("SUCCESS WRITING " + itemTSID + ".json file to " + configInfo.readPersdataPath());
            }
         } // end if changes to save to JSON file
         else
         {
             // No changes to make to JSON - either because item found (and matches existing file) or not found
            if (newItemX != missCoOrds)
            {
                    s = "Matches existing item (";
            }
            else
            {
                s = "No changes - not found item ERROR SHOULD NOT REACH THIS LEG (";
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
            printToFile.printDebugLine(this, s, 2);
        }
        
        // Now clean up the copies of the old/new JSONs if they exist
        // If in debug mode then this step is skipped
        if (!configInfo.readDebugSaveOrigAndNewJSONs())
        {
            // Now remove the file from the temporary directories.
            f = new File(dataPath("") + "/OrigJSONs/" + itemTSID + ".json");
            if (f.exists())
            {
                f.delete();
            }
                
            f = new File(dataPath("") + "/NewJSONs/" + itemTSID + ".json");
            if (f.exists())
            {
                f.delete();
            }
        }
        
        
        return true;
    }
       
    public boolean searchSnapForImage()
    { 
        if (fragFind.readSearchDone())
        {
            String s;
            
            // Search has completed - for this item on this street
            if (fragFind.readItemFound())
            {
                // Item was successfully found on the street
                if ((itemClassTSID.equals("quoin") || itemClassTSID.equals("marker_qurazy")) && newItemX != missCoOrds)
                {
                    // This is the 2nd time or more that we've found this quoin/QQ
                    // Only save the Y-cord if lower than the one we already have
                    if (newItemY < fragFind.readNewItemY())
                    {
                        s = "SEARCH DONE Resetting y-value for " + itemTSID + " " + itemClassTSID + " " + newItemExtraInfo + " from " + newItemY + " to " + fragFind.readNewItemY();
                        printToFile.printDebugLine(this, s, 2);
                        
                        newItemY = fragFind.readNewItemY();
                    }
                    else
                    {
                        s = "SEARCH DONE Ignoring y-value for " + itemTSID + " " + itemClassTSID + " " + newItemExtraInfo + " remains at " + newItemY + "(new = " + fragFind.readNewItemY() + ")";
                        printToFile.printDebugLine(this, s, 1);
                    }
                    // continue on to next snap for quoins/QQ
                }
                else
                {
                    // Enter here for non quoins/QQ or for quoins/QQ when first found
                    // Save the information
                    newItemX = fragFind.readNewItemX();
                    newItemY = fragFind.readNewItemY();
                    newItemExtraInfo = fragFind.readNewItemExtraInfo();
                    
                    // For all non-quoins/QQ, we only need to do the search once, so on future street snaps, skip this item
                    if (!itemClassTSID.equals("quoin") && !itemClassTSID.equals("marker_qurazy"))
                    {
                        itemFound = true;
                        s = "SEARCH FOUND (skip in future) (";
                    }
                    else
                    {
                        s = "SEARCH FOUND (but keep looking) (";
                    }
                    
                    s = s + itemTSID + ") " + itemClassTSID + " x,y = " + newItemX + "," + newItemY;             
                    if (newItemExtraInfo.length() > 0)
                    {
                        s = s + " " + itemExtraInfoKey + " = " + newItemExtraInfo;
                        if (itemClassTSID.equals("quoin"))
                        {
                            s = s + " (" + newItemClassName + ")";
                        }
                    }
                    s = s + " was x,y = " + origItemX + "," + origItemY;;             
                    if (origItemExtraInfo.length() > 0)
                    {
                        s = s + " " + itemExtraInfoKey + " = " + origItemExtraInfo;
                        if (itemClassTSID.equals("quoin"))
                        {
                            s = s + " (" + origItemClassName + ")";
                        }
                    }
                    printToFile.printOutputLine(s);
                    printToFile.printDebugLine(this, s, 2);
                }
            }
            else
            {
                // Item was not found on the street
                // So need to go on to the next item on this street
                s = "SEARCH FAILED " + itemTSID + ") " + itemClassTSID + " x,y = " + origItemX + "," + origItemY;             
                if (origItemExtraInfo.length() > 0)
                {
                    s = s + " " + itemExtraInfoKey + " = " + origItemExtraInfo;
                    if (itemClassTSID.equals("quoin"))
                    {
                        s = s + " (" + origItemClassName + ")";
                    }
                }
                printToFile.printDebugLine(this, s, 1);
                

                
            }
            itemFinished = true;
            
            // Clear the flag ready for when we come around again
            

             // If an item was found, then delay the image for a second before continuing - for debug onl
            if (doDelay && newItemX != missCoOrds)
            {
                delay(1000);
            }
        }
        else
        {
            // Kick off the seach using the current street snap and set of item images
            if (!fragFind.searchForFragment())
            {
                return false;
            }
            delay(1000);
        }
        return true;
    }
    
    public boolean resetReadyForNewItemSearch()
    {
        fragFind = null;
        System.gc();
        fragFind = new FragmentFind(this);
        if (!fragFind.readOkFlag())
        {
            return false;
        }
        //memory.printMemoryUsage();
        
        itemFinished = false;
        return true;
    }
    
    // Simple functions to read/set variables
    public boolean readItemFinished()
    {
        return itemFinished;
    }
    
    public ArrayList<PNGFile> readItemImages()
    {
        return itemImages;
    }
    
    public PNGFile readItemImage(int n)
    {
        if (n < itemImages.size())
        {
            return itemImages.get(n);
        }
        else
        {
            return null;
        }
        
    }
       
    public boolean loadItemImages()
    {
        for (int i = 0; i < itemImages.size(); i++)
        {
            if (!itemImages.get(i).loadPNGImage())
            {
                return false;
            }
        }
        return true;
    }
    
    public boolean unloadItemImages()
    {
        for (int i = 0; i < itemImages.size(); i++)
        {
            itemImages.get(i).unloadPNGImage();
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
    public int readNewItemX()
    {
        return newItemX;
    }
    public int readNewItemY()
    {
        return newItemY;
    }
   
    public boolean readSkipThisItem()
    {
        return skipThisItem;
    }
    
    public boolean readItemFound()
    {
        return itemFound;
    }
    
    public boolean readOkFlag()
    {
        return okFlag;
    }  
   

}