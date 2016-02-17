class SpiralSearch
{
    // Number of times search has been carried out
    int spiralCount;
    // Maximum attempts to try and match before giving up
    int maxSpiralCount;
    
    PImage thisItemImage;
    PImage thisStreetImage;
    int startX;
    int startY;
    
    //int search_radius = 20; // to be replaced by maxSpiralCount - May change e.g. if just finding y position of quoin

    // (di, dj) is a vector - direction in which we move right now
    int di;
    int dj;
    // length of current segment
    int segmentLength;

    // current position (i, j) and how much of current segment we passed
    int i;
    int j;
    int segmentPassed;

    // loop for QA archive fragment to be read from archive snap
    int k; // spiralCount

    // Variables for keeping track of lowest rgb differences
    float sumTotalRGBDiff;
    float lowestTotalRGBDiff;
    int lowestTotalRGBDiff_i;
    int lowestTotalRGBDiff_j;

    boolean matchFound;
    boolean noMoreValidFragments;

    // The smaller this value, the more exacting the match test
    // but then it takes much longer to run. 
    // Too big - risk false positives
    // NB QQ change shape as bounces, so need to be more generous
    final float goodEnoughTotalRGB = 5000;
    //final float goodEnoughTotalRGB = 1000;

    //final float goodEnoughQQTotalRGB = 3 * goodEnoughTotalRGB;
    final float goodEnoughQQTotalRGB = 5 * goodEnoughTotalRGB;

    public SpiralSearch(PImage itemImage, PImage streetImage, int x, int y)
    {
        // if pass boolean - just finding quoin_y???
        // Then can change the value of maxSpiralCount

        // Initialise variables      
        thisItemImage = itemImage;
        thisStreetImage = streetImage;
        startX = x;
        startY = y;
        
        spiralCount = 0; // was k
        maxSpiralCount = 20 * 20; // but may be changed if quoin y to be found? - search_raduis squared
        
        // spiral variables
        di = 1;
        dj = 0;
        // length of current segment
        segmentLength = 1;

        // current position (i, j) and how much of current segment we passed
        i = startX;
        j = startY;
        segmentPassed = 0;
        matchFound = false;

        // Initialise values for keeping record of 'best' fit of QA fragments with archive
        sumTotalRGBDiff = 0;
        lowestTotalRGBDiff = 0;
        // snap co-ords for lowest rgb 
        lowestTotalRGBDiff_i = 0;
        lowestTotalRGBDiff_j = 0;

        noMoreValidFragments = false; 
    }
    
    
    
    boolean check_fragments_match()
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
    

        for (int pixelYPosition = 0; pixelYPosition < thisItemImage.height; pixelYPosition++) 
        {
            for (int pixelXPosition = 0; pixelXPosition < thisItemImage.width; pixelXPosition++) 
            {
               
                //int loc = pixelXPosition + (pixelYPosition * streetItemInfo[streetItemCount].sampleWidth);
                        
                // For street snap
                locStreet = (i + pixelXPosition) + ((j + pixelYPosition) * thisStreetImage.width);
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
            s = "totalRGBDiff for i,j " + str(i - startX) + "," +  str(j - startY) + ": " + int(totalRGBDiff);
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
            if ((i == startX) && (j == startY))
            {
                // Save this one always - so overwrite initilised value
                lowestTotalRGBDiff = totalRGBDiff;
                lowestTotalRGBDiff_i = i;
                lowestTotalRGBDiff_j = j;
            }
            else if (totalRGBDiff < lowestTotalRGBDiff)
            {
                // save this if the lowest one so far
                lowestTotalRGBDiff = totalRGBDiff;
                lowestTotalRGBDiff_i = i;
                lowestTotalRGBDiff_j = j;
            }        
            sumTotalRGBDiff += totalRGBDiff;
            return false;
        }
    }

}