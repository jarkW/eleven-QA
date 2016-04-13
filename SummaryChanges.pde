class SummaryChanges implements Comparable
{
    // small class which should make it easier to output/summarise the changes being made to individual item JSON files
    ItemInfo itemInfo;
    
    // Used to populate the results field
    final static int SKIPPED = 1;
    final static int MISSING = 2;
    final static int COORDS_ONLY = 3;
    final static int VARIANT_ONLY = 4;
    final static int VARIANT_AND_COORDS_CHANGED = 5;
    final static int UNCHANGED = 6;
    
    // Populate fields I might want to sort on
    int itemX;
    int itemY;
    int result; 
    
    // If sort reveals that quoins have been stacked onto the same x,y
    boolean misplacedQuoin;

        
    public SummaryChanges( ItemInfo item)
    {
        itemInfo = item;
        misplacedQuoin = false;
        
        printToFile.printDebugLine(this, itemInfo.readItemTSID() + " found=" + itemInfo.readItemFound() + " orig x,y=" + itemInfo.readOrigItemX() + "," +
                                    itemInfo.readOrigItemY() + " new x,y=" + itemInfo.readNewItemX() + "," +  itemInfo.readNewItemY() + " change in info " + itemInfo.readItemFound(), 1);
                                    
        
        if (itemInfo.readSkipThisItem())
        {
            itemX = itemInfo.readOrigItemX();
            itemY = itemInfo.readOrigItemY();
            result = SKIPPED;
        }
        else if (itemInfo.readItemFound())
        {
            if (configInfo.readChangeXYOnly())
            {
                if ((itemInfo.readNewItemX() == itemInfo.readOrigItemX()) && (itemInfo.readNewItemY() == itemInfo.readOrigItemY()))
                {
                    itemX = itemInfo.readOrigItemX();
                    itemY = itemInfo.readOrigItemY();
                    result = UNCHANGED;
                }
                else
                {
                    itemX = itemInfo.readNewItemX();
                    itemY = itemInfo.readNewItemY();
                    result = COORDS_ONLY;
                }
            }
            else
            {
                if (itemInfo.differentVariantFound())
                {
                    // Variant has changed/been inserted
                    if ((itemInfo.readNewItemX() == itemInfo.readOrigItemX()) && (itemInfo.readNewItemY() == itemInfo.readOrigItemY()))
                    {
                        itemX = itemInfo.readOrigItemX();
                        itemY = itemInfo.readOrigItemY();
                        result = VARIANT_ONLY;
                    }
                    else
                    {
                        itemX = itemInfo.readNewItemX();
                        itemY = itemInfo.readNewItemY();
                        result = VARIANT_AND_COORDS_CHANGED;
                    }
                }
                else
                {
                    if ((itemInfo.readNewItemX() == itemInfo.readOrigItemX()) && (itemInfo.readNewItemY() == itemInfo.readOrigItemY()))
                    {
                        itemX = itemInfo.readOrigItemX();
                        itemY = itemInfo.readOrigItemY();
                        result = UNCHANGED;
                    }
                    else
                    {
                        itemX = itemInfo.readNewItemX();
                        itemY = itemInfo.readNewItemY();
                        result = COORDS_ONLY;
                    }
                }
            }
        }
        else
        {
            // If the original item was a mystery quoin, then this is an unchanged item rather than missing 
            // Means the tool has been run twice - so picking up a mystery quoin second time around
            if (itemInfo.readItemClassTSID().equals("quoin") && itemInfo.readOrigItemExtraInfo().equals("mystery"))
            {
                result = UNCHANGED;
            }
            else
            {
                result = MISSING;
            }
            itemX = itemInfo.readOrigItemX();
            itemY = itemInfo.readOrigItemY();
        }
        
    }

    public int compareTo(Object o) 
    {
        SummaryChanges n = (SummaryChanges) o;
        int X1 = itemX;
        int X2 = n.itemX;
        
        if (X1 == X2)
        {
            int Y1 = itemY;
            int Y2 = n.itemY;
            if (Y1 == Y2)
            {
                // Should never happen - but can happen to closely clustered quoins. So mark these for resetting back to orig x,y/mystery after giving the appropriate warning message
                // The processing will done after the first time the items have been sorted on x,y - that way if there are 3 or more items clustered together, it won't matter if this
                // flag is set twice, the check will still be valid for whether x1,y1 = x2,y2 or not
                // Only report the warning in the user output file if this matching of x,y is found on the second sorting of items - should not happen
                String info;
                if (streetInfo.readNumberTimesResultsSortedSoFar() > 0)
                {
                    info = "!!! WARNING !!! - ";
                }
                else
                {
                    info = "!!! INFO !!! - ";
                }
                
                if (itemInfo.readItemClassTSID().equals("quoin") && (n.itemInfo.readItemClassTSID().equals("quoin")))
                {
                    info = info + "Two quoins " + itemInfo.readItemTSID() + " and " + n.itemInfo.readItemTSID();
                }
                else
                {
                    info = info + "Two items " + itemInfo.readItemTSID() + " and " + n.itemInfo.readItemTSID();
                }   
                
                if (streetInfo.readNumberTimesResultsSortedSoFar() > 0)
                {
                    info = info + " appear to be clustered together at x,y " + X1 + "," + Y1 + " and so will need to be manually configured";
                    printToFile.printDebugLine(this, info, 3);
                    printToFile.printOutputLine(info);
                }
                else
                {
                    // If either/both items are quoins then mark them for reprocessing - only done for first sorting
                    // As will never get two non-quoin items at the same x,y, is OK to only ever assume the quoins are incorrect
                    String quoinInfo = "For reference:";
                    if (itemInfo.readItemClassTSID().equals("quoin"))
                    {
                        misplacedQuoin = true;
                        quoinInfo = quoinInfo + " " + itemInfo.readItemTSID() + " would have been of type " + itemInfo.readNewItemExtraInfo();
                    }
                    if (n.itemInfo.readItemClassTSID().equals("quoin"))
                    {
                        n.misplacedQuoin = true;
                        quoinInfo = quoinInfo + " " + n.itemInfo.readItemTSID() + " would have been of type " + n.itemInfo.readNewItemExtraInfo();
                    }
                    // Don't print anything to the user output file for the first sorting of the results
                    info = info + " have been set to the same x,y " + X1 + "," + Y1 + " - if one/both is a quoin then then it will be redefined as missing";
                    printToFile.printDebugLine(this, info, 3);
                    printToFile.printDebugLine(this, quoinInfo, 3);
                    
                }               
                return 0;
            }
            else if (Y1 > Y2)
            {
                return 1;
            }
            else
            {
                return -1;
            }
        }
        else
        {
            if (X1 > X2)
            {
                return 1;
            }
            else
            {
                return -1;
            }
        }
    }
    
    public int readItemX()
    {
        return itemX;
    }
    
    public int readItemY()
    {
        return itemY;
    }
    
    public int readResult()
    {
        return result;
    }
    
    public boolean readMisplacedQuoin()
    {
        return misplacedQuoin;
    }
    
    public ItemInfo readItemInfo()
    {
        return itemInfo;
    }

}