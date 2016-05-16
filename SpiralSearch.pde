class SpiralSearch
{
    
    // Number of times attempt search has been carried out on street snap
    int spiralCount;
    // As the spiral path is sometimes outside the search box, this is the actual count of
    // the number of RGB comparisons made - needed when seeing if an RGB difference is good 
    // enough to count as a match
    int RGBDiffCount;
    // Maximum attempts to try and match before giving up
    int maxSpiralCount;

    int widthSearchBox;
    int heightSearchBox;
    
    PImage thisItemImage;
    PImage thisStreetImage;
    PImage testStreetFragment;
    PImage testItemFragment;
    int startX;
    int startY;
    String thisItemClassTSID;
    
    // For debug info?
    int itemJSONX;
    int itemJSONY;
    int fragOffsetX;
    int fragOffsetY;
    
    // FOR DEBUG ONLY
    // dumps out the images that are being compared as files - useful for when failing and not sure why.
    // Used to dump out the best of the failure cases. 
    boolean saveImages = false;
    int numSavedImages = 0;
    
    // (dStepX, dStepY) is a vector - direction in which we move right now
    int dStepX;
    int dStepY;
    // length of current segment
    int segmentLength;

    // current position (stepX, stepY) and how much of current segment we passed
    int stepX;
    int stepY;
    int segmentPassed;

    // Variables for keeping track of lowest rgb differences
    float sumTotalRGBDiff;
    float avgTotalRGBDiffPerPixel;
    float lowestAvgRGBDiffPerPixel;

    // Saving the x,y associated with the lowest average RGB difference found so far
    int lowestAvgRGBDiffStepX;
    int lowestAvgRGBDiffStepY;
    

        
    // final found difference in x,y
    int foundStepX;
    int foundStepY;

    boolean noMoreValidFragments;
    
    boolean okFlag;

    // NB QQ change shape as bounces, so need to be more generous when considering
    // what constutitutes a match. 
    final static int QQ_MATCH_ADJUSTMENT = 15; 
    
    // What the value of lowest average RGB diff divided by total average RGB diff is in order to count as  found
    float maxRGBDiffVariation;


    public SpiralSearch(PImage itemImage, PImage streetImage, String classTSID, int itemX, int itemY, int offsetX, int offsetY, int widthBox, int heightBox, int searchRadius, int searchAdjustment)
    {
        okFlag = true;
        
        //printToFile.printDebugLine(this, "Create New SpiralSearch", 1);
        // Initialise variables      
        thisItemImage = itemImage;
        thisStreetImage = streetImage;
               
        if (thisStreetImage == null)
        {
            printToFile.printDebugLine(this, "Null street image passed in to new SpiralSearch", 1);
            okFlag = false;
            return;
        }

        thisItemClassTSID = classTSID;
        
        // Work out the startX/startY - need to convert from the game JSON x,y to the Processing system
        // Save in case we need them for reporting
        itemJSONX = itemX;
        itemJSONY = itemY;
        fragOffsetX = offsetX;
        fragOffsetY = offsetY;        
        
        startX = itemX + thisStreetImage.width/2 + fragOffsetX;
        startY = itemY + thisStreetImage.height + fragOffsetY;
        
        spiralCount = 0; 
        RGBDiffCount = 0;
        
        // Set the search width to whatever was specified in the config.json file
        // For some items e.g. sloths, will manually extend the search radius as the branches have been
        // very poorly configured so far
        widthSearchBox = widthBox + (2*searchRadius) + searchAdjustment;
        heightSearchBox = heightBox + (2*searchRadius) + searchAdjustment;
        
         // convert the searchbox to be even numbers
         // deal with odd sizes of box - by adding 1 before do divide so box
        // is larger rather than smaller
        if ((heightSearchBox % 2) == 1)
        {
            heightSearchBox++;
        }
        if ((widthSearchBox % 2) == 1)
        {
            widthSearchBox++;
        }
        
        // In order to make sure we catch all the elements inside the box
        // the spiral needs to be (n+1) squared. 
        if (heightSearchBox >= widthSearchBox)
        {
            maxSpiralCount = (heightSearchBox+1) * (heightSearchBox+1);
        }
        else
        {
           maxSpiralCount = (widthSearchBox+1) * (widthSearchBox+1);
        } 
        
        maxSpiralCount = 4000 * maxSpiralCount;
        
        // spiral variables
        dStepX = 1;
        dStepY = 0;
        // length of current segment
        segmentLength = 1;

        // current position (i, j) and how much of current segment we passed
        stepX = startX;
        stepY = startY;
        foundStepX = MISSING_COORDS;
        foundStepY = MISSING_COORDS;
        segmentPassed = 0;

        // Initialise values for keeping record of 'best' fit of QA fragments with archive
        sumTotalRGBDiff = 0;
        avgTotalRGBDiffPerPixel = 0;
        lowestAvgRGBDiffPerPixel = 0;
        // snap co-ords for lowest rgb 
        lowestAvgRGBDiffStepX = 0;
        lowestAvgRGBDiffStepY = 0;
        
        // Set up the limit that the ratio between lowest average RGB diff divided by total average RGB diff is in order to count as a match
        if (thisItemClassTSID.equals("marker_qurazy"))
        {
            // Need to increase the level which counts as a match
            maxRGBDiffVariation = float(100 - configInfo.readPercentMatchCriteria() + QQ_MATCH_ADJUSTMENT)/100;            
        }
        else
        {
            // So if user wants 100%, then, this is set to 0
            // If user wants 90%, then this is set to 10/100 
            maxRGBDiffVariation = float (100 - configInfo.readPercentMatchCriteria())/100;
        }

        noMoreValidFragments = false; 
        
        printToFile.printDebugLine(this, "New SpiralSearch for " + classTSID + " at snap x,y " + itemX + "," + itemY + " using offsetX=" + fragOffsetX + " offsetY=" + fragOffsetY + " with search box wxh " + widthBox + "x" + heightBox, 1);
        //printHashCodes(this);
    }
    
    public boolean searchForItem()
    {    
        String info;
        //printToFile.printDebugLine(this, "Enter searchForItem " + thisItemClassTSID + " (" + itemJSONX + "," + itemJSONY, 1);
        noMoreValidFragments = false;

        for (spiralCount = 0; spiralCount < maxSpiralCount && !noMoreValidFragments; spiralCount++)
        {
            if (checkFragmentsMatch())
            {
                // This only returns true for a perfect match - for everything else do a full search and then just take the smallest RGBDiff as the result
                foundStepX = stepX;
                foundStepY = stepY;
                printToFile.printDebugLine(this, "Perfect Match found at  x,y " + convertToJSONX(foundStepX) + "," + convertToJSONY(foundStepY) + " spiralCount = " + spiralCount, 2);
                           
                if (usingBlackWhiteComparison)
                {
                    info = "Perfect fit/grey at " + convertToJSONX(foundStepX) + "," + convertToJSONY(foundStepY);
                }
                else
                {
                    info = "Perfect fit/colour at " + convertToJSONX(foundStepX) + "," + convertToJSONY(foundStepY);
                }
                displayMgr.showDebugImages(testStreetFragment, testItemFragment, info);
                
                return true;
            }
            else 
            {
                // make a step, add 'direction' vector (dStepX, dStepY) to current position (stepX, stepY)
                getNextStepInSpiral();
            }
        }
        
        // Reached end of matching QA fragment against archive snap - need to see if the lowest RGB diff is good enough to be a match 
        avgTotalRGBDiffPerPixel = sumTotalRGBDiff/float(RGBDiffCount*thisItemImage.width*thisItemImage.height);
        float ratioRGBDiff;
        
        // Need to avoid dividing by 0, or a very small number.
        if (avgTotalRGBDiffPerPixel < 0.01)
        {
            // Treat as 0, i.e. the first match was perfect, so the average total is the same as the average for the fragment
            ratioRGBDiff = 0;
        }
        else
        {
            ratioRGBDiff = lowestAvgRGBDiffPerPixel/avgTotalRGBDiffPerPixel;
        }

        // See if the ratio of the best average RGB difference for a fragment, to the total average RGB differance over all searches is less than the cutoff limit
        // which has already been readjusted if dealing with a QQ rather than any other object.
        DecimalFormat df = new DecimalFormat("#.##"); 
        String formattedRatio = df.format(ratioRGBDiff); 
        if (ratioRGBDiff < maxRGBDiffVariation)
        {
            foundStepX = lowestAvgRGBDiffStepX;
            foundStepY = lowestAvgRGBDiffStepY;
            printToFile.printDebugLine(this, "Good enough match found " +
            " at x,y " + convertToJSONX(foundStepX) + "," + convertToJSONY(foundStepY) +
            " lowest avg RGB diff/pixel = " + int(lowestAvgRGBDiffPerPixel) +
            " avg RGB total diff/pixel = " + int (avgTotalRGBDiffPerPixel) +
            " ratio lowest:total avg RGB diff = " + formattedRatio, 2); 
               
            // Recreate the appropriate street fragment for this good enough search result
            testStreetFragment = thisStreetImage.get(foundStepX, foundStepY, thisItemImage.width, thisItemImage.height);
            testStreetFragment = convertImage(testStreetFragment);
            info = "good enough fit (avgRGBDiff = " + formattedRatio + ") at " + convertToJSONX(foundStepX) + "," + convertToJSONY(foundStepY);
            displayMgr.showDebugImages(testStreetFragment, testItemFragment, info);

            return true;
        }
        else
        {
            // Consider item not found
            printToFile.printDebugLine(this, "No match found at x,y " + itemJSONX + "," + itemJSONY + " for reference, " +
            " lowest avg RGB diff/pixel = " + int(lowestAvgRGBDiffPerPixel) +
            " avg RGB total diff/pixel = " + int (avgTotalRGBDiffPerPixel) +
            " ratio lowest:total avg RGB diff = " + formattedRatio +
            " for x,y " + convertToJSONX(lowestAvgRGBDiffStepX) + "," + convertToJSONY(lowestAvgRGBDiffStepY), 2); 
            
            
            if (saveImages)
            {
                // This doesn't really work as we don't know which of the images had this lowest RGB for example. Might need instead to have a separate class
                // for dumping out images - or pass the item info field as well??? 
                testStreetFragment = thisStreetImage.get(lowestAvgRGBDiffStepX, lowestAvgRGBDiffStepY, thisItemImage.width, thisItemImage.height);
                testStreetFragment = convertImage(testStreetFragment);
                testStreetFragment.save(sketchPath() + "/BW" + convertToJSONX(lowestAvgRGBDiffStepX) + "_" + convertToJSONY(lowestAvgRGBDiffStepY)+ "_" + thisItemClassTSID + "_" + numSavedImages + ".png");
                testItemFragment.save(sketchPath() + "/BW" + thisItemClassTSID + "_" + numSavedImages + ".png");
                numSavedImages++;
            }
            
            
            foundStepX = MISSING_COORDS;
            foundStepY = MISSING_COORDS;
        }
             
        // If reached this stage - failed to find item
        return false;
    }
    
    void getNextStepInSpiral()
    {
        boolean continueSearching = true;
    
        while (continueSearching && !noMoreValidFragments)
        {
            // make a step, add 'direction' vector (di, dj) to current position (i, j)     
            stepX += dStepX;
            stepY += dStepY;
            segmentPassed++;
  
           if (segmentPassed == segmentLength) 
            {
                // done with current segment
                segmentPassed = 0;
                // 'rotate' directions
                int buffer = dStepX;
                dStepX = -dStepY;
                dStepY = buffer;

                // increase segment length if necessary
                if (dStepY == 0) 
                {
                    segmentLength++;
                }
            }
                     
            // Check to see if off side of snap, or if outside the search box area
            if ((stepX < 0) || (stepX > thisStreetImage.width) || (stepY < 0) || (stepY > thisStreetImage.height) ||
                (stepX < startX - widthSearchBox/2 ) || (stepX > startX + widthSearchBox/2) || 
                (stepY < startY - heightSearchBox/2) || (stepY > startY + heightSearchBox/2))
            {
                // invalid value - off edge of archive snap, or outside searchbox area so skip this one and continue
                //printToFile.printDebugLine(this, "Off edge of street snap/outside search box - skip this RGB comparison (stepX = " + stepX + " stepY = " + stepY + ")", 1);    
                spiralCount++;
            }            
            else
            {
                // found valid stepX, stepY
                continueSearching = false;
            }
            
            if (spiralCount >= maxSpiralCount) 
            {
                noMoreValidFragments = true;
            }
        }
    }

    boolean checkFragmentsMatch()
    {
    
        float totalRGBDiff = 0;
        int locItem;
        int locStreet;
        float rStreet;
        float gStreet;
        float bStreet;
        float rItem;
        float gItem;
        float bItem;
        
        String s;
        
        boolean debugRGB = false;
    
        // Register fact that doing another RGB comparison
        RGBDiffCount++;
                
        testStreetFragment = thisStreetImage.get(stepX, stepY, thisItemImage.width, thisItemImage.height);
        testItemFragment = thisItemImage.get(0, 0, thisItemImage.width, thisItemImage.height);
        // Draw out image pre-conversion  
        testStreetFragment = convertImage(testStreetFragment);
        testItemFragment = convertImage(testItemFragment);
        
        // Don't draw these out now - only want to show the closest match ones.
        //image(streetFragment, 650, 100, 50, 50);
        //image(itemFragment, 750, 100, 50, 50);
        
        
        for (int pixelYPosition = 0; pixelYPosition < thisItemImage.height; pixelYPosition++) 
        {
            for (int pixelXPosition = 0; pixelXPosition < thisItemImage.width; pixelXPosition++) 
            {
               
                //int loc = pixelXPosition + (pixelYPosition * streetItemInfo[streetItemCount].sampleWidth);
                        
                // For street snap
                locStreet = pixelXPosition + (pixelYPosition * thisItemImage.width);
                rStreet = red(testStreetFragment.pixels[locStreet]);
                gStreet = green(testStreetFragment.pixels[locStreet]);
                bStreet = blue(testStreetFragment.pixels[locStreet]);
            
                // for Item snap
                locItem = pixelXPosition + (pixelYPosition * thisItemImage.width);
                rItem = red(testItemFragment.pixels[locItem]);
                gItem = green(testItemFragment.pixels[locItem]);
                bItem = blue(testItemFragment.pixels[locItem]);
                  
                totalRGBDiff += abs(rStreet-rItem) + abs (bStreet-bItem) + abs(gStreet-gItem);
            
                if (debugRGB)
                {
                    s = "Frag Xpos,YPos = " + pixelXPosition + "," + pixelYPosition;
                    s = s + "    RGB street = " + int(rStreet) + ":" + int(gStreet) + ":" + int(bStreet);
                    s = s + "    RGB item = " + int(rItem) + ":" + int(gItem) + ":" + int(bItem);
                    //printToFile.printDebugLine(this, s, 1);                    
                }
            }
        }
    
        // Need to save the totalRGBDiff - firstly if lower than lowestTotalRGBDiff, then save it as that, along with i,j
        // But also need to know what counts as a valid lowest_rgb diff - so also add totalRGBDiff to sumTotalRGBDiff 
    
        if (debugRGB)
        {
            s = "totalRGBDiff for stepX,stepY " + str(stepX - startX) + "," +  str(stepY - startY) + ": " + int(totalRGBDiff);
            printToFile.printDebugLine(this, s, 1);
        }
        
        float avgRGBFragmentDiff = totalRGBDiff/float(thisItemImage.height * thisItemImage.width);
        
        if (avgRGBFragmentDiff < 0.01)
        {
            // i.e. is effectively 0
            lowestAvgRGBDiffStepX = stepX;
            lowestAvgRGBDiffStepY = stepY; 
            lowestAvgRGBDiffPerPixel = 0;
            return true;
        }
        // only return true if perfect match, otherwise search the entire snap and take the lowest value

        else
        {
            if ((stepX == startX) && (stepY == startY))
            {
                // Save this one always - so overwrite initilised value
                lowestAvgRGBDiffPerPixel = avgRGBFragmentDiff;
                lowestAvgRGBDiffStepX = stepX;
                lowestAvgRGBDiffStepY = stepY;
            }
            else if (avgRGBFragmentDiff < lowestAvgRGBDiffPerPixel)
            {
                // save this if the lowest one so far
                lowestAvgRGBDiffPerPixel = avgRGBFragmentDiff;
                lowestAvgRGBDiffStepX = stepX;
                lowestAvgRGBDiffStepY = stepY;
            }     
            // Needed when we eventually calculate the average RGB per pixel over all searches
            sumTotalRGBDiff += totalRGBDiff;
            return false;
        }
    }
   
    PImage convertImage(PImage fragment)
    {
        if (!usingBlackWhiteComparison)
        {
            return (fragment);
        }
        
        // Convert image to be greyscale
        fragment.filter(GRAY);

        
        // Now find what the rgb value is for the median bright pixel in the fragment
        // Now it is greyscale, r = g = b
        int[] brightCount = new int[256];
        int i;
        int j;
        int locItem;
        float r;
        for (i = 0; i < fragment.height; i++) 
        {
            for (j = 0; j < fragment.width; j++)
            {
                //int loc = pixelXPosition + (pixelYPosition * streetItemInfo[streetItemCount].sampleWidth);
                locItem = j + (i * fragment.width);
                r = red(fragment.pixels[locItem]);
                
                //Increment the count for the array entry matching this rgb value
                brightCount[int(r)]++;
            }
        }
        
        // Now find the median brightness this array
        int medianRGB = 0;
        int count = 0;
        boolean found = false;
        for (i = 0; i < 256 && !found; i++) 
        {
           count = count + brightCount[i];
           if (count > fragment.width * fragment.height / 2)
           {
               medianRGB = i;
               found = true;
           }
        }
         
        
        // Now make the image black/white using this median RGB
        fragment.filter(THRESHOLD, map(medianRGB, 0, 255, 0, 1)); 
        
        return (fragment);
        
    }
       
    public int convertToJSONX(int pixelX)
    {
        // converts the foundStepX = pixel X co-ord from 0-width, into JSON equivalent X co-ord
        if (pixelX != MISSING_COORDS)
        {
            return pixelX - thisStreetImage.width/2 - fragOffsetX;
        }
        else
        {
            return MISSING_COORDS;
        }
    }
    public int convertToJSONY(int pixelY)
    {
        // converts the foundStepY = pixel Y co-ord from 0-width, into JSON equivalent Y co-ord
        if (pixelY != MISSING_COORDS)
        {
            return pixelY - thisStreetImage.height - fragOffsetY;
        }
        else
        {
            return MISSING_COORDS;
        }
    }

    // Used for debugging only
    public String debugRGBInfo()
    {  
        float ratioRGBDiff;
        avgTotalRGBDiffPerPixel = sumTotalRGBDiff/float(RGBDiffCount*thisItemImage.width*thisItemImage.height); 
        
        // Need to avoid dividing by 0, or a very small number.
        if (avgTotalRGBDiffPerPixel < 0.01)
        {
            // Treat as 0, i.e. the first match was perfect, so the average total is the same as the average for the fragment
            ratioRGBDiff = 0;
        }
        else
        {
            ratioRGBDiff = lowestAvgRGBDiffPerPixel/avgTotalRGBDiffPerPixel;
        }

        // See if the ratio of the best average RGB difference for a fragment, to the total average RGB differance over all searches is less than the cutoff limit
        // which has already been readjusted if dealing with a QQ rather than any other object.
        DecimalFormat df = new DecimalFormat("#.##"); 
        String formattedRatio = df.format(ratioRGBDiff);  
        String s = " avg lowest RGB diff/pixel/avg RGB total diff/pixel = " + int (lowestAvgRGBDiffPerPixel) +
                    " /" + int (avgTotalRGBDiffPerPixel) +
                    " = " + formattedRatio +
                    " at x,y " + convertToJSONX(foundStepX) + "," + convertToJSONY(foundStepY);

        return s;
    }
    
    public MatchInfo readSearchMatchInfo()
    {       
        avgTotalRGBDiffPerPixel = sumTotalRGBDiff/float(RGBDiffCount*thisItemImage.width*thisItemImage.height); 
        int x;
        int y;
        // If not found item, then return the x,y associated with the lowest RGBDiff
        if (foundStepX == MISSING_COORDS)
        {
            x = convertToJSONX(lowestAvgRGBDiffStepX);
            y = convertToJSONY(lowestAvgRGBDiffStepY);
        }
        else
        {
            x = convertToJSONX(foundStepX);
            y = convertToJSONY(foundStepY);
        }
        
        MatchInfo RGBInfo = new MatchInfo(lowestAvgRGBDiffPerPixel, avgTotalRGBDiffPerPixel, x, y);
        
        return RGBInfo;
    }
    
    public float readPercentageMatchInfo()
    {
        avgTotalRGBDiffPerPixel = sumTotalRGBDiff/float(RGBDiffCount*thisItemImage.width*thisItemImage.height); 
        float percentageMatch;
          
        // Need to avoid dividing by 0, or a very small number.
        if (avgTotalRGBDiffPerPixel < 0.01)
        {
            // Treat as 0, i.e. the first match was perfect, so the average total is the same as the average for the fragment
            percentageMatch = 100;
        }
        else
        {
            percentageMatch = 100 - ((lowestAvgRGBDiffPerPixel/avgTotalRGBDiffPerPixel) * 100);
        }
        
        return percentageMatch;
    }
    
    public int readFoundStepX()
    {
        return foundStepX;
    }
    
    public int readFoundStepY()
    {
        return foundStepY;
    }
    
    public boolean readOkFlag()
    {
        return okFlag;
    }

}