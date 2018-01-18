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
    MatchInfo bestMatchInfo;
    
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
        
        bestMatchInfo = null;
        
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
            printToFile.printDebugLine(this, "ItemInfo constructor item tsid is " + itemTSID + "(" + itemLabel + ")", 1);
        }
    }
    
    public void initItemVars()
    {
        // These need to be reset after been through the loop of streets
        // as part of initial validation
        itemFinished = false;
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
                
        printToFile.printDebugLine(this, "Item file name is " + itemFileName, 1); 

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
        if (!resetReadyForNewItemSearch())
        {
            return false;
        }
 
        return true;
    } 
    
    boolean validItemToCheckFor()
    {
        
        // During testing, this check allows me to just search for single item (TSID) or class of items and ignore everything else
        String validItemStr = configInfo.readDebugThisTSIDOnly();       
        if (validItemStr.length() > 0)
        {
            // Only continue on if the item matches this TSID
            if (!itemTSID.equals(validItemStr))
            {
                return false;
            }
        }
        validItemStr = configInfo.readDebugThisClassTSIDOnly();       
        if (validItemStr.length() > 0)
        {
            // Only continue on if the item class matches this class
            if (itemClassTSID.indexOf(validItemStr, 0) != 0)
            {
                return false;
            }
        }

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
            case "street_spirit_zutto":
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
        if (itemIsAPlayerPlantedTree())
        {
            if (itemClassTSID.equals("trant_egg") || itemClassTSID.equals("patch_dark"))
            {
                itemImages = allItemImages.getItemImages("trees_subterranean");
            }
            else
            {
                itemImages = allItemImages.getItemImages("trees_ground");
            }
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
            //case "street_spirit_zutto": Do not read in cap information as the item is not stable enough to use this information to generate good matches

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
            case "street_spirit_zutto": // are ignoring the cap information - we don't change this due to poor pattern matching
                       
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
    
    boolean findValidVariant()
    {
        // This function takes the name of the matching fragment and works out what variant information this provides if any.
                
       // Need to be careful of using the variant field deduced from the image name - trees/patches must not have a variant field set (because matched a wood tree), 
       // For wood trees, keep the existing variant? Or could reset from street if also a wood tree
       // When reading in the variant, need to do check here that do get that information from the image name if expecting this      
        newItemVariant = "";
        String name = bestMatchInfo.readBestMatchItemImageName();
        String s;
        
        s = "What is this? " + itemClassTSID;
        if (origItemVariant.length() > 0)
        {
            s = s + "(" + origItemVariant + ")";
        }
        s = s + " for matching image name " + name;
        printToFile.printDebugLine(this, s, 1);
        
        // Some items never have a variant field e.g. QQ, so image name = class TSID
        if (itemClassTSID.equals(name))
        {
            newItemVariant = "";
            return true;
        }
        else if ((itemClassTSID.indexOf("trant_") == 0) || (itemClassTSID.indexOf("patch") == 0))
        {
            // Quite often might have a bean tree on our QA street, but the snap has a fruit tree. Therefore the itemClassTSID (bean)
            // in the JSON file doesn't reflect the found fruit tree on the snap. 
            // Unlike quoins, we are not changing tree JSONs to match snaps, therefore quite feasible that the itemClassTSID won't match the snap name. 
            // So just return a clean empty variant field if not appropriate - i.e. because have non-wood tree/patch present.  
            // Also means the maturity information in the matched file name will also be ignored
            printToFile.printDebugLine(this, " tree or patch " + itemClassTSID, 1);
            newItemVariant = "";
            return true;
        }
        else if (itemClassTSID.equals("street_spirit_zutto"))
        {
            printToFile.printDebugLine(this, " zutto street spirit - ignore flipped/normal part of image name " + itemClassTSID, 1);
            newItemVariant = "";
            return true;
        }
        else if ((itemClassTSID.indexOf("rock_", 0) == 0) || (itemClassTSID.indexOf("peat_", 0) == 0))
        {
            // Rocks have mutiple images but this information is not used for rocks/peat
            printToFile.printDebugLine(this, " rock or peat " + itemClassTSID, 1);
            newItemVariant = "";
            return true;
        }
        else if (itemClassTSID.equals("wood_tree"))
        {            
            // Note that if the JSON file is set up to be a wood tree, then we do want to know what variant was found which constituted a match.
            // But have 2 possible scenarios - might have a wood_tree matching snap, or some other tree. Need to handle these two scenarios separately
            if (name.indexOf("wood_tree") != 0)
            {
                // The match for this wood tree JSON file has been found with a non-wood tree image on the street snap
                // So return the variant which was set in the original JSON file
                printToFile.printDebugLine(this, " default wood tree variant to original value of " + origItemVariant, 1);
                newItemVariant = origItemVariant;
                return true;
            }
            
            // else - continue on to extract the variant information below.
        }
        
        // Extract the variant information from the item file name
        // Just do a sanity check that the class TSID is correct for the image we are matching to ...
        if (name.indexOf(itemClassTSID) == 0)
        {
            // The class TSID is correctly reflected in the name of the matching snap.
            if (name.length() > (itemClassTSID.length() + 1))
            {          
                // The matching image contains variant information, and possibly maturity information which needs to be ignored
                // The variant will be the next character in the string - as either had classTSID_variant or classTSID_variant_maturity 
                switch (itemClassTSID)
                {
                    // These items have a variant and state part of the matching file name
                    case "wood_tree":
                    case "wood_tree_enchanted":
                    case "mortar_barnacle":
                    case "jellisac":
                        // The variant is the next digit - ignore the maturity information which comes after that
                        newItemVariant = (name.replace(itemClassTSID + "_", "")).substring(0,1);
                        break;
                        
                    case "dirt_pile":
                        // The variant of the form dirt1 or dirt2 - ignore the maturity information which comes after that
                        newItemVariant = (name.replace(itemClassTSID + "_", "")).substring(0,5);
                        break;
            
                    // These items only have a variant that needs to be extracted
                    case "ice_knob": // the maturity images are unusable, so only search on the healthiest images (state 4)
                    default:
                        newItemVariant = name.replace(itemClassTSID + "_", "");    
                        break;
                }               
                printToFile.printDebugLine(this, " image name "  + name + " for item class tsid " + itemClassTSID + " returns variant + " + newItemVariant, 1);
                return true;                          
            }
            else
            {
                // Should never reach this point - but if we do, just default the variant to nothing
                newItemVariant = "";
                printToFile.printDebugLine(this, " ERROR - missing variant in image name "  + name + " for item class tsid " + itemClassTSID, 3);
                return false;
            }
        }
        else
        {
            // error - the matched name does not start with the item classTSID 
            printToFile.printDebugLine(this, " image name "  + name + " is incorrect for (does not match) item class tsid " + itemClassTSID, 3);
            return false;
        }
    }
      
    public boolean saveItemChanges(boolean secondTimeThrough)
    {
        // Called once all the street snaps have been searched for this item
        String s = "";

        if (skipThisItem)
        {
            s = "No changes written - ";
            s = s + "SKIPPED item (";
            s = s + itemTSID + ") " + itemClassTSID + " x,y = " + origItemX + "," + origItemY;             
            if (origItemVariant.length() > 0)
            {
                s = s + " " + itemVariantKey + " = " + origItemVariant;
            }
            printToFile.printDebugLine(this, s, 2);         

            // nothing else to do for these skipped items - do not save
            return true;
        }
 
        // At this stage we only have the information for the changes saved in bestMatchInfo. So therefore need to convert the information there
        // into useful information to save to JSON files
        if (!secondTimeThrough && bestMatchInfo.readBestMatchResult() > NO_MATCH)
        {
            newItemX = bestMatchInfo.readBestMatchX();
            newItemY = bestMatchInfo.readBestMatchY();
            if (!findValidVariant())
            {
                return false;
            }
            s = "Extracting information for " + itemTSID + " " + itemClassTSID;
            if (origItemVariant.length() > 0)
            {
                s = s + " (" + origItemVariant + ")";
            }
            s = s + " x,y = " + origItemX + "," + origItemY + " has been found to be ";
            if (newItemVariant.length() > 0)
            {
                s = s + " (" + newItemVariant + ")";
            }            
            s = s + "with new x,y = " + newItemX + "," + newItemY + "(" + bestMatchInfo.readPercentageMatch() + "%)";
            printToFile.printDebugLine(this, s, 1);
        }

        // Need to handle the missing items first
        if (newItemX == MISSING_COORDS)
        {
            if (!itemClassTSID.equals("quoin"))
            {
                // For all non-quoins, items that are not found will not cause any file changes - so clean up and return here
                s = "No changes written - ";
                // Already handled the case where an item is skipped
                if (!itemFound)
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
                
                if (!streetInfo.readChangeItemXYOnly())
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
        if (!streetInfo.readChangeItemXYOnly())
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
        int prevSearchY;
        int newSearchY;
        String s;
        // This function is the entry point into FragmentFind - which may be to start a new search, or to move on to the next image
        // Once all images have been searched, bestMatchInfo will be returned which contains the 'best' result for the item.
        // This class needs to validate the results in order to avoid assigning a variant field to a gas tree because the result was found 
        // from a wood tree on a snap for example.         
        if (fragFind.readSearchDone())
        {
            for (int n=0; n<fragFind.allMatchResultsForItem.size(); n++)
            {
                MatchInfo entry = fragFind.allMatchResultsForItem.get(n);
                 
                if (entry.readPercentageMatch() > configInfo.readDebugDumpAllMatchesValue())
                {
                    s = "Search Results (>" + configInfo.readDebugDumpAllMatchesValue() + "%) entry " + n + " " + itemTSID + " " + itemClassTSID + "(" + origItemVariant + ") " + entry.readBestMatchResultAsString() + " "  + entry.readBestMatchItemImageName();
                    s = s + " giving x,y " + entry.matchXYString() + " (" + entry.matchPercentAsFloatString() + ")";
                    printToFile.printDebugLine(this, s, 2);
                }
            }
            
            // Search has completed - for this item on this street. All images searched OR item was actually found. 
            if (fragFind.readItemFound())
            {                
                // Item was successfully found on the street with a PERFECT match - this leg is never entered for QQ/quoins 
                bestMatchInfo = fragFind.readBestMatchInfo();
                itemFound = true;
                s = "SEARCH DONE, Item found as perfect match " + itemTSID + " " + itemClassTSID + " with " + bestMatchInfo.readBestMatchItemImageName();
                s = s + " giving x,y " + bestMatchInfo.matchXYString() + " (" + bestMatchInfo.matchPercentAsFloatString() + ")";
                printToFile.printDebugLine(this, s, 2);
            }
            else
            {
                // Search is done for the street, but need to carry on searching on future streets
                // For most items, only save the matchInfo, if better than what we've already got for this item, from previous searches
                // For quoins, we need to prioritise saving information for quoins that are nearer the original x,y, over the match result
                // However need to be able to differentiate 'nearer' quoins from finding the same quoin on a second snap, which just happens to be higher/lower than on the previous snap
                if (bestMatchInfo == null)
                {
                    // First street for this item
                    bestMatchInfo = fragFind.readBestMatchInfo();
                    s = "SEARCH DONE, First street, 'best' match for " + itemTSID + " " + itemClassTSID + " with " + bestMatchInfo.readBestMatchItemImageName();
                    s = s + " giving x,y " + bestMatchInfo.matchXYString() + " (" + bestMatchInfo.matchPercentAsFloatString() + ")";
                    printToFile.printDebugLine(this, s, 2);
                } 
                else if (itemClassTSID.equals("quoin"))
                {
                    prevSearchY = MISSING_COORDS;
                    newSearchY = MISSING_COORDS;
                    if ((bestMatchInfo.readBestMatchResult() > NO_MATCH) &&  (fragFind.readBestMatchInfo().readBestMatchResult() > NO_MATCH))
                    {
                        // Record the y-values for the cases where we actually have a match of some sort recorded
                        prevSearchY = bestMatchInfo.readBestMatchY();
                        newSearchY = fragFind.readBestMatchInfo().readBestMatchY();
                       
                        if (!fragFind.readBestMatchInfo().readBestMatchItemImageName().equals(bestMatchInfo.readBestMatchItemImageName()) ||
                            fragFind.readBestMatchInfo().readBestMatchX() != bestMatchInfo.readBestMatchX() ||
                            abs(prevSearchY - newSearchY) > 12)
                        {
                            // This quoin has a different type, a different x-value or is further away in the y direction (allowing for +/- 6px bounce)
                            // So assume this is a different quoin and so save it if it is nearer to the origin x,y. And if it is the same distance away, then save
                            // if the match is better
                            float prevSearchDistFromOrigXY = Utils.distanceBetweenX1Y1_X2Y2(origItemX, origItemY, bestMatchInfo.readBestMatchX(), bestMatchInfo.readBestMatchY());
                            float newSearchDistFromOrigXY = Utils.distanceBetweenX1Y1_X2Y2(origItemX, origItemY, fragFind.readBestMatchInfo().readBestMatchX(), fragFind.readBestMatchInfo().readBestMatchY());
                            if (newSearchDistFromOrigXY <= prevSearchDistFromOrigXY)
                            {
                                // The new search result references a quoin which is nearer the starting point than anything found on a previous street - so save this one without question
                                // For simplicity sake, also do this if the quoin is the same distance away as the previous one - should rarely happen?
                                bestMatchInfo = fragFind.readBestMatchInfo();
                                if (newSearchDistFromOrigXY < prevSearchDistFromOrigXY)
                                {
                                    s = "SEARCH DONE, found closer quoin for " + itemTSID + " " + itemClassTSID + " with " + bestMatchInfo.readBestMatchItemImageName();
                                    s = s + " giving x,y " + bestMatchInfo.matchXYString() + " (" + bestMatchInfo.matchPercentAsFloatString() + ")";
                                    printToFile.printDebugLine(this, s, 2);
                                }
                                else
                                {
                                    s = "SEARCH DONE, WARNING found different quoin exactly same distance away as prevous one (" + newSearchDistFromOrigXY + ") ";
                                    s = s + itemTSID + " " + itemClassTSID + " with " + bestMatchInfo.readBestMatchItemImageName();
                                    s = s + " giving x,y " + bestMatchInfo.matchXYString() + " (" + bestMatchInfo.matchPercentAsFloatString() + "%)";
                                    printToFile.printDebugLine(this, s, 3);
                                }
                            }
                            else
                            {
                                // new quoin is further away, so ignore this data
                                s = "SEARCH DONE, 'worse' match found for " + itemTSID + " " + itemClassTSID + " with " + fragFind.readBestMatchInfo().readBestMatchItemImageName();
                                s = s + " giving x,y " + bestMatchInfo.matchXYString() + " (" + fragFind.readBestMatchInfo().matchPercentAsFloatString() + "% compared to existing " + bestMatchInfo.matchPercentAsFloatString() + "%)";
                                printToFile.printDebugLine(this, s, 2);     
                            }                           
                        }
                        else
                        {
                            // We've found the same quoin again - it has the same found quoin type and x value, and the y value is within theoretical range (+/- 6 px bounce)
                            // So just save the lowest y value
                            saveLowerYVal(prevSearchY, newSearchY);
                        }
                    }    
                    else
                    {
                        // At least one of these is a no match case - so only copy across the match information if it is better. No y-values to adjust as these results are referring to different quoins/objects
                        saveBestMatchInfo();
                    } 
                } // end quoin
                else if (itemClassTSID.equals("marker_qurazy"))
                {
                    prevSearchY = MISSING_COORDS;
                    newSearchY = MISSING_COORDS;
                    // Record the y-values for the cases where we actually have a match of some sort recorded
                    if (bestMatchInfo.readBestMatchResult() > NO_MATCH)
                    {
                        prevSearchY = bestMatchInfo.readBestMatchY();
                    }
                    if (fragFind.readBestMatchInfo().readBestMatchResult() > NO_MATCH)
                    {
                        newSearchY = fragFind.readBestMatchInfo().readBestMatchY();
                    }
                    // Update the bestMatchInfo structure if a better match has been found
                    saveBestMatchInfo();
                    
                    // Update the y-values 
                    saveLowerYVal(prevSearchY, newSearchY);
 
                } // end QQ
                else
                {
                    // All other items can simply copy across the better search result
                    saveBestMatchInfo();
                }
            }// end if else ! itemFound
            
            // As we've finished on this street - due to searchDone flag - then mark appropriately so can move on to next item
            itemFinished = true; 
        }// end if search done
        else
        {
            // Kick off the seach using the current street snap and set of item images
            if (!fragFind.searchForFragment())
            {
                return false;
            }
        }
        return true;
    }
    
    void saveBestMatchInfo()
    {
        String s;
        if (bestMatchInfo.readPercentageMatch() < fragFind.readBestMatchInfo().readPercentageMatch())
        {
            // This street has returned a better match than any previous streets
            s = "SEARCH DONE, 'better' match found for " + itemTSID + " " + itemClassTSID + " with " + fragFind.readBestMatchInfo().readBestMatchItemImageName();
            s = s + " giving x,y " + bestMatchInfo.matchXYString() + " (" + fragFind.readBestMatchInfo().matchPercentAsFloatString() + "% compared to " + bestMatchInfo.matchPercentAsFloatString() + "%)";
            printToFile.printDebugLine(this, s, 2);                  
            bestMatchInfo = fragFind.readBestMatchInfo();
        }
        else
        {
            // else - ignore the results of the last street search as it was worse than the best we have so far
            s = "SEARCH DONE, 'worse' match found for " + itemTSID + " " + itemClassTSID + " with " + fragFind.readBestMatchInfo().readBestMatchItemImageName();
            s = s + " giving x,y " + bestMatchInfo.matchXYString() + " (" + fragFind.readBestMatchInfo().matchPercentAsFloatString() + "% compared to existing " + bestMatchInfo.matchPercentAsFloatString() + "%)";
            printToFile.printDebugLine(this, s, 2);     
        }
    }  
    
    void saveLowerYVal(int savedY, int newY)
    {
        String s;
        // For quoins and QQ, need to make sure the y-values are always the lowest ones measured for this item
        // However, assuming that a search was partially successful, it is still OK to correct the Y values if they exist
        if ((savedY != MISSING_COORDS) && (newY != MISSING_COORDS))
        {
            if (collectItemYValues)
            {
                itemYValues.append(newY);
                printToFile.printDebugLine(this, "adding Y value 2 " + newY + " for item " + itemTSID + " itemClassTSID " + itemClassTSID, 1);
            }
            if (savedY < newY)
            {
                // The new Y-value is lower (less negative) than the old one - so save this in bestMatchInfo
                bestMatchInfo.setBestMatchY(newY);
                s = "SEARCH DONE, Resetting y-value for " + itemTSID + " " + itemClassTSID + " with " + bestMatchInfo.readBestMatchItemImageName();
                s = s + " from " + savedY + " to " + newY;
                printToFile.printDebugLine(this, s, 2);                          
            }
            else
            {
                s = "SEARCH DONE Ignoring y-value for " + itemTSID + " " + itemClassTSID + " with " + bestMatchInfo.readBestMatchItemImageName();
                s = s + " remains at " + savedY + " (new = " + newY + ")";
                printToFile.printDebugLine(this, s, 1);
            }
        }
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
    
    public void resetDuplicateAsMissingItem()
    {
        // This function is called if the item is found to have the same x,y as another item
        // Item will be marked as 'missing' - for quoins, will also be set to be of type 'mystery'
        // and the changes saved as a JSON file
        itemFound = false;
        bestMatchInfo.setBestMatchResult(NO_MATCH);  
        newItemX = MISSING_COORDS;
        newItemY = MISSING_COORDS;
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
    
    public String readItemVariantKey()
    {
        return itemVariantKey;
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
    
    public boolean itemIsAPlayerPlantedTree()
    {
        // Don't need to include enchanted trees in this list as they are not player planted trees
        if ((itemClassTSID.indexOf("trant", 0) == 0) || (itemClassTSID.equals("wood_tree")) || (itemClassTSID.indexOf("patch", 0) == 0))
        {
            return true;
        }
        return false;
    }
    
    public boolean itemHasMultipleImages()
    {
        // Some items have multiple images associated with them - to reflect maturity or whether been used up by players.        
        // Returns true if this an item we expect to be scanning for on a snap
        if (itemClassTSID.indexOf("npc_shrine_", 0) == 0)
        {
            return false;
        }
        else if ((itemClassTSID.indexOf("trant_", 0) == 0) || (itemClassTSID.indexOf("rock_", 0) == 0) || (itemClassTSID.indexOf("peat_", 0) == 0))
        {
            return true;
        }
        
        switch (itemClassTSID)
        {
            // These items have a single image associated with the item (variant)
            case "marker_qurazy":
            case "paper_tree":
            case "npc_mailbox":
            case "ice_knob":
            case "dust_trap":
            case "wall_button":
            case "visiting_stone":              
            case "npc_sloth":
            case "sloth_knocker":
            case "party_atm":
            case "race_ticket_dispenser":
            case "subway_gate":
            case "subway_map":
            case "bag_notice_board":
            case "quoin":
                return false;
            
            // These items have multiple images - several states per item (variant)
            case "wood_tree":
            case "wood_tree_enchanted":
            case "mortar_barnacle":
            case "jellisac":
            case "dirt_pile":
            case "street_spirit_zutto": // have flipped/normal image
                return true;
             
            // Whilst these don't have multiple states, they could have trees planted in them in snaps ... so get treated like trees for this purpose
            case "patch":
            case "patch_dark":
                return true;

            default:
                // Unexpected class tsid - should never be hit - so mark as only having single image
                printToFile.printDebugLine(this, itemTSID + " has unexpected class tsid " + itemClassTSID, 3);
                return true;
         }
    }
    
    public MatchInfo readBestMatchInfo()
    {
        return bestMatchInfo;
    }
    

}