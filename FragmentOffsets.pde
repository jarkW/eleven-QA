class FragmentOffsets
{
    HashMap<String, Offsets> itemOffsetHashMap;
    
    public FragmentOffsets()
    {
        itemOffsetHashMap = new HashMap<String,Offsets>();
    }
    
    boolean loadFragmentDefaultsForItems()
    {
        // NB These are only valid for the first search of an item - once the item has been found on a snap, then the
        // offset is not applied again for subsequent searches of that item on other snaps.
        // Otherwise the final item x,y gradually creep ...
        JSONObject json;
        JSONArray values;
        JSONObject fragment = null;
        int fragOffsetX;
        int fragOffsetY;
        int fragWidth;
        int fragHeight;
        
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
            fragment = Utils.readJSONObjectFromJSONArray(values, i, true);
            if (!Utils.readOkFlag())
            {
                printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                printToFile.printDebugLine(this, "Failed to read fragments array in samples.json file", 3);
                return false;
            }

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
            
            String state = Utils.readJSONString(fragment, "state", false);
            if (!Utils.readOkFlag())
            {
                // The state field may not exist - only used for items which need to have the maturity recorded for the image e.g. trees
                state = "";
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
            
            // Read in the expected fragment width/height - used for validation checking only when loading images
            fragWidth = Utils.readJSONInt(fragment, "width", true);
            if (!okFlag)
            {
                printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                printToFile.printDebugLine(this, "Failed to read width in fragments array in samples.json file", 3);
                return false;
            }
            fragHeight = Utils.readJSONInt(fragment, "height", true);
            if (!okFlag)
            {
                printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
                printToFile.printDebugLine(this, "Failed to read height in fragments array in samples.json file", 3);
                return false;
            }
            
            // Need to correct these offsets for quoins/QQ to compensate for original item images being recorded
            // at extremes of the actual range of the quoin (measured over 15 snaps)
            // Doesn't seem to make much difference, but worth keeping.
            // NB if recreate the images, will need to adjust these offsets ...
            /*
            switch (tsid)
            {
                case "marker_qurazy":
                    fragOffsetY = fragOffsetY - 2;
                    printToFile.printDebugLine(this, "Resetting QQ y-offset by -2 from value in samples.json file", 1);
                    break;
                case "quoin":
                    switch (info)
                    {
                        case "xp":
                            //fragOffsetY = fragOffsetY;
                            break;
                        case "energy":
                            fragOffsetY = fragOffsetY - 4;
                            printToFile.printDebugLine(this, "Resetting quoin " + info + " y-offset by -4 from value in samples.json file", 1);
                            break;
                        case "mood":
                            fragOffsetY = fragOffsetY - 3;
                            printToFile.printDebugLine(this, "Resetting quoin " + info + " y-offset by -3 from value in samples.json file", 1);
                            break;
                        case "currants":
                            fragOffsetY = fragOffsetY - 3;
                            printToFile.printDebugLine(this, "Resetting quoin " + info + " y-offset by -3 from value in samples.json file", 1);
                            break;
                        case "favor":
                            fragOffsetY = fragOffsetY  - 1;
                            printToFile.printDebugLine(this, "Resetting quoin " + info + " y-offset by -1 from value in samples.json file", 1);
                            break;
                        case "time":
                            fragOffsetY = fragOffsetY - 4;
                            printToFile.printDebugLine(this, "Resetting quoin " + info + " y-offset by -4 from value in samples.json file", 1);
                            break;
                        case "mystery":
                            fragOffsetY = fragOffsetY - 3; 
                            printToFile.printDebugLine(this, "Resetting quoin " + info + " y-offset by -3 from value in samples.json file", 1);
                            break;
                        default:
                            // unexpected
                            printToFile.printDebugLine(this, "Unexpected type of quoin " + info + " in fragments array in samples.json file", 3);
                            return false;                            
                    }
                    break;
                default:
                    break;
            }
             */            
             
            // Now add into the hashmap - using classTSID/info as the key           
            Offsets itemOffsets = new Offsets(fragOffsetX, fragOffsetY, fragWidth, fragHeight);
            String keyString = tsid;
            if (info.length() > 0)
            {
                keyString = keyString + "_" + info;
            }
            if (state.length() > 0)
            {
                keyString = keyString + "_" + state;
            }
            itemOffsetHashMap.put(keyString, itemOffsets);
        }
        
        printToFile.printDebugLine(this, "Number of offsets recorded is " + itemOffsetHashMap.size(), 1);
        return true;
    }
    
        
    public Offsets getFragmentOffsets(String itemClassAndInfoAndState)
    {
        // Up to the calling function to make sure this is not null 
        return itemOffsetHashMap.get(itemClassAndInfoAndState);
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
        int fragmentWidth;
        int fragmentHeight;
        
        Offsets(int x, int y, int w, int h)
        {
            offsetX = x;
            offsetY = y;
            fragmentWidth = w;
            fragmentHeight = h;
        }
        
        public int readOffsetX()
        {
            return offsetX;
        }
        
         public int readOffsetY()
        {
            return offsetY;
        }
        
        public int readFragmentWidth()
        {
            return fragmentWidth;
        }
        
        public int readFragmentHeight()
        {
            return fragmentHeight;
        }
        
  
    }