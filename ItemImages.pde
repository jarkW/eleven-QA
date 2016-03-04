class ItemImages
{
    // Contains an array of all the sets of item images that are needed for a street
    // Means we only load the quoin snaps once for example, and each quoin can use this set of loaded images.
    // Should keep memory usage low.
        
    // This is an array with the key being the item classTSID, and the value being the appropriate list of images for that item
    // For now, always load up the items in the same order for each of the same items, hopefully it won't slow down things too much
    // as most of the searching work will be for quoins.
    HashMap<String,ArrayList<PNGFile>> itemImageHashMap;
    //HashMap<String,HashMap<String, PNGFile>> itemImageHashMap2;
    
    public ItemImages()
    {
        itemImageHashMap = new HashMap<String,ArrayList<PNGFile>>();
    }
    
  
    public boolean loadAllItemImages()
    { 
        // This function initialises and then loads all images - done at start of program
        ArrayList<PNGFile> itemImages = new ArrayList<PNGFile>();       
        
        itemImages.add(new PNGFile("quoin_xp.png", false));
        itemImages.add(new PNGFile("quoin_energy.png", false));
        itemImages.add(new PNGFile("quoin_mood.png", false));
        itemImages.add(new PNGFile("quoin_currants.png", false));
        itemImages.add(new PNGFile("quoin_favor.png", false));
        itemImages.add(new PNGFile("quoin_time.png", false));
        itemImageHashMap.put("quoin", itemImages);
        // Now load the images into memory
        if (!loadItemImages("quoin"))
        {
            return false;
        }
        
        itemImages = new ArrayList<PNGFile>();
        itemImages.add(new PNGFile("marker_qurazy.png", false));  
        itemImageHashMap.put("marker_qurazy", itemImages);
        // Now load the images into memory
        if (!loadItemImages("marker_qurazy"))
        {
            return false;
        }
        
        itemImages = new ArrayList<PNGFile>();
        itemImages.add(new PNGFile("trant_bean.png", false));
        itemImages.add(new PNGFile("trant_fruit.png", false));
        itemImages.add(new PNGFile("trant_bubble.png", false));
        itemImages.add(new PNGFile("trant_spice.png", false));
        itemImages.add(new PNGFile("trant_gas.png", false));
        itemImages.add(new PNGFile("trant_egg.png", false));
        itemImages.add(new PNGFile("wood_tree_1.png", false));    
        itemImages.add(new PNGFile("wood_tree_2.png", false));  
        itemImages.add(new PNGFile("wood_tree_3.png", false));  
        itemImages.add(new PNGFile("wood_tree_4.png", false));  
        itemImageHashMap.put("trees", itemImages);
        // Now load the images into memory
        if (!loadItemImages("trees"))
        {
            return false;
        }
        
        itemImages = new ArrayList<PNGFile>();
        itemImages.add(new PNGFile("visiting_stone_left.png", false));  
        itemImages.add(new PNGFile("visiting_stone_right.png", false)); 
        itemImageHashMap.put("visiting_stone", itemImages);
        // Now load the images into memory
        if (!loadItemImages("visiting_stone"))
        {
            return false;
        }
  
        itemImages = new ArrayList<PNGFile>();
        itemImages.add(new PNGFile("npc_mailbox_mailboxLeft.png", false));  
        itemImages.add(new PNGFile("npc_mailbox_mailboxRight.png", false)); 
        itemImageHashMap.put("npc_mailbox", itemImages);
        // Now load the images into memory
        if (!loadItemImages("npc_mailbox"))
        {
            return false;
        }
        
        itemImages = new ArrayList<PNGFile>();
        itemImages.add(new PNGFile("paper_tree.png", false));  
        itemImageHashMap.put("paper_tree", itemImages);
        // Now load the images into memory
        if (!loadItemImages("paper_tree"))
        {
            return false;
        }
        
        // Now create one entry for each of the rock snaps
        String [] imageFilenames = null;
        imageFilenames = Utils.loadFilenames(dataPath(""), "rock_");
        if ((imageFilenames == null) || (imageFilenames.length == 0))
        {
            printToFile.printDebugLine(this, "No files found in " + dataPath("") + " for rock*.png", 3);
            return false;
        }
        for (int i = 0; i < imageFilenames.length; i++) 
        {
            itemImages = new ArrayList<PNGFile>();
            itemImages.add(new PNGFile(imageFilenames[i], false)); 
            String className = imageFilenames[i].replace(".png", "");
            itemImageHashMap.put(className, itemImages);
            // Now load the images into memory
            if (!loadItemImages(className))
            {
                return false;
            }
        } 
        

 
        // Now create one entry for each of the shrine snaps - one per shrine as only come in right versions
        imageFilenames = null;
        imageFilenames = Utils.loadFilenames(dataPath(""), "npc_shrine");
        if ((imageFilenames == null) || (imageFilenames.length == 0))
        {
            printToFile.printDebugLine(this, "No files found in " + dataPath("") + " for npc_shrine*.png", 3);
            return false;
        }
        for (int i = 0; i < imageFilenames.length; i++) 
        {
            itemImages = new ArrayList<PNGFile>();
            itemImages.add(new PNGFile(imageFilenames[i], false)); 
            String className = imageFilenames[i].replace("_right.png", "");
            itemImageHashMap.put(className, itemImages);
            // Now load the images into memory
            if (!loadItemImages(className))
            {
                return false;
            }
        } 

// TO DO
            // Can search for images based on the class_tsid and info fields
            // Rest of items do not have a dir field (or in case of shrines, only ever set to right, so only one image to load
            // wall_button (load up both variants, left will be first, which suits us)
            // sloth_knocker
            // patch
            // patch_dark
            // party_atm
            // race_ticket_dispenser
            // peat_*
            // marker_qurazy
            // dirt_pile_*
            // mortar_barnacle_*
            // jellisac_*
            // ice_knob_*
            // dust_trap_*
        
        return true;
    }
    /*
    public boolean loadItemImages(String itemClassTSID, String origItemExtraInfo)
    {
        // IS THIS EVER USED???
        
        
        // NB this function just loads up the file image names - they are not loaded into memory. This is done separately by calling function.
        ArrayList<PNGFile> itemImages = new ArrayList<PNGFile>();
        PNGFile itemPNG;
        int i;
        
        // First check to see if the item has already been loaded up for this street
        if (itemImageHashMap.get(itemClassTSID) != null)
        {
            printToFile.printDebugLine(this, "Already loaded images for " + itemClassTSID + "(" + origItemExtraInfo + ")", 1);
            return true;
        }
        
        // The names of the images are deduced from the classTSID and info fields.
        // For some items, additional checks are done so that the most likely snap is
        // the first one to be used. 
        
        // First set create all the entries in the itemImages - loading the snaps will be done later
        if (itemClassTSID.indexOf("npc_sloth", 0) == 0)
        {
            printToFile.printDebugLine(this, "NEED TO CONFIGURE SLOTH in setupItemImages ", 3);
            return false;
        }
        else if (itemClassTSID.indexOf("quoin", 0) == 0)
        {
            if (!configInfo.readChangeXYOnly())
            {
                // As we are setting quoins from the snap, load up the most common quoins first
                itemImages.add(new PNGFile("quoin_xp.png", false));
                itemImages.add(new PNGFile("quoin_energy.png", false));
                itemImages.add(new PNGFile("quoin_mood.png", false));
                itemImages.add(new PNGFile("quoin_currants.png", false));
                itemImages.add(new PNGFile("quoin_favor.png", false));
                itemImages.add(new PNGFile("quoin_time.png", false));
            }
            else
            {
                // As only changing the x,y can just load up the relevant snap (including mystery quoins)
                itemImages.add(new PNGFile(itemClassTSID + "_" + origItemExtraInfo + ".png", false));
            }
        }
        else if ((itemClassTSID.indexOf("wood_tree", 0) == 0) || (itemClassTSID.indexOf("trant_", 0) == 0))
        {
            // Are dealing with a tree but this probably doesn't match the snap
            // Therefore OK to just load up the tree images in order of occurrence 
            // and hope that is not too slow. 
            // Paper trees are done separately as they can never be replanted as something else.
            itemImages.add(new PNGFile("trant_bean.png", false));
            itemImages.add(new PNGFile("trant_fruit.png", false));
            itemImages.add(new PNGFile("trant_bubble.png", false));
            itemImages.add(new PNGFile("trant_spice.png", false));
            itemImages.add(new PNGFile("trant_gas.png", false));
            itemImages.add(new PNGFile("trant_egg.png", false));
            itemImages.add(new PNGFile("wood_tree_1.png", false));    
            itemImages.add(new PNGFile("wood_tree_2.png", false));  
            itemImages.add(new PNGFile("wood_tree_3.png", false));  
            itemImages.add(new PNGFile("wood_tree_4.png", false));             
        }
        else
        {
            // Can search for images based on the class_tsid and info fields
            // Rest of items do not have a dir field (or in case of shrines, only ever set to right, so only one image to load
            // npc_shrine_* (will only ever be _right variety)
            // visiting_stone (just load up both variants)
            // wall_button (load up both variants, left will be first, which suits us)
            // npc_mailbox (load up both variants)
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
                printToFile.printDebugLine(this, "No files found in " + dataPath("") + " for item/info " + itemImagePNGName, 3);
                return false;
            }
       
            // Now create am entry for each of the snaps
            for (i = 0; i < imageFilenames.length; i++) 
            {
                // This currently never returns an error
                itemImages.add(new PNGFile(imageFilenames[i], false));
            } 
        }

        // Images have all been added (although not loaded into memory) - add the images for this item to the hash map
        itemImageHashMap.put(itemClassTSID, itemImages);
        printToFile.printDebugLine(this, "Loaded images for " + itemClassTSID + "(" + origItemExtraInfo + ")", 1);
        
        return true;
    }
   */    
    public ArrayList<PNGFile> getItemImages(String itemClassTSID)
    {
        // Up to the calling function to make sure this is not null 
        // This function must be called after loadItemImages() below       
        return itemImageHashMap.get(itemClassTSID);
    }
    
    public boolean loadItemImages(String itemClassTSID)
    {
        ArrayList<PNGFile> itemImages = itemImageHashMap.get(itemClassTSID);
        
        if (itemImages == null)
        {
            // Shouldn't be loading item images if they've not in the hashmap
            printToFile.printDebugLine(this, "Missing images names for " + itemClassTSID + " in hashmap", 3);
            return false;
        }
        
        // Work through the images loading them
        for (int i = 0; i < itemImages.size(); i++)
        {
            // loads the image into memory and sets up the width/height fields
            if (!itemImages.get(i).setupPNGImage())
            {
                printToFile.printDebugLine(this, "Errors loading images for " + itemClassTSID, 3);
                return false;
            }
        }
        
       return true; 
    }
    
    public void unloadItemImages(String itemClassTSID)
    {
        ArrayList<PNGFile> itemImages = itemImageHashMap.get(itemClassTSID);
        
        if (itemImages == null)
        {
            // nothing to unload so just return - is this an error condition?
            printToFile.printDebugLine(this, "Unloading images for " + itemClassTSID + " but nothing is loaded!", 1);
        }
        else
        {
        
            // Work through the images unloading them
            for (int i = 0; i < itemImages.size(); i++)
            {
                itemImages.get(i).unloadPNGImage();
            }
        }
    }
}