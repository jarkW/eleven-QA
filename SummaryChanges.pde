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
            // Item has not been found
            
            // If the original item was a mystery quoin, then this is an unchanged item rather than missing 
            // Means the tool has been run twice - so picking up a mystery quoin second time around, which won't match any of the normal quoin images.
            if (itemInfo.readItemClassTSID().equals("quoin") && itemInfo.readOrigItemVariant().equals("mystery"))
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
                // Closely clustered quoins can sometimes be incorrectly deduced - so that two or more can end up with the same x,y values. 
                // So look at both items - if it is a quoin/non-quoin combination then set the quoin to be missing (not sure this scenario will happen
                // but just in case.
                // But if two quoins have the same x,y, then measure the distance between the original x,y for both quoins and this deduced x,y - and set
                // the quoin which is furthest away as missing - assume the quoin which was already nearest the deduced x,y is the correct one.
                // However it is possible that e.g. in a large cluster could have 3 or more with the same co-ordinates, so will need to keep repeating this
                // sorting process until all co-located items have been resolved. E.g. first sort results in  A, B and C having the same co-ordinates which 
                // could be detected as A-B and B-C being compared. If B is the actual quoin, then A is reset to original x,y. But B-C still have the same
                // co-ordinates. 
                if (streetInfo.readNumberTimesResultsSortedSoFar() >= StreetInfo.MAX_SORT_COUNT)
                {
                    // We've exceeded the sanity count - to prevent any infinite looping - so set the flag for any quoins which are present
                    if (itemInfo.readItemClassTSID().equals("quoin"))
                    {
                        misplacedQuoin = true;
                        printToFile.printDebugLine(this, "Warning - Quoin " + itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " and so will need to be manually configured", 3);
                        printToFile.printOutputLine("Warning - Quoin " + itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " and so will need to be manually configured");
                    }
                    if (n.itemInfo.readItemClassTSID().equals("quoin"))
                    {
                        n.misplacedQuoin = true;
                        printToFile.printDebugLine(this, "Warning - Quoin " + n.itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " and so will need to be manually configured", 3);
                        printToFile.printOutputLine("Warning - Quoin " + n.itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " and so will need to be manually configured");
                    }
                }
                else
                {
                    // If both items are quoins then reset the one furthest away
                    if (itemInfo.readItemClassTSID().equals("quoin") && (n.itemInfo.readItemClassTSID().equals("quoin")))
                    {
                        float quoin1Distance = Utils.distanceBetweenX1Y1_X2Y2(itemInfo.readOrigItemX(), itemInfo.readOrigItemY(), X1, Y1);
                        float quoin2Distance = Utils.distanceBetweenX1Y1_X2Y2(n.itemInfo.readOrigItemX(), n.itemInfo.readOrigItemY(), X1, Y1);

                        if (quoin1Distance < quoin2Distance)
                        {
                            // As the first quoin was originally nearer X1,Y1, then mark the second quoin as missing
                            n.misplacedQuoin = true;
                            printToFile.printDebugLine(this, "Warning - Quoin " + n.itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " and so will need to be manually configured", 3);
                            printToFile.printOutputLine("Warning - Quoin " + n.itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " and so will need to be manually configured");
                        }
                        else
                        {
                            // Treat the second quoin as being at X1, Y1 - and mark the first quoin as missing
                            misplacedQuoin = true;
                            printToFile.printDebugLine(this, "Warning - Quoin " + itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " and so will need to be manually configured", 3);
                            printToFile.printOutputLine("Warning - Quoin " + itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " and so will need to be manually configured");
                        }
                    }
                    else
                    {
                        // Means we have an overlap between an item/quoin (rare) - so just reset the quoin
                        if (itemInfo.readItemClassTSID().equals("quoin"))
                        {
                            misplacedQuoin = true;
                            printToFile.printDebugLine(this, "Warning - Quoin " + itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " and so will need to be manually configured", 3);
                            printToFile.printOutputLine("Warning - Quoin " + itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " and so will need to be manually configured");
                        }
                    
                        if (n.itemInfo.readItemClassTSID().equals("quoin"))
                        {
                            n.misplacedQuoin = true;
                            printToFile.printDebugLine(this, "Warning - Quoin " + n.itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " and so will need to be manually configured", 3);
                            printToFile.printOutputLine("Warning - Quoin " + n.itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " and so will need to be manually configured");
                        }
                        
                    }
                }
                
                
                /*
                // 1st ATTEMPT
                // REDO THIS TEXT
                // Should never happen - but can happen to closely clustered quoins. So mark these for resetting back to orig x,y/mystery after giving the appropriate warning message
                // The processing will done after the first time the items have been sorted on x,y - that way if there are 3 or more items clustered together, it won't matter if this
                // flag is set twice, the check will still be valid for whether x1,y1 = x2,y2 or not
                // Only report the warning in the user output file if this matching of x,y is found on the second sorting of items - should not happen
                
                // Let the closest one win - and set the further one to be reset as mystery quoin
                // Might also do this comparison several times until there are no colocated items any more - might have A-B and B-C co-located. If B is the nearest one then A->mystery. But B-C are still colocated. Need C-> mystery
                // In which case there should be a loop counter - and at max, just set everything to mystery/original so that the colocation stops completely
                /* Define your two points. Point 1 at (x1, y1) and Point 2 at (x2, y2).

 
    
                
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
                        quoinInfo = quoinInfo + " " + itemInfo.readItemTSID() + " would have been of type " + itemInfo.readNewItemVariant();
                    }
                    if (n.itemInfo.readItemClassTSID().equals("quoin"))
                    {
                        n.misplacedQuoin = true;
                        quoinInfo = quoinInfo + " " + n.itemInfo.readItemTSID() + " would have been of type " + n.itemInfo.readNewItemVariant();
                    }
                    // Don't print anything to the user output file for the first sorting of the results
                    info = info + " have been set to the same x,y " + X1 + "," + Y1 + " - if one/both is a quoin then then it will be redefined as missing";
                    printToFile.printDebugLine(this, info, 3);
                    printToFile.printDebugLine(this, quoinInfo, 3);
                    
                }   
                */
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