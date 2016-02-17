class ConfigInfo {
    
    boolean okFlag;
    
    boolean useVagrant;   
    String fixturesPath;
    String persdataPath;
    String streetSnapPath;
    StringList streetTSIDArray = new StringList();
    String outputFile;

    // constructor/initialise fields
    public ConfigInfo()
    {
        okFlag = true;
    
        // Read in config info from JSON file
        if (!readConfigData())
        {
            println("Error in readConfigData");
            okFlag = false;
            return;
        }
    }
    
    boolean readConfigData()
    {
        JSONObject json;
        // Open the config file
        try
        {
        // Read in stuff from the config file
            json = loadJSONObject("config.json");
        }
        catch(Exception e)
        {
            println(e);
            println("Failed to load config.json file");
            return false;
        }
   
        // Now read in the different fields
        useVagrant = readJSONBoolean(json, "use_vagrant_dirs");       
        fixturesPath = readJSONString(json, "fixtures_path");   
        persdataPath = readJSONString(json, "persdata_path");
        streetSnapPath = readJSONString(json, "street_snap_path");
        outputFile = readJSONString(json, "output_file");
        
        // Need to check that output file is a text file
        if (outputFile.indexOf(".txt") == -1)
        {
            println("Output file (output_file) needs to a .txt file");
            okFlag = false;
            return false;
        }    
        
        // Read in array of street TSID from config file
        try
        {
            JSONArray TSIDArray = null;
            TSIDArray = json.getJSONArray("streets");
            for (int i = 0; i < TSIDArray.size(); i++)
            {    
                // extract the TSID
                JSONObject tsidObject = TSIDArray.getJSONObject(i);
                String tsid = tsidObject.getString("tsid", null);
                
                if (tsid.length() == 0)
                {
                    println("Missing value for street tsid");
                    return false;
                }
                streetTSIDArray.append(tsid);
            }
        }
        catch(Exception e)
        {
            println(e);
            println("Failed to read in street array from config.json");
            return false;
        }  
        
            
        // Everything OK
        return true;
    }
    
    String readJSONString(JSONObject jsonFile, String key)
    {
        String readString = "";
        try
        {
            if (jsonFile.isNull(key) == true) 
            {
                println("Missing key ", key, " in json file");
                okFlag = false;
                return "";
            }
            readString = jsonFile.getString(key, "");
        }
        catch(Exception e)
        {
            println(e);
            println("Failed to read string from json file with key ", key);
            okFlag = false;
            return "";
        }
        if (readString.length() == 0)
        {
            println("Null field returned for key", key);
            okFlag = false;
            return "";
        }
        return readString;
    }
    
    boolean readJSONBoolean(JSONObject jsonFile, String key)
    {
        boolean readBool = false;
        try
        {
            if (jsonFile.isNull(key) == true) 
            {
                println("Missing key ", key, " in json file");
                okFlag = false;
                return false;
            }
            readBool = jsonFile.getBoolean(key, false);
        }
        catch(Exception e)
        {
            println(e);
            println("Failed to read boolean from json file with key ", key);
            okFlag = false;
            return false;
        }
        return readBool;
    }
    
    public boolean readOkFlag()
    {
        return okFlag;
    }
    
    public boolean readUseVagrantFlag()
    {
        return useVagrant;
    }   
    
    public String readFixturesPath()
    {
        return fixturesPath;
    }
       
    public String readPersdataPath()
    {
        return persdataPath;
    } 
    
    public String readStreetSnapPath()
    {
        return streetSnapPath;
    }
         
    public String readStreetTSID(int n)
    {
        if (n < streetTSIDArray.size())
        {
            return streetTSIDArray.get(n);
        }
        else
        {
            // error condition
            return "";
        }
    }
    
    public int readTotalJSONStreetCount()
    {
        return streetTSIDArray.size();
    }
    
    public String readOutputFilename()
    {
        return outputFile;
    } 
    
}