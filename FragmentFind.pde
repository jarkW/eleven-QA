class FragmentFind
{
    boolean okFlag;
    boolean searchDone;
       
    ItemInfo thisItemInfo;
    
    SpiralSearch spiralSearch;
    
    // x,y on street where need to start the item search (i.e. converted item JSON x,y)
    int startX;
    int startY;
    
    // difference from initial x,y passed in
    int foundX;
    int foundY;
    
    int itemImageBeingUsed;
    int streetImageBeingUsed;
    int itemImageThatMatched; // will be used to set the info field from the fname
    
    ArrayList<PNGFile> itemImageArray;
    ArrayList<PNGFile> streetSnapArray; 
    
  
    // constructor
    public FragmentFind(ItemInfo itemInfo)
    {
        okFlag = true;
        
        searchDone = false;
        itemImageBeingUsed = 0;
        streetImageBeingUsed = 0;
        itemImageThatMatched = -1;
                
        // NB Don't need to save if never used again
        thisItemInfo = itemInfo;
        
        itemImageArray = itemInfo.readItemImageArray();
        streetSnapArray = streetInfoArray.get(streetBeingProcessed).getStreetImageArray();
        println("Size of street snap array is ", streetInfoArray.get(streetBeingProcessed).streetSnapArray.size()); 
                

        // Need to convert the JSON x,y to relate to the street snap - use the first loaded street snap
        startX = thisItemInfo.readOrigItemX() + streetInfoArray.get(streetBeingProcessed).readStreetSnap(0).PNGImage.width/2 + thisItemInfo.readFragOffsetX();
        startY = thisItemInfo.readOrigItemY() + streetInfoArray.get(streetBeingProcessed).readStreetSnap(0).PNGImage.height + thisItemInfo.readFragOffsetY();
        foundX = startX;
        foundY = startY;
        
        spiralSearch = new SpiralSearch(thisItemInfo.readItemImage(itemImageBeingUsed).readPNGImage(), 
                                        streetInfoArray.get(streetBeingProcessed).readStreetSnap(streetImageBeingUsed).readPNGImage(), startX, startY);
        
        printToFile.printDebugLine("Starting search for item " + thisItemInfo.itemClassTSID + " (" + thisItemInfo.itemTSID + ") with x,y " + str(startX) + "," + str(startY), 2);
    }
        
    public void showFragment()
    {
        display.clearDisplay();
        display.showStreetName();
        
        display.showItemImage(thisItemInfo.readItemImage(itemImageBeingUsed).readPNGImage(), thisItemInfo.readOrigItemX() + "," + thisItemInfo.readOrigItemY());
        display.showStreetImage(thisItemInfo.readItemImage(itemImageBeingUsed).readPNGImage(), streetInfoArray.get(streetBeingProcessed).readStreetSnap(streetImageBeingUsed).readPNGImage(), startX, startY);
        
        exitNow=true;
        
        //This loop is basically searching the first street for the item - so hopefully many things will be found first time through
        
        // Need to repeat k times from within this loop
        
        
        // when do search - could be with found X, which is updated after each search
        // when found quoin match, then next ones could be narrower search rectangle - as x will be the same, only y will be different
        // QQ - again, narrower search rectangle
        // all other items, once found, return found.
        
        // If search is successful - then set the searchDone flag and Useimagename before updating (if appropriate) - also save k, rgb stuff
        // if search is unsuccessful then set the searchDone flag, imagename = "", increase itemimage counter (so can search using next image)
        // Could return 
        // 
    }
    
    public boolean readSearchDone()
    {
        return searchDone;
    }
    
    public int readDiffX()
    {
        return foundX - startX;
    }
    
    public int readDiffY()
    {
        return foundY - startY;
    }
    
    public String readItemImageThatMatched()
    {
        if (itemImageThatMatched < 0)
        {
            // i.e. failed to find a match
            return "";
        }
        else
        {
            return thisItemInfo.readItemImageArray().get(itemImageThatMatched).PNGImageName;
        }
    }

}