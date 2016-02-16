class PNGFile
{
    // Used for both street snaps and item images
    String PNGImageName;  
    PImage PNGImage;
    int PNGImageHeight;
    int PNGImageWidth;
    
    boolean okFlag;
    boolean isStreetSnapFlag;
    
    public PNGFile(String fname, boolean isStreetSnap)
    {
        okFlag = true;
         
        PNGImageName = fname;
        isStreetSnapFlag = isStreetSnap;
    }
    
    public boolean loadPNGImage()
    {
        // Load up this snap/item image
        String fullFileName;
        
        if (isStreetSnapFlag)
        {
            fullFileName = configInfo.readStreetSnapPath() + "/" + PNGImageName;
        }
        else
        {
            fullFileName = dataPath(PNGImageName);
        }
        File file = new File(fullFileName);
        if (!file.exists())
        {
            printToFile.printDebugLine("Missing file - " + fullFileName, 3);
            return false;
        }
        
        PNGImage = loadImage(fullFileName, "png");
        
        
        // appropriate to do this now???
        PNGImage.loadPixels();
        
        PNGImageWidth = PNGImage.width;
        PNGImageHeight = PNGImage.height;
        
        printToFile.printDebugLine("Loading image from " + fullFileName + " with width " + PNGImageHeight + " height " + PNGImageWidth, 1);
        
        
        return true;
    }
    
    public boolean readOkFlag()
    {
        return okFlag;
    }
    
    public String readPNGImageName()
    {
        return PNGImageName;
    }
    
    public PImage readPNGImage()
    {
        return PNGImage;
    }   
    
    public int readPNGImageHeight()
    {
        return PNGImageHeight;
    }
    
    public int readPNGImageWidth()
    {
        return PNGImageWidth;
    }

}