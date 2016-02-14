class PNGFile
{
    // Used for both street snaps and item images
    String PNGImageName;  // includes path and filename
    PImage PNGImage;
    int PNGImageHeight;
    int PNGImageWidth;
    boolean okFlag;
    
    public PNGFile(String fname)
    {
        okFlag = true;
        // Includes path as well as fname
        PNGImageName = fname;
    }
    
    public boolean loadPNGImage()
    {
        // Load up this snap/item image
        File file = new File(PNGImageName);
        if (!file.exists())
        {
            printToFile.printDebugLine("Missing file - " + PNGImageName, 3);
            return false;
        }
        
        PNGImage = loadImage(PNGImageName, "png");
        
        
        // appropriate to do this now???
        PNGImage.loadPixels();
        
        PNGImageWidth = PNGImage.width;
        PNGImageHeight = PNGImage.height;
        
        printToFile.printDebugLine("Loading image from " + PNGImageName + " with width " + PNGImageHeight + " height " + PNGImageWidth, 1);
        
        
        return true;
    }
    
    public boolean readOkFlag()
    {
        return okFlag;
    }
}