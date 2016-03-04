class FragmentFindOld
{
    /*
    boolean okFlag;
    boolean searchDone;
    
    final int defSearchBox = 20; // for usual searches
    final int narrowSearchWidthBox = 2; // for QQ/quoins to just find changes in y
          
    SpiralSearch spiralSearch;
    ItemInfo thisItemInfo;
    
    // x,y on street where need to start the item search (i.e. converted item JSON x,y)
    int startX;
    int startY;
    
    int newItemX;
    int newItemY;
    String newItemExtraInfo;
    boolean itemFound;
    
    int itemImageBeingUsed;
    int streetImageBeingUsed;
    
    // Saved item information we need here - easier to read
    ArrayList<PNGFile> itemImages;
    ArrayList<PNGFile> streetSnaps;         
  
    // constructor
    public FragmentFindOld(ItemInfo itemInfo)
    {
        okFlag = true;
        
        searchDone = false;
        streetImageBeingUsed = 0;
        newItemX = missCoOrds;
        newItemY = missCoOrds;
        newItemExtraInfo = "";
        itemFound = false;
        
        thisItemInfo = itemInfo;
        
        // Copy arrays we need from the item object - to keep the code simpler onl      
        itemImages = itemInfo.readItemImages();
        if (itemImages == null)
        {
            printToFile.printDebugLine(this, "Failed to retrieve item images for item " + thisItemInfo.readItemClassTSID() + "(" + thisItemInfo.readItemTSID() + ")", 3);
            okFlag = false;
            return;
        }
                
        if (configInfo.readChangeXYOnly() && thisItemInfo.readItemClassTSID().equals("quoin"))
        {
            // can just set itemImageBeingUsed to the correct number 
            // which will force it to just use that image to check with
            //So for quoins, just select the image we are interested in - for everything else, once the item is found once, it won't be searched for again
            // so less important
            for (int i = 0; i < itemImages.size(); i++)
            {
                if (itemImages.get(i).readPNGImageName().indexOf(thisItemInfo.readOrigItemExtraInfo()) != -1)
                {
                    itemImageBeingUsed = i;
                }
            }
        }
        else
        {
            // start at the beginning
            itemImageBeingUsed = 0;
        }
        
        printToFile.printDebugLine(this, "Starting search with image number " + itemImageBeingUsed + " i.e. " + itemImages.get(itemImageBeingUsed).readPNGImageName(), 1);
        
        streetSnaps = streetInfo.getStreetImageArray();
        printToFile.printDebugLine(this, "Size of street snap array is " + streetInfo.streetSnaps.size(), 1);

        // Need to convert the JSON x,y to relate to the street snap - use the first loaded street snap
        startX = thisItemInfo.readOrigItemX() + streetSnaps.get(0).PNGImage.width/2 + thisItemInfo.readFragOffsetX();
        startY = thisItemInfo.readOrigItemY() + streetSnaps.get(0).PNGImage.height + thisItemInfo.readFragOffsetY();
        
        // Most items will only be searched for until found once - so once this happens, the search moves on to the next item
        // As this is the first search being carried out for item, always have a 20 x 20 window to search with startX, startY at centre of that box
        spiralSearch = new SpiralSearch(itemImages.get(itemImageBeingUsed).readPNGImage(), 
                                        streetSnaps.get(streetImageBeingUsed).readPNGImage(), 
                                        thisItemInfo.readItemClassTSID(),
                                        startX, startY, defSearchBox, defSearchBox);
                       
        printToFile.printDebugLine(this, "Starting search for item " + thisItemInfo.readItemClassTSID() + " (" + thisItemInfo.readItemTSID() + ") with x,y " + str(startX) + "," + str(startY), 2);
    }
        
    public boolean searchForFragment()
    {
        String debugInfo = "";
        
        display.clearDisplay();
        display.showStreetName();
        
        display.showItemImage(itemImages.get(itemImageBeingUsed).readPNGImage(), thisItemInfo.readOrigItemX() + "," + thisItemInfo.readOrigItemY());
        display.showStreetImage(streetSnaps.get(streetImageBeingUsed).readPNGImage(), 
                                itemImages.get(itemImageBeingUsed).readPNGImageWidth(), 
                                itemImages.get(itemImageBeingUsed).readPNGImageHeight(),
                                startX, startY);
        
        // Carry out the search for the item and depending on the result might then move on to look at the next image
        if (spiralSearch.searchForItem())
        {           
            itemFound = true;
            // Match has been found - might be perfect or good enough - so save the information         
            if (thisItemInfo.readItemClassTSID().equals("quoin") || thisItemInfo.readItemClassTSID().equals("marker_qurazy"))
            {
                // Need to search all snaps for quoins/QQ - so can find the lowest y-value for the quoin.
                
                // Only save the x,y if this is the first time the item has been found on the snap, or if the
                // found Y is lower than the previous found Y (i.e. bottom of bounce found)
                if ((newItemX == missCoOrds) || (newItemY < (thisItemInfo.readOrigItemY() + spiralSearch.readDiffY())))
                {
                    printToFile.printDebugLine(this, "Quoin - replacing previous y value of " + newItemY + " with " + thisItemInfo.readOrigItemY() + spiralSearch.readDiffY(), 2);
                    newItemX = thisItemInfo.readOrigItemX() + spiralSearch.readDiffX();
                    newItemY = thisItemInfo.readOrigItemY() + spiralSearch.readDiffY(); 
                }
                
                if (thisItemInfo.readItemClassTSID().equals("quoin") && newItemExtraInfo.length() == 0)
                {
                    // First time we've found this quoin - as 'type' not set 

                    // As matched item image is the current one, extract the extra information from the item image filename
                    newItemExtraInfo = extractItemInfoFromItemImageFilename();
                }

                // Now repeat the search with the next street image - but using this image file
                debugInfo = spiralSearch.debugRGBInfo(); // extract before we destroy the information
                spiralSearch = null;
                streetImageBeingUsed++;    
                if (streetImageBeingUsed >= streetSnaps.size())
                {
                    // No more snaps to search
                    searchDone = true;
                }
                else
                {
                    // Set up for fresh search for this item, but using next street snap.
                    // As only interested in changes in y value, can reduce the width of the search box to speed things up
                    spiralSearch = new SpiralSearch(itemImages.get(itemImageBeingUsed).readPNGImage(), 
                                                    streetSnaps.get(streetImageBeingUsed).readPNGImage(), 
                                                    thisItemInfo.readItemClassTSID(),
                                                    startX + spiralSearch.readDiffX(), 
                                                    startY + spiralSearch.readDiffY(), 
                                                    narrowSearchWidthBox, defSearchBox);
                    if (!spiralSearch.readOkFlag()) 
                    {
                        return false;
                    }                                
                    printToFile.printDebugLine(this, "Continuing search for quoin/QQ (" + thisItemInfo.readItemTSID() + ") with x,y " + str(startX) + "," + str(startY) + " using street snap " + streetSnaps.get(streetImageBeingUsed).readPNGImageName(), 2);
                }
            }
            else
            {
                // For all non-quoins/QQ - only need to find single match for the search to count
                newItemX = thisItemInfo.readOrigItemX() + spiralSearch.readDiffX();
                newItemY = thisItemInfo.readOrigItemY() + spiralSearch.readDiffY(); 
                // As matched item image is the current one, extract the extra information from the item image filename
                newItemExtraInfo = extractItemInfoFromItemImageFilename();
                debugInfo = spiralSearch.debugRGBInfo(); 
                searchDone = true;  
            }
        }
        else
        {
           // Item has not been found - so move onto the next street image for this item (unless quoin - in which case need to search for all quoin types before changing
           // streets
           debugInfo = spiralSearch.debugRGBInfo(); // extract before we destroy the information
           spiralSearch = null;
                       
            // Still searching to find out what kind of quoin we have - need to search for the next quoin image, on the same street 
            if (thisItemInfo.readItemClassTSID().equals("quoin") && newItemX == missCoOrds)
            {
                // set up for the next quoin type
                itemImageBeingUsed++;
                if (itemImageBeingUsed >= itemImages.size())
                {
                    // No more quoin item images to search - so OK to skip to next street, starting with first quoin image again
                    streetImageBeingUsed++; 
                    printToFile.printDebugLine(this, "streetImageBeingUsed is now " + streetImageBeingUsed + " array size is " + streetSnaps.size(), 1);
                    if (streetImageBeingUsed >= streetSnaps.size())
                    {
                        // No more snaps to search
                        // If the quoin has not been found, then set the type to be mystery, so user can reset manually
                        // And keep existing x,y
                        newItemX = thisItemInfo.readOrigItemX();
                        newItemY = thisItemInfo.readOrigItemY();
                        newItemExtraInfo = "mystery";
                        searchDone = true;
                    }
                    itemImageBeingUsed = 0;
                }
                if (!searchDone)
                {
                    spiralSearch = new SpiralSearch(itemImages.get(itemImageBeingUsed).readPNGImage(), 
                                                    streetSnaps.get(streetImageBeingUsed).readPNGImage(), 
                                                    thisItemInfo.readItemClassTSID(),
                                                    startX, startY, defSearchBox, defSearchBox);
                    if (!spiralSearch.readOkFlag()) 
                    {
                        return false;
                    }
                    printToFile.printDebugLine(this, "Continuing search for missing quoin ("  + thisItemInfo.readItemTSID() + ") with x,y " + str(startX) + "," + str(startY) + " using street snap " + streetSnaps.get(streetImageBeingUsed).readPNGImageName(), 2);
                }
            }
            else
            {
                // OK to move on to the next street - all other items and quoins with known types which have yet to be found
                streetImageBeingUsed++;    
                if (streetImageBeingUsed >= streetSnaps.size())
                {
                    // No more snaps to search - set quoins to be mystery - calling function will check for this
                    if (thisItemInfo.readItemClassTSID().equals("quoin") && newItemX == missCoOrds)
                    {
                        // Item was not found - so set the new x,y to match the original x,y. 
                        // For quoins, default the type to mystery so clear which ones have not been set
                        newItemX = thisItemInfo.readOrigItemX();
                        newItemY = thisItemInfo.readOrigItemY();
                        newItemExtraInfo = "mystery";
                    }
                    searchDone = true;
                }
                else
                {
                    // If a quoin has previously been found on a search, then can use different search window as only interested in new values of y.
                    // Also start at the best found x,y found so far
                    if ((thisItemInfo.readItemClassTSID().equals("quoin") || thisItemInfo.readItemClassTSID().equals("marker_qurazy")) && newItemX != missCoOrds)
                    {
                        spiralSearch = new SpiralSearch(itemImages.get(itemImageBeingUsed).readPNGImage(), 
                                                    streetSnaps.get(streetImageBeingUsed).readPNGImage(), 
                                                    thisItemInfo.readItemClassTSID(),
                                                    startX + thisItemInfo.readOrigItemX() - newItemX,
                                                    startY + thisItemInfo.readOrigItemY() - newItemY,
                                                    narrowSearchWidthBox, defSearchBox);
                            if (!spiralSearch.readOkFlag()) 
        {
            okFlag = false;
            return;
        }
                        printToFile.printDebugLine(this, "Continuing search for quoin/QQ (" + thisItemInfo.readItemTSID() + ") with x,y " + str(startX) + "," + str(startY) + " using street snap " + streetSnaps.get(streetImageBeingUsed).readPNGImageName(), 2);
                    }
                    else
                    {
                        // Set up for fresh search for this item, but using next street snap
                        spiralSearch = new SpiralSearch(itemImages.get(itemImageBeingUsed).readPNGImage(), 
                                                        streetSnaps.get(streetImageBeingUsed).readPNGImage(), 
                                                        thisItemInfo.readItemClassTSID(),
                                                        startX, startY, defSearchBox, defSearchBox);
                        printToFile.printDebugLine(this, "Continuing search for item " + thisItemInfo.readItemClassTSID() + " (" + thisItemInfo.readItemTSID() + ") with x,y " + str(startX) + "," + str(startY) + " using street snap " + streetSnaps.get(streetImageBeingUsed).readPNGImageName(), 2);
                    }
                }
            }
        }
        
        if (searchDone)
        {
            // Dump out debug info to give me some idea of whether I've gotten the searchbox the right size or not
            printToFile.printDebugLine(this, "Returning from FragmentFound item  found = " + itemFound + thisItemInfo.readItemClassTSID() + " (" + thisItemInfo.readItemTSID() + ") info <" + newItemExtraInfo + 
                                        "> old x,y = " + thisItemInfo.readOrigItemX() + "," + thisItemInfo.readOrigItemY() + " new x,y " + newItemX + "," + newItemY, 2);
            printToFile.printDebugLine(this, " For reference - " + debugInfo, 2);

        }
 
    }
    
    String extractItemInfoFromItemImageFilename()
    {
        // Extract the information which describes the quoin type or dir/variant fields for different items
        // Just need to strip out the item class_tsid from the front of the file name - if anything left, then
        // this is the value needed for the JSON file if the street item is to match the archive snaps. 
        
        // Remove the classTSID and .png part 
        String fname = itemImages.get(itemImageBeingUsed).readPNGImageName();
        String extraInfo = "";
        
        println(" image name ", fname, " for item class tsid ", thisItemInfo.itemClassTSID);
        
        if (fname.length() > (thisItemInfo.itemClassTSID.length() + 4))
        {
            // Means there is an _info field to extract - so strip off the classTSID_ part and .png
            extraInfo = fname.substring((thisItemInfo.itemClassTSID.length() + 1), fname.length() - 4);
        }
        return extraInfo;
    }
       
    public boolean readSearchDone()
    {
        return searchDone;
    }
        
    public int readNewItemX()
    {
        return newItemX;
    }
    
    public int readNewItemY()
    {
        return newItemY;
    }
    
    public String readNewItemExtraInfo()
    {
        return newItemExtraInfo;
    }
    
    public boolean readItemFound()
    {
        return itemFound;
    }
    
    public boolean readOkFlag()
    {
        return okFlag;
    }
    */
}