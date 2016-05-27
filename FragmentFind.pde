class FragmentFind
{
    boolean okFlag;
    boolean searchDone;
    
    final static int DEF_SEARCH_BOX = 20; // for usual searches
    final static int NARROW_SEARCH_WIDTH_BOX = 2; // for QQ/quoins to just find changes in y
    final static int SLOTH_ADJUSTMENT = 100;
    
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
    
    ArrayList<QuoinMatchData> quoinMatches;
    
    int itemImageBeingUsed;
    //int streetImageBeingUsed;
    
    // Saved item information we need here - easier to read
    ArrayList<PNGFile> itemImages;
    PNGFile streetSnapImage;  
    
    // Information saved from the search before it is nulled ready for the next search/image
    // Keeps a running version of the 'best' match in
    MatchInfo bestMatchInfo;
  
    // constructor
    public FragmentFind(ItemInfo itemInfo)
    {
        //printToFile.printDebugLine(this, "Create New FragmentFind", 1);
        okFlag = true;
        
        quoinMatches = new ArrayList<QuoinMatchData>();
        
        searchDone = false;
        //streetImageBeingUsed = 0;
        newItemX = MISSING_COORDS;
        newItemY = MISSING_COORDS;
        newItemExtraInfo = "";
        itemFound = false;
        
        thisItemInfo = itemInfo;
        
        bestMatchInfo = null;
        
        // Copy arrays we need from the item object - to keep the code simpler onl      
        itemImages = itemInfo.readItemImages();
        if (itemImages == null)
        {
            printToFile.printDebugLine(this, "Failed to retrieve item images for item " + thisItemInfo.readItemClassTSID() + "(" + thisItemInfo.readItemTSID() + ")", 3);
            okFlag = false;
            return;
        }
                        
        if (thisItemInfo.readItemClassTSID().equals("quoin") && (configInfo.readChangeXYOnly() || thisItemInfo.readNewItemX() != MISSING_COORDS))
        {
            // If we are only searching for x,y changes, or if the quoin has already been found, then we know what image to be searching for.
            // So can just set itemImageBeingUsed to the correct number which will force it to just use that image to check with
            // If this is an x,y change only, then search for the quoin type from the original JSON file, otherwise use the newly found quoin type
            String quoinType;
            if (configInfo.readChangeXYOnly())
            {
                quoinType = thisItemInfo.readOrigItemExtraInfo();
            }
            else
            {
                quoinType = thisItemInfo.readNewItemExtraInfo();
            }

            for (int i = 0; i < itemImages.size(); i++)
            {
                if (itemImages.get(i).readPNGImageName().indexOf(quoinType) != -1)
                {
                    printToFile.printDebugLine(this, " setting image number to be " + i, 1);
                    itemImageBeingUsed = i;
                }
            }
        }
        else
        {
            // start at the beginning
            printToFile.printDebugLine(this, " image number starting at 0" , 1);
            itemImageBeingUsed = 0;
        }
        printToFile.printDebugLine(this, " init FragmentFind - " + thisItemInfo.readItemClassTSID() + " change x/y only = " + configInfo.readChangeXYOnly() + " new item X = " + thisItemInfo.readNewItemX() + " using image " + itemImageBeingUsed, 1);
                
        streetSnapImage = streetInfo.readCurrentStreetSnap();
        if (streetSnapImage.readPNGImage() == null)
        {
            printToFile.printDebugLine(this, "Failed to retrieve street snap image " + streetSnapImage.readPNGImageName(), 3);
            okFlag = false;
            return;
        }

        printToFile.printDebugLine(this, "Starting search with image number " + itemImageBeingUsed + " i.e. " + itemImages.get(itemImageBeingUsed).readPNGImageName() +
                                    " with street snap " + streetSnapImage.readPNGImageName(), 1);        
        
        // For most items, the search will only be done once so the starting point is the JSON x,y. And the search box will be the default
        // 20x20 size. But for quoins/QQ the search is done on all streets even if a match is found - to find the y variation. In this case
        // is more efficient to start the search with the latest x,y co-ords.  

        if ((thisItemInfo.readItemClassTSID().equals("quoin") || thisItemInfo.readItemClassTSID().equals("marker_qurazy")) && thisItemInfo.readNewItemX() != MISSING_COORDS)
        {
            // Already have the co-ordinates for a matching quoin/QQ - so use those to start this search
            startItemX = thisItemInfo.readNewItemX();
            startItemY = thisItemInfo.readNewItemY();
            searchBoxWidth = NARROW_SEARCH_WIDTH_BOX;
            searchBoxHeight = DEF_SEARCH_BOX;
            if (thisItemInfo.readItemClassTSID().equals("quoin"))
            printToFile.printDebugLine(this, "Continuing search for quoin/QQ  " + thisItemInfo.readItemClassTSID() + " (" + thisItemInfo.readItemTSID() + ") with x,y " + startItemX + "," + startItemY, 1);
        }
        else
        {
            // First time through for QQ/quoins and for all other items - use default 20x20 box and start at JSON x,y
            startItemX = thisItemInfo.readOrigItemX();
            startItemY = thisItemInfo.readOrigItemY();
            searchBoxWidth = DEF_SEARCH_BOX;
            searchBoxHeight = DEF_SEARCH_BOX;
            printToFile.printDebugLine(this, "Starting search for item " + thisItemInfo.readItemClassTSID() + " (" + thisItemInfo.readItemTSID() + ") with x,y " + thisItemInfo.readOrigItemX() + "," + thisItemInfo.readOrigItemY(), 1);
        }
        // Set up the structure to actually do the search
        spiralSearch = null;
        System.gc();
        int adjustment = 0;
        int searchRadius = configInfo.readSearchRadius();
        if (thisItemInfo.readItemClassTSID().equals("npc_sloth"))
        {
            // extend the search area for sloths - otherwise branches difficult to find
            adjustment = SLOTH_ADJUSTMENT;
        }
        
        spiralSearch = new SpiralSearch(itemImages.get(itemImageBeingUsed).readPNGImage(), 
            streetSnapImage.readPNGImage(), 
            thisItemInfo.readItemClassTSID(),
            startItemX,
            startItemY, 
            itemImages.get(itemImageBeingUsed).readFragOffsetX(),
            itemImages.get(itemImageBeingUsed).readFragOffsetY(),
            searchBoxWidth, searchBoxHeight, searchRadius, adjustment,
            thisItemInfo.readItemTSID(), 
            itemImages.get(itemImageBeingUsed).readPNGImageName().replace(".png", ""),
            streetSnapImage.readPNGImageName().replace(".png", ""));     
            
        // dump list of images being used
        for (int i = 0; i < itemImages.size(); i++)
        {
            //printToFile.printDebugLine(this, "image loaded " + thisItemInfo.readItemClassTSID() + " = " + itemImages.get(i).readPNGImageName(), 1);
        }

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
                
        displayMgr.showItemImage(itemImages.get(itemImageBeingUsed).readPNGImage(), thisItemInfo.readOrigItemX() + "," + thisItemInfo.readOrigItemY());
        displayMgr.showStreetFragmentImage(streetSnapImage.readPNGImage(), 
                                itemImages.get(itemImageBeingUsed).readPNGImageWidth(), 
                                itemImages.get(itemImageBeingUsed).readPNGImageHeight(),
                                startItemX + streetSnapImage.readPNGImage().width/2 + itemImages.get(itemImageBeingUsed).readFragOffsetX(),
                                startItemY + streetSnapImage.readPNGImage().height + itemImages.get(itemImageBeingUsed).readFragOffsetY());
        displayMgr.showStreetImage(streetSnapImage.readPNGImage(), streetSnapImage.readPNGImageName());
        
        // Carry out the search for the item and depending on the result might then move on to look at the next image
        printToFile.printDebugLine(this, "Search for item " + thisItemInfo.readItemClassTSID() + " (" + thisItemInfo.readItemTSID() + ") with x,y " + thisItemInfo.readOrigItemX() + "," + thisItemInfo.readOrigItemY() + " using item image " + itemImages.get(itemImageBeingUsed).readPNGImageName() , 2);
        
        boolean searchSuccess = spiralSearch.searchForItem();
        if (searchSuccess)
        {
            // NB This can be because a perfect match has been found, or a good-enough that fits within the % match required criteria
            if (thisItemInfo.readItemClassTSID().equals("quoin") && thisItemInfo.readNewItemX() == MISSING_COORDS)
            {
                // have yet to scan through all images to find the best/closest quoin image 
                // So save this information before dropping down below to search with the next image available  
                bestMatchInfo = spiralSearch.readSearchMatchInfo(); 
                quoinMatches.add(new QuoinMatchData(spiralSearch.convertToJSONX(spiralSearch.readFoundStepX()),
                                 spiralSearch.convertToJSONY(spiralSearch.readFoundStepY()),
                                 extractItemInfoFromItemImageFilename(),
                                 bestMatchInfo));                          

                debugInfo = spiralSearch.debugRGBInfo();
                printToFile.printDebugLine(this, "searchForFragment - full quoin search found " + extractItemInfoFromItemImageFilename() + " found at x,y " + newItemX + "," + newItemY, 2);
            }
            else
            {
                // Valid found item so save the new x,y and other information
                itemFound = true;
                // Match has been found - might be perfect or good enough - so save the information    
                // For all non-quoin items it is assumed that once a match has been found, x,y are valid because these items do not move
                // Trees are a bit more complicated - if the JSON file is a trant_* tree then we only need a valid x,y which we can get from
                // any match between fragment/snap. However for wood trees, also want the variant type if at all possible from the snap.
                // As a cludge for now, make sure extractItemInfoFromItemImageFilename() returns the same variant type if a non-wood tree match
                // has been found.
                newItemX = spiralSearch.convertToJSONX(spiralSearch.readFoundStepX());
                newItemY = spiralSearch.convertToJSONY(spiralSearch.readFoundStepY());
            
                // As matched item image is the current one, extract the extra information from the item image filename
                newItemExtraInfo = extractItemInfoFromItemImageFilename();
                debugInfo = spiralSearch.debugRGBInfo();
                bestMatchInfo = spiralSearch.readSearchMatchInfo(); 
                searchDone = true;
                printToFile.printDebugLine(this, "searchForFragment - Item found at x,y " + newItemX + "," + newItemY, 2);
            }
        }
        
        if (!searchDone)
        {
            // Item was not found on this image, or still searching through entire set of quoins before deciding on best find, so move on to the next image to search
            // However no point doing this in the case where only looking to update x,y values for quoins (and so won't change their type, are using
            // the JSON as the expected type), or if the quoin has been previously found on a street snap (and so we know what to look for from then onwards).
            if (thisItemInfo.readItemClassTSID().equals("quoin") && (configInfo.readChangeXYOnly() || thisItemInfo.readNewItemX() != MISSING_COORDS))
            {
                // We only ever search on one image in this case - for quoins, we know what the quoin looks like as is in the JSON file
                // and that info was used to select the single quoin image that needed to be used to search this street snap. Therefore if
                // if was not found - and we enter this leg of code - then consider the search done for this item.
                // Won't reach this leg of the code for any other items - as once an item is found, it never enters FragmentFind again - skipped on future street snaps.
                bestMatchInfo = spiralSearch.readSearchMatchInfo(); 
                searchDone = true;
                printToFile.printDebugLine(this, "searchForFragment - found 1 item, no more images to search", 2);
                printToFile.printDebugLine(this, "searchForFragment - " + thisItemInfo.readItemClassTSID().equals("quoin") + " new X is " + thisItemInfo.readNewItemX() , 2);
            }
            else
            {
                // Move on to search with the next image in the set
                itemImageBeingUsed++;
                if (itemImageBeingUsed >= itemImages.size())
                {
                    // Have searched using all the item images
                    // This will include the case of the QQ - as only has one image (but will be searched for as special case on next street snap)
                    printToFile.printDebugLine(this, "searchForFragment - no more images to search", 2);
                    
                    // In the case of quoins - need to save the details of the image that was closest to the original co-ordinates
                    if (thisItemInfo.readItemClassTSID().equals("quoin") && thisItemInfo.readNewItemX() == MISSING_COORDS)
                    {
                        // Also copies across the associated debugRGB info
                        saveClosestQuoin();
                    }
                    else
                    {
                        // NB Need to save the 'best' fit found - needed for trees where search multiple very different images, so don't
                        // just want to see the search info for a wood tree if the 2nd fruit tree search was close to the specified accuracy requested.
                        // Otherwise the output report implies a terrible match, when actually seeing the result of the last tree image, which could
                        // well be hopeless.
                        if (bestMatchInfo == null)
                        {
                            // Returned from first search, so OK to overwrite with the information for this search
                            bestMatchInfo = spiralSearch.readSearchMatchInfo();
                        }
                        else if (bestMatchInfo.readPercentageMatch() < spiralSearch.readPercentageMatchInfo())
                        {
                            // Last search returned a better percentage match - so save this information 
                            bestMatchInfo = spiralSearch.readSearchMatchInfo();
                        }
                        // else - ignore the results of the last search as it was worse than the best we have so far
                    }                             
                    searchDone = true;
                }
                else
                {
                    // Carry out search using the new image
                    
                    // Before starting new search, save information from the previous search
                    // Again, only save the bestMatchInfo if it is better than that obtained in previous searches
                    debugInfo = spiralSearch.debugRGBInfo();
                    if (bestMatchInfo == null)
                    {
                        // Returned from first search, so OK to overwrite with the information for this search
                        bestMatchInfo = spiralSearch.readSearchMatchInfo();
                    }
                    else if (bestMatchInfo.readPercentageMatch() < spiralSearch.readPercentageMatchInfo())
                    {
                        // Last search returned a better percentage match - so save this information 
                        bestMatchInfo = spiralSearch.readSearchMatchInfo();
                    }
                    // else - ignore the results of the last search as it was worse than the best we have so far
                    //printToFile.printDebugLine(this, " For reference before start search with next image - " + debugRGBMatchInfo, 2);
                    
                    printToFile.printDebugLine(this, "searchForFragment - with new image " + itemImages.get(itemImageBeingUsed).readPNGImageName() + " and street " + streetSnapImage.readPNGImageName(), 2);
                    spiralSearch = null; 
                    System.gc();
                    int adjustment = 0;
                    int searchRadius = configInfo.readSearchRadius();
                    if (thisItemInfo.readItemClassTSID().equals("npc_sloth"))
                    {
                        // extend the search area for sloths - otherwise branches difficult to find
                        adjustment = SLOTH_ADJUSTMENT;
                    }

                    spiralSearch = new SpiralSearch(itemImages.get(itemImageBeingUsed).readPNGImage(), 
                        streetSnapImage.readPNGImage(), 
                        thisItemInfo.readItemClassTSID(),
                        startItemX,
                        startItemY,
                        itemImages.get(itemImageBeingUsed).readFragOffsetX(),
                        itemImages.get(itemImageBeingUsed).readFragOffsetY(),
                        searchBoxWidth, searchBoxHeight, searchRadius, adjustment,
                        thisItemInfo.readItemTSID(),
                        itemImages.get(itemImageBeingUsed).readPNGImageName().replace(".png", ""),
                        streetSnapImage.readPNGImageName().replace(".png", ""));                    

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
            printToFile.printDebugLine(this, " and also RGB info is " + bestMatchInfo.bestMatchAvgRGB + "/" + bestMatchInfo.bestMatchAvgTotalRGB + " try " + bestMatchInfo.bestMatchX + "," + bestMatchInfo.bestMatchY, 2);
            if (debugInfo.length() > 0)
            {
                printToFile.printDebugLine(this, " For reference - " + debugInfo, 2);
                printToFile.printDebugLine(this, " For RGB reference - " + bestMatchInfo.matchDebugInfoString(), 2);
            }
                           
        }
        return true;
    }
    
    String extractItemInfoFromItemImageFilename()
    {
        // Extract the information which describes the quoin type or dir/variant fields for different items
        // Just need to strip out the item class_tsid from the front of the file name - if anything left, then
        // this is the value needed for the JSON file if the street item is to match the archive snaps. 
        String extraInfo = "";
        String imageName = itemImages.get(itemImageBeingUsed).readPNGImageName();
        String name = imageName.replace(".png", "");
        
        // Some items never have a variant field e.g. rock_metal_1, QQ, so image name = class TSID
        if (thisItemInfo.readItemClassTSID().equals(name))
        {
            return "";
        }
        else if (thisItemInfo.readItemClassTSID().indexOf("trant_") == 0)
        {
            // Quite often might have a bean tree on our QA street, but the snap has a fruit tree. Therefore the itemClassTSID (bean)
            // in the JSON file doesn't reflect the found fruit tree on the snap. 
            // Unlike quoins, we are not changing tree JSONs to match snaps, therefore quite feasible that the itemClassTSID won't match the snap name. 
            // So just return a clean empty extraInfo field if not wanted.    
            return "";
        }
        else if (thisItemInfo.readItemClassTSID().equals("wood_tree"))
        {            
            // Note that if the JSON file is set up to be a wood tree, then we do want to know what variant was found which constituted a match
            // - what happens if we have a wood tree as the JSON file, but the snap finds a match for a fruit tree. This gives us the x,y
            // but not the variant of the wood tree ... so as a workaround for now, return the existing extraInfo field (which will be "" for trant_*
            // and variant for wood trees. 
            // Default the return value to the existing wood tree variant. Then if the name of the image is a non-wood tree, won't matter as will
            // return this original rather than new value
            extraInfo = thisItemInfo.readOrigItemExtraInfo();
            printToFile.printDebugLine(this, " default wood tree variant to original value of " + extraInfo, 1);
        }
        
        // Remove the classTSID              
        if (name.length() > (thisItemInfo.readItemClassTSID().length() + 1))
        {
            // Means there is an _info field to extract - so strip off the classTSID_ part and .png
            //extraInfo = imageName.substring((thisItemInfo.itemClassTSID.length() + 1), imageName.length() - 4);
            // Means there is an _info field to extract - so strip off the classTSID_ part and _
            extraInfo = name.replace(thisItemInfo.readItemClassTSID() + "_", "");
        }
        printToFile.printDebugLine(this, " image name "  + imageName + " for item class tsid " + thisItemInfo.readItemClassTSID() + " returns variant + " + extraInfo, 1);
        return extraInfo;
    }
    
    void saveClosestQuoin()
    {
        // Go through the array of results and save the new x,y and type field with the quoin found nearest to the original x,y
        if (quoinMatches.size() == 0)
        {
            // Nothing was found that matched - so mark as not found
            itemFound = false;        
            newItemX = spiralSearch.convertToJSONX(spiralSearch.readFoundStepX());
            newItemY = spiralSearch.convertToJSONY(spiralSearch.readFoundStepY());
            newItemExtraInfo = "";
            bestMatchInfo = spiralSearch.readSearchMatchInfo(); 
            printToFile.printDebugLine(this, "No quoin images matched", 2);
        }
        else
        {
            // Need to loop through all the saved entries, saving the details of the nearest image found
            // So first of all save the first entry, and then go through the remaining ones, if any
            int i = 0;
            float nearestQuoinDist = quoinMatches.get(i).distFromOrigXY;
            newItemX = quoinMatches.get(i).itemX;
            newItemY = quoinMatches.get(i).itemY;
            newItemExtraInfo = quoinMatches.get(i).quoinType;
            bestMatchInfo = quoinMatches.get(i).bestMatchInfo;
            
            for (i = 1; i < quoinMatches.size(); i++)
            {
                if (quoinMatches.get(i).distFromOrigXY < nearestQuoinDist)
                {
                    // Found quoin that is even nearer to original x,y than one that is saved
                    // Overwrite the values
                    nearestQuoinDist = quoinMatches.get(i).distFromOrigXY;
                    newItemX = quoinMatches.get(i).itemX;
                    newItemY = quoinMatches.get(i).itemY;
                    newItemExtraInfo = quoinMatches.get(i).quoinType;
                    
                    bestMatchInfo = quoinMatches.get(i).bestMatchInfo;
                }
                else
                {
                    printToFile.printDebugLine(this, "ignoring quoin image found for type " + quoinMatches.get(i).quoinType + " at x,y " + quoinMatches.get(i).itemX + "," + quoinMatches.get(i).itemY, 1);
                }
            }
            printToFile.printDebugLine(this, "closest quoin image found for type " + newItemExtraInfo + " at x,y " + newItemX + "," + newItemY, 2);
            itemFound = true;
        }
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
    
    public MatchInfo readBestMatchInfo()
    {
        return bestMatchInfo;
    }
    
    class QuoinMatchData
    {
        int itemX;
        int itemY;
        float distFromOrigXY;
        String quoinType;
        MatchInfo bestMatchInfo;
        
        QuoinMatchData(int foundX, int foundY, String extraInfo, MatchInfo RGBInfo)
        {
            itemX = foundX;
            itemY = foundY;
            quoinType = extraInfo;
            distFromOrigXY = Utils.distanceBetweenX1Y1_X2Y2(thisItemInfo.readOrigItemX(), thisItemInfo.readOrigItemY(), foundX, foundY); 
            bestMatchInfo = RGBInfo;
            printToFile.printDebugLine(this, "Saving quoin data for " + extraInfo + " with avg RGB " + bestMatchInfo.bestMatchAvgRGB + " at x,y " + bestMatchInfo.bestMatchX + "," + bestMatchInfo.bestMatchY, 3);
        }
    }
    
}