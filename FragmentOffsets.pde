class FragmentOffsets
{
    HashMap<String, Offsets> itemOffsetHashMap;
    
    public FragmentOffsets()
    {
        itemOffsetHashMap = new HashMap<String,Offsets>();
    }
    
    boolean loadFragmentDefaultsForItems()
    {
        JSONObject json;
        JSONArray values;
        JSONObject fragment = null;
        int fragOffsetX;
        int fragOffsetY;
        
        // Read in from samples.json file - created by the save_fragments tool. Easier to read in/update
        try
        {
            // Read in stuff from the existing file
            json = loadJSONObject(dataPath("samples.json"));
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine(this, "Failed to open samples.json file", 3);
            return false;
        }
        
        values = Utils.readJSONArray(json, "fragments", true);
        if (!Utils.readOkFlag())
        {
            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
            printToFile.printDebugLine(this, "Failed to read fragments array in samples.json file", 3);
            return false;
        }
        
        for (int i = 0; i < values.size(); i++) 
        {
            fragment = values.getJSONObject(i);
            String tsid = Utils.readJSONString(fragment, "class_tsid", true);
            if (!Utils.readOkFlag() || tsid.length() == 0)
            {
                printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                printToFile.printDebugLine(this, "Failed to read class_tsid in fragments array in samples.json file", 3);
                return false;
            }
            String info = Utils.readJSONString(fragment, "info", true);
            // Is OK if set to ""
            if (!Utils.readOkFlag())
            {
                printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                printToFile.printDebugLine(this, "Failed to read info in fragments array in samples.json file", 3);
                return false;
            }
            
            // Now read in the offsets for this classTSID/info combination
            fragOffsetX = Utils.readJSONInt(fragment, "offset_x", true);
            if (!okFlag)
            {
                printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                printToFile.printDebugLine(this, "Failed to read offset_x in fragments array in samples.json file", 3);
                return false;
            }
            fragOffsetY = Utils.readJSONInt(fragment, "offset_y", true);
            if (!okFlag)
            {
                printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                printToFile.printDebugLine(this, "Failed to read offset_y in fragments array in samples.json file", 3);
                return false;
            }
            
            // Now add into the hashmap - using classTSID/info as the key
            Offsets itemOffsets = new Offsets(fragOffsetX, fragOffsetY);
            if (info.length() > 0)
            {
                itemOffsetHashMap.put(tsid + "_" + info, itemOffsets);
            }
            else
            {
                itemOffsetHashMap.put(tsid, itemOffsets);
            }
        }
        
        printToFile.printDebugLine(this, "Number of offsets recorded is " + itemOffsetHashMap.size(), 1);
        println("Number of offsets recorded is " + itemOffsetHashMap.size());
        return true;
    }
    
        
    public Offsets getFragmentOffsets(String itemClassAndInfo)
    {
        // Up to the calling function to make sure this is not null 
        return itemOffsetHashMap.get(itemClassAndInfo);
    }
    
    public int sizeOf()
    {
        return itemOffsetHashMap.size();
    }
    

}
    class Offsets
    {
        int offsetX;
        int offsetY;
        
        Offsets(int x, int y)
        {
            offsetX = x;
            offsetY = y;
        }
        
        public int readOffsetX()
        {
            return offsetX;
        }
        
         public int readOffsetY()
        {
            return offsetY;
        }
        
  
    }