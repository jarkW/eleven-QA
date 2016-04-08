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
    
    String TSID; // used for debugging error case only

        
    public SummaryChanges( ItemInfo item)
    {
        itemInfo = item;
        TSID = itemInfo.readItemTSID();
        
        printToFile.printDebugLine(this, TSID + " found=" + itemInfo.readItemFound() + " orig x,y=" + itemInfo.readOrigItemX() + "," +
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
            itemX = itemInfo.readOrigItemX();
            itemY = itemInfo.readOrigItemY();
            result = MISSING;
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
                // Should never happen
                printToFile.printDebugLine(this, "Error -  Two items " + TSID + " and " + n.TSID + " with same x,y " + X1 + "," + Y1, 3);
                printToFile.printOutputLine("Error -  Two items " + TSID + " and " + n.TSID + " with same x,y " + X1 + "," + Y1);
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
    
    public String readItemClassTSID()
    {
        return itemInfo.readItemClassTSID();
    }
        
    public String readItemTSID()
    {
        return TSID;
    }
    
    public boolean readChangedJSON()
    {
        return itemInfo.readSaveChangedJSONfile();
    }
    
    public int readOrigItemX()
    {
        return itemInfo.readOrigItemX();
    }
    
    public int readOrigItemY()
    {
        return itemInfo.readOrigItemY();
    }
    
    public String readOrigItemExtraInfo()
    {
        return itemInfo.readOrigItemExtraInfo();
    }
    
    public String readOrigItemClassName()
    {
        return itemInfo.readOrigItemClassName();
    }
    
    public String readNewItemExtraInfo()
    {
        return itemInfo.readNewItemExtraInfo();
    }
    
    public String readNewItemClassName()
    {
        return itemInfo.readNewItemClassName();
    }


}