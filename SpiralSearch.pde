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
    
    int searchResult;
    
    // For debug info?
    int itemJSONX;
    int itemJSONY;
    int fragOffsetX;
    int fragOffsetY;
        
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
    int sumTransparentPixels;

    // Saving the x,y associated with the lowest average RGB difference found so far - which for a perfect match will be RGB diff = 0
    int lowestAvgRGBDiffStepX;
    int lowestAvgRGBDiffStepY;

    boolean noMoreValidFragments;
    
    boolean okFlag;
    
    // Used for debug info about the fragments
    final static int RED_PIXEL_COLOUR = #FC0808;   
    String itemTSID;
    String itemImageName;
    String streetImageName;
    int itemRGBMedian;
    int streetRGBMedian;

    // NB QQ change shape as bounces, so need to be more generous when considering
    // what constutitutes a match. 
    final static int QQ_MATCH_ADJUSTMENT = 15; 
    
    // What the value of lowest average RGB diff divided by total average RGB diff is in order to count as  found
    float maxRGBDiffVariation;


    public SpiralSearch(PImage itemImage, PImage streetImage, String classTSID, int itemX, int itemY, int offsetX, int offsetY, int widthBox, int heightBox, int searchRadius, int searchAdjustment, 
                        String TSID, String itemFragName, String streetSnapName)
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
        
        itemTSID = TSID;
        itemImageName = itemFragName;
        streetImageName = streetSnapName;
        
        startX = streetInfo.convertJSONXToProcessingX(itemX + fragOffsetX);
        startY = streetInfo.convertJSONYToProcessingY(itemY + fragOffsetY);
        
        spiralCount = 0; 
        RGBDiffCount = 0;
        
        itemRGBMedian = -9999;
        streetRGBMedian = -9999;
        
        // Set the search width to whatever was specified in the QABot_QABot_config.json file
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
        segmentPassed = 0;

        // Initialise values for keeping record of 'best' fit of QA fragments with archive
        sumTotalRGBDiff = 0;
        avgTotalRGBDiffPerPixel = 0;
        lowestAvgRGBDiffPerPixel = 0;
        // snap co-ords for lowest rgb 
        lowestAvgRGBDiffStepX = 0;
        lowestAvgRGBDiffStepY = 0;
        sumTransparentPixels = 0;
        
        // Set up the limit that the ratio between lowest average RGB diff divided by total average RGB diff is in order to count as a match
        // Some items e.g. ice knobs and QQ need some slightly more generous criteria.
        // If user wants 100% match, then this maxRGBDiffVariation value is set to 0 for normal items, for 90%, is set to 10/100
        maxRGBDiffVariation = float(100 - adjustedPercentMatchCriteria())/100;

        noMoreValidFragments = false; 
        
        searchResult = NO_MATCH;
        
        printToFile.printDebugLine(this, "New SpiralSearch for " + classTSID + " at snap x,y " + itemX + "," + itemY + " using offsetX=" + fragOffsetX + " offsetY=" + fragOffsetY + " with search box wxh " + widthBox + "x" + heightBox, 1);
        //printHashCodes(this);
    }
    
    public int searchForItem()
    {    
        String info;
        //printToFile.printDebugLine(this, "Enter searchForItem " + thisItemClassTSID + " (" + itemJSONX + "," + itemJSONY, 1);
        noMoreValidFragments = false;
        searchResult = NO_MATCH;

        for (spiralCount = 0; spiralCount < maxSpiralCount && !noMoreValidFragments; spiralCount++)
        {
            if (checkFragmentsMatch())
            {
                // This only returns true for a perfect match - for everything else do a full search and then just take the smallest RGBDiff as the result
                searchResult = PERFECT_MATCH;
                lowestAvgRGBDiffStepX = stepX;
                lowestAvgRGBDiffStepY = stepY;
                printToFile.printDebugLine(this, "Perfect Match found at  x,y " + streetInfo.convertProcessingXToJSONX(lowestAvgRGBDiffStepX - fragOffsetX) + "," + 
                                                  streetInfo.convertProcessingYToJSONY(lowestAvgRGBDiffStepY - fragOffsetY) + " spiralCount = " + spiralCount, 2);
                           
                if (!configInfo.readDebugUseTintedFragment())
                {
                    info = "Perfect fit/B&W at " + streetInfo.convertProcessingXToJSONX(lowestAvgRGBDiffStepX - fragOffsetX) + "," + 
                            streetInfo.convertProcessingYToJSONY(lowestAvgRGBDiffStepY - fragOffsetY) + " with " + itemImageName;
                }
                else
                {
                    info = "Perfect fit/tinted at " + streetInfo.convertProcessingXToJSONX(lowestAvgRGBDiffStepX - fragOffsetX) + "," + 
                            streetInfo.convertProcessingYToJSONY(lowestAvgRGBDiffStepY - fragOffsetY) + " with " + itemImageName;
                }
                displayMgr.showDebugImages(testStreetFragment, testItemFragment, info);
                return searchResult;
            }
            else 
            {
                // make a step, add 'direction' vector (dStepX, dStepY) to current position (stepX, stepY)
                getNextStepInSpiral();
            }
        }
        
        // Reached end of matching QA fragment against archive snap - need to see if the lowest RGB diff is good enough to be a match 
                
        // Need to take account of any pixels which were skipped because the item fragment pixel was transparent
        int numMatchesPerformed = (RGBDiffCount*thisItemImage.height * thisItemImage.width) - sumTransparentPixels;          
        avgTotalRGBDiffPerPixel = sumTotalRGBDiff/float(numMatchesPerformed);
        float ratioRGBDiff;
        float percentageMatch;
        
        // Need to avoid dividing by 0, or a very small number.
        if (avgTotalRGBDiffPerPixel < 0.01)
        {
            // Treat as 0, i.e. the first match was perfect, so the average total is the same as the average for the fragment
            ratioRGBDiff = 0;
            percentageMatch = 100;
        }
        else
        {
            ratioRGBDiff = lowestAvgRGBDiffPerPixel/avgTotalRGBDiffPerPixel;
            percentageMatch = 100 - (ratioRGBDiff * 100);
        }

        // See if the ratio of the best average RGB difference for a fragment, to the total average RGB differance over all searches is less than the cutoff limit
        // which has already been readjusted if dealing with a QQ rather than any other object.
        DecimalFormat df = new DecimalFormat("#.##"); 
        String formattedRatio = df.format(ratioRGBDiff); 
        String formattedPercentage = df.format(percentageMatch);
        if (ratioRGBDiff < maxRGBDiffVariation)
        {
            searchResult = GOOD_MATCH;
            printToFile.printDebugLine(this, "Good enough match found " +
            " at x,y " + streetInfo.convertProcessingXToJSONX(lowestAvgRGBDiffStepX - fragOffsetX) + "," + 
            streetInfo.convertProcessingYToJSONY(lowestAvgRGBDiffStepY - fragOffsetY) +
            " lowest avg RGB diff/pixel = " + round(lowestAvgRGBDiffPerPixel) +
            " avg RGB total diff/pixel = " + round(avgTotalRGBDiffPerPixel) +
            " ratio lowest:total avg RGB diff = " + formattedRatio +
            " % match = " + formattedPercentage, 2); 
   
            // Recreate the appropriate street fragment for this good enough search result - which doesn't need tinting, but does need converting to B&W
            testStreetFragment = thisStreetImage.get(lowestAvgRGBDiffStepX, lowestAvgRGBDiffStepY, thisItemImage.width, thisItemImage.height);
            testStreetFragment = convertImageToBW(testStreetFragment, thisItemImage); 

            // Item images are good as they are - are the ones which have been used to do the searching with
            info = "good enough fit (avgRGBDiff = " + formattedRatio + ") at " + streetInfo.convertProcessingXToJSONX(lowestAvgRGBDiffStepX - fragOffsetX) + "," + 
                    streetInfo.convertProcessingYToJSONY(lowestAvgRGBDiffStepY - fragOffsetY) + " with " + itemImageName;
            displayMgr.showDebugImages(testStreetFragment, testItemFragment, info);          
            return searchResult;
        }
        else
        {
            // Consider item not found
            printToFile.printDebugLine(this, "No match found at x,y " + itemJSONX + "," + itemJSONY + " for reference, " +
            " lowest avg RGB diff/pixel = " + round(lowestAvgRGBDiffPerPixel) +
            " avg RGB total diff/pixel = " + round(avgTotalRGBDiffPerPixel) +
            " ratio lowest:total avg RGB diff = " + formattedRatio +
            " % match = " + formattedPercentage +
            " for x,y " + streetInfo.convertProcessingXToJSONX(lowestAvgRGBDiffStepX - fragOffsetX) + "," + 
            streetInfo.convertProcessingYToJSONY(lowestAvgRGBDiffStepY - fragOffsetY), 2); 
        }
             
        // If reached this stage - failed to find item
        searchResult = NO_MATCH;
        return searchResult;
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
        int loc;
        float rStreet;
        float gStreet;
        float bStreet;
        float rItem;
        float gItem;
        float bItem;
        float aItem;
        
        String s;
        
        // Used to adjust the average RGB as if we skip the search result for these mismatches, should not affect the result
        // E.g. if have 3 non-transparent pixels out of 100, and all match, this is 100% success, not 3% (3/100)
        int skippedTransparentPixelsCount = 0;
        
        boolean debugRGB = false;
    
        // Register fact that doing another RGB comparison
        RGBDiffCount++;
                
        testStreetFragment = thisStreetImage.get(stepX, stepY, thisItemImage.width, thisItemImage.height);
        testItemFragment = thisItemImage.get(0, 0, thisItemImage.width, thisItemImage.height);
        // Draw out image pre-conversion  
        if (configInfo.readDebugUseTintedFragment())
        {
             // Street fragment does not need adjusting, only the item
             testItemFragment = applyGeoSettingsToItemImage(testItemFragment);
        }
        // Now convert both fragments to B&W ready for testing
        testItemFragment = convertImageToBW(null, testItemFragment);
        testStreetFragment = convertImageToBW(testStreetFragment, testItemFragment);

        // Don't draw these out now - only want to show the closest match ones.
        //image(streetFragment, 650, 100, 50, 50);
        //image(itemFragment, 750, 100, 50, 50);
        
        
        for (int pixelYPosition = 0; pixelYPosition < thisItemImage.height; pixelYPosition++) 
        {
            for (int pixelXPosition = 0; pixelXPosition < thisItemImage.width; pixelXPosition++) 
            {  
                loc = pixelXPosition + (pixelYPosition * thisItemImage.width);
                
                // Extract the transparency info first - as the comparison is skipped for transparent item pixels
                aItem = alpha(testItemFragment.pixels[loc]);               
                if (aItem != 255)
                {
                    if (debugRGB)
                    {
                        s = "Frag Xpos,YPos = " + pixelXPosition + "," + pixelYPosition;
                        s = s + " - transparent pixel";
                        printToFile.printDebugLine(this, s, 1);    
                    }
                    skippedTransparentPixelsCount++;
                }
                else
                {
                     // For street snap
                    rStreet = red(testStreetFragment.pixels[loc]);
                    gStreet = green(testStreetFragment.pixels[loc]);
                    bStreet = blue(testStreetFragment.pixels[loc]);
            
                    // for Item snap
                    rItem = red(testItemFragment.pixels[loc]);
                    gItem = green(testItemFragment.pixels[loc]);
                    bItem = blue(testItemFragment.pixels[loc]);
                    
                    totalRGBDiff += abs(rStreet-rItem) + abs (bStreet-bItem) + abs(gStreet-gItem);
                    
                    if (debugRGB)
                    {
                        s = "Frag Xpos,YPos = " + pixelXPosition + "," + pixelYPosition;
                        s = s + "    RGB street = " + int(rStreet) + ":" + int(gStreet) + ":" + int(bStreet);
                        s = s + "    RGB item = " + int(rItem) + ":" + int(gItem) + ":" + int(bItem);
                        printToFile.printDebugLine(this, s, 1);                    
                    }
                }
            }
        }
    
        // Need to save the totalRGBDiff - firstly if lower than lowestTotalRGBDiff, then save it as that, along with i,j
        // But also need to know what counts as a valid lowest_rgb diff - so also add totalRGBDiff to sumTotalRGBDiff 
    
        if (debugRGB)
        {
            s = "totalRGBDiff for stepX,stepY " + str(stepX - startX) + "," +  str(stepY - startY) + ": " + round(totalRGBDiff);
            printToFile.printDebugLine(this, s, 1);
        }
        
        // Keep track of number of skipped pixels
        sumTransparentPixels += skippedTransparentPixelsCount;
        
        // Need to take account of any pixels which were skipped because the item fragment pixel was transparent
        int numMatchesPerformed = (thisItemImage.height * thisItemImage.width) - skippedTransparentPixelsCount;
        float avgRGBFragmentDiff = totalRGBDiff/float(numMatchesPerformed);
        
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
    
    PImage applyGeoSettingsToItemImage(PImage fragment)
    {
        // Converts the original item fragment to be coloured in the same way as the street is e.g. saturation, brightness etc
        // But leaves any transparent pixels untouched - as these will be ignored when come to do the comparison
        int i;
        int j;
        int loc;
        float r;
        float g;
        float b;
        float a;
        PImage workingImage = fragment;       
        color newColour;
        
        //printToFile.printDebugLine(this, "Applying geo matrix info to fragment", 1);
        ColorMatrix cm = streetInfo.readCM();
        
        for (i = 0; i < workingImage.height; i++) 
        {
            for (j = 0; j < workingImage.width; j++)
            {
                loc = j + (i * workingImage.width);
                a = alpha(workingImage.pixels[loc]);
                
                // Convert using the matrix - if the pixel is not transparent
                if (a == 255)
                {
                    r = red(workingImage.pixels[loc]);
                    g = green(workingImage.pixels[loc]);
                    b = blue(workingImage.pixels[loc]);
                    newColour = cm.calcNewRPGA(r, g, b, a);
                    //Update the pixel
                    workingImage.pixels[loc] = newColour;
                }
            }
        }
        workingImage.updatePixels();
        
        return (workingImage);        
    }
   
    PImage convertImageToBW(PImage streetFragment, PImage itemFragment)
    {
        // When converting the street fragment, need to only convert the pixels which equate to non-transparent
        // ones in the item fragment. When converting the item fragment, the street Fragment is set to null
        PImage workingImage;
        boolean usingItem = false;
        if (streetFragment == null)
        {
            // Item is being converted
            workingImage = itemFragment;
            usingItem = true;
        }
        else
        {
            // street fragment being converted
            workingImage = streetFragment;
        }      
        
        // Convert image to be greyscale - this appears to preserve the alpha setting so should be safe to do
        workingImage.filter(GRAY);
        
        //printToFile.printDebugLine(this, "Converting image to B&W", 1);
        // Now find what the rgb value is for the median bright pixel in the fragment
        // Now it is greyscale, r = g = b
        int[] brightCount = new int[256];
        int i;
        int j;
        int loc;
        float r;
        float a;
        int numTransparentPixels = 0;
        for (i = 0; i < workingImage.height; i++) 
        {
            for (j = 0; j < workingImage.width; j++)
            {                
                //int loc = pixelXPosition + (pixelYPosition * streetItemInfo[streetItemCount].sampleWidth);
                loc = j + (i * workingImage.width);
  
                // Streets never have the alpha set, but fragments might. Therefore see if we need to skip over this
                // pixel by looking up the alpha of the item                
                a = alpha(itemFragment.pixels[loc]);

                // Only update the array entry if the pixel is not transparent
                if (a == 255)
                {
                    //Increment the count for the array entry matching this red value of the fragment
                    r = red(workingImage.pixels[loc]);
                    brightCount[int(r)]++;
                }
                else
                {
                    numTransparentPixels++;
                    if (!usingItem)
                    {
                        // As there is a transparent pixel in the item fragment, update the street pixel in this position to also be transparent
                        workingImage.pixels[loc] = color(0, 0, 0, 0);
                    }
                }
            }
        }
        
        // Now find the median brightness this array
        int medianRGB = 0;
        int count = 0;
        boolean found = false;
        int numValidPixels = (workingImage.height * workingImage.width) - numTransparentPixels; 
        
        for (i = 0; i < 256 && !found; i++) 
        {
           count = count + brightCount[i];
           if (count > numValidPixels / 2)
           {
               medianRGB = i;
               found = true;
           }
        }
        // Can't debug print the median value - crashes PC
        if (usingItem)
        {
            itemRGBMedian = medianRGB;
        }
        else
        {
            streetRGBMedian = medianRGB;
        }
        
        // Now make the image black/white using this median RGB - does not mess up the transparent pixels 
        workingImage.filter(THRESHOLD, map(medianRGB, 0, 255, 0, 1));
       
        return (workingImage);
    }
    
    PImage diffBWImages(PImage bestBWStreetFragment, PImage bestBWItemFragment)
    {
        // Need to diff and set pixels to be red where don't match.
        int loc;
        float rStreet;
        float rItem;
        float aItem;
        
        PImage diffImage = createImage(thisItemImage.width, thisItemImage.height, RGB);
                
        for (int pixelYPosition = 0; pixelYPosition < thisItemImage.height; pixelYPosition++) 
        {
            for (int pixelXPosition = 0; pixelXPosition < thisItemImage.width; pixelXPosition++) 
            {                    
                // For street snap
                loc = pixelXPosition + (pixelYPosition * thisItemImage.width);

                // for Item snap
                // Need to check for transparency
                aItem = alpha(bestBWItemFragment.pixels[loc]);
                if (aItem != 255)
                {
                    // transparent pixel - so mark as identical
                    diffImage.pixels[loc] = bestBWItemFragment.pixels[loc];
                }
                else
                {
                    rItem = red(bestBWItemFragment.pixels[loc]);
                    rStreet = red(bestBWStreetFragment.pixels[loc]);
                                
                    if (rStreet != rItem)
                    {
                        // If the two pixels are not both white or both black, then mark as red
                        diffImage.pixels[loc] = RED_PIXEL_COLOUR;
                    }
                    else
                    {
                        diffImage.pixels[loc] = bestBWItemFragment.pixels[loc];
                    }
                }
            }
        }        
        
        // Update the pixel array for this fragment
        diffImage.updatePixels();

        return diffImage;
    }
    
    PImage diffColourImages(PImage bestColStreetFragment, PImage bestColItemFragment, String rgbType)
    {
        // Need to diff the component requested and set the pixel to be this shade of grey
        int loc;
        float colStreet;
        float colItem;
        float diff;
        float deltaMultiplier;
        float rgbIncrement;
        float aItem;
        
        float largestDeltaNeg = 0;
        float largestDeltaPos = 0;
        
        PImage diffImage = createImage(bestColItemFragment.width, bestColItemFragment.height, RGB);
                        
        for (int pixelYPosition = 0; pixelYPosition < bestColItemFragment.height; pixelYPosition++) 
        {
            for (int pixelXPosition = 0; pixelXPosition < bestColItemFragment.width; pixelXPosition++) 
            {                    

                loc = pixelXPosition + (pixelYPosition * bestColItemFragment.width);
                aItem = alpha(bestColItemFragment.pixels[loc]);
                if (aItem != 255)
                {
                    // transparent pixel in the item - so mark as transparent in the diff image
                    diffImage.pixels[loc] = color(0, 0, 0, 0);
                }
                else
                {
                    // Proceed with colour comparison
                    switch (rgbType)
                    {
                        case "red":
                            colStreet = red(bestColStreetFragment.pixels[loc]);
                            colItem = red(bestColItemFragment.pixels[loc]);
                            break;
                        case "blue":
                            colStreet = blue(bestColStreetFragment.pixels[loc]);
                            colItem = blue(bestColItemFragment.pixels[loc]);
                            break;
                        case "green":
                            colStreet = green(bestColStreetFragment.pixels[loc]);
                            colItem = green(bestColItemFragment.pixels[loc]);
                            break;
                        default:
                            printToFile.printDebugLine(this, "Received invalid parameter of " + rgbType, 3);
                            return null;
                    }
    
                    diff = colStreet-colItem;
                    // Update the range - used for reporting for now
                    if (diff < largestDeltaNeg)
                    {
                        largestDeltaNeg = diff;
                    }
                    else if (diff > largestDeltaPos)
                    {
                        largestDeltaPos = diff;
                    }
                    
                    //printToFile.printDebugLine(this, "Delta for " + rgbType + " at " + pixelXPosition + "," + pixelYPosition + " = " + diff, 1);
                    
                    // Increase range of the diffs so easier to see subtle differences - but ensure is still 0-255
                    //diff = constrain(128 + (5 * diff), (float)0, (float)255);
                    // Now save this back using same value for r, g, b = grey                
                    //diffImage.pixels[loc] = color(diff, diff, diff);
                    
                    deltaMultiplier = 1;
                    rgbIncrement = 50;
                    // If there is no difference in pixels, set to black (0). Otherwise if positive difference, make more red, if negative difference, make bluer.
                    if (diff > 0)
                    {
                        // make more red
                        diffImage.pixels[loc] = color(constrain((128 + (diff * deltaMultiplier) + rgbIncrement), (float)0, (float)255), 
                                                      constrain((128 + (diff * deltaMultiplier)), (float)0, (float)255), 
                                                      constrain((128 + (diff * deltaMultiplier)), (float)0, (float)255));
                    }
                    else if (diff < 0)
                    {
                        // make more blue
                        diffImage.pixels[loc] = color(constrain((128 + (diff * deltaMultiplier)), (float)0, (float)255),
                                                      constrain((128 + (diff * deltaMultiplier)), (float)0, (float)255), 
                                                      constrain((128 + (diff * deltaMultiplier) + rgbIncrement), (float)0, (float)255));
                    }
                    else
                    {
                        diffImage.pixels[loc] = color(0, 0, 0);
                    }
                }
            }
        }        
        
        //printToFile.printDebugLine(this, "Delta range for " + rgbType + " is " + (int)largestDeltaNeg + " to "  + (int)largestDeltaPos, 1);
        
        // Update the pixel array for this fragment
        diffImage.updatePixels();
    
        return diffImage;
   }    

    int adjustedPercentMatchCriteria()
    {
        float adjustedPercent;
        
        switch (thisItemClassTSID)
        {
            case "marker_qurazy":
                // Effectively allows for an extra 15% of lee way
                adjustedPercent = float(configInfo.readPercentMatchCriteria()) * 0.85; 
                break;
                
            case "ice_knob":
                // Ice knobs are semi-transparent and so the match is not good compared to sample fragment - depends on underlying colour
                // So allow a bit more leeway for a match
                adjustedPercent = float(configInfo.readPercentMatchCriteria()) * 0.90;
                break;
                
            default:
                adjustedPercent = float(configInfo.readPercentMatchCriteria());
                break;
        }
        
        printToFile.printDebugLine(this, "Adjusted percentage match criteria for " + thisItemClassTSID + " is " + adjustedPercent, 1);
        return int(adjustedPercent);
    }

    // Used for debugging only
    public String debugRGBInfo()
    {  
        float ratioRGBDiff;
        
         // Need to take account of any pixels which were skipped because the item fragment pixel was transparent
        int numMatchesPerformed = (RGBDiffCount*thisItemImage.height * thisItemImage.width) - sumTransparentPixels;          
        avgTotalRGBDiffPerPixel = sumTotalRGBDiff/float(numMatchesPerformed);       
        
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
        String s = " avg lowest RGB diff/pixel/avg RGB total diff/pixel = " + round(lowestAvgRGBDiffPerPixel) +
                    " /" + round(avgTotalRGBDiffPerPixel) +
                    " = " + formattedRatio +
                    " at x,y " + streetInfo.convertProcessingXToJSONX(lowestAvgRGBDiffStepX - fragOffsetX) + "," + streetInfo.convertProcessingYToJSONY(lowestAvgRGBDiffStepY - fragOffsetY);
        return s;
    }
    
    public MatchInfo readSearchMatchInfo()
    {       
        int x;
        int y;
        
        // Convert back from Processing co-ordinates into JSON co-ordinates
        x = streetInfo.convertProcessingXToJSONX(lowestAvgRGBDiffStepX - fragOffsetX);
        y = streetInfo.convertProcessingYToJSONY(lowestAvgRGBDiffStepY - fragOffsetY);
               
        PImage BWfragmentDiffImage = null;
        PImage BWItemFragImage = null;
        PImage BWStreetFragImage = null;
        PImage colourItemFragImage = null;
        PImage colourStreetFragImage = null;
        PImage colourfragmentDiffRImage = null;
        PImage colourfragmentDiffGImage = null;
        PImage colourfragmentDiffBImage = null;
        MatchInfo searchMatchInfo = null;
        
        // Generate both colour and black/white images as might be useful if being dumped out in cases where not sure why matches are not being found          
        // Generate the colour images, and re-tint the item image to match the street
        // But only need to do this if the flag is set - otherwise will simply pass in null 
        
        // The item fragment will be used at the end of the street parsing in order to generate a street summary image which quickly shows matches/fails
        colourItemFragImage = thisItemImage.get(0, 0, thisItemImage.width, thisItemImage.height);
        if (configInfo.readDebugUseTintedFragment())
        {
            colourItemFragImage = applyGeoSettingsToItemImage(colourItemFragImage);
        }
        
        if (configInfo.readDebugDumpDiffImages())
        {
            colourStreetFragImage = thisStreetImage.get(lowestAvgRGBDiffStepX, lowestAvgRGBDiffStepY, thisItemImage.width, thisItemImage.height);

            colourfragmentDiffRImage = diffColourImages(colourStreetFragImage, colourItemFragImage, "red");
            colourfragmentDiffGImage = diffColourImages(colourStreetFragImage, colourItemFragImage, "green");
            colourfragmentDiffBImage = diffColourImages(colourStreetFragImage, colourItemFragImage, "blue");
            
            // generate the black & white images and obtain the diff image
            // Can use copies of the ones above - will then have correct tinting etc
            PImage tempStreetImage = colourStreetFragImage.get(0, 0, colourStreetFragImage.width, colourStreetFragImage.height);
            PImage tempItemImage = colourItemFragImage.get(0, 0, colourItemFragImage.width, colourItemFragImage.height);
            BWItemFragImage = convertImageToBW(null, tempItemImage);
            BWStreetFragImage = convertImageToBW(tempStreetImage, tempItemImage);
            BWfragmentDiffImage = diffBWImages(BWStreetFragImage, BWItemFragImage);
        }
        
        searchMatchInfo = new MatchInfo(readPercentageMatchInfo(), x, y, searchResult,
                                itemTSID, itemImageName, fragOffsetX, fragOffsetY, streetImageName,
                                colourStreetFragImage, BWStreetFragImage, colourItemFragImage, BWItemFragImage, BWfragmentDiffImage, colourfragmentDiffRImage, colourfragmentDiffGImage, colourfragmentDiffBImage);
        
        return searchMatchInfo;
    }

    public float readPercentageMatchInfo()
    {       
        // Need to take account of any pixels which were skipped because the item fragment pixel was transparent
        int numMatchesPerformed = (RGBDiffCount*thisItemImage.height * thisItemImage.width) - sumTransparentPixels;          
        avgTotalRGBDiffPerPixel = sumTotalRGBDiff/float(numMatchesPerformed);
               
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
        
    public boolean readOkFlag()
    {
        return okFlag;
    }

}