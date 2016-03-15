class FragmentFind
{
    boolean okFlag;
    boolean searchDone;
    
    final int defSearchBox = 20; // for usual searches
    final int narrowSearchWidthBox = 2; // for QQ/quoins to just find changes in y
    int searchBoxWidth;
    int searchBoxHeight;
          
    SpiralSearch spiralSearch;
    ItemInfo thisItemInfo;
    
    // x,y on street where need to start the item search - might be the original x,y or new x,y for a quoin (as have to keep searching snaps for quoins)
    int startItemX;
    int startItemY;
    
    int newItemX;
    int newItemY;
    String newItemExtraInfo;
    boolean itemFound;
    
    int itemImageBeingUsed;
    //int streetImageBeingUsed;
    
    // Saved item information we need here - easier to read
    ArrayList<PNGFile> itemImages;
    PNGFile streetSnapImage;  
  
    // constructor
    public FragmentFind(ItemInfo itemInfo)
    {
        //printToFile.printDebugLine(this, "Create New FragmentFind", 1);
        okFlag = true;
        
        searchDone = false;
        //streetImageBeingUsed = 0;
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
                        
        if (thisItemInfo.readItemClassTSID().equals("quoin") && (configInfo.readChangeXYOnly() || thisItemInfo.readNewItemX() != missCoOrds))
        {
            // If we are only searching for x,y changes, or if the quoin has already been found, then we know what image to be searching for.
            // So can just set itemImageBeingUsed to the correct number which will force it to just use that image to check with
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
                
        streetSnapImage = streetInfo.readCurrentStreetSnap();
        if (streetSnapImage.readPNGImage() == null)
        {
            printToFile.printDebugLine(this, "Failed to retrieve street snap image " + streetSnapImage.readPNGImageName(), 3);
            okFlag = false;
            return;
        }

        printToFile.printDebugLine(this, "Starting search with image number " + itemImageBeingUsed + " i.e. " + itemImages.get(itemImageBeingUsed).readPNGImageName() +
                                    " with street snap " + streetSnapImage.readPNGImageName(), 2);        
        
        // Need to convert the JSON x,y to relate to the street snap 
        // For most items, the search will only be done once so the starting point is the JSON x,y. And the search box will be the default
        // 20x20 size. But for quoins/QQ the search is done on all streets even if a match is found - to find the y variation. In this case
        // is more efficient to start the search with the latest x,y co-ords.

        
        if ((thisItemInfo.readItemClassTSID().equals("quoin") || thisItemInfo.readItemClassTSID().equals("marker_qurazy")) && thisItemInfo.readNewItemX() != missCoOrds)
        {
            // Already have the co-ordinates for a matching quoin/QQ - so use those to start this search
            startItemX = thisItemInfo.readNewItemX();
            startItemY = thisItemInfo.readNewItemY();
            searchBoxWidth = narrowSearchWidthBox;
            searchBoxHeight = defSearchBox;
            printToFile.printDebugLine(this, "Continuing search for quoin/QQ  " + thisItemInfo.readItemClassTSID() + " (" + thisItemInfo.readItemTSID() + ") with x,y " + startItemX + "," + startItemY, 2);
        }
        else
        {
            // First time through for QQ/quoins and for all other items - use default 20x20 box and start at JSON x,y
            startItemX = thisItemInfo.readOrigItemX();
            startItemY = thisItemInfo.readOrigItemY();
            searchBoxWidth = defSearchBox;
            searchBoxHeight = defSearchBox;
            printToFile.printDebugLine(this, "Starting search for item " + thisItemInfo.readItemClassTSID() + " (" + thisItemInfo.readItemTSID() + ") with x,y " + thisItemInfo.readOrigItemX() + "," + thisItemInfo.readOrigItemY(), 2);
        }
        // Set up the structure to actually do the search
        spiralSearch = null;
        System.gc();
        spiralSearch = new SpiralSearch(itemImages.get(itemImageBeingUsed).readPNGImage(), 
            streetSnapImage.readPNGImage(), 
            thisItemInfo.readItemClassTSID(),
            startItemX,
            startItemY, 
            itemImages.get(itemImageBeingUsed).readFragOffsetX(),
            itemImages.get(itemImageBeingUsed).readFragOffsetY(),
            searchBoxWidth, searchBoxHeight);

        if (!spiralSearch.readOkFlag()) 
        {
            okFlag = false;
            return;
        }

        //printHashCodes(this);
    }
        
    public boolean searchForFragment()
    {
        String debugInfo = "";
        
        display.clearDisplay();
        display.showStreetName();
        
        display.showItemImage(itemImages.get(itemImageBeingUsed).readPNGImage(), thisItemInfo.readOrigItemX() + "," + thisItemInfo.readOrigItemY());
        display.showStreetFragmentImage(streetSnapImage.readPNGImage(), 
                                itemImages.get(itemImageBeingUsed).readPNGImageWidth(), 
                                itemImages.get(itemImageBeingUsed).readPNGImageHeight(),
                                startItemX + streetSnapImage.readPNGImage().width/2 + itemImages.get(itemImageBeingUsed).readFragOffsetX(),
                                startItemY + streetSnapImage.readPNGImage().height + itemImages.get(itemImageBeingUsed).readFragOffsetY());
        display.showStreetImage(streetSnapImage.readPNGImage(), streetSnapImage.readPNGImageName());
        
        // Carry out the search for the item and depending on the result might then move on to look at the next image
        printToFile.printDebugLine(this, "Search for item " + thisItemInfo.readItemClassTSID() + " (" + thisItemInfo.readItemTSID() + ") with x,y " + thisItemInfo.readOrigItemX() + "," + thisItemInfo.readOrigItemY() + " using item image " + itemImages.get(itemImageBeingUsed).readPNGImageName() , 1);
        if (spiralSearch.searchForItem())
        {   
            // Item was found so save the new x,y and other information
            itemFound = true;
            // Match has been found - might be perfect or good enough - so save the information 
            newItemX = thisItemInfo.readOrigItemX() + spiralSearch.readDiffX();
            newItemY = thisItemInfo.readOrigItemY() + spiralSearch.readDiffY(); 
            // As matched item image is the current one, extract the extra information from the item image filename
            newItemExtraInfo = extractItemInfoFromItemImageFilename();
            debugInfo = spiralSearch.debugRGBInfo(); 
            searchDone = true;
            printToFile.printDebugLine(this, "searchForFragment - Item found at x,y " + newItemX + "," + newItemY, 1);
        }
        else
        {
            // Item was not found on this image, so move on to the next image to search
            // However no point doing this in the case where only looking to update x,y values for quoins (and so won't change their type, are using
            // the JSON as the expected type), or if the quoin has been previously found on a street snap (and so we know what to look for from then onwards).
            if (thisItemInfo.readItemClassTSID().equals("quoin") && (configInfo.readChangeXYOnly() || thisItemInfo.readNewItemX() != missCoOrds))
            {
                // We only ever search on one image in this case - as we know what the quoin looks like, so can ignore the other quoin images
                // Won't reach this leg of the code for any other items - as once
                
                searchDone = true;
                printToFile.printDebugLine(this, "searchForFragment - found 1 item, no more images to search", 1);
            }
            else
            {
                // Move on to search with the next image in the set
                itemImageBeingUsed++;
                if (itemImageBeingUsed >= itemImages.size())
                {
                    // Have searched using all the item images
                    // This will include the case of the QQ - as only has one image (but will be searched for as special case on next street snap)
                    printToFile.printDebugLine(this, "searchForFragment - no more images to search", 1);
                    searchDone = true;
                }
                else
                {
                    // Carry out search using the new image
                    printToFile.printDebugLine(this, "searchForFragment - with new image " + itemImages.get(itemImageBeingUsed).readPNGImageName() + " and street " + streetSnapImage.readPNGImageName(), 1);
                    spiralSearch = null; 
                    System.gc();
                    spiralSearch = new SpiralSearch(itemImages.get(itemImageBeingUsed).readPNGImage(), 
                        streetSnapImage.readPNGImage(), 
                        thisItemInfo.readItemClassTSID(),
                        startItemX,
                        startItemY,
                        itemImages.get(itemImageBeingUsed).readFragOffsetX(),
                        itemImages.get(itemImageBeingUsed).readFragOffsetY(),
                        searchBoxWidth, searchBoxHeight);                    

                    if (!spiralSearch.readOkFlag()) 
                    {
                        // error
                        return false;
                    }
                }
            }
        }
        
        if (searchDone)
        {
            // Dump out debug info to give me some idea of whether I've gotten the searchbox the right size or not
            printToFile.printDebugLine(this, " Returning from FragmentFound item  found = " + itemFound + " " + thisItemInfo.readItemClassTSID() + " (" + thisItemInfo.readItemTSID() + ") info <" + newItemExtraInfo + 
                                        "> old x,y = " + thisItemInfo.readOrigItemX() + "," + thisItemInfo.readOrigItemY() + " new x,y " + newItemX + "," + newItemY, 2);
            if (debugInfo.length() > 0)
            {
                printToFile.printDebugLine(this, " For reference - " + debugInfo, 2);
            }

        }
        return true;
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
    
}