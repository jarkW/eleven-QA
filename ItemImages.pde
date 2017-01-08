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
    
    // These are used when constructing the image arrays - so can split out the functionality
    int imageCount = 0;
    ArrayList<PNGFile> itemImages = new ArrayList<PNGFile>();
    
    public ItemImages()
    {
        itemImageHashMap = new HashMap<String,ArrayList<PNGFile>>();
    }
    
  
    public boolean loadAllItemImages()
    { 
        int i;
        int j;
        int smallestMaturity;
        String [] imageFilenames;
        
        // This function initialises and then loads all images - done at start of program      
        itemImages.add(new PNGFile("quoin_xp.png", false));
        itemImages.add(new PNGFile("quoin_energy.png", false));
        itemImages.add(new PNGFile("quoin_mood.png", false));
        itemImages.add(new PNGFile("quoin_currants.png", false));
        itemImages.add(new PNGFile("quoin_favor.png", false));
        itemImages.add(new PNGFile("quoin_time.png", false));
        //itemImages.add(new PNGFile("quoin_mystery.png", false));
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("quoin"))
        {
            return false;
        }

        itemImages.add(new PNGFile("marker_qurazy.png", false));  
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("marker_qurazy"))
        {
            return false;
        }       

        // Load up the trees - most mature variants first as these are the most common
        // If the option is set, then only load up the mature images rather than all images
        if (configInfo.readUseMatureItemImagesOnly())
        {
            smallestMaturity = 10;
        }
        else
        {
            smallestMaturity = 1;
        }
        for (i = 10; i >= smallestMaturity; i--)
        { 
            // Some trees have maturity 1-10, wood trees are 1-6
            addImageForItem("trant_bean", "", str(i));
            addImageForItem("trant_fruit", "", str(i));
            addImageForItem("trant_bubble", "", str(i));
            addImageForItem("trant_spice", "", str(i));
            addImageForItem("trant_gas", "", str(i));
            addImageForItem("trant_egg", "", str(i));
            // Wood trees - need to include state 6 at same level as state 10 for all other trees
            // Wood trees have maturity 1-6 rather than 1-10
            // Although the random duplication means that some 'adult' wood trees are searched before others
            // because the fully grown version may be included in _6 or _2 files.
            j = i - 4;
            if (j > 0)
            {
                addImageForItem("wood_tree", "1", str(j));
                addImageForItem("wood_tree", "2", str(j));
                addImageForItem("wood_tree", "3", str(j));
                addImageForItem("wood_tree", "4", str(j));
            }
        }
        // Add in images for dead trees
        itemImages.add(new PNGFile("trant_bean_dead.png", false));
        itemImages.add(new PNGFile("trant_fruit_dead.png", false));
        itemImages.add(new PNGFile("trant_bubble_dead.png", false));
        itemImages.add(new PNGFile("trant_spice_dead.png", false));
        itemImages.add(new PNGFile("trant_gas_dead.png", false));
        itemImages.add(new PNGFile("trant_egg_dead.png", false));

        // Also include dirt patches - as these might be what exists on snaps if trees had been killed
        itemImages.add(new PNGFile("patch_dark.png", false)); 
        itemImages.add(new PNGFile("patch.png", false)); 

        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("trees"))
        {
            return false;
        }
        
        itemImages.add(new PNGFile("visiting_stone_left.png", false));  
        itemImages.add(new PNGFile("visiting_stone_right.png", false)); 
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("visiting_stone"))
        {
            return false;
        }
  
        itemImages.add(new PNGFile("npc_mailbox_mailboxLeft.png", false));  
        itemImages.add(new PNGFile("npc_mailbox_mailboxRight.png", false)); 
         // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("npc_mailbox"))
        {
            return false;
        }
        
        itemImages.add(new PNGFile("paper_tree.png", false));  
        itemImageHashMap.put("paper_tree", itemImages);
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("paper_tree"))
        {
            return false;
        }
        
        // Now create one entry for each of the rock snaps e.g. rock_beryl_1, rock_beryl_2, rock_beryl_3
        for (j = 1; j < 4; j++)
        {
            // Load up the mature version of the rock first.
            // chunks_remaining goes from 50 down to 10
            // As some of the different states have identical images, some of the images have not been created - this does
            // not create an error as addImageForItem handles this scenario (more efficient than searching identical images)
            // If the option is set, then only load up the mature images rather than all images
            if (configInfo.readUseMatureItemImagesOnly())
            {
                smallestMaturity = 5;
            }
            else
            {
                smallestMaturity = 1;
            }
            
            // Beryl
            for (i = 5; i >= smallestMaturity; i--)
            { 
                // As the string is of the form rock_beryl_1_x, treat it as if we are calling the function for variant/state
                addImageForItem("rock_beryl", str(j), str(i * 10));
            }
            // Now add this to the hashmap
            if (!addToHashMapAndLoadImages("rock_beryl_" + str(j)))
            {
                return false;
            }
            
            // Dullite
            for (i = 5; i >= smallestMaturity; i--)
            { 
                // As the string is of the form rock_dullite_1_x, treat it as if we are calling the function for variant/state
                addImageForItem("rock_dullite", str(j), str(i * 10));
            }
            // Now add this to the hashmap
            if (!addToHashMapAndLoadImages("rock_dullite_" + str(j)))
            {
                return false;
            }
            
            // Sparkly
            for (i = 5; i >= smallestMaturity; i--)
            { 
                // As the string is of the form rock_sparkly_1_x, treat it as if we are calling the function for variant/state
                addImageForItem("rock_sparkly", str(j), str(i * 10));
            }
            // Now add this to the hashmap
            if (!addToHashMapAndLoadImages("rock_sparkly_" + str(j)))
            {
                return false;
            }
            
            // Metal
            for (i = 5; i >= smallestMaturity; i--)
            { 
                // As the string is of the form rock_metal_1_x, treat it as if we are calling the function for variant/state
                addImageForItem("rock_metal", str(j), str(i * 10));
            }
            // Now add this to the hashmap
            if (!addToHashMapAndLoadImages("rock_metal_" + str(j)))
            {
                return false;
            }
        }

        // Now create one entry for each of the shrine snaps - one per shrine as only come in right versions
        imageFilenames = null;
        imageFilenames = Utils.loadFilenames(dataPath(""), "npc_shrine", ".png");
        if ((imageFilenames == null) || (imageFilenames.length == 0))
        {
            printToFile.printDebugLine(this, "No files found in " + dataPath("") + " for npc_shrine*.png", 3);
            return false;
        }
        for (i = 0; i < imageFilenames.length; i++) 
        {
            itemImages.add(new PNGFile(imageFilenames[i], false)); 
            // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
            if (!addToHashMapAndLoadImages(imageFilenames[i].replace("_right.png", "")))
            {
                return false;
            }
        } 
        
        // Now create an entry for barnacles
        // Barnacles have a scrape state of 1-4, but state 1 is unusable for searching.
        // Load up all the mature versions of the barnacles first
        // If the option is set, then only load up the mature images rather than all images
        if (configInfo.readUseMatureItemImagesOnly())
        {
            smallestMaturity = 4;
        }
        else
        {
            smallestMaturity = 2;
        }
        for (i = 4; i >= smallestMaturity; i--)
        { 
            addImageForItem("mortar_barnacle", "1", str(i));
            addImageForItem("mortar_barnacle", "2", str(i));
            addImageForItem("mortar_barnacle", "3", str(i));
            addImageForItem("mortar_barnacle", "4", str(i));
            addImageForItem("mortar_barnacle", "5", str(i));
            addImageForItem("mortar_barnacle", "6", str(i));
        }
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("mortar_barnacle"))
        {
            return false;
        }
        
        // Now create one entry for each of the peat snaps i.e. for peat_1, peat_2, peat_3
        // If the option is set, then only load up the mature images rather than all images
        if (configInfo.readUseMatureItemImagesOnly())
        {
            smallestMaturity = 4;
        }
        else
        {
            smallestMaturity = 0;
        }
        for (j = 1; j < 4; j++)
        {
            // Load up the mature version of the peat first.
            // harvests_remaining goes from 4 to 0
            for (i = 4; i >= smallestMaturity; i--)
            { 
                // As the string is of the form peat_1_x, treat it as if we are calling the function for variant/state
                addImageForItem("peat", str(j), str(i));
            }
            // Now add this to the hashmap
            if (!addToHashMapAndLoadImages("peat_" + str(j)))
            {
                return false;
            }
        }
                
        // Now create an entry for jellisac
        // Jellisacs have a scoop state of 1-5, but state 1 is unusable for searching.
        // Load up all the mature versions of the jellisacs first
        // If the option is set, then only load up the mature images rather than all images
        if (configInfo.readUseMatureItemImagesOnly())
        {
            smallestMaturity = 5;
        }
        else
        {
            smallestMaturity = 2;
        }
        for (i = 5; i >= smallestMaturity; i--)
        { 
            addImageForItem("jellisac", "1", str(i));
            addImageForItem("jellisac", "2", str(i));
            addImageForItem("jellisac", "3", str(i));
            addImageForItem("jellisac", "4", str(i));
        }
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("jellisac"))
        {
            return false;
        }
        
        // Now create an entry for ice nubbin
        itemImages.add(new PNGFile("ice_knob_1.png", false)); 
        itemImages.add(new PNGFile("ice_knob_2.png", false)); 
        itemImages.add(new PNGFile("ice_knob_3.png", false)); 
        itemImages.add(new PNGFile("ice_knob_4.png", false)); 
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("ice_knob"))
        {
            return false;
        }
        
        // Now create an entry for dirt pile
        // Dirt piles have a dirt_state of 1-11.
        // Load up all the full versions of the dirt pile first
        // If the option is set, then only load up the mature images rather than all images
        if (configInfo.readUseMatureItemImagesOnly())
        {
            smallestMaturity = 11;
        }
        else
        {
            smallestMaturity = 1;
        }
        for (i = 11; i >= smallestMaturity; i--)
        { 
            addImageForItem("dirt_pile", "dirt1", str(i));
            addImageForItem("dirt_pile", "dirt2", str(i));
        }
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("dirt_pile"))
        {
            return false;
        }
        
        // Now create an entry for dust trap - only ever type A
        itemImages.add(new PNGFile("dust_trap_A.png", false)); 
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("dust_trap"))
        {
            return false;
        }
        
        // Now create an entry for party atm
        itemImages.add(new PNGFile("party_atm.png", false)); 
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("party_atm"))
        {
            return false;
        }
        
        // Now create an entry for Race Ticket Dispenser
        itemImages.add(new PNGFile("race_ticket_dispenser.png", false)); 
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("race_ticket_dispenser"))
        {
            return false;
        }
        
        // Now create an entry for Wall Button
        itemImages.add(new PNGFile("wall_button.png", false)); 
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("wall_button"))
        {
            return false;
        }
        
         // Now create an entry for red subway buttons
        itemImages.add(new PNGFile("subway_gate_left.png", false));
        itemImages.add(new PNGFile("subway_gate_right.png", false)); 
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("subway_gate"))
        {
            return false;
        }
        
        // Now create an entry for subway map
        itemImages.add(new PNGFile("subway_map.png", false));
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("subway_map"))
        {
            return false;
        }
        
        // Now create an entry for Notice Board
        itemImages.add(new PNGFile("bag_notice_board.png", false));
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("bag_notice_board"))
        {
            return false;
        }
        
        // Now create an entry for sloth knocker
        itemImages.add(new PNGFile("sloth_knocker.png", false));
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("sloth_knocker"))
        {
            return false;
        }
        
        // Now create an entry for sloth (right is default sloth direction) 
        itemImages.add(new PNGFile("npc_sloth_right.png", false));
        itemImages.add(new PNGFile("npc_sloth_left.png", false));
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("npc_sloth"))
        {
            return false;
        }
        
        // Now create an entry for enchanted wood trees
        // Load up mature variant first i.e. 6
        // If the option is set, then only load up the mature images rather than all images
        if (configInfo.readUseMatureItemImagesOnly())
        {
            smallestMaturity = 6;
        }
        else
        {
            smallestMaturity = 1;
        }
        for (i = 6; i >= smallestMaturity; i--)
        {
            addImageForItem("wood_tree_enchanted", "1", str(i));
            addImageForItem("wood_tree_enchanted", "2", str(i));
            addImageForItem("wood_tree_enchanted", "3", str(i));
            addImageForItem("wood_tree_enchanted", "4", str(i));
        }
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("wood_tree_enchanted"))
        {
            return false;
        }
        
        // Now create an entry for zutto street vendor
        itemImages.add(new PNGFile("street_spirit_zutto_normal.png", false));
        itemImages.add(new PNGFile("street_spirit_zutto_flipped.png", false));
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("street_spirit_zutto"))
        {
            return false;
        }
       
        printToFile.printDebugLine(this, "Loaded " + imageCount + " images in hashmap", 2);
        return true;
    }
    
    boolean addToHashMapAndLoadImages(String hashkey)
    {
        itemImageHashMap.put(hashkey, itemImages);
        // Now load the images into memory
        if (!loadItemImages(hashkey))
        {
            // error
            return false;
        }
        imageCount = imageCount + itemImages.size();
        
        // Now new the array ready for the next set of items
        itemImages = new ArrayList<PNGFile>();
        return true;
    }
    
    void addImageForItem(String classTSID, String variant, String maturity)
    {
        String fname = classTSID;
        
        if (variant.length() > 0)
        {
            fname = fname + "_" + variant;
        }
        
        if (maturity.length() > 0)
        {
            fname = fname + "_" + maturity;
        }
        fname = fname + ".png";
        
        // Only add the item if it exists - wood trees share images across different aged trees of the same variant and so are not 
        // always in numerical order. E.g. have images for variant 3 for maturity 1, 2 (which does 3-5 also) and 6
        File file = new File(dataPath(fname));
        if (file.exists())
        {
            itemImages.add(new PNGFile(fname, false));
        }
        else
        {
            printToFile.printDebugLine(this, "Non-error - missing image for " + fname, 1);
        }
    }
    
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
    
     public int sizeOf()
    {
        return itemImageHashMap.size();
    }
    
}