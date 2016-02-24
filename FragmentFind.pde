class FragmentFind
{
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
    
    int itemImageBeingUsed;
    int streetImageBeingUsed;
    
    // Saved item information we need here - easier to read
    ArrayList<PNGFile> itemImageArray;
    ArrayList<PNGFile> streetSnapArray;         
  
    // constructor
    public FragmentFind(ItemInfo itemInfo)
    {
        okFlag = true;
        
        searchDone = false;
        itemImageBeingUsed = 0;
        streetImageBeingUsed = 0;
        newItemX = missCoOrds;
        newItemY = missCoOrds;
        newItemExtraInfo = "";
        
        thisItemInfo = itemInfo;
        
        // Copy arrays we need from the item object - to keep the code simpler only
        itemImageArray = itemInfo.readItemImageArray();
        streetSnapArray = streetInfoArray.get(streetBeingProcessed).getStreetImageArray();
        println("Size of street snap array is ", streetInfoArray.get(streetBeingProcessed).streetSnapArray.size());

        // Need to convert the JSON x,y to relate to the street snap - use the first loaded street snap
        startX = thisItemInfo.readOrigItemX() + streetSnapArray.get(0).PNGImage.width/2 + thisItemInfo.readFragOffsetX();
        startY = thisItemInfo.readOrigItemY() + streetSnapArray.get(0).PNGImage.height + thisItemInfo.readFragOffsetY();
        
        // Most items will only be searched for until found once - so once this happens, the search moves on to the next item
        // As this is the first search being carried out for item, always have a 20 x 20 window to search with startX, startY at centre of that box
        spiralSearch = new SpiralSearch(itemImageArray.get(itemImageBeingUsed).readPNGImage(), 
                                        streetSnapArray.get(streetImageBeingUsed).readPNGImage(), 
                                        thisItemInfo.readItemClassTSID(),
                                        startX, startY, defSearchBox, defSearchBox);
                       
        printToFile.printDebugLine("Starting search for item " + thisItemInfo.readItemClassTSID() + " (" + thisItemInfo.readItemTSID() + ") with x,y " + str(startX) + "," + str(startY), 2);
    }
        
    public void searchForFragment()
    {
        String debugInfo = "";
        
        display.clearDisplay();
        display.showStreetName();
        
        display.showItemImage(itemImageArray.get(itemImageBeingUsed).readPNGImage(), thisItemInfo.readOrigItemX() + "," + thisItemInfo.readOrigItemY());
        display.showStreetImage(itemImageArray.get(itemImageBeingUsed).readPNGImage(), streetSnapArray.get(streetImageBeingUsed).readPNGImage(), startX, startY);
        
        // Carry out the search for the item and depending on the result might then move on to look at the next image
        if (spiralSearch.searchForItem())
        {           
            // Match has been found - might be perfect or good enough - so save the information         
            if (thisItemInfo.readItemClassTSID().equals("quoin") || thisItemInfo.readItemClassTSID().equals("marker_qurazy"))
            {
                // Need to search all snaps for quoins/QQ - so can find the lowest y-value for the quoin.
                
                // Only save the x,y if this is the first time the item has been found on the snap, or if the
                // found Y is lower than the previous found Y (i.e. bottom of bounce found)
                if ((newItemX == missCoOrds) || (newItemY < (thisItemInfo.readOrigItemY() + spiralSearch.readDiffY())))
                {
                    printToFile.printDebugLine("Quoin - replacing previous y value of " + newItemY + " with " + thisItemInfo.readOrigItemY() + spiralSearch.readDiffY(), 2);
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
                if (streetImageBeingUsed >= streetSnapArray.size())
                {
                    // No more snaps to search
                    searchDone = true;
                }
                else
                {
                    // Set up for fresh search for this item, but using next street snap.
                    // As only interested in changes in y value, can reduce the width of the search box to speed things up
                    spiralSearch = new SpiralSearch(itemImageArray.get(itemImageBeingUsed).readPNGImage(), 
                                                    streetSnapArray.get(streetImageBeingUsed).readPNGImage(), 
                                                    thisItemInfo.readItemClassTSID(),
                                                    startX + spiralSearch.readDiffX(), 
                                                    startY + spiralSearch.readDiffY(), 
                                                    narrowSearchWidthBox, defSearchBox);
                    printToFile.printDebugLine("Continuing search for quoin/QQ (" + thisItemInfo.readItemTSID() + ") with x,y " + str(startX) + "," + str(startY) + " using street snap " + streetSnapArray.get(streetImageBeingUsed).readPNGImageName(), 2);
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
                if (itemImageBeingUsed >= itemImageArray.size())
                {
                    // No more quoin item images to search - so OK to skip to next street, starting with first quoin image again
                    streetImageBeingUsed++; 
                    println("streetImageBeingUsed is now ", streetImageBeingUsed, " array size is ", streetSnapArray.size());
                    if (streetImageBeingUsed >= streetSnapArray.size())
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
                    spiralSearch = new SpiralSearch(itemImageArray.get(itemImageBeingUsed).readPNGImage(), 
                                                    streetSnapArray.get(streetImageBeingUsed).readPNGImage(), 
                                                    thisItemInfo.readItemClassTSID(),
                                                    startX, startY, defSearchBox, defSearchBox);
                    printToFile.printDebugLine("Continuing search for missing quoin ("  + thisItemInfo.readItemTSID() + ") with x,y " + str(startX) + "," + str(startY) + " using street snap " + streetSnapArray.get(streetImageBeingUsed).readPNGImageName(), 2);
                }
            }
            else
            {
                // OK to move on to the next street - all other items and quoins with known types
                streetImageBeingUsed++;    
                if (streetImageBeingUsed >= streetSnapArray.size())
                {
                    // No more snaps to search
                    searchDone = true;
                }
                else
                {
                    // If a quoin has previously been found on a search, then can use different search window as only interested in new values of y.
                    // Also start at the best found x,y found so far
                    if ((thisItemInfo.readItemClassTSID().equals("quoin") || thisItemInfo.readItemClassTSID().equals("marker_qurazy")) && newItemX != missCoOrds)
                    {
                        spiralSearch = new SpiralSearch(itemImageArray.get(itemImageBeingUsed).readPNGImage(), 
                                                    streetSnapArray.get(streetImageBeingUsed).readPNGImage(), 
                                                    thisItemInfo.readItemClassTSID(),
                                                    startX + thisItemInfo.readOrigItemX() - newItemX,
                                                    startY + thisItemInfo.readOrigItemY() - newItemY,
                                                    narrowSearchWidthBox, defSearchBox);
                        printToFile.printDebugLine("Continuing search for quoin/QQ (" + thisItemInfo.readItemTSID() + ") with x,y " + str(startX) + "," + str(startY) + " using street snap " + streetSnapArray.get(streetImageBeingUsed).readPNGImageName(), 2);
                    }
                    else
                    {
                        // Set up for fresh search for this item, but using next street snap
                        spiralSearch = new SpiralSearch(itemImageArray.get(itemImageBeingUsed).readPNGImage(), 
                                                        streetSnapArray.get(streetImageBeingUsed).readPNGImage(), 
                                                        thisItemInfo.readItemClassTSID(),
                                                        startX, startY, defSearchBox, defSearchBox);
                        printToFile.printDebugLine("Continuing search for item " + thisItemInfo.readItemClassTSID() + " (" + thisItemInfo.readItemTSID() + ") with x,y " + str(startX) + "," + str(startY) + " using street snap " + streetSnapArray.get(streetImageBeingUsed).readPNGImageName(), 2);
                    }
                }
            }
        }
        
        if (searchDone)
        {
            // Dump out debug info to give me some idea of whether I've gotten the searchbox the right size or not
            printToFile.printDebugLine("Found item " + thisItemInfo.readItemClassTSID() + " (" + thisItemInfo.readItemTSID() + ") info <" + newItemExtraInfo + 
                                        "> old x,y = " + thisItemInfo.readOrigItemX() + "," + thisItemInfo.readOrigItemY() + " new x,y " + newItemX + "," + newItemY, 2);
            printToFile.printDebugLine(" For reference - " + debugInfo, 2);

        }
 
    }
    
    String extractItemInfoFromItemImageFilename()
    {
        // Extract the information which describes the quoin type or dir/variant fields for different items
        // Just need to strip out the item class_tsid from the front of the file name - if anything left, then
        // this is the value needed for the JSON file if the street item is to match the archive snaps. 
        
        // Remove the classTSID and .png part 
        String fname = itemImageArray.get(itemImageBeingUsed).readPNGImageName();
        String extraInfo = "";
        
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
    
}