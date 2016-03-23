class DisplayMgr
{
    boolean okFlag;
   

    // Add in list of failed streets - can be display at the end when program ends
    // is street + reason why failed (missing L*, missing snaps)
    StringList failedStreets;
    
    String streetNameMsg;
    String itemNameMsg;
    
    // for testing - might need to use 'set' instead of 'image' - might use less memory
    // not implemented yet
    boolean USE_SET_FOR_DISPLAY = false;  
    
    final static int BACKGROUND = #D6D6D6;
    final static int STREET_FRAGMENT_WIDTH = 200;
    final static int STREET_FRAGMENT_HEIGHT = 200;
    
    // These contain the dimensions of the street on the screen - so can be cleared easily 
    float scaledStreetWidth;
    float scaledStreetHeight;
    int streetFragmentWidth;
    int streetFragmentHeight;
    int itemWidth;
    int itemHeight;
    
    
    public DisplayMgr()
    {
        okFlag = true;
        textSize(14);
        streetNameMsg = "";
        itemNameMsg = "";
        failedStreets = new StringList();
    }
    
    public void showInfoMsg(String info)
    {
        // clear existing text box
        clearTextBox(0, height - 50, width, 50);
        
        // print out message
        fill(50);
        textSize(14);
        // Want text to go along bottom - so set relative to height of display
        text(info, 10, height - 50, width, 50);  // Text wraps within text box
    }
        
    public void setStreetName(String streetName, String streetTSID, int streetNum, int totalStreets)
    {
        String s = "Processing street " + streetName + " (" + streetTSID + "): " + streetNum + " of " + totalStreets;
        
        // clear existing text box
        clearTextBox(10, 10, width, 50);
        
        fill(50);
        textSize(14);
        // Want text to go along top - so set relative to width of display
        //text( x, y, width, height)
        text(s, 10, 10, width, 50);  // Text wraps within text box
        
        // Save for future use
        streetNameMsg = streetName + "(" + streetTSID + "): " + streetNum + " of " + totalStreets;
    }
    
    
    public void showStreetName()
    {
        // DO WE NEED THIS ONE?????
        String s = "Searching for items on street " + streetNameMsg;
        
        // clear existing text box
        clearTextBox(10, 10, width, 50);
        
        fill(50);
        textSize(14);
        // Want text to go along top - so set relative to width of display
        //text( x, y, width, height)
        text(s, 10, 10, width, 50);  // Text wraps within text box
    }
    
    public void setItemProgress(String itemClass, String itemTSID, int itemNumber, int totalItems)
    {
        String s = "Processing item " + itemClass + " (" + itemTSID + "): " + itemNumber + " of " + totalItems; 
        
        // clear existing text box
        clearTextBox(10, 30, width, 50);
        
        fill(50);
        textSize(12);
        // Want text to go along top - so set relative to width of display
        //text( x, y, width, height)
        text(s, 10, 30, width, 50);  // Text wraps within text box
        
        // Save for future use
        itemNameMsg = itemClass + " (" + itemTSID + "): " + itemNumber + " of " + totalItems;
    }   
   
    public void showItemImage(PImage itemImage, String itemCoordStr)
    {

        String s = "Searching for " + itemNameMsg + " at (" + itemCoordStr + ")";
        
        // clear existing text box
        clearTextBox(10, 30, width, 50);
        // clear existing image
        clearImage(50,100, itemWidth, itemHeight);
        rectMode(CORNER);
        stroke(BACKGROUND);
        rect(50, 100, itemWidth, itemHeight);
        
        // Write out new text
        fill(50);
        text(s, 10, 30, width, 50);
        itemWidth = itemImage.width;
        itemHeight = itemImage.height;
        image(itemImage, 50, 100, itemWidth, itemHeight);
        
        // draw box around image to delineate item
        noFill();
        rectMode(CORNER);
        stroke(0);
        rect(50, 100, itemWidth, itemHeight);
    }
    

    
    public void showStreetImage(PImage streetImage, String streetImageName)
    {
        // scale down the street so fits in bottom of window
        float maxWidth;
        float maxHeight;
        float scalar;
        
       // clear the previous image
        clearImage(50, height - 50 - int(scaledStreetHeight), int(scaledStreetWidth), int(scaledStreetHeight));
        
        // Need to change the location/size of snap depending on whether it is a wide or tall street
        // DO WE NEED THIS - COULD JUST ALWAYS MAKE THE SAME HEIGHT, THEN NOT HAVING TO FIDDLE WITH ITEM POSITION
        if (streetImage.width > streetImage.height)
        {
           // scale down the wide street so fits in bottom of window
           maxWidth = width-100;
           maxHeight = 200;      
           scalar = maxWidth / streetImage.width;
        
           scaledStreetWidth = maxWidth;
           scaledStreetHeight = streetImage.height * scalar;
            if (scaledStreetHeight > maxHeight)
            {
                scalar = maxHeight / scaledStreetHeight;
                scaledStreetHeight = maxHeight;
                scaledStreetWidth = scaledStreetWidth * scalar;
            }
        }
        else
        {
           // scale down the tall street so fits in bottom of window
           maxWidth = 500;
           maxHeight = height - 200;      
           scalar = maxHeight / streetImage.height;
        
           scaledStreetHeight= maxHeight;
           scaledStreetWidth = streetImage.width * scalar;
           
           if (scaledStreetWidth > maxWidth)
            {

                scalar = maxWidth / scaledStreetWidth;
                scaledStreetWidth = maxWidth;
                scaledStreetHeight = scaledStreetHeight * scalar;
            }
        }
        
        image(streetImage, 50, height - 50 - int(scaledStreetHeight), scaledStreetWidth, scaledStreetHeight);
        showInfoMsg("Using " + streetImageName);
    }
        
    public void showStreetFragmentImage(PImage streetImage, int itemBoxWidth, int itemBoxHeight, int centreX, int centreY)
    {
        PImage streetFragment = streetImage.get(centreX - STREET_FRAGMENT_WIDTH/2, centreY - STREET_FRAGMENT_HEIGHT/2, STREET_FRAGMENT_WIDTH, STREET_FRAGMENT_HEIGHT);
        
        // clear the previous image from this place
        clearImage(200, 100, streetFragmentWidth, streetFragmentHeight);
        
        // Now create the new street fragment
        streetFragmentWidth = streetFragment.width;
        streetFragmentHeight = streetFragment.height;
        image(streetFragment, 200, 100, streetFragmentWidth, streetFragmentHeight);

        // Also need to show a red box which matches the item fragment size
        noFill();
        stroke(204, 0, 0);
        // Need to calculate where to put the rectangle            
        rect(200 + int(STREET_FRAGMENT_WIDTH/2), 100 + int(STREET_FRAGMENT_HEIGHT/2), itemBoxWidth, itemBoxHeight);

    }
           
    public void clearDisplay()
    {
        // clear screen
        //background(230);
        fill(BACKGROUND);
        stroke(BACKGROUND);
        rect(0, 0, width, height); 
    }
    
    public void clearImage(int x, int y, int imageWidth, int imageHeight)
    {
        // This just creates an image which is the same size as the existing one ... and then draws it out in background colour
        PImage img = createImage(imageWidth + 1, imageHeight + 1, RGB);
        img.loadPixels();
    
        for (int i = 0; i< img.pixels.length; i++)
        {
            img.pixels[i] = BACKGROUND; 
        }

        //rect(50, height - 50, scaledSnapWidth, scaledSnapHeight);
        image(img, x, y, imageWidth, imageHeight);
    }
    
    public void clearTextBox(int x, int y, int boxWidth, int boxHeight)
    {
        // Clear text box - i.e. fill with background colour
        fill(BACKGROUND);
        stroke(BACKGROUND);
        rect(x, y, boxWidth, boxHeight); 
    }
    
    public void setSkippedStreetsMsg(String msg)
    {
        failedStreets.append(msg);
    }
    
    public void showSkippedStreetsMsg()
    {
        if (failedStreets.size() == 0)
        {
            return;
        }
        String s = "The following streets were not processed";
        fill(50);
        text(s, 10, 100, width-10, 80);  // Text wraps within text box
        for (int i = 0; i < failedStreets.size(); i++)
        {
            text(failedStreets.get(i), 10, 120 + (i * 20), width-10, 80);
        }
        
    }
    
    public boolean checkIfFailedStreetsMsg()
    {
        if (failedStreets.size() == 0)
        {
            return false;
        }
        return true;
    }
}