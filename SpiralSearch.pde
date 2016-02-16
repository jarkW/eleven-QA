class SpiralSearch
{
    // Number of times search has been carried out
    int spiralCount;
    // Maximum attempts to try and match before giving up
    int maxSpiralCount;
    
    PImage thisItemImage;
    PImage thisStreetImage;
    PImage streetFragment;
    int startX;
    int startY;
    
    //int search_radius = 20; // to be replaced by maxSpiralCount - May change e.g. if just finding y position of quoin

    // (di, dj) is a vector - direction in which we move right now
    int di;
    int dj;
    // length of current segment
    int segment_length;

    // current position (i, j) and how much of current segment we passed
    int i;
    int j;
    int segment_passed;

    // loop for QA archive fragment to be read from archive snap
    int k; // spiralCount

    // Variables for keeping track of lowest rgb differences
    float sum_total_rgb_diff;
    float lowest_total_rgb_diff;
    int lowest_total_rgb_diff_i;
    int lowest_total_rgb_diff_j;

    boolean match_found;
    boolean no_more_valid_fragments;

    // The smaller this value, the more exacting the match test
    // but then it takes much longer to run. 
    // Too big - risk false positives
    // NB QQ change shape as bounces, so need to be more generous
    final float good_enough_total_rgb = 5000;
    //final float good_enough_total_rgb = 1000;

    //final float good_enough_QQ_total_rgb = 3 * good_enough_total_rgb;
    final float good_enough_QQ_total_rgb = 5 * good_enough_total_rgb;

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
        segment_length = 1;

        // current position (i, j) and how much of current segment we passed
        i = start_x;
        j = start_y;
        segment_passed = 0;
        match_found = false;

        // Initialise values for keeping record of 'best' fit of QA fragments with archive
        sum_total_rgb_diff = 0;
        lowest_total_rgb_diff = 0;
        // snap co-ords for lowest rgb 
        lowest_total_rgb_diff_i = 0;
        lowest_total_rgb_diff_j = 0;

        no_more_valid_fragments = false; 
        
        
        // Set up for first fragment match
        //streetFragment = thisStreetImage.get(i, j, itemImage.width, itemImage.height);
    }
    
    
    
    boolean check_fragments_match()
    {
    
        float total_rgb_diff = 0;
        float rgb_diff = 0;
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
    

        for (int pixelYPosition = 0; pixelYPosition < streetItemInfo[streetItemCount].sampleHeight; pixelYPosition++) 
        {
            for (int pixelXPosition = 0; pixelXPosition < streetItemInfo[streetItemCount].sampleWidth; pixelXPosition++) 
            {
               
                //int loc = pixelXPosition + (pixelYPosition * streetItemInfo[streetItemCount].sampleWidth);
                        
                // For street snap
                locStreet = (i + pixelXPosition) + ((j + pixelYPosition) * thisStreetImage.width);
                rStreet = red(thisStreetImage.pixels[locStreet]);
                gStreet = green(thisStreetImage.pixels[locStreet]);
                bStreet = blue(thisStreetImage.pixels[locStreet]);
            
                // for Item snap
                locItem = pixelXPosition + (pixelYPosition * streetItemInfo[streetItemCount].itemImage.width);
                rItem = red(thisItemImage.pixels[locItem]);
                gItem = green(thisItemImage.pixels[locItem]);
                bItem = blue(thisItemImage.pixels[locItem]);
                  
                rgb_diff = abs(rStreet-rItem) + abs (bStreet-bItem) + abs(gStreet-gItem);
                total_rgb_diff += abs(rStreet-rItem) + abs (bStreet-bItem) + abs(gStreet-gItem);
            
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
    
        // Need to save the total_rgb_diff - firstly if lower than lowest_total_rgb_diff, then save it as that, along with i,j
        // But also need to know what counts as a valid lowest_rgb diff - so also add total_rgb_diff to sum_total_rgb_diff 
    
        if (debugRGB)
        {
            s = "total_rgb_diff for i,j " + i - startX + "," +  j - startY + ": " + int(total_rgb_diff));
            printToFile.printDebugLine(s, 1);
        }
            
        if (total_rgb_diff == 0)
        {
            return true;
        }
        else if (total_rgb_diff < good_enough_total_rgb)
        {
            sum_total_rgb_diff += total_rgb_diff;
            return true;
        }
        else
        {
            if ((i == startX) && (j == startY))
            {
                // Save this one always - so overwrite initilised value
                lowest_total_rgb_diff = total_rgb_diff;
                lowest_total_rgb_diff_i = i;
                lowest_total_rgb_diff_j = j;
            }
            else if (total_rgb_diff < lowest_total_rgb_diff)
            {
                // save this if the lowest one so far
                lowest_total_rgb_diff = total_rgb_diff;
                lowest_total_rgb_diff_i = i;
                lowest_total_rgb_diff_j = j;
            }        
            sum_total_rgb_diff += total_rgb_diff;
            return false;
        }
    }

}