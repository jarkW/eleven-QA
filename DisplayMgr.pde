class DisplayMgr
{
    boolean okFlag;
    
    // Add in list of failed streets - can be display at the end when program ends
    // is street + reason why failed (missing L*, missing snaps)
    StringList failedStreets;
    
    String streetNameMsg;
    String itemNameMsg;
    
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
        fill(50);
        textSize(14);
        // Want text to go along bottom - so set relative to height of display
        //text( x, y, width, height)
        text(info, 10, height - 50, width, 50);  // Text wraps within text box
    }
    
    public void setStreetName(String streetName, String streetTSID, int streetNum, int totalStreets)
    {
   
        String s = "Processing street " + streetName + " (" + streetTSID + "): " + streetNum + " of " + totalStreets;
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
   
        String s = "Searching for items on street " + streetNameMsg;
        fill(50);
        textSize(14);
        // Want text to go along top - so set relative to width of display
        //text( x, y, width, height)
        text(s, 10, 10, width, 50);  // Text wraps within text box
    }
    
    public void setItemProgress(String itemClass, String itemTSID, int itemNumber, int totalItems)
    {
        String s = "Processing item " + itemClass + " (" + itemTSID + "): " + itemNumber + " of " + totalItems; 
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
        fill(50);
        text(s, 10, 30, width, 50);
        image(itemImage, 50, 100);
        
        // draw box around image to delineate item
        noFill();
        rectMode(CORNER);
        stroke(0);
        rect(50, 100, itemImage.width, itemImage.height);
    }
    
    public void showStreetImage(PImage streetImage, int itemBoxWidth, int itemBoxHeight, int centreX, int centreY)
    {
        int streetFragHeight = 200;
        int streetFragWidth = 200;
        PImage streetFragment = streetImage.get(centreX - 100, centreY - 100, streetFragWidth, streetFragHeight);      
        image(streetFragment, 200, 100);

        // Also need to show a red box which matches the item fragment size
        noFill();
        stroke(204, 0, 0);
        // Need to calculate where to put the rectangle            
        rect(200 + int(streetFragWidth/2), 100 + int(streetFragHeight/2), itemBoxWidth, itemBoxHeight);

    }
    

       
    public void clearDisplay()
    {
        // clear screen
        background(230);
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