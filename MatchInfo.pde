    class MatchInfo
    {    
        // New values - average RGB per pixel, rather than per whole fragment compare
        float bestMatchAvgRGB;
        float bestMatchAvgTotalRGB; 
        int bestMatchX;
        int bestMatchY;
        float percentageMatch;
        String bestMatchItemImageName;
        // Used to dump out a diff - so can see mismatched pixels in read - save the image and the useful filename to save it as, if this is the best match at the end
        PImage bestMatchBWDiffImage;
        PImage bestMatchColRDiffImage;
        PImage bestMatchColBDiffImage;
        PImage bestMatchColGDiffImage;
        
        PImage BWItemFragment;
        PImage ColourItemFragment;
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
        
        int bestItemRGBMedian;
        int bestStreetRGBMedian;
        String itemTSID;
        
        public MatchInfo(float avgRGB, float totalAvgRGB, int x, int y, int itemRGBMedian, int streetRGBMedian,
                         String TSID, String itemImageFname, String streetSnapFname, 
                         PImage colourStreetFragImage, PImage BWStreetFragImage, PImage colourItemImage, PImage BWItemImage, 
                         PImage BWDiffImage, PImage ColDiffRImage, PImage ColDiffGImage, PImage ColDiffBImage)    
        {           
            bestMatchAvgRGB = avgRGB;
            bestMatchAvgTotalRGB = totalAvgRGB;
            bestMatchX = x;
            bestMatchY = y;
            bestItemRGBMedian = itemRGBMedian;
            bestStreetRGBMedian = streetRGBMedian;
            itemTSID = TSID;
            bestMatchItemImageName = itemImageFname;
            
            // Need to avoid dividing by 0, or a very small number.
            if (bestMatchAvgTotalRGB < 0.01)
            {
                // Treat as 0, i.e. the first match was perfect, so the average total is the same as the average for the fragment
                percentageMatch = 100;
            }
            else
            {
                percentageMatch = 100 - ((bestMatchAvgRGB/bestMatchAvgTotalRGB) * 100);
            }
            
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
                
                ColourItemFragment = colourItemImage;
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
                ColourItemFragment = null;
                BWStreetFragment = null;
                ColourStreetFragment = null;
            }
        }
        
        public String matchDebugInfoString()
        {
            // Used for debug info only
            // Have %Match as 2 decimal places
            DecimalFormat df = new DecimalFormat("#.##"); 
            String formattedPercentage = df.format(percentageMatch); 

            String s = "avg RGB = " + int (bestMatchAvgRGB) + 
                       "/" + int (bestMatchAvgTotalRGB) + 
                       " = " + formattedPercentage + "%" +
                       " at x,y " + bestMatchX + "," + bestMatchY;
            return s;
        }
        
        public String dumpRGBInfo()
        {
            String s = "RGB Median info: " + itemTSID  + " item =" + bestItemRGBMedian + ", street = " + bestStreetRGBMedian;
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
        
        public String bestMatchVariant(String classTSID)
        {
            String variant = "";
            // If the saved best match image name has the same root as the class TSID, then the variant information can
            // be extracted and given to the user - used when an item is not found and simply reporting the nearest match
            if (bestMatchItemImageName.indexOf(classTSID) == 0)
            {
                variant = bestMatchItemImageName.replace(classTSID+"_", "");
            }
            return variant;
        }
 }