class DisplayMgr
{
    boolean okFlag;
    
    
    public DisplayMgr()
    {
        okFlag = true;
        textSize(14);
    }
    
    public void setInfoMsg(String info)
    {
        fill(50);
        textSize(14);
        // Want text to go along bottom - so set relative to height of display
        //text( x, y, width, height)
        text(info, 10, height - 50, width, 50);  // Text wraps within text box
    }
    
    public void setStreetName(String streetName, String streetTSID, int streetNum, int totalStreets)
    {
   
        String s = "Processing street " + streetName + "(" + streetTSID + "): " + streetNum + " of " + totalStreets;
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
    }
       
    public void clearDisplay()
    {
        // clear screen
        background(230);
    }
}