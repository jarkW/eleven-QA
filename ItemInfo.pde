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
    String origItemVariant;  // additional info needed for some items
    String origItemClassName;    // used for quoins only/reporting differences at end
    int    origItemX;
    int    origItemY;
    
    // Used to read/set the additional info in item JSON
    String itemVariantKey;

    // Fields which are deduced from snap comparison - and then written to JSON file
    String newItemVariant;  
    String newItemClassName;    // used for quoins only
    int    newItemX;
    int    newItemY;
       
    // show if need to write out changed JSON file
    boolean saveChangedJSONfile;
      
    FragmentFind fragFind;
    
    // Information about the x,y which relate to the lowest RGB averages, which may/may not be considered a match
    ArrayList<MatchInfo> bestMatchInfoList;
    
    // Contains the item fragments used to search the snap
    ArrayList<PNGFile> itemImages;
    
    // Only used for debug purposes - to collect y values on the street with reference quoins on
    IntList itemYValues;
    boolean collectItemYValues = false;
    String validationInfo;
              
    // constructor/initialise fields
    public ItemInfo(JSONObject item)
    {
        okFlag = true;
        itemJSON = null;
        origItemVariant = "";
        origItemClassName = "";
        itemVariantKey = "";
        fragFind = null;
        origItemX = 0;
        origItemY = 0;
        newItemX = MISSING_COORDS;
        newItemY = MISSING_COORDS;
        newItemVariant = "";        
        newItemClassName = "";
                
        skipThisItem = false;
        itemFound = false;
        saveChangedJSONfile = false;
        
        itemYValues = new IntList();
        validationInfo = "";
        
        bestMatchInfoList = new ArrayList<MatchInfo>();
        
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
            // Read in the label to supply additional info - but as sometimes is set to null, be able to handle this without failing
            String itemLabel = Utils.readJSONString(item, "label", false);
            printToFile.printDebugLine(this, "ItemInfo constructor item tsid is " + itemTSID + "(" + itemLabel + ")", 2);
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
        // Now open the relevant I* file - use the version which has been downloaded/copied to OrigJSONs
        // If it is not there then report an error
        String itemFileName = workingDir + File.separatorChar + "OrigJSONs" + File.separatorChar+ itemTSID  + ".json";
        File file = new File(itemFileName);
        if (!file.exists())
        {
            printToFile.printDebugLine(this, "Missing file - " + itemFileName, 3);
            return false;
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
        
        // Populate the info field for some items e.g. quoins, dirt etc
        if (!extractItemInfoFromJson())
        {
            // Error populating info field
            printToFile.printDebugLine(this, "Failed to extract info for class_tsid " + itemClassTSID, 3);
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
                                
        // Point to the item images which will be used to search the snap
        if (!getThisItemImages())
        {
            printToFile.printDebugLine(this, "Error getting item images for class_tsid " + itemClassTSID, 3); 
            return false;
        }      
        
        if (origItemVariant.length() > 0)
        {
            printToFile.printDebugLine(this, "class_tsid " + itemClassTSID + " info = <" + origItemVariant + "> with x,y " + str(origItemX) + "," + str(origItemY), 2); 
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
        /*
        switch (itemTSID)
        {
            //case "IIF10MG5VTK1126":
            case "IIF18F2UM4K1MEP":
                //break;
            default:
                return false;
        } */

        
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
            case "wood_tree_enchanted":
            case "npc_gardening_vendor":            
                return true;
           
            case "quoin":
                // Do not want to search for temporary qurazy quoin as we use the marker_qurazy instead
                if (origItemVariant.equals("qurazy"))
                {
                    printToFile.printDebugLine(this, "Skipping item " + itemTSID + " quoin (qurazy)", 2);
                    return false;
                }
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
        
        if ((itemClassTSID.indexOf("trant", 0) == 0) || (itemClassTSID.equals("wood_tree")) || (itemClassTSID.indexOf("patch", 0) == 0))
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
            itemVariantKey = "dir";
            origItemVariant = Utils.readJSONString(itemJSON, itemVariantKey, false);
            
            // Currently all shrines are set to 'right' so flag up error if that isn't true
            // Putting this in so that if I ever come across a left-shrine, it will cause the code to fail
            // It is also OK at this stage for the dir field to be left unset 
            if (origItemVariant.length() > 0)
            {
                if (!origItemVariant.equals("right"))
                {
                    printToFile.printDebugLine(this, "Unexpected dir = left field in shrine JSON file  " + itemTSID, 3);
                    return false;
                }    
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
            case "wood_tree_enchanted":

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
                        printToFile.printDebugLine(this, "Failed to get instanceProps.class_name" + itemVariantKey + " from item JSON file " + itemTSID, 3);
                        return false;
                    }    
                    
                    // Now continue with getting the type field from the json file
                    itemVariantKey = "type";
                }
                else if ((itemClassTSID.equals("wood_tree")) || (itemClassTSID.equals("npc_mailbox")) || (itemClassTSID.equals("dirt_pile")) || (itemClassTSID.equals("wood_tree_enchanted")))
                {
                    itemVariantKey = "variant";
                }
                else if ((itemClassTSID.equals("mortar_barnacle")) || (itemClassTSID.equals("jellisac")))
                {
                    itemVariantKey = "blister";
                }
                else if (itemClassTSID.equals("ice_knob"))
                {
                    itemVariantKey = "knob";
                }
                else if (itemClassTSID.equals("dust_trap"))
                {
                    itemVariantKey = "trap_class";
                }
                else
                {
                    printToFile.printDebugLine(this, "Trying to read unexpected field from instanceProps for item class " + itemClassTSID, 3);
                    return false;
                }
                
                // Now read in the additional information using the key
                origItemVariant = Utils.readJSONString(instanceProps, itemVariantKey, true);
                if (!Utils.readOkFlag() || origItemVariant.length() == 0)
                {
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    printToFile.printDebugLine(this, "Failed to get from instanceProps." + itemVariantKey + " from item JSON file " + itemTSID, 3);
                    return false;
                }

                if (origItemVariant.length() == 0)
                {
                    return false;
                }                
                
                break;
   
            case "subway_gate": 
                // Read in the dir field 
                itemVariantKey = "dir";
                origItemVariant = Utils.readJSONString(itemJSON, itemVariantKey, true);
                if (!Utils.readOkFlag() || origItemVariant.length() == 0)
                {
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    printToFile.printDebugLine(this, "Failed to read dir field from item JSON file " + itemTSID, 3);
                    return false;
                }
                break;
                         
            case "npc_sloth":
                // Read in the dir field - is in two places - overwrite with the one from instanceProps if necessary
                // Read in the instanceProps array - failure is always an error
                instanceProps = Utils.readJSONObject(itemJSON, "instanceProps", true);
                if (!Utils.readOkFlag())
                {
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    printToFile.printDebugLine(this, "Failed to get instanceProps from item JSON file " + itemTSID, 3);
                    return false;
                }
                              
                itemVariantKey = "dir";
                
                origItemVariant = Utils.readJSONString(instanceProps, itemVariantKey, true);
                if (!Utils.readOkFlag() || origItemVariant.length() == 0)
                {
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    printToFile.printDebugLine(this, "Failed to get from instanceProps." + itemVariantKey + " from item JSON file " + itemTSID, 3);
                    return false;
                }

                String dir = Utils.readJSONString(itemJSON, itemVariantKey, true);
                if (!Utils.readOkFlag() || dir.length() == 0)
                {
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    printToFile.printDebugLine(this, "Failed to read dir field from item JSON file " + itemTSID, 3);
                    return false;
                }
                
                if (!origItemVariant.equals(dir))
                {
                    // Should never happen - just flag up an error and continue
                    printToFile.printDebugLine(this, "Sloth " + itemTSID + " has inconsistent dir settings in JSON files. Using value of " + origItemVariant + " from instanceProps", 3);
                }
               break;
            
            case "visiting_stone":
                // Read in the dir field 
                // NB The dir field is not always set in visiting_stones - and often set wrong.
                // Is OK if does not exist for now - as will be found when search the street and set to correct
                // direction then
                itemVariantKey = "dir";  
                origItemVariant = Utils.readJSONString(itemJSON, itemVariantKey, false);
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
            if (!newItemVariant.equals("right"))
            {
                // Should never happen
                printToFile.printDebugLine(this, "Dir field in shrine " + itemTSID + " is not set to right - is set to " + newItemVariant, 3);
                return false;
            }
            
            if (origItemVariant.length() == 0)
            {
                // Need to insert the dir field - as missing from original JSON file                
                if (!Utils.setJSONString(itemJSON, itemVariantKey, "right"))
                {
                    // Error occurred - fail
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    printToFile.printDebugLine(this, "Failed to insert new dir field in item JSON file " + itemTSID, 3);
                    return false;
                }
                saveChangedJSONfile = true; 
            }  
            return true;
        }
        else if (!itemClassTSID.equals("quoin") && newItemVariant.equals(origItemVariant)) 
        {
            // For all non-quoins
            // None of the additional information has been changed from the original. 
            // So just return without setting the flag.
            // For quoins this check is done later once the classname has been determined.
            return true;
        }
        
        // Only reach here if the information field has changed for non-quoins. 
        switch (itemClassTSID)
        {
            case "quoin":     
                // Read in the instanceProps array - failure is always an error
                instanceProps = Utils.readJSONObject(itemJSON, "instanceProps", true);
                if (!Utils.readOkFlag())
                {
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    printToFile.printDebugLine(this, "Failed to get instanceProps from item JSON file " + itemTSID, 3);
                    return false;
                }

                // Now need to set up the type and class_name field in the JSON structure
                // As we won't know until the instance props have been populated as to whether there are changes
                // to be saved, then setQuoinInstanceProps is responsible for setting the saveChangedJSONFile flag
                if (!setQuoinInstanceProps(instanceProps))
                {
                    return false;
                }
                return true;
             
            case "wood_tree":
            case "npc_mailbox":
            case "dirt_pile":
            case "mortar_barnacle":
            case "jellisac":
            case "ice_knob":
            case "dust_trap":
            case "wood_tree_enchanted":
                // Read in the instanceProps array - failure is always an error
                instanceProps = Utils.readJSONObject(itemJSON, "instanceProps", true);
                if (!Utils.readOkFlag())
                {
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    printToFile.printDebugLine(this, "Failed to get instanceProps from item JSON file " + itemTSID, 3);
                    return false;
                }
                if (!Utils.setJSONString(instanceProps, itemVariantKey, newItemVariant))
                {
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    return false;
                }             
                break;
   
            case "subway_gate":
                if (!Utils.setJSONString(itemJSON, itemVariantKey, newItemVariant))
                {
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    return false;
                }          
                break;
                
            case "visiting_stone":
                if (!Utils.setJSONString(itemJSON, itemVariantKey, newItemVariant))
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
                break;
                         
            case "npc_sloth":
                // Read in the instanceProps array - failure is always an error
                instanceProps = Utils.readJSONObject(itemJSON, "instanceProps", true);
                if (!Utils.readOkFlag())
                {
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    printToFile.printDebugLine(this, "Failed to get instanceProps from item JSON file " + itemTSID, 3);
                    return false;
                }
                if (!Utils.setJSONString(instanceProps, itemVariantKey, newItemVariant))
                {
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    return false;
                } 
                // Also need to set the dir key at the root level
                if (!Utils.setJSONString(itemJSON, itemVariantKey, newItemVariant))
                {
                    printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                    return false;
                } 
                break;          
        
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
            case "wall_button":
            case "subway_map":
            case "bag_notice_board":
            case "npc_gardening_vendor":
                       
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
    
    boolean setQuoinInstanceProps(JSONObject instanceProps)
    {
        // Sets up the rest of the instanceProps fields depending on the setting of the newItemVariant field    
        QuoinFields quoinInstanceProps = new QuoinFields();                   
        if (!quoinInstanceProps.defaultFields(streetInfo.readHubID(), streetInfo.readStreetTSID(), newItemVariant))
        {
            printToFile.printDebugLine(this, "Error defaulting fields in quoin instanceProps structure", 3);
            return false;
        }
        
        // In the case of Rainbow Run, possible chance that quoin type has been reset - if a mood quoin is found, it is considered valid, but set to currants
        // to match video evidence (and quoin.js has been changed to do this also). For all other quoin types, the quoin is reset to mystery quoin (should never happen).
        // Need to flag up a warning message to the user
        switch (streetInfo.readStreetTSID())
        {
            case "LM4105MGKMSLT":
            case "LIF9NRCLF273JBA":
                String warningMsg = quoinInstanceProps.readWarningInfo();
                if (warningMsg.length() > 0)
                {
                    // Save the warning message so that it is printed out for the user
                    streetInfo.setQuoinDefaultingWarningMsg(itemTSID + " " + warningMsg);
                    
                    // The type field has been reset, so pick up the changed value before carrying on
                    // Otherwise class name and quoin type will be out of sync
                    newItemVariant = quoinInstanceProps.readQuoinType();
                }
                break;
                
            default:
                break;
        }

        newItemClassName = quoinInstanceProps.readClassName();
                 
        if (newItemClassName.equals(origItemClassName))
        {
            // Nothing to save so return without setting flag
            return true;
        }
 
        // Now save the fields in instanceProps
        if (!Utils.setJSONString(instanceProps, "type", newItemVariant))
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
                    
        if (newItemVariant.equals("favor"))
        {
            if (!Utils.setJSONString(instanceProps, "giant", quoinInstanceProps.readGiant()))
            {
                 printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                 return false;
            }
        }
        
        // Save any special message to the user about special quoin defaults having been set
        streetInfo.setQuoinDefaultingInfo(quoinInstanceProps.readSpecialDefaultingInfo());
        
        // Show changes made to instanceProps that need to be changed
        saveChangedJSONfile = true;
        return true;
    }
        
    public boolean saveItemChanges(boolean secondTimeThrough)
    {
        // Called once all the street snaps have been searched for this item
        String s = "";

        // Need to handle the missing items first
        if (newItemX == MISSING_COORDS)
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
                if (origItemVariant.length() > 0)
                {
                    s = s + " " + itemVariantKey + " = " + origItemVariant;
                }
                //printToFile.printOutputLine(s);
                printToFile.printDebugLine(this, s, 2);         

                // nothing else to do for these missing/skipped items - do not save
                return true;
            }
            else
            {
                 // Reset the quoin type if the x,y was not found - set to mystery, with the original x,y
                newItemX = origItemX;
                newItemY = origItemY;
                // As might be coming through this a second time after marking a quoin as missing because of duplication of x,y finding, need to write the new x,y to the JSON file
                if (secondTimeThrough)
                {
                    if (!Utils.setJSONInt(itemJSON, "x", newItemX))
                    {
                        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                        return false;
                    }
                    if (!Utils.setJSONInt(itemJSON, "y", newItemY))
                    {
                        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                        return false;
                    }
                    saveChangedJSONfile = true;
                }
                
                if (!configInfo.readChangeXYOnly())
                {
                    printToFile.printDebugLine(this, "Set missing quoin " + itemTSID + " to be type = mystery", 1);
                    newItemVariant = "mystery";
                }
                else
                {    
                    // Do not reset to mystery, leave as is
                    newItemVariant = origItemVariant;
                }
                // OK to then carry on in this function

            }
        } 
        
        // Just to double check - do not continue if the new x or y is still set to MISSING_COORDS as it would be disastrous for this to 
        // end up in a new JSON file!
        // This code should never be hit - hence treated as failure case
        if (newItemX == MISSING_COORDS || newItemY == MISSING_COORDS)
        {
            printToFile.printDebugLine(this, "ERROR for " + itemTSID + "  which has new x,y set to " + newItemX + "," + newItemY, 3);
            return false;
        }
                       
        // dump out all the y values nb 'max y' is the most negative
        // Only do this occasionally when want to correct the quoin images offset manually
        // as have to allow for bounce.
        if (collectItemYValues && (itemClassTSID.equals("quoin") || itemClassTSID.equals("marker_qurazy")))
        {
            String s1 = "";
            for (int i = 0; i < itemYValues.size(); i++)
            {
                s1 = s1 + " " + itemYValues.get(i);
            }
            printToFile.printOutputLine("Y values for " + itemTSID + "(" + newItemVariant + ") x,y " + origItemX + "," + origItemY + " are " + s1);
        }

        // Item has been found or has been reset as mystery quoin - so changes to write
        
        // Change in co-ords
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
            
        // Sets up the special fields e.g. 'dir' or 'type' fields based on variant field
        // Only do this if not doing an x,y_only kind of search - which leaves the special fields
        // as originally set
        // Sets the saveChangedJSONFile flag as needed
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
            if (newItemVariant.length() > 0)
            {
                if (newItemVariant.equals(origItemVariant) && newItemClassName.equals(origItemClassName))
                {
                    s = "Saving change - unchanged item info/class (" + itemTSID + ") " + itemClassTSID;
                    s = s + " " + itemVariantKey + " = " + origItemVariant;
                    if (itemClassTSID.equals("quoin"))
                    {
                        s = s + " (" + origItemClassName + ")";
                    }
                }
                else
                {
                    s = "";
                    if (newItemVariant.length() > 0)
                    {
                        if (newItemVariant.equals("mystery"))
                        {
                            s = "Saving change - missing quoin - (" + itemTSID + ") " + itemClassTSID;
                        }
                    }
                    if (s.length() == 0)
                    {
                        // I.e. not a change due to a missing quoin set to mystery
                        s = "Saving change - changed item info/class (" + itemTSID + ") " + itemClassTSID;
                    }
                    
                    s = s + itemVariantKey + " = " + origItemVariant;
                    if (itemClassTSID.equals("quoin"))
                    {
                        s = s + " (" + origItemClassName + ")";
                    }
                    s = s + " to " + newItemVariant;
                    if (itemClassTSID.equals("quoin"))
                    {
                        s = s + " (" + newItemClassName + ")";
                    }
                }
            }
            else
            {
                s = "Saving change - item (" + itemTSID + ") " + itemClassTSID;
            }
            
            if ((origItemX == newItemX) && (origItemY == newItemY))
            {
                s = s + " with unchanged x,y = " + origItemX + "," + origItemY;
            }
            else
            {
                s = s + " with changed x,y = " + origItemX + "," + origItemY + " to " + newItemX + "," + newItemY;
            }

            //printToFile.printOutputLine(s);
            printToFile.printDebugLine(this, s, 2);   
            // Write the JSON file out to temporary place before checking that the new file length = old one plus calculated diff
            
            //saveJSONObject doesn't close the file which causes problems when we later try to move this file to UploadedJSONs once uploaded
            // So using this work around.
            
            if (!writeJSONObjectToFile(itemJSON, workingDir + File.separatorChar + "NewJSONs" + File.separatorChar + itemTSID + ".json"))
            {
                // Error writing file logged in the called function
                return false;
            }
            /*
            try
            {
                saveJSONObject(itemJSON, workingDir + File.separatorChar + "NewJSONs" + File.separatorChar + itemTSID + ".json");
            }
            catch(Exception e)
            {
                println(e);
                printToFile.printDebugLine(this, "Error writing " + itemTSID + ".json file to " + workingDir + File.separatorChar + "NewJSONs", 3);
                printToFile.printOutputLine("ERROR WRITING " + itemTSID + ".json file to " + workingDir + File.separatorChar + "NewJSONs");
                return false;
            }
            */
                            
            // Double check the new file is reasonable - has to be done by eye by looking at output from a diff comparison tool
            JSONDiff jsonDiff = new JSONDiff(itemTSID, itemClassTSID, workingDir + File.separatorChar + "OrigJSONs" + File.separatorChar + itemTSID + ".json", 
                                            workingDir + File.separatorChar + "NewJSONs" + File.separatorChar + itemTSID + ".json");
            if (!jsonDiff.compareJSONFiles())
            {
                // Error during the diff process
                // Display all the messages and then return
                jsonDiff.displayInfoMsg(true);
                return false;
            }
            // Displays message to user in both debug files
            jsonDiff.displayInfoMsg(false);
            
            // Save the JSON diff information validation runs - will be later printed out in the output file so easy to view
            if (configInfo.readDebugValidationRun())
            {
                validationInfo = jsonDiff.readValidationInfo();
            }
                                
         } // end if changes to save to JSON file
         else
         {
             // No changes to make to JSON - either because item found (and matches existing file) or not found
            if (newItemX != MISSING_COORDS)
            {
                    s = "Matches existing item (";
            }
            else
            {
                s = "No changes - not found item ERROR SHOULD NOT REACH THIS LEG (";
            }
            s = s + itemTSID + ") " + itemClassTSID + " x,y = " + origItemX + "," + origItemY;             
            if (origItemVariant.length() > 0)
            {
                s = s + " " + itemVariantKey + " = " + origItemVariant;
                if (itemClassTSID.equals("quoin"))
                {
                    s = s + " (" + origItemClassName + ")";
                }
            }
            //printToFile.printOutputLine(s);
            printToFile.printDebugLine(this, s, 2);
        } 
                
        return true;
    }
    
    boolean writeJSONObjectToFile(JSONObject json, String filePath)
    {
        // This replaces the saveJSONObject function call which doesn't appear to properly close the file
        // although this was allegedly fixed in https://github.com/processing/processing/issues/3705
        
        PrintWriter writer = PApplet.createWriter(saveFile(filePath));        
        
        try
        {
            json.write(writer);
        }
        catch(IllegalStateException e)
        {
            println(e);
            printToFile.printDebugLine(this, "Error writing (Illegal state Exception) " + itemTSID + ".json file to " + filePath, 3);
            printToFile.printOutputLine("ERROR WRITING (Illegal state Exception) " + itemTSID + ".json file to " + filePath);
            return false;
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine(this, "Error writing " + itemTSID + ".json file to " + filePath, 3);
            printToFile.printOutputLine("ERROR WRITING " + itemTSID + ".json file to " + filePath);
            return false;
        }
        
        
        try
        {
            writer.close();
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine(this, "Error closing " + itemTSID + ".json file to " + filePath, 3);
            printToFile.printOutputLine("ERROR CLOSING " + itemTSID + ".json file to " + filePath);
            return false;
        }
        
        // If reach here, the write succeeded
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
                if (itemClassTSID.equals("quoin") || itemClassTSID.equals("marker_qurazy"))
                {
                    // debug only
                    s = "quoin/QQ (" + itemTSID + ") orig type <" + origItemVariant + "> new type <" + newItemVariant + " found on street snap " + streetInfo.streetSnapBeingUsed + " with new item X " + newItemX;
                    printToFile.printDebugLine(this, s, 1);
                }
                
                
                // Item was successfully found on the street
                if ((itemClassTSID.equals("quoin") || itemClassTSID.equals("marker_qurazy")) && newItemX != MISSING_COORDS)
                {                   
                    // This is the 2nd time or more that we've found this quoin/QQ - because only save the newItemX in the next few lines, so if not missing_coords, then been here already
                    // Only save the Y-cord if lower than the one we already have i.e. less negative
                    if (collectItemYValues)
                    {
                        itemYValues.append(fragFind.readNewItemY());
                        printToFile.printDebugLine(this, "adding Y value 2 " + fragFind.readNewItemY() + " for item " + itemTSID + " itemClassTSID " + itemClassTSID, 1);
                    }
                    if (newItemY < fragFind.readNewItemY())
                    {
                        s = "SEARCH DONE Resetting y-value for " + itemTSID + " " + itemClassTSID + " " + newItemVariant + " from " + newItemY + " to " + fragFind.readNewItemY();
                        printToFile.printDebugLine(this, s, 2);
                        
                        newItemY = fragFind.readNewItemY();
                    }
                    else
                    {
                        s = "SEARCH DONE Ignoring y-value for " + itemTSID + " " + itemClassTSID + " " + newItemVariant + " remains at " + newItemY + " (new = " + fragFind.readNewItemY() + ")";
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
                    newItemVariant = fragFind.readNewItemVariant();
                    itemFound = true;
                    
                    // For all non-quoins/QQ, we only need to do the search once, so on future street snaps, skip this item
                    if (!itemClassTSID.equals("quoin") && !itemClassTSID.equals("marker_qurazy"))
                    {
                        s = "SEARCH FOUND (skip in future) (";
                    }
                    else
                    {
                        s = "SEARCH FOUND (but keep looking) (";
                        if (collectItemYValues)
                        {
                            printToFile.printDebugLine(this, "adding Y value " + fragFind.readNewItemY() + " for item " + itemTSID + " itemClassTSID " + itemClassTSID, 1);
                            itemYValues.append(fragFind.readNewItemY());
                        }
                    }
                    
                    s = s + itemTSID + ") " + itemClassTSID + " x,y = " + newItemX + "," + newItemY;             
                    if (newItemVariant.length() > 0)
                    {
                        s = s + " " + itemVariantKey + " = " + newItemVariant;
                        if (itemClassTSID.equals("quoin"))
                        {
                            s = s + " (" + newItemClassName + ")";
                        }
                    }
                    s = s + " was x,y = " + origItemX + "," + origItemY;;             
                    if (origItemVariant.length() > 0)
                    {
                        s = s + " " + itemVariantKey + " = " + origItemVariant;
                        if (itemClassTSID.equals("quoin"))
                        {
                            s = s + " (" + origItemClassName + ")";
                        }
                    }
                    //printToFile.printOutputLine(s);
                    printToFile.printDebugLine(this, s, 2);
                }
            }
            else
            {
                // Item was not found on the street
                // So need to go on to the next item on this street
                s = "SEARCH FAILED " + itemTSID + ") " + itemClassTSID + " x,y = " + origItemX + "," + origItemY;             
                if (origItemVariant.length() > 0)
                {
                    s = s + " " + itemVariantKey + " = " + origItemVariant;
                    if (itemClassTSID.equals("quoin"))
                    {
                        s = s + " (" + origItemClassName + ")";
                    }
                }
                printToFile.printDebugLine(this, s, 1);
                

                
            }
            itemFinished = true;
            
            // Save the debug information for this street snap
            MatchInfo bestMatchInfo = fragFind.readBestMatchInfo();         
            bestMatchInfoList.add(bestMatchInfo);
            
            // If an item was found, then delay the image for a second before continuing - for debug onl
            if (doDelay && newItemX != MISSING_COORDS)
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
            if (doDelay)
            {
                delay(1000);
                //delay(5000);
            }

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
    
    public void clearFragFind()
    {
        fragFind = null;
        System.gc();
    }
    
    public boolean resetAsMissingQuoin()
    {
        // This function is called if it is a quoin found to have the same x,y as another quoin
        // This quoin will be reset as a 'missing' quoin and the changes saved as a JSON file
        if (!itemClassTSID.equals("quoin"))
        {
            printToFile.printDebugLine(this, "Error - resetAsMissingQuoin should not be called for item " + itemClassTSID, 3);
            return false;
        }
        itemFound = false;
        newItemX = MISSING_COORDS;
        newItemY = MISSING_COORDS;        
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
    
    public String readOrigItemVariant()
    {
        return origItemVariant;
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
    
    public String readNewItemVariant()
    {
        return newItemVariant;
    }
      
    public boolean readSkipThisItem()
    {
        return skipThisItem;
    }
    
    public boolean readItemFound()
    {
        return itemFound;
    }
    
    public boolean readSaveChangedJSONfile()
    {
        return saveChangedJSONfile;
    }
    
    public boolean differentVariantFound()
    {
        // For quoins, also need to check for differences in class name to make sure
        // the difference is reported correctly to user
        boolean differentVariant = false;
        
        if (itemClassTSID.equals("quoin") && !origItemClassName.equals(newItemClassName))
        {
            differentVariant = true;
        }
        
        if (!origItemVariant.equals(newItemVariant))
        {
            differentVariant = true;
        }
        
        return differentVariant;
    }
    
    public String readOrigItemClassName()
    {
        if (itemClassTSID.equals("quoin"))
        {
            return origItemClassName;
        }
        else
        {
            return "";
        }
    }
    
    public String readNewItemClassName()
    {
        if (itemClassTSID.equals("quoin"))
        {
            return newItemClassName;
        }
        else
        {
            return "";
        }
    }
    
    public boolean readOkFlag()
    {
        return okFlag;
    } 
    
    public String readValidationInfo()
    {
        return validationInfo;
    }
    
    public MatchInfo readBestMatchInfo()
    {
        if (bestMatchInfoList.size() < 1)
        {
            // This should never happen - no RGB info has been added
            printToFile.printDebugLine(this, "MatchInfo array is empty - no data has been added for snap searches for item " + itemTSID, 3);
            return null;
        }
        
        printToFile.printDebugLine(this, "Item + " + itemTSID + " Size of debugRGBInfo is " + bestMatchInfoList.size(), 1);
        // Need to walk through the array and return the lowest value of RGB
        MatchInfo info;
        info = bestMatchInfoList.get(0);
        for (int i = 0; i < bestMatchInfoList.size(); i++)
        {
            printToFile.printDebugLine(this, "Item + " + itemTSID + " Debug RGB info is " + bestMatchInfoList.get(i).matchDebugInfoString(), 1);
            if (bestMatchInfoList.get(i).bestMatchAvgRGB < info.bestMatchAvgRGB)
            {
                info = bestMatchInfoList.get(i);
            }
            else if ((itemClassTSID.equals("quoin") || itemClassTSID.equals("qurazy_marker")) && (bestMatchInfoList.get(i).bestMatchAvgRGB == info.bestMatchAvgRGB))
            {
                // If the RGB values are the same, if this one has a lower y value (i.e. more positive), then copy across
                if (bestMatchInfoList.get(i).bestMatchY > info.bestMatchY)
                {
                    info = bestMatchInfoList.get(i);
                }
            }
        }
        
        printToFile.printDebugLine(this, "Item + " + itemTSID + " Best debug RGB info is " + info.matchDebugInfoString(), 1);
        return info;
    }
    

}