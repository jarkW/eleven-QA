class ConfigInfo {
    
    boolean okFlag;
    
    boolean useVagrant;   
    String fixturesPath;
    String persdataPath;
    String streetSnapPath;
    boolean changeXYOnly;
    
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
        useVagrant = Utils.readJSONBool(json, "use_vagrant_dirs", true);  
        if (!Utils.readOkFlag())
        {
            println(Utils.readErrMsg());
            println("Failed to read use_vagrant_dirs in config.json file");
            return false;
        }
        fixturesPath = Utils.readJSONString(json, "fixtures_path", true); 
        if (!Utils.readOkFlag() || fixturesPath.length() == 0)
        {
            println(Utils.readErrMsg());
            println("Failed to read fixtures_path in config.json file");
            return false;
        }
        persdataPath = Utils.readJSONString(json, "persdata_path", true);
        if (!Utils.readOkFlag() || persdataPath.length() == 0)
        {
            println(Utils.readErrMsg());
            println("Failed to read persdata_path in config.json file");
            return false;
        }
        streetSnapPath = Utils.readJSONString(json, "street_snap_path", true);
        if (!Utils.readOkFlag() || streetSnapPath.length() == 0)
        {
            println(Utils.readErrMsg());
            println("Failed to read street_snap_path in config.json file");
            return false;
        }
        outputFile = Utils.readJSONString(json, "output_file", true);
        if (!Utils.readOkFlag() || outputFile.length() == 0)
        {
            println(Utils.readErrMsg());
            println("Failed to read output_file in config.json file");
            return false;
        }
        
        changeXYOnly = Utils.readJSONBool(json, "change_xy_only", true);
        if (!Utils.readOkFlag() || outputFile.length() == 0)
        {
            println(Utils.readErrMsg());
            println("Failed to read change_xy_only in config.json file");
            return false;
        }
        
        // Need to check that output file is a text file
        if (outputFile.indexOf(".txt") == -1)
        {
            println("Output file (output_file) needs to a .txt file");
            return false;
        }    
        
        // Read in array of street TSID from config file
        JSONArray TSIDArray = Utils.readJSONArray(json, "streets", true);
        if (!Utils.readOkFlag())
        {
            println(Utils.readErrMsg());
            println("Failed to read in streets array from config.json");
            return false;
        }
        try
        {
            for (int i = 0; i < TSIDArray.size(); i++)
            {    
                // extract the TSID
                JSONObject tsidObject = TSIDArray.getJSONObject(i);                               
                String tsid = Utils.readJSONString(tsidObject, "tsid", true);
                if (!Utils.readOkFlag() || tsid.length() == 0)
                {
                    println(Utils.readErrMsg());
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
    
    public boolean readChangeXYOnly()
    {
        return changeXYOnly;
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