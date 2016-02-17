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
    
    public boolean setupPNGImage()
    {
        if (!loadPNGImage())
        {
            return false;
        }
               
        PNGImageWidth = PNGImage.width;
        PNGImageHeight = PNGImage.height;
        
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
        
        
        try
        {
            // load image
            PNGImage = loadImage(fullFileName, "png");
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine("Fail to load image for " + PNGImageName, 3);
            return false;
        }         
        try
        {
            // load image pixels
            PNGImage.loadPixels();
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine("Fail to load image pixels for " + PNGImageName, 3);
            return false;
        } 
        
        printToFile.printDebugLine("Loading image from " + fullFileName + " with width " + PNGImage.height + " height " + PNGImage.width, 3);
        
        return true;
    }
    
    public void unloadPNGImage()
    {
        PNGImage = null;
        printToFile.printDebugLine("Unloading image " + PNGImageName, 3);
    }

}