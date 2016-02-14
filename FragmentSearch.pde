class FragmentSearch
{
    boolean okFlag;
    boolean searchDone;
    ArrayList<PNGFile> itemImageArray;
    ArrayList<PNGFile> streetImageArray;
    // offset from initial x,y passed in
    int offsetX;
    int offsetY;
    
    int startX;
    int startY;
    int itemImageBeingUsed;
    int streetImageBeingUsed;
    int itemImageThatMatched;
    
    
    // constructor
    // Pass in the completed co-ords
    public FragmentSearch(ArrayList<PNGFile> fragmentArray, int x, int y)
    {
        okFlag = true;
        
        searchDone = false;
        itemImageBeingUsed = 0;
        streetImageBeingUsed = 0;
        itemImageThatMatched = -1;
        offsetX = 0;
        offsetY = 0;
        
        itemImageArray = fragmentArray;
        streetImageArray = thisStreetInfo.getStreetImageArray();
        startX = x;
        startY = y;

        
        println("first image is ", itemImageArray.get(0).PNGImageName);
    }
    
    public void showFragment()
    {
    }
    
    public boolean readSearchDone()
    {
        return searchDone;
    }
    
    public int readOffsetX()
    {
        return offsetX;
    }
    
    public int readOffsetY()
    {
        return offsetY;
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
            return itemImageArray.get(itemImageThatMatched).PNGImageName;
        }
    }

}