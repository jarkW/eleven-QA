    class MatchInfo
    {    
        // New values - average RGB per pixel, rather than per whole fragment compare
        int bestMatchX;
        int bestMatchY;
        float percentageMatch;
        int bestMatchResult;
        String bestMatchItemImageName;
        int itemImageXOffset;
        int itemImageYOffset;
        
        // Used to dump out a diff - so can see mismatched pixels in read - save the image and the useful filename to save it as, if this is the best match at the end
        PImage bestMatchBWDiffImage;
        PImage bestMatchColRDiffImage;
        PImage bestMatchColBDiffImage;
        PImage bestMatchColGDiffImage;
        
        PImage BWItemFragment;
        PImage ColourItemFragment; // Also used to generate a street summary image at the end
        PImage BWStreetFragment;
        PImage ColourStreetFragment;
        
        String bestMatchBWDiffImageName;
        String bestMatchColRDiffImageName;
        String bestMatchColGDiffImageName;
        String bestMatchColBDiffImageName;
        String BWItemFragmentName;
        String ColourItemFragmentName;
        String BWStreetFragmentName;
        String ColourStreetFragmentName;
        
        String itemTSID;
        
        public MatchInfo(float percentMatch, int x, int y, int matchResult,
                         String TSID, String itemImageFname, int xOffset, int yOffset, String streetSnapFname,
                         PImage colourStreetFragImage, PImage BWStreetFragImage, PImage colourItemImage, PImage BWItemImage, 
                         PImage BWDiffImage, PImage ColDiffRImage, PImage ColDiffGImage, PImage ColDiffBImage)    
        {           
            percentageMatch = percentMatch;
            bestMatchResult = matchResult;
            bestMatchX = x;
            bestMatchY = y;
            itemTSID = TSID;
            bestMatchItemImageName = itemImageFname;
            itemImageXOffset = xOffset;
            itemImageYOffset = yOffset;
            
            // This image is always saved - as used to generate a street summary of the street items, showing successful/failed matches graphically
            ColourItemFragment = colourItemImage;
             
            // Save the diff image passed to class - might be later saved
            if (configInfo.readDebugDumpDiffImages())
            {
                bestMatchBWDiffImage = BWDiffImage;
                bestMatchBWDiffImageName = TSID  + "_BWDiff_" + itemImageFname + "__" + streetSnapFname + round(percentageMatch) + ".png";
                
                bestMatchColRDiffImage = ColDiffRImage;
                bestMatchColRDiffImageName = TSID  + "_ColR_Diff_" + itemImageFname + "__" + streetSnapFname + round(percentageMatch) + ".png";
                
                bestMatchColGDiffImage = ColDiffGImage;
                bestMatchColGDiffImageName = TSID  + "_ColG_Diff_" + itemImageFname + "__" + streetSnapFname + round(percentageMatch) + ".png";               
                
                bestMatchColBDiffImage = ColDiffBImage;
                bestMatchColBDiffImageName = TSID  + "_ColB_Diff_" + itemImageFname + "__" + streetSnapFname + round(percentageMatch) + ".png";
                                
                BWItemFragment = BWItemImage;
                BWItemFragmentName = TSID  + "_BW_" + itemImageFname + "__" + round(percentageMatch) + ".png";
                
                ColourItemFragmentName = TSID  + "_Col_" + itemImageFname + "__" + round(percentageMatch) + ".png";
                
                BWStreetFragment = BWStreetFragImage;
                BWStreetFragmentName = TSID  + "_BW_" + streetSnapFname + "__" + round(percentageMatch) + ".png";
                
                ColourStreetFragment = colourStreetFragImage;
                ColourStreetFragmentName = TSID  + "_Col_" + streetSnapFname + "__" + round(percentageMatch) + ".png";              
            }
            else
            {
                bestMatchBWDiffImage = null;
                bestMatchColRDiffImage = null;
                bestMatchColGDiffImage = null;
                bestMatchColBDiffImage = null;
                BWItemFragment = null;
                BWStreetFragment = null;
                ColourStreetFragment = null;
            }
            
            printToFile.printDebugLine(this, "Creating matchinfo entry for " + TSID + " " + itemImageFname + " %match = " + percentageMatch + "%", 1);
        }
        
        public String matchDebugInfoString()
        {
            // Used for debug info only
            // Have %Match as 2 decimal places
            DecimalFormat df = new DecimalFormat("#.##"); 
            String formattedPercentage = df.format(percentageMatch); 

            String s = formattedPercentage + "% at x,y " + bestMatchX + "," + bestMatchY;
            return s;
        }
        
        public String matchPercentAsFloatString()
        {
            // Have %Match as 2 decimal places
            DecimalFormat df = new DecimalFormat("#.##"); 
            String formattedPercentage = df.format(percentageMatch); 

            String s = formattedPercentage + "%";
            return s;
        }
        
        public String matchPercentString()
        {
            // Have match to nearest whole digit
            String s = round(percentageMatch) + "%";
            return s;
        }
        
        public String matchXYString()
        {
            // Have %Match as 2 decimal places

            String s = bestMatchX + "," + bestMatchY;
            return s;
        }
        
        public int furthestCoOrdDistance(int origX, int origY)
        {
            // Return the biggest co-ordinate shift between original/found x,y
            // so can see if the pixel radius is being set far too high for the 
            // accuracy of how items have been placed. 
            int diffX = abs(origX - bestMatchX);
            int diffY = abs(origY - bestMatchY);
            if (diffX >= diffY)
            {
                return diffX;
            }
            else
            {
                return diffY;
            }
        }
        
        public float readPercentageMatch()
        {
            return percentageMatch;
        }
        
        public boolean saveBestDiffImageFiles()
        {                
            if (configInfo.readDebugDumpDiffImages())
            {
                if (!saveImageFile(bestMatchBWDiffImage, bestMatchBWDiffImageName))
                {
                    return false;
                }
                if (!saveImageFile(bestMatchColRDiffImage, bestMatchColRDiffImageName))
                {
                    return false;
                }
                if (!saveImageFile(bestMatchColGDiffImage, bestMatchColGDiffImageName))
                {
                    return false;
                }                
                  if (!saveImageFile(bestMatchColBDiffImage, bestMatchColBDiffImageName))
                {
                    return false;
                }              

                if (!saveImageFile(BWItemFragment, BWItemFragmentName))
                {
                    return false;
                }
                if (!saveImageFile(ColourItemFragment, ColourItemFragmentName))
                {
                    return false;
                }
                if (!saveImageFile(BWStreetFragment, BWStreetFragmentName))
                {
                    return false;
                }
                if (!saveImageFile(ColourStreetFragment, ColourStreetFragmentName))
                {
                    return false;
                }
            }
            
            return true;
        }
        
        boolean saveImageFile(PImage fragment, String fragmentName)
        {
            if (fragment == null)
            {
                // Might have null image because did not need saving
                printToFile.printDebugLine(this, "Null image passed for " + fragmentName, 1);
                return true;
            }
            
            String fname = workingDir + File.separatorChar +"BestMatchImages" + File.separatorChar + fragmentName;
            printToFile.printDebugLine(this, "Saving fragment image to " + fname, 1);
            if (!fragment.save(fname))
            {
                printToFile.printDebugLine(this, "Unexpected error - failed to save image to " + fragmentName, 3);
                return false;
            }
            return true;
        }
        
        public int readBestMatchX()
        {
            return bestMatchX;
        }
        
        public int readBestMatchY()
        {
            return bestMatchY;
        }
        
        public void setBestMatchX(int x)
        {
            bestMatchX = x;
        }
        
        public void setBestMatchY(int y)
        {
            bestMatchY = y;
        }
        
        public String readBestMatchItemImageName()
        {
            return bestMatchItemImageName;
        }
        
        public int readBestMatchResult()
        {
            return bestMatchResult;
        }
        
        public void setBestMatchResult(int result)
        {
            bestMatchResult = result;
        }
        
        public int readItemImageXOffset()
        {
            return itemImageXOffset;
        }
        
        public int readItemImageYOffset()
        {
            return itemImageYOffset;
        }
        
        public PImage readColourItemFragment()
        {
            return ColourItemFragment;
        }
 }