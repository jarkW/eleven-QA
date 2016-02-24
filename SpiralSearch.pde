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
    int startX;
    int startY;
    String thisItemClassTSID;
    
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
    float lowestTotalRGBDiff;
    int lowestTotalRGBDiffStepX;
    int lowestTotalRGBDiffStepY;
    
    // final found difference in x,y
    int foundStepX;
    int foundStepY;

    boolean noMoreValidFragments;

    // The smaller this value, the more exacting the match test
    // but then it takes much longer to run. 
    // Too big - risk false positives
    // NB QQ change shape as bounces, so need to be more generous
    final float goodEnoughTotalRGB = 5000;
    //final float goodEnoughTotalRGB = 1000;

    //final float goodEnoughQQTotalRGB = 3 * goodEnoughTotalRGB;
    final float goodEnoughQQTotalRGB = 5 * goodEnoughTotalRGB;

    public SpiralSearch(PImage itemImage, PImage streetImage, String classTSID, int x, int y, int widthBox, int heightBox)
    {

        // Initialise variables      
        thisItemImage = itemImage;
        thisStreetImage = streetImage;
        thisItemClassTSID = classTSID;
        startX = x;
        startY = y;
        
        spiralCount = 0; 
        RGBDiffCount = 0;
         
        widthSearchBox = widthBox;
        heightSearchBox = heightBox;
        
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
        
        // spiral variables
        dStepX = 1;
        dStepY = 0;
        // length of current segment
        segmentLength = 1;

        // current position (i, j) and how much of current segment we passed
        stepX = startX;
        stepY = startY;
        foundStepX = missCoOrds;
        foundStepY = missCoOrds;
        segmentPassed = 0;

        // Initialise values for keeping record of 'best' fit of QA fragments with archive
        sumTotalRGBDiff = 0;
        lowestTotalRGBDiff = 0;
        // snap co-ords for lowest rgb 
        lowestTotalRGBDiffStepX = 0;
        lowestTotalRGBDiffStepY = 0;

        noMoreValidFragments = false; 
        
        printToFile.printDebugLine("Continuing search for " + classTSID + " at snap x,y " + x + "," + y + " with search box wxh " + widthBox + "x" + heightBox, 1);

    }
    
    public boolean searchForItem()
    {        
        noMoreValidFragments = false; 

        for (spiralCount = 0; spiralCount < maxSpiralCount && !noMoreValidFragments; spiralCount++)
        {
            if (checkFragmentsMatch())
            {
                printToFile.printDebugLine("OK/perfect Match found at  stepX = " + stepX + " stepY = " + stepY + " with sumTotalRGBDiff = " + int(sumTotalRGBDiff) + " spiralCount = " + spiralCount, 2);
                foundStepX = stepX;
                foundStepY = stepY;
                return true;
            }
            else 
            {
                // make a step, add 'direction' vector (dStepX, dStepY) to current position (stepX, stepY)
                getNextStepInSpiral();
            }
        }
        
        // Reached end of matching QA fragment against archive snap - need to see if the lowest RGB diff is good enough to be a match
        // Assume good enough if less than 10% of average total_rgb_diff measured
                   
        // Need to be more generous for QQ because shape changes as bounces
        float percentagePass;
        if (thisItemClassTSID == "marker_qurazy")
        {
            //percentagePass = 15;
            percentagePass = 25;
        }
        else
        {
            percentagePass = 10;
        }

        if (lowestTotalRGBDiff < (percentagePass * sumTotalRGBDiff/float(100*RGBDiffCount)))
        {
            printToFile.printDebugLine("Good enough % match found at step X " + lowestTotalRGBDiffStepX + " stepY = " + lowestTotalRGBDiffStepY + 
            "(lowest RGB diff = " + int(lowestTotalRGBDiff) + 
            //") avg RGB diff = " + int(sumTotalRGBDiff/percentagePass*RGBDiffCount) +
            ") avg RGB diff = " + int(sumTotalRGBDiff/RGBDiffCount) +
            " sum_total_rgb_diff=" + int(sumTotalRGBDiff) +
            " RGBDiffCount = " + RGBDiffCount +
            " spiralCount = " + spiralCount, 2);  
          
            foundStepX = lowestTotalRGBDiffStepX;
            foundStepY = lowestTotalRGBDiffStepY;
            return true;
        }
        else
        {
            // Consider item not found
            printToFile.printDebugLine("No match found, for reference, lowest RGB Diffstep X" + lowestTotalRGBDiffStepX + " stepY = " + lowestTotalRGBDiffStepY + 
           " (lowest RGB diff = " + int(lowestTotalRGBDiff) + 
            //") avg RGB diff = " + int(sumTotalRGBDiff/percentagePass*RGBDiffCount) + 
            ") avg RGB diff = " + int(sumTotalRGBDiff/RGBDiffCount) + 
            " su_rgb_dmTotalRGBDiff=" + int(sumTotalRGBDiff) +
            " RGBDiffCount = " + RGBDiffCount +
            " spiralCount = " + spiralCount, 2);  
            foundStepX = missCoOrds;
            foundStepY = missCoOrds;
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
                printToFile.printDebugLine("Off edge of street snap/outside search box - skip this RGB comparison (stepX = " + stepX + " stepY = " + stepY + ")", 1);    
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
        float RGBDiff = 0;
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
        
        for (int pixelYPosition = 0; pixelYPosition < thisItemImage.height; pixelYPosition++) 
        {
            for (int pixelXPosition = 0; pixelXPosition < thisItemImage.width; pixelXPosition++) 
            {
               
                //int loc = pixelXPosition + (pixelYPosition * streetItemInfo[streetItemCount].sampleWidth);
                        
                // For street snap
                locStreet = (stepX + pixelXPosition) + ((stepY + pixelYPosition) * thisStreetImage.width);
                rStreet = red(thisStreetImage.pixels[locStreet]);
                gStreet = green(thisStreetImage.pixels[locStreet]);
                bStreet = blue(thisStreetImage.pixels[locStreet]);
            
                // for Item snap
                locItem = pixelXPosition + (pixelYPosition * thisItemImage.width);
                rItem = red(thisItemImage.pixels[locItem]);
                gItem = green(thisItemImage.pixels[locItem]);
                bItem = blue(thisItemImage.pixels[locItem]);
                  
                RGBDiff = abs(rStreet-rItem) + abs (bStreet-bItem) + abs(gStreet-gItem);
                totalRGBDiff += abs(rStreet-rItem) + abs (bStreet-bItem) + abs(gStreet-gItem);
            
                /*
                if (debugRGB)
                {
                    s = "Frag Xpos,YPos = " + pixelXPosition + "," + pixelYPosition;
                    s = s + "    RGB street = " + int(rStreet) + ":" + int(gStreet) + ":" + int(bStreet);
                    s = s + "    RGB item = " + int(rItem) + ":" + int(gItem) + ":" + int(bItem);
                    printToFile.printDebugLine(s, 1);                    
                    //println("RGB archive = ", int(rStreet), ":",int(gStreet), ":", int(bStreet),"    RGB Item = ", int(rItem), ":", int(gItem), ":", int(bItem));
                }
                */
            }
        }
    
        // Need to save the totalRGBDiff - firstly if lower than lowestTotalRGBDiff, then save it as that, along with i,j
        // But also need to know what counts as a valid lowest_rgb diff - so also add totalRGBDiff to sumTotalRGBDiff 
    
        if (debugRGB)
        {
            s = "totalRGBDiff for stepX,stepY " + str(stepX - startX) + "," +  str(stepY - startY) + ": " + int(totalRGBDiff);
            printToFile.printDebugLine(s, 1);
        }
            
        if (totalRGBDiff == 0)
        {
            return true;
        }
        else if (totalRGBDiff < goodEnoughTotalRGB)
        {
            sumTotalRGBDiff += totalRGBDiff;
            return true;
        }
        else
        {
            if ((stepX == startX) && (stepY == startY))
            {
                // Save this one always - so overwrite initilised value
                lowestTotalRGBDiff = totalRGBDiff;
                lowestTotalRGBDiffStepX = stepX;
                lowestTotalRGBDiffStepY = stepY;
            }
            else if (totalRGBDiff < lowestTotalRGBDiff)
            {
                // save this if the lowest one so far
                lowestTotalRGBDiff = totalRGBDiff;
                lowestTotalRGBDiffStepX = stepX;
                lowestTotalRGBDiffStepY = stepY;
            }        
            sumTotalRGBDiff += totalRGBDiff;
            return false;
        }
    }
    
    public int readDiffX()
    {
        if (foundStepX != missCoOrds)
        {
            return foundStepX - startX;
        }
        else
        {
            return missCoOrds;
        }
    }
    public int readDiffY()
    {
        if (foundStepY != missCoOrds)
        {
            return foundStepY - startY;
        }
        else
        {
            return missCoOrds;
        }
    }

    // Used for debugging only
    public String debugRGBInfo()
    {
        float percentagePass;
        if (thisItemClassTSID == "marker_qurazy")
        {
            //percentagePass = 15;
            percentagePass = 25;
        }
        else
        {
            percentagePass = 10;
        }
        String s = "lowest RGB was " + lowestTotalRGBDiff + 
                    " lowestTotalRGBDiffStepX = " + lowestTotalRGBDiffStepX + " lowestTotalRGBDiffStepY = " + lowestTotalRGBDiffStepY + 
                    " avg RGB diff = " + int(sumTotalRGBDiff/RGBDiffCount) + 
                    " sumTotalRGBDiff=" + int(sumTotalRGBDiff) +
                    " RGBDiffCount = " + RGBDiffCount +
                    " foundStepX = " + foundStepX + 
                    " foundStepY = " + foundStepY + 
                    " spiralCount = " + spiralCount;

        return s;
    }
}