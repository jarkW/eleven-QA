class SummaryChanges implements Comparable
{
    // small class which should make it easier to output/summarise the changes being made to individual item JSON files
    ItemInfo itemInfo;
    
    // Used to populate the results field
    final static int SKIPPED = 1;
    final static int MISSING = 2;
    final static int MISSING_DUPLICATE = 3;
    final static int COORDS_ONLY = 4;
    final static int VARIANT_ONLY = 5;
    final static int VARIANT_AND_COORDS_CHANGED = 6;
    final static int UNCHANGED = 7;
    
    // Populate fields I might want to sort on
    int itemX;
    int itemY;
    int result; 
    
    // If sort reveals that items have been stacked onto the same x,y
    boolean duplicateItemXY;

        
    public SummaryChanges( ItemInfo item, boolean dupItemXY)
    {
        itemInfo = item;
        
        // As bestMatchInfo is not set up for skipped items, deal with that before going any further
        if (itemInfo.readSkipThisItem())
        {
            itemX = itemInfo.readOrigItemX();
            itemY = itemInfo.readOrigItemY();
            result = SKIPPED;
            return;
        }
        
        
        duplicateItemXY = dupItemXY;
        int searchResult = itemInfo.readBestMatchInfo().readBestMatchResult();
        String s;
        s = itemInfo.readItemTSID() + " match=";
        if (searchResult == PERFECT_MATCH)
        {
            s = s + "PERFECT";
        }
        else if (searchResult == GOOD_MATCH)
        {
            s = s + "GOOD";
        }
        else if (searchResult == NO_MATCH)
        {
            s = s + "NONE";
        }
        else
        {
            s = s + "ERROR UNEXPECTED SEARCH RESULT OF " + searchResult;
        }
        s = s + " orig x,y=" + itemInfo.readOrigItemX() + "," + itemInfo.readOrigItemY() + " new x,y=" + itemInfo.readNewItemX() + "," + itemInfo.readNewItemY() + " change in info " + itemInfo.differentVariantFound();
        printToFile.printDebugLine(this, s, 1);
                                    
        if (searchResult > NO_MATCH)
        {
            if (streetInfo.readChangeItemXYOnly())
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
            else if (duplicateItemXY)
            {
                // Means we can give out a slightly better info message when reporting back to user
                result = MISSING_DUPLICATE;
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
                // Closely clustered items of the same type can sometimes be incorrectly deduced - so that two or more can end up with the same x,y values. 
                // Typically this will happen with quoins, but can also happen with e.g. jellisacs.
                // So look at both items - if it is a quoin/non-quoin combination then set the quoin to be missing (not sure this scenario will happen
                // but just in case.
                // Otherwise, measure the distance between the original x,y for both items and this deduced x,y - and set the item which is furthest away
                // as missing - assume the item which was already nearest the deduced x,y is the correct one.
                // However it is possible that e.g. in a large cluster could have 3 or more with the same co-ordinates, so will need to keep repeating this
                // sorting process until all co-located items have been resolved. E.g. first sort results in  A, B and C having the same co-ordinates which 
                // could be detected as A-B and B-C being compared. If B is the actual quoin, then A is reset to original x,y. But B-C still have the same
                // co-ordinates. This multiple case is only likely to happen for tightly clustered quoins. 
                //
                // The list of items on a street may include the skipped qurazy quoin - which we need to ignore here as well otherwise a null pointer error happens as there is no bestMatchResult object associated with this quoin
                if (streetInfo.readNumberTimesResultsSortedSoFar() >= StreetInfo.MAX_SORT_COUNT)
                {
                    // We've exceeded the sanity count - to prevent any infinite looping - so set the flag for any items which are present
                    if (!itemInfo.readOrigItemVariant().equals("qurazy"))
                    {
                        duplicateItemXY = true;
                        if (configInfo.readDebugRun())
                        {
                            // Only give out this information to me - will confuse users
                            printToFile.printOutputLine("Warning - " + itemInfo.readItemClassTSID() + " " + itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " and so will need to be manually configured (exceeded sanity count)");
                        }
                        printToFile.printDebugLine(this, "Warning - " + itemInfo.readItemClassTSID() + " " + itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " and so will need to be manually configured (exceeded sanity count)", 2);
                    }
                    if (!n.itemInfo.readOrigItemVariant().equals("qurazy"))
                    {
                        n.duplicateItemXY = true;
                        if (configInfo.readDebugRun())
                        {
                            // Only give out this information to me - will confuse users                      
                            printToFile.printOutputLine("Warning - " + n.itemInfo.readItemClassTSID() + " " + n.itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " and so will need to be manually configured (exceeded sanity count)");
                        }
                        printToFile.printDebugLine(this, "Warning - " + n.itemInfo.readItemClassTSID() + " " + n.itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " and so will need to be manually configured (exceeded sanity count)", 2);
                    }
                }
                else
                {
                    // Deal with the case when one of the matching items is a qurazy quoin - should never happen, but if it does, set the non-QQ item to be missing (never get 2 QQ on a street)
                    if (itemInfo.readOrigItemVariant().equals("qurazy"))
                    {
                        n.duplicateItemXY = true;
                        if (configInfo.readDebugRun())
                        {
                            // Only give out this information to me - will confuse users
                            printToFile.printOutputLine("Warning - " + n.itemInfo.readItemClassTSID() + " " + n.itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " with qurazy quoin and so will need to be manually configured");
                        }
                        printToFile.printDebugLine(this, "Warning - " + n.itemInfo.readItemClassTSID() + " " + n.itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " with qurazy quoin and so will need to be manually configured", 2);
                    }
                    else if (n.itemInfo.readOrigItemVariant().equals("qurazy"))
                    {
                        duplicateItemXY = true;
                        if (configInfo.readDebugRun())
                        {
                            // Only give out this information to me - will confuse users
                            printToFile.printOutputLine("Warning - " + itemInfo.readItemClassTSID() + " " + itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " with qurazy quoin and so will need to be manually configured");
                        }
                        printToFile.printDebugLine(this, "Warning - " + itemInfo.readItemClassTSID() + " " + itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " with qurazy quoin and so will need to be manually configured", 2);
                    }
                    else
                    {
                        // Have 2 items co-located. If one of them is a quoin, then mark that as missing, otherwise mark the furthest item as missing
                        if (itemInfo.readItemClassTSID().equals("quoin"))
                        {
                            duplicateItemXY = true;
                            if (configInfo.readDebugRun())
                            {
                                // Only give out this information to me - will confuse users
                                printToFile.printOutputLine("Warning - " + itemInfo.readItemClassTSID() + " " + itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " with item " + n.itemInfo.readItemClassTSID() + " " + n.itemInfo.readItemTSID() + " and so will need to be manually configured");
                            }
                            printToFile.printDebugLine(this, "Warning - " + itemInfo.readItemClassTSID() + " " + itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " with item " + n.itemInfo.readItemClassTSID() + " " + n.itemInfo.readItemTSID() + " and so will need to be manually configured", 2);
                        }
                        else if (n.itemInfo.readItemClassTSID().equals("quoin"))
                        {
                            n.duplicateItemXY = true;
                            if (configInfo.readDebugRun())
                            {
                                // Only give out this information to me - will confuse users
                                printToFile.printOutputLine("Warning - " + n.itemInfo.readItemClassTSID() + " " + n.itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " with item " + itemInfo.readItemClassTSID() + " " + itemInfo.readItemTSID() + " and so will need to be manually configured");
                            }
                            printToFile.printDebugLine(this, "Warning - " + n.itemInfo.readItemClassTSID() + " " + n.itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " with item " + itemInfo.readItemClassTSID() + " " + itemInfo.readItemTSID() + " and so will need to be manually configured", 2);
                        }
                        else
                        {
                            float item1Distance = Utils.distanceBetweenX1Y1_X2Y2(itemInfo.readOrigItemX(), itemInfo.readOrigItemY(), X1, Y1);
                            float item2Distance = Utils.distanceBetweenX1Y1_X2Y2(n.itemInfo.readOrigItemX(), n.itemInfo.readOrigItemY(), X1, Y1);
    
                            if (item1Distance < item2Distance)
                            {
                                // As the first item was originally nearer X1,Y1, then mark the second item as missing
                                n.duplicateItemXY = true;
                                if (configInfo.readDebugRun())
                                {
                                    // Only give out this information to me - will confuse users
                                    printToFile.printOutputLine("Warning - " + n.itemInfo.readItemClassTSID() + " " + n.itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " with item " + itemInfo.readItemClassTSID() + " " + itemInfo.readItemTSID() + " and so will need to be manually configured");
                                }
                                printToFile.printDebugLine(this, "Warning - " + n.itemInfo.readItemClassTSID() + " " + n.itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " with item " + itemInfo.readItemClassTSID() + " " + itemInfo.readItemTSID() + " and so will need to be manually configured", 2);
                            }
                            else
                            {
                                // Treat the second item as being at X1, Y1 - and mark the first item as missing
                                duplicateItemXY = true;
                               if (configInfo.readDebugRun())
                                {
                                    // Only give out this information to me - will confuse users
                                    printToFile.printOutputLine("Warning - " + itemInfo.readItemClassTSID() + " " + itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " with item " + n.itemInfo.readItemClassTSID() + " " + n.itemInfo.readItemTSID() + " and so will need to be manually configured");
                                }
                                printToFile.printDebugLine(this, "Warning - " + itemInfo.readItemClassTSID() + " " + itemInfo.readItemTSID() + " assigned duplicate x,y " + X1 + "," + Y1 + " with item " + n.itemInfo.readItemClassTSID() + " " + n.itemInfo.readItemTSID() + " and so will need to be manually configured", 2);
                            }
                        }
                    }
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

    public String readResultAsText()
    {
        switch (result)
        {
            case SKIPPED:
                return "SKIPPED";
            case MISSING:
                return "MISSING";
            case MISSING_DUPLICATE:
                return "MISSING_DUPLICATE";
            case COORDS_ONLY:
                return "COORDS_ONLY";
            case VARIANT_ONLY:
                return "VARIANT_ONLY";
            case VARIANT_AND_COORDS_CHANGED:
                return "VARIANT_AND_COORDS_CHANGED";
            case UNCHANGED:
                return "UNCHANGED";
            default:
                return "UNEXPECTED RESULT";      
        }
    }
    
    public boolean readDuplicateItemXY()
    {
        return duplicateItemXY;
    }
    
    public ItemInfo readItemInfo()
    {
        return itemInfo;
    }

}