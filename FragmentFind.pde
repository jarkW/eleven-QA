class FragmentFind
{
    boolean okFlag;
    boolean searchDone;
    
    final static int DEF_SEARCH_BOX = 20; // for usual searches
    final static int NARROW_SEARCH_WIDTH_BOX = 2; // for QQ/quoins to just find changes in y
    final static int SLOTH_ADJUSTMENT = 100;
    
    int searchBoxWidth;
    int searchBoxHeight;
    int searchRadius;
    
    // Fudge factor for searching for sloths
    int adjustment;
          
    SpiralSearch spiralSearch;
    ItemInfo thisItemInfo;
    
    // x,y on street where need to start the item search - might be the original x,y or new x,y for a QQ (as have to keep searching snaps for QQ)
    // For quoins, just stick to original x,y to make sure we always find any quoins on subsequent street snaps that are missing from the first streets.
    int startItemX;
    int startItemY;
    
    boolean itemFound;
    
    ArrayList<QuoinMatchData> quoinMatches;
    
    int itemImageBeingUsed;
    
    // Saved item information we need here - easier to read
    ArrayList<PNGFile> itemImages;
    PNGFile streetSnapImage;  
    
    // Information saved from the search before it is nulled ready for the next search/image
    // Keeps a running version of the 'best' match in
    MatchInfo bestMatchInfo;
    
        // constructor
    public FragmentFind(ItemInfo itemInfo)
    {
        okFlag = true;
        
        quoinMatches = new ArrayList<QuoinMatchData>();
        
        searchDone = false;
        
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
        
        // When only making x/y changes only, then assume that the JSON file contains the correct information for the variant type (except for wood trees which 
        // need be checked against all tree types because they may have been replanted relative to street snaps
        if (configInfo.readChangeXYOnly() && thisItemInfo.readOrigItemVariant().length() > 0 && !thisItemInfo.readItemClassTSID().equals("wood_tree"))
        {
            // If we are only searching for x,y changes so can just set itemImageBeingUsed to the correct number which will force it to just use that image to check with
            String variantType;
            variantType = thisItemInfo.readOrigItemVariant();

            for (int i = 0; i < itemImages.size(); i++)
            {
                if (itemImages.get(i).readPNGImageName().indexOf(variantType) != -1)
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
        printToFile.printDebugLine(this, " init FragmentFind - " + thisItemInfo.readItemClassTSID() + " change x/y only = " + configInfo.readChangeXYOnly() + " using image " + itemImageBeingUsed, 1);
                
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
        // 20x20 size. But for QQ the search is done on all streets even if a match is found - to find the y variation. In this case
        // is more efficient to start the search with the latest x,y co-ords.  

        if (thisItemInfo.readItemClassTSID().equals("marker_qurazy") && thisItemInfo.bestMatchInfo != null &&  thisItemInfo.bestMatchInfo.readBestMatchResult() > NO_MATCH)
        {
            // Already have the co-ordinates for a matching QQ - so use those to start this search
            startItemX = thisItemInfo.bestMatchInfo.readBestMatchX();
            startItemY = thisItemInfo.bestMatchInfo.readBestMatchY();
            searchBoxWidth = NARROW_SEARCH_WIDTH_BOX;
            searchBoxHeight = DEF_SEARCH_BOX;
            printToFile.printDebugLine(this, "Continuing search for QQ  " + thisItemInfo.readItemClassTSID() + " (" + thisItemInfo.readItemTSID() + ") with x,y " + startItemX + "," + startItemY, 1);
        }
        else
        {
            // First time through for QQ and for all other items - use default 20x20 box and start at JSON x,y
            startItemX = thisItemInfo.readOrigItemX();
            startItemY = thisItemInfo.readOrigItemY();
            searchBoxWidth = DEF_SEARCH_BOX;
            searchBoxHeight = DEF_SEARCH_BOX;
            printToFile.printDebugLine(this, "Starting search for item " + thisItemInfo.readItemClassTSID() + " (" + thisItemInfo.readItemTSID() + ") with x,y " + thisItemInfo.readOrigItemX() + "," + thisItemInfo.readOrigItemY(), 1);
        }
        // Set up the structure to actually do the search
        spiralSearch = null;
        System.gc();
        adjustment = 0;
        searchRadius = configInfo.readSearchRadius();
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
        
        int searchResult = spiralSearch.searchForItem();
        
        // What happens next depends on the result of this search
        switch (searchResult)
        {
            case PERFECT_MATCH:
                // Quoins still need to be searched for using the next image (unless this is an x/y only search). QQ still need to be searched for on future snaps also
                // All other items can be marked as found and not searched on future snaps
                
                // The match info for non-quoins will be the best so far because perfect - for quoins, it will be rewritten from the saved quoinData structure before returning the search result
                bestMatchInfo = spiralSearch.readSearchMatchInfo();
                if (thisItemInfo.readItemClassTSID().equals("quoin") && !configInfo.readChangeXYOnly())
                {
                    // Only need to do this when collecting search results for all quoin images - otherwise can just use the data for the single search done
                    QuoinMatchData quoinData = new QuoinMatchData(bestMatchInfo);
                    if (!okFlag)
                    {
                        // Error - logged by called function
                        return false;
                    }
                    quoinMatches.add(quoinData); 
                    // Don't set the searchDone flag as need to continue on searching for the other quoin images on this street
                }
                else
                {
                    // Quoins being searched for using the x/y only option, and all other items - search is done for this street. 
                    // And for all non-QQ/quoins, item has also been found, and does not need searching on future street snaps
                    searchDone = true;
                    if (!thisItemInfo.readItemClassTSID().equals("marker_qurazy") && !thisItemInfo.readItemClassTSID().equals("quoin"))
                    {
                        // For trees/items a perfect match means we've definitely found our item x,y. And so don't need to bother searching for this item on any further street snaps
                        itemFound = true;
                    }
                }
                debugInfo = spiralSearch.debugRGBInfo();
                printToFile.printDebugLine(this, "searchForFragment - PERFECT match found for " + thisItemInfo.readItemClassTSID() + " with " + 
                                            bestMatchInfo.readBestMatchItemImageName() + ") found at x,y " +
                                            bestMatchInfo.readBestMatchX() + "," + bestMatchInfo.readBestMatchY() + " (" + bestMatchInfo.readPercentageMatch() + "%)", 2);
                break;
                
            case GOOD_MATCH:
                // Quoins still need to be searched for using the next image (unless this is an x/y only search). 
                // Check other images for items on this street in the hope that a perfect match might be found
                if (thisItemInfo.readItemClassTSID().equals("quoin") && !configInfo.readChangeXYOnly())
                {
                    // Only need to do this when collecting search results for all quoin images - otherwise can just use the data for the single search done
                    bestMatchInfo = spiralSearch.readSearchMatchInfo();
                    QuoinMatchData quoinData = new QuoinMatchData(bestMatchInfo);
                    if (!okFlag)
                    {
                        // Error - logged by called function
                        return false;
                    }
                    quoinMatches.add(quoinData); 
                    // Don't set the searchDone flag as need to continue on searching for the other quoin images on this street
                }
                else
                {
                    // Case of single quoin search (x/y only) and all other items - only save the bestMatchInfo if better than what we've already got
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
                    else
                    {
                        // else - ignore the results of the last search as it was worse than the best we have so far
                    }                                     
                }

                debugInfo = spiralSearch.debugRGBInfo();
                printToFile.printDebugLine(this, "searchForFragment - GOOD match found for " + thisItemInfo.readItemClassTSID() + ": best match is with " + 
                                            bestMatchInfo.readBestMatchItemImageName() + ") found at x,y " +
                                            bestMatchInfo.readBestMatchX() + "," + bestMatchInfo.readBestMatchY() + " (" + bestMatchInfo.readPercentageMatch() + "%)", 2);
                break;
                
            case NO_MATCH:
                // For quoins in the non-x/y search case, there is nothing to add to the quoinData structure
                // Only save the bestMatchInfo if better than what we've already got
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
                else
                {
                    // else - ignore the results of the last search as it was worse than the best we have so far
                }     
                debugInfo = spiralSearch.debugRGBInfo();
                                printToFile.printDebugLine(this, "searchForFragment - NO match found for " + thisItemInfo.readItemClassTSID() + ": best match is with " + 
                                            bestMatchInfo.readBestMatchItemImageName() + ") found at x,y " +
                                            bestMatchInfo.readBestMatchX() + "," + bestMatchInfo.readBestMatchY() + " (" + bestMatchInfo.readPercentageMatch() + "%)", 2);               
                break;
        }
               
        // If this is an x,y search only, then we only search for one image on the street anyhow because we know the class/variant from the JSON file
        // - except for trees which still have to search for all images regardless
        if (configInfo.readChangeXYOnly() && !thisItemInfo.itemIsATree())
        {
            searchDone = true;    
        }
        
        // So at this stage we have updated the quoin structure if necessary and bestMatchInfo contains the best match so far on this street with the item images
        if (!searchDone)
        {
            // Need to move on to process the next image on the street
            itemImageBeingUsed++;
            if (itemImageBeingUsed >= itemImages.size())
            {
                // Have searched using all the item images
                // This will include the case of the QQ - as only has one image (but will be searched for as special case on next street snap)
                printToFile.printDebugLine(this, "searchForFragment - no more images to search on this street", 2);
                    
                // In the case of quoins - need to save the details of the image that was closest to the original co-ordinates
                if (thisItemInfo.readItemClassTSID().equals("quoin"))
                {
                    // Finds the closest quoin to the original x,y and saves it into bestMatchInfo
                    saveClosestQuoin();
                }
                
                // Mark as search done as we've run out of images to search with
                searchDone = true;
            }
            else
            {
                // Carry out search using the new image                  
                printToFile.printDebugLine(this, "searchForFragment - with new image " + itemImages.get(itemImageBeingUsed).readPNGImageName() + " and street " + streetSnapImage.readPNGImageName(), 2);
                spiralSearch = null; 
                System.gc();

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
        
        // If we're finished on this street then just dump out the current state of play        
        if (searchDone)
        {
            // Dump out debug info to give me some idea of whether I've gotten the searchbox the right size or not
            printToFile.printDebugLine(this, " Returning from FragmentFound: item found? = " + itemFound + " " + thisItemInfo.readItemClassTSID() + " (" + thisItemInfo.readItemTSID() + ") old x,y = " + 
                                               thisItemInfo.readOrigItemX() + "," + thisItemInfo.readOrigItemY(), 2);
            printToFile.printDebugLine(this, " Best match is " + bestMatchInfo.matchPercentAsFloatString() + " for " + bestMatchInfo.bestMatchX + "," + bestMatchInfo.bestMatchY + " for " + bestMatchInfo.readBestMatchItemImageName(), 2);            
            if (debugInfo.length() > 0)
            {
                printToFile.printDebugLine(this, " For reference - " + debugInfo, 2);
                printToFile.printDebugLine(this, " For RGB reference - " + bestMatchInfo.matchDebugInfoString(), 2);
            }
                           
        }
        return true;
    }
    
    void saveClosestQuoin()
    {
        // Go through the array of results and save the new x,y and type field with the quoin found nearest to the original x,y
        if (quoinMatches.size() == 0)
        {
            // Nothing was found that matched well enough - so don't overwrite bestMatchInfo - which will already contain the best 'missing' search results to date
            printToFile.printDebugLine(this, "No quoin images matched", 2);
        }
        else
        {
            // Need to loop through all the saved entries, saving the details of the nearest image found
            // So first of all save the first entry, and then go through the remaining ones, if any
            int i = 0;
            float nearestQuoinDist = quoinMatches.get(i).distFromOrigXY;
            bestMatchInfo = quoinMatches.get(i).bestMatchInfo;            
            for (i = 1; i < quoinMatches.size(); i++)
            {
                if (quoinMatches.get(i).distFromOrigXY < nearestQuoinDist)
                {
                    // Found quoin that is even nearer to original x,y than one that is saved
                    // Overwrite the values
                    nearestQuoinDist = quoinMatches.get(i).distFromOrigXY;            
                    bestMatchInfo = quoinMatches.get(i).bestMatchInfo;
                }
                else
                {
                    printToFile.printDebugLine(this, "Skip quoin image found for type " + quoinMatches.get(i).quoinType + " at x,y " + quoinMatches.get(i).itemX + "," + quoinMatches.get(i).itemY, 1);
                }
            }
            printToFile.printDebugLine(this, "Closest quoin image found for type " + bestMatchInfo.readBestMatchItemImageName().replace("quoin_", "") + 
                                             " at x,y " + bestMatchInfo.readBestMatchX() + "," + bestMatchInfo.readBestMatchY(), 2);
        }
    }
    
    public boolean readItemFound()
    {
        return itemFound;
    }
    
    public boolean readOkFlag()
    {
        return okFlag;
    }
    
    public boolean readSearchDone()
    {
        return searchDone;
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
        
        QuoinMatchData(MatchInfo matchInfo)
        {
            okFlag = true;
            bestMatchInfo = matchInfo;
            itemX = bestMatchInfo.readBestMatchX();
            itemY = bestMatchInfo.readBestMatchY();
            quoinType = bestMatchInfo.readBestMatchItemImageName().replace("quoin_", "");
            if (quoinType.length() == 0)
            {
                okFlag = false;
                printToFile.printDebugLine(this, "Error - missing variant for quoin ", 3);
            }
            distFromOrigXY = Utils.distanceBetweenX1Y1_X2Y2(thisItemInfo.readOrigItemX(), thisItemInfo.readOrigItemY(), itemX, itemY); 
            printToFile.printDebugLine(this, "Saving quoin data for " + quoinType + " with match of " + bestMatchInfo.matchPercentAsFloatString() + "% at x,y " + bestMatchInfo.bestMatchX + "," + bestMatchInfo.bestMatchY, 1);
        }
    }
}