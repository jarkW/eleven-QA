class PNGFile
{
    // Used for both street snaps and item images
    String PNGImageName;  
    PImage PNGImage;
    int PNGImageHeight;
    int PNGImageWidth;

    // Offset from the actual x,y of the item for this fragment
    int fragOffsetX;
    int fragOffsetY;
    
    boolean okFlag;
    boolean isStreetSnapFlag;
    
    public PNGFile(String fname, boolean isStreetSnap)
    {
        okFlag = true;
         
        PNGImageName = fname;
        isStreetSnapFlag = isStreetSnap;
        PNGImage = null;
    }
        
    public boolean setupPNGImage()
    {
        if (!loadPNGImage())
        {
            return false;
        }
        
        if (!isStreetSnapFlag)
        {
            // set up the offset values for item images
            
            // From the file name - use the first bit as the key to the offset array (as is classTSID "_" info)
            // Save the shifting from item x,y in order to use this item image as a search tool
            // Varies between snaps e.g. of quoins or trees. 
            Offsets fragOffsets = allFragmentOffsets.getFragmentOffsets(PNGImageName.replace(".png", ""));
            if (fragOffsets == null)
            {
                printToFile.printDebugLine(this, "Unable to access fragment offsets for item image " + PNGImageName, 3);
                return false;
            }
            fragOffsetX = fragOffsets.readOffsetX();
            fragOffsetY = fragOffsets.readOffsetY();
        }
               
        PNGImageWidth = PNGImage.width;
        PNGImageHeight = PNGImage.height;
        
        return true;
    }
    
    public boolean readOkFlag()
    {
        return okFlag;
    }
    
    public int readFragOffsetX()
    {
        return fragOffsetX;
    }
    
    public int readFragOffsetY()
    {
        return fragOffsetY;
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
        
        if (PNGImage != null)
        {
            // Image has already been loaded into memory
            return true;
        } 
        
        if (isStreetSnapFlag)
        {
            fullFileName = configInfo.readStreetSnapPath() + File.separatorChar + PNGImageName;
        }
        else
        {
            fullFileName = dataPath(PNGImageName);
        }
        File file = new File(fullFileName);
        if (!file.exists())
        {
            printToFile.printDebugLine(this, "Missing file - " + fullFileName, 3);
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
            printToFile.printDebugLine(this, "Fail to load image for " + PNGImageName, 3);
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
            printToFile.printDebugLine(this, "Fail to load image pixels for " + PNGImageName, 3);
            return false;
        } 
        
        printToFile.printDebugLine(this, "Loading image from " + fullFileName + " with width " + PNGImage.height + " height " + PNGImage.width, 1);
        
        return true;
    }
    
    public void unloadPNGImage()
    {
        PNGImage = null;
        printToFile.printDebugLine(this, "Unloading image " + PNGImageName, 1);
        // Need this to force the garbage collection to free up the memory associated with the image
        System.gc();
    }

}