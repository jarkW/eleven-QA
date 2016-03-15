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
            itemImages.add(new PNGFile(imageFilenames[i], false)); 
            // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
            if (!addToHashMapAndLoadImages(imageFilenames[i].replace(".png", "")))
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
            itemImages.add(new PNGFile(imageFilenames[i], false)); 
            // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
            if (!addToHashMapAndLoadImages(imageFilenames[i].replace("_right.png", "")))
            {
                return false;
            }
        } 
        
        // Now create an entry for barnacles
        itemImages.add(new PNGFile("mortar_barnacle_1.png", false)); 
        itemImages.add(new PNGFile("mortar_barnacle_2.png", false)); 
        itemImages.add(new PNGFile("mortar_barnacle_3.png", false)); 
        itemImages.add(new PNGFile("mortar_barnacle_4.png", false)); 
        itemImages.add(new PNGFile("mortar_barnacle_5.png", false)); 
        itemImages.add(new PNGFile("mortar_barnacle_6.png", false)); 
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("mortar_barnacle"))
        {
            return false;
        }
        
        // Now create one entry for each of the peat snaps
        imageFilenames = null;
        imageFilenames = Utils.loadFilenames(dataPath(""), "peat_");
        if ((imageFilenames == null) || (imageFilenames.length == 0))
        {
            printToFile.printDebugLine(this, "No files found in " + dataPath("") + " for peat*.png", 3);
            return false;
        }
        for (int i = 0; i < imageFilenames.length; i++) 
        {
            itemImages.add(new PNGFile(imageFilenames[i], false)); 
            // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
            if (!addToHashMapAndLoadImages(imageFilenames[i].replace(".png", "")))
            {
                return false;
            }
        } 
        
        // Now create an entry for jellisac
        itemImages.add(new PNGFile("jellisac_1.png", false)); 
        itemImages.add(new PNGFile("jellisac_2.png", false)); 
        itemImages.add(new PNGFile("jellisac_3.png", false)); 
        itemImages.add(new PNGFile("jellisac_4.png", false)); 
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
        
        // Now create an entry for dark dirt patch
        itemImages.add(new PNGFile("patch_dark.png", false)); 
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("patch_dark"))
        {
            return false;
        }
        
        // Now create an entry for dirt patch
        itemImages.add(new PNGFile("patch.png", false)); 
        // This function will also update the imageCount and then new the itemImages array list ready for the next set of images
        if (!addToHashMapAndLoadImages("patch"))
        {
            return false;
        }
        
        // Now create an entry for dirt pile
        itemImages.add(new PNGFile("dirt_pile_dirt1.png", false)); 
        itemImages.add(new PNGFile("dirt_pile_dirt2.png", false)); 
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

        printToFile.printDebugLine(this, "Loaded " + imageCount + "images in hashmap", 1);
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