class ItemImages
{
    // Contains an array of all the sets of item images that are needed for a street
    // Means we only load the quoin snaps once for example, and each quoin can use this set of loaded images.
    // Should keep memory usage low.
    
    // Process - during validation of street, set up the hashmap and load the item images - to check they are all there - and then unload them.
    // When the item is created, it loads the images into memory for that item class, and then requests the pointer to the structure containing these loaded images. 
    
    // This is an array with the key being the item classTSID, and the value being the appropriate list of images for that item
    // For now, always load up the items in the same order for each of the same items, hopefully it won't slow down things too much
    // as most of the searching work will be for quoins.
    HashMap<String,ArrayList<PNGFile>> itemImageHashMap;
    
    public void ItemImages()
    {
        itemImageHashMap = new HashMap<String,ArrayList<PNGFile>>();
    }
    
  
    public boolean initItemImages(String itemClassTSID, String origItemExtraInfo, int xCoOrd)
    { 
        // NB this function just loads up the file image names - they are not loaded into memory. This is done separately by calling function.
        ArrayList<PNGFile> itemImageArray = new ArrayList<PNGFile>();
        PNGFile itemPNG;
        int i;
        
        // First check to see if the item has already been loaded up for this street
        if (itemImageHashMap.get(itemClassTSID) != null)
        {
            printToFile.printDebugLine("Already loaded images for " + itemClassTSID + "(" + origItemExtraInfo + ")", 1);
            return true;
        }
        
        // The names of the images are deduced from the classTSID and info fields.
        // For some items, additional checks are done so that the most likely snap is
        // the first one to be used. 
        
        // First set create all the entries in the itemImageArray - loading the snaps will be done later
        if (itemClassTSID.indexOf("visiting_stone", 0) == 0)
        {
            // For visiting stones - load up the correct image using the item JSON x,y to know what is expected
            // As there is only ever one of these on a street, the order of images will always be correct
            if (xCoOrd < 0)
            {
                // visiting stone is on LHS of page - so load up the 'right' image to be first
                itemImageArray.add(new PNGFile(itemClassTSID + "_right.png", false));
                itemImageArray.add(new PNGFile(itemClassTSID + "_left.png", false));
            }
            else
            {
                // visiting stone is on RHS of page - so load up the 'left' image to be first
                itemImageArray.add(new PNGFile(itemClassTSID + "_left.png", false));
                itemImageArray.add(new PNGFile(itemClassTSID + "_right.png", false));
            }
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
            // Are dealing with a tree but this probably doesn't match the snap
            // Therefore OK to just load up the tree images in order of occurrence 
            // and hope that is not too slow. 
            // Paper trees are done separately as they can never be replanted as something else.
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
            String itemImagePNGName = itemClassTSID;
            if (origItemExtraInfo.length() > 0)
            {
                itemImagePNGName = itemImagePNGName + "_" + origItemExtraInfo;
            }
            
            // Work out how many item images exist
            String [] imageFilenames = null;
            imageFilenames = Utils.loadFilenames(dataPath(""), itemImagePNGName);

            if ((imageFilenames == null) || (imageFilenames.length == 0))
            {
                printToFile.printDebugLine("No files found in " + dataPath("") + " for item/info " + itemImagePNGName, 3);
                return false;
            }
       
            // Now create am entry for each of the snaps
            for (i = 0; i < imageFilenames.length; i++) 
            {
                // This currently never returns an error
                itemImageArray.add(new PNGFile(imageFilenames[i], false));
            } 
        }

        // Images have all been added (although not loaded into memory) - add the images for this item to the hash map
        itemImageHashMap.put(itemClassTSID, itemImageArray);
        printToFile.printDebugLine("Loaded images for " + itemClassTSID + "(" + origItemExtraInfo + ")", 1);
        
        return true;
    }
       
    public ArrayList<PNGFile> getItemImages(String itemClassTSID)
    {
        // Up to the calling function to make sure this is not null 
        // This function must be called after loadItemImages() below       
        return itemImageHashMap.get(itemClassTSID);
    }
    
    public boolean loadItemImages(String itemClassTSID)
    {
        ArrayList<PNGFile> itemImageArray = itemImageHashMap.get(itemClassTSID);
        
        if (itemImageArray == null)
        {
            // Shouldn't be loading item images if they've not in the hashmap
            printToFile.printDebugLine("Missing images names for " + itemClassTSID + " in hashmap", 3);
            return false;
        }
        
        // Work through the images loading them
        for (int i = 0; i < itemImageArray.size(); i++)
        {
            // loads the image into memory and sets up the width/height fields
            if (!itemImageArray.get(i).setupPNGImage())
            {
                printToFile.printDebugLine("Errors loading images for " + itemClassTSID, 3);
                return false;
            }
        }
        
       return true; 
    }
    
    public void unloadItemImages(String itemClassTSID)
    {
        ArrayList<PNGFile> itemImageArray = itemImageHashMap.get(itemClassTSID);
        
        if (itemImageArray == null)
        {
            // nothing to unload so just return - is this an error condition?
            printToFile.printDebugLine("Unloading images for " + itemClassTSID + " but nothing is loaded!", 1);
        }
        else
        {
        
            // Work through the images unloading them
            for (int i = 0; i < itemImageArray.size(); i++)
            {
                itemImageArray.get(i).unloadPNGImage();
            }
        }
    }
}