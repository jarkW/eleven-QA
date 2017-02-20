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
    
    int itemImageBeingUsed = -1;
    
    // Saved item information we need here - easier to read
    ArrayList<PNGFile> itemImages;
    PNGFile streetSnapImage;  
    
    // Information saved from the search before it is nulled ready for the next search/image
    // Keeps a running version of the 'best' match in
    MatchInfo bestMatchInfo;
    
    ArrayList<MatchInfo> allMatchResultsForItem;
    
        // constructor
    public FragmentFind(ItemInfo itemInfo)
    {
        okFlag = true;
        
        quoinMatches = new ArrayList<QuoinMatchData>();
        
        allMatchResultsForItem = new ArrayList<MatchInfo>();
        
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
        
        itemImageBeingUsed = nextImageToBeUsed(itemImageBeingUsed);
        
        if (itemImageBeingUsed >= itemImages.size())
        {
            // Should never happen at this initialisation stage
            printToFile.printDebugLine(this, "Failed to find first item image for " + thisItemInfo.readItemClassTSID() + "(" + thisItemInfo.readItemTSID() + ")", 3);
            okFlag = false;
            return;
        }
                
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
    
    int nextImageToBeUsed(int currentImageNumber)
    {
        // Returns the next image number to be used.
        // If -1 is passed in to the function, then indicates first time here, so forces check of first fragment image
        
        // This code is only really needed to handle efficient stripping down of searches to only use the images of the correct variant for the case when we're 
        // doing x,y changes only - when the variant is assumed to be correct.
        // Seemed easier than making an object copy of the array list of images passed to this class - didn't want to risk breaking images for subsequent item searches
        int nextImageNumber = currentImageNumber + 1;
        if (!streetInfo.readChangeItemXYOnly() || thisItemInfo.readOrigItemVariant().length() == 0 || thisItemInfo.readItemClassTSID().equals("wood_tree"))
        {
            // Need to search all the fragment images - as this is a normal search or there is no variant field (e.g. trant) or this is a wood tree - which could have a match
            // on a snap for any other kind of tree, so need to search all tree images as per normal
            return (nextImageNumber);
        }
               
        // If we've reached here then we need to skip over anything which does not match the variant type specified in the JSON file
        String itemVariant;
        itemVariant = thisItemInfo.readItemClassTSID() + "_" + thisItemInfo.readOrigItemVariant();
        // NB If incrementing the image number has pushed us past the end, then the for loop won't be entered
        while (nextImageNumber < itemImages.size())
        {
            if (itemImages.get(nextImageNumber).readPNGImageName().indexOf(itemVariant) != -1)
            {
                //Image exists
                printToFile.printDebugLine(this, " setting next item image number to be " + nextImageNumber, 1);
                return nextImageNumber;
            }
            nextImageNumber++;
        }

        // Only get here is no more matching images found or already at end of image list
        // Although nextImageNumber is set to be the size of the images array, explicitly set it for clarity
        printToFile.printDebugLine(this, "No more item images to use", 1);
        return itemImages.size();  
    }
    
    public boolean searchForFragment()
    {
        String debugInfo = "";
        String s;
                
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
        
        // Add in the search result even if useless so I can dump out later
        if (configInfo.readDebugDumpAllMatches())
        {
            allMatchResultsForItem.add(spiralSearch.readSearchMatchInfo());
        }
        
        // What happens next depends on the result of this search
        String additionalInfo = "";
        switch (searchResult)
        {
            case PERFECT_MATCH:
                // Quoins still need to be searched for using the next image (unless this is an x/y only search). QQ still need to be searched for on future snaps also
                // All other items can be marked as found and not searched on future snaps
                
                // The match info for non-quoins will be the best so far because perfect - for quoins, it will be rewritten from the saved quoinData structure before returning the search result
                bestMatchInfo = spiralSearch.readSearchMatchInfo();
                if (thisItemInfo.readItemClassTSID().equals("quoin") && !streetInfo.readChangeItemXYOnly())
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
                s = "searchResult - PERFECT match found for " + thisItemInfo.readItemTSID() + " " + thisItemInfo.readItemClassTSID() + " (with " + 
                                            bestMatchInfo.readBestMatchItemImageName() + ") found at x,y " +
                                            bestMatchInfo.readBestMatchX() + "," + bestMatchInfo.readBestMatchY() + " (" + bestMatchInfo.matchPercentAsFloatString() + "%)";
                                            
                printToFile.printDebugLine(this, s, 2);
                break;
                
            case GOOD_MATCH:
                // Quoins still need to be searched for using the next image (unless this is an x/y only search). 
                // Check other images for items on this street in the hope that a perfect match might be found - except items with multiple maturity images such as trees when we call 99% a good enough match

                if (thisItemInfo.readItemClassTSID().equals("quoin") && !streetInfo.readChangeItemXYOnly())
                {
                    // Only need to do this when collecting search results for all quoin images - otherwise can just use the data for the single search done
                    bestMatchInfo = spiralSearch.readSearchMatchInfo();
                    additionalInfo = " - quoin - ";
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
                        additionalInfo = " - overwrite null - ";
                        bestMatchInfo = spiralSearch.readSearchMatchInfo();
                    }
                    else if (bestMatchInfo.readPercentageMatch() < spiralSearch.readPercentageMatchInfo())
                    {
                        // Last search returned a better percentage match - so save this information
                        additionalInfo = " - better match - ";
                        bestMatchInfo = spiralSearch.readSearchMatchInfo();
                    }
                    else
                    {
                        // else - ignore the results of the last search as it was worse than/same as the best we have so far
                        additionalInfo = " - worse/same match, stick with this one - ";
                    }  
                    
                    // If this last search was 99% or better and the item has multiple states (images) e.g. trees, barnacles, then consider 99% 'perfect' and stop searching
                    // Note that some wood trees give 98% results for the wrong maturity level of that variant - but as the x,y returned are not affected, I'll ignore this for now
                    // Otherwise are having to search 100s of images unnecessarily
                    // This is a configurable setting for my purposes only - 99 is the default
                    if (thisItemInfo.itemHasMultipleImages() && spiralSearch.readPercentageMatchInfo() > configInfo.readDebugGoodEnoughMatch())
                    {
                        searchDone = true;
                        if (!thisItemInfo.readItemClassTSID().equals("marker_qurazy") && !thisItemInfo.readItemClassTSID().equals("quoin"))
                        {
                            // For trees and/items a 99% match means we've definitely found our item x,y. And so don't need to bother searching for this item on any further street snaps
                            itemFound = true;
                        }
                    }
                }

                debugInfo = spiralSearch.debugRGBInfo();
                s = "searchResult - " + additionalInfo + "GOOD match found for " + thisItemInfo.readItemTSID() + " " + thisItemInfo.readItemClassTSID() + ": best match so far is (with " + 
                                           bestMatchInfo.readBestMatchItemImageName() + ") found at x,y " +
                                           bestMatchInfo.readBestMatchX() + "," + bestMatchInfo.readBestMatchY() + " (" + bestMatchInfo.matchPercentAsFloatString() + ")";
                printToFile.printDebugLine(this, s, 2);          
                break;
                
            case NO_MATCH:
                // For quoins in the non-x/y search case, there is nothing to add to the quoinData structure
                // Only save the bestMatchInfo if better than what we've already got
                if (bestMatchInfo == null)
                {
                    // Returned from first search, so OK to overwrite with the information for this search
                    bestMatchInfo = spiralSearch.readSearchMatchInfo();
                    additionalInfo = " - overwrite null - ";
                }
                else if (bestMatchInfo.readPercentageMatch() < spiralSearch.readPercentageMatchInfo())
                {
                    // Last search returned a better percentage match - so save this information 
                    bestMatchInfo = spiralSearch.readSearchMatchInfo();
                    additionalInfo = " - better match - ";
                }
                else
                {
                    // else - ignore the results of the last search as it was worse than the best we have so far
                    additionalInfo = " - worse match, stick with this one - ";
                }     
                debugInfo = spiralSearch.debugRGBInfo();
                s = "searchResult - " + additionalInfo + "NO match found for " + thisItemInfo.readItemClassTSID() + ": best match is with " + 
                                           bestMatchInfo.readBestMatchItemImageName() + ") found at x,y " +
                                           bestMatchInfo.readBestMatchX() + "," + bestMatchInfo.readBestMatchY() + " (" + bestMatchInfo.matchPercentAsFloatString() + ")";
                printToFile.printDebugLine(this, s, 2);               
                break;
        }
               
        // If this is an x,y search only, then we only search for one image on the street anyhow because we know the class/variant from the JSON file
        // - except for trees which still have to search for all images regardless.
        // But also need to continue the search for the items which have multiple images loaded to manage the case where players have used resources and changed the appearance        
        if (streetInfo.readChangeItemXYOnly() && !thisItemInfo.itemIsAPlayerPlantedTree() && !thisItemInfo.itemHasMultipleImages())
        {
            searchDone = true;    
        }
        
        // So at this stage we have updated the quoin structure if necessary and bestMatchInfo contains the best match so far on this street with the item images
        if (!searchDone)
        {
            // Need to move on to process the next image on the street - this function will handle skipping searches 
            itemImageBeingUsed = nextImageToBeUsed(itemImageBeingUsed);
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