class SummaryChanges implements Comparable
{
    // small class which should make it easier to output/summarise the changes being made to individual item JSON files
    ItemInfo itemInfo;
    
    // Can access this from outside - SummaryChanges.SKIPPED
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
    String itemClassTSID;
    String itemExtraInfo;
    String TSID;
    boolean changedJSON;
    int result; 
    
    /*
    What might I want to display
    Also useful to say at top - name of street/TSID - and where files being written to (from config file)
        1. List items from L to R - i.e. by -ve X to +ve X (summary of what was to what is now) - and then summary list of missing/skipped items and count of new quoin types?
        2. List of missing items
        3. list of skipped items
    */
    
    public SummaryChanges( ItemInfo item)
    {
        itemInfo = item;
        itemClassTSID = itemInfo.readItemClassTSID();
        TSID = itemInfo.readItemTSID();
        changedJSON = itemInfo.readSaveChangedJSONfile();
        
        //newItemExtraInfo = itemInfo.readNewItemExtraInfo;
        if (itemInfo.readSkipThisItem())
        {
            itemX = itemInfo.readOrigItemX();
            itemY = itemInfo.readOrigItemY();
            itemExtraInfo = itemInfo.readOrigItemExtraInfo();
            result = SKIPPED;
        }
        else if (itemInfo.readItemFound())
        {
            if (itemInfo.differentVariantFound())
            {
                if (itemX == itemInfo.readOrigItemX())
                {
                    itemX = itemInfo.readOrigItemX();
                    itemY = itemInfo.readOrigItemY();
                    itemExtraInfo = itemInfo.readNewItemExtraInfo();
                    result = VARIANT_ONLY;
                }
                else
                {
                    itemX = itemInfo.readNewItemX();
                    itemY = itemInfo.readNewItemY();
                    itemExtraInfo = itemInfo.readNewItemExtraInfo();
                    result = VARIANT_AND_COORDS_CHANGED;
                }
            }
            else
            {
                if (itemInfo.readNewItemX() != itemInfo.readOrigItemX())
                {
                    itemX = itemInfo.readNewItemX();
                    itemY = itemInfo.readNewItemY();
                    itemExtraInfo = itemInfo.readOrigItemExtraInfo();
                    result = COORDS_ONLY;
                }
                else
                {
                    itemX = itemInfo.readNewItemX();
                    itemY = itemInfo.readNewItemY();
                    itemExtraInfo = itemInfo.readOrigItemExtraInfo();
                    result = UNCHANGED;
                }
            }
        }
        else
        {
            itemX = itemInfo.readOrigItemX();
            itemY = itemInfo.readOrigItemY();
            if (itemClassTSID.equals("quoin"))
            {
                // As will be set to mystery = change
                itemExtraInfo = itemInfo.readNewItemExtraInfo();
            }
            else
            {
                itemExtraInfo = itemInfo.readOrigItemExtraInfo();
            }
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
                printToFile.printDebugLine(this, "Error -  Two items " + TSID + " and " + n.TSID + " with same x,y", 3);
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
        return itemClassTSID;
    }
    
    public String readItemExtraInfo()
    {
        return itemExtraInfo;
    }
    
    public String readItemTSID()
    {
        return TSID;
    }
    
    public boolean readChangedJSON()
    {
        return changedJSON;
    }

}