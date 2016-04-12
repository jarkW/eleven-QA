class ConfigInfo {
    
    boolean okFlag;
    
    boolean useVagrant;   
    String fixturesPath;
    String persdataPath;
    String streetSnapPath;
    boolean changeXYOnly;
    int searchRadius;
    String serverName;
    String serverUsername;
    String serverPassword;
    int serverPort;
    boolean writeJSONsToPersdata;  // until sure that the files are all OK, will be in NewJSONs directory under processing sketch
    
    boolean debugSaveOrigAndNewJSONs;
    boolean debugShowBWFragments;
    
    StringList streetTSIDs = new StringList();
    String outputFile;

    // constructor/initialise fields
    public ConfigInfo()
    {
        okFlag = true;
            
        // Read in config info from JSON file
        if (!readConfigData())
        {
            println("Error in readConfigData");
            // displayMgr.showInfoMsg("Error in readConfigData"); - not do this as overwrites the information given by readConfigData call to this function
            okFlag = false;
            return;
        }
    }
    
    boolean readConfigData()
    {
        JSONObject json;
        // Open the config file
        File file = new File(workingDir + File.separatorChar + "config.json");
        if (!file.exists())
        {
            println("Missing config.json file from ", workingDir);
            displayMgr.showInfoMsg("Missing config.json file from " + workingDir);
            return false;
        }
        
        try
        {
            // Read in stuff from the config file
            json = loadJSONObject(workingDir + File.separatorChar + "config.json"); 
        }
        catch(Exception e)
        {
            println(e);
            println("Failed to load config.json file");
            displayMgr.showInfoMsg("Failed to load config.json file");
            return false;
        }
   
        // Now read in the different fields
        useVagrant = Utils.readJSONBool(json, "use_vagrant_dirs", true);  
        if (!Utils.readOkFlag())
        {
            println(Utils.readErrMsg());
            println("Failed to read use_vagrant_dirs in config.json file");
            displayMgr.showInfoMsg("Failed to read use_vagrant_dirs in config.json file");
            return false;
        }
        
        // Read in the locations of the JSON directories        
        JSONObject fileSystemInfo;
        if (useVagrant)
        {
            fileSystemInfo = Utils.readJSONObject(json, "vagrant_dirs", true);
            if (!Utils.readOkFlag())
            {
                println(Utils.readErrMsg());
                println("Failed to read vagrant_info in config.json file");
                displayMgr.showInfoMsg("Failed to read vagrant_info in config.json file");
                return false;
            }           
            serverName = "";
            serverUsername = "";
            serverPassword = "";
            serverPort = 0;
        }
        else
        {
            // Read in server details
            JSONObject serverInfo = Utils.readJSONObject(json, "server_info", true); 
            if (!Utils.readOkFlag())
            {
                println(Utils.readErrMsg());
                println("Failed to read server_info in config.json file");
                displayMgr.showInfoMsg("Failed to read server_info in config.json file");
                return false;
            }  
            serverName = Utils.readJSONString(serverInfo, "host", true);
            if (!Utils.readOkFlag())
            {
                println(Utils.readErrMsg());
                println("Failed to read server host name in config.json file");
                displayMgr.showInfoMsg("Failed to read server host name in config.json file");
                return false;
            }  
            serverUsername = Utils.readJSONString(serverInfo, "username", true);
            if (!Utils.readOkFlag())
            {
                 println(Utils.readErrMsg());
                 println("Failed to read server username in config.json file");
                 displayMgr.showInfoMsg("Failed to read server username in config.json file");
                 return false;
            }            
            serverPassword = Utils.readJSONString(serverInfo, "password", true);
            if (!Utils.readOkFlag())
            {
               println(Utils.readErrMsg());
               println("Failed to read server password in config.json file");
               displayMgr.showInfoMsg("Failed to read server password in config.json file");
               return false;
            }
            serverPort = Utils.readJSONInt(serverInfo, "port", true);
            if (!Utils.readOkFlag())
            {
               println(Utils.readErrMsg());
               println("Failed to read port in config.json file");
               displayMgr.showInfoMsg("Failed to read port in config.json file");
               return false;
            }
            
            fileSystemInfo = Utils.readJSONObject(serverInfo, "server_dirs", true);
            if (!Utils.readOkFlag())
            {
                println(Utils.readErrMsg());
                println("Failed to read server_dirs in config.json file");
                displayMgr.showInfoMsg("Failed to read server_dirs in config.json file");
                return false;
            }
        }
        
        // Now read in the appropriate dirs that contain JSON files
        fixturesPath = Utils.readJSONString(fileSystemInfo, "fixtures_path", true); 
        if (!Utils.readOkFlag() || fixturesPath.length() == 0)
        {
            println(Utils.readErrMsg());
            if (useVagrant)
            {
                println("Failed to read fixtures_path from vagrant_dirs in config.json file");
                displayMgr.showInfoMsg("Failed to read fixtures_path from vagrant_dirs in config.json file");
            }
            else
            {
                println("Failed to read fixtures_path from server_dirs in config.json file");
                displayMgr.showInfoMsg("Failed to read fixtures_path from server_dirs in config.json file");
            }
            return false;
        }      
        
        persdataPath = Utils.readJSONString(fileSystemInfo, "persdata_path", true);
        if (!Utils.readOkFlag() || persdataPath.length() == 0)
        {
            println(Utils.readErrMsg());
            if (useVagrant)
            {
                println("Failed to read persdata_path from vagrant_dirs in config.json file");
                displayMgr.showInfoMsg("Failed to read persdata_path from vagrant_dirs in config.json file");
            }
            else
            {
                println("Failed to read persdata_path from server_dirs in config.json file");
                displayMgr.showInfoMsg("Failed to read persdata_path from server_dirs in config.json file");
            }
            return false;
        }
        // Check that the directories exist
        if (useVagrant)
        {
            File myDir = new File(fixturesPath);
            if (!myDir.exists())
            {
                println("Fixtures directory ", fixturesPath, " does not exist");
                displayMgr.showInfoMsg("Fixtures directory " + fixturesPath + " does not exist");
                return false;
            }
            myDir = new File(persdataPath);
            if (!myDir.exists())
            {
                println("Persdata directory ", persdataPath, " does not exist");
                displayMgr.showInfoMsg("Persdata directory " + persdataPath + " does not exist");
                return false;
            }
            
        }
        else
        {
            // Will validate the fixtures/persdata paths on server once session has been established
        }
        
        
        streetSnapPath = Utils.readJSONString(json, "street_snap_path", true);
        if (!Utils.readOkFlag() || streetSnapPath.length() == 0)
        {
            println(Utils.readErrMsg());
            println("Failed to read street_snap_path in config.json file");
            displayMgr.showInfoMsg("Failed to read street_snap_path in config.json file");
            return false;
        }
        File myDir = new File(streetSnapPath);
        if (!myDir.exists())
        {
            println("Street snap archive directory ", streetSnapPath, " does not exist");
            displayMgr.showInfoMsg("Street snap archive directory " + streetSnapPath + " does not exist");
            return false;
        }
               
        outputFile = Utils.readJSONString(json, "output_file", true);
        if (!Utils.readOkFlag() || outputFile.length() == 0)
        {
            println(Utils.readErrMsg());
            println("Failed to read output_file in config.json file");
            displayMgr.showInfoMsg("Failed to read output_file in config.json file");
            return false;
        }        
        // Need to check that output file is a text file
        if (outputFile.indexOf(".txt") == -1)
        {
            println("Output file (output_file) needs to be a .txt file");
            displayMgr.showInfoMsg("Output file (output_file) needs to be a .txt file");
            return false;
        } 
                
        changeXYOnly = Utils.readJSONBool(json, "change_xy_only", true);
        if (!Utils.readOkFlag())
        {
            println(Utils.readErrMsg());
            println("Failed to read change_xy_only in config.json file");
            displayMgr.showInfoMsg("Failed to read change_xy_only in config.json file");
            return false;
        }
        
        searchRadius = Utils.readJSONInt(json, "search_radius", true);
        if (!Utils.readOkFlag())
        {
            println(Utils.readErrMsg());
            println("Failed to read search_radius in config.json file");
            displayMgr.showInfoMsg("Failed to read search_radius in config.json file");
            return false;
        }
        
        // THESE ARE ONLY USED FOR DEBUG TESTING - so not error if missing
        debugSaveOrigAndNewJSONs = Utils.readJSONBool(json, "debug_save_all_JSONs_for_comparison", false);
        if (!Utils.readOkFlag())
        {
            debugSaveOrigAndNewJSONs = false;
        }
        writeJSONsToPersdata = Utils.readJSONBool(json, "debug_write_JSONs_To_Persdata", false);
        if (!Utils.readOkFlag())
        {
            // By default want to write files to persdata
            writeJSONsToPersdata = true;
        }
        debugShowBWFragments = Utils.readJSONBool(json, "debug_show_BW_fragments", false);
        if (!Utils.readOkFlag())
        {
            debugShowBWFragments = false;
        }
       // End of debug only info
        
        // Read in array of street TSID from config file
        JSONArray TSIDArray = Utils.readJSONArray(json, "streets", true);
        if (!Utils.readOkFlag())
        {
            println(Utils.readErrMsg());
            println("Failed to read in streets array from config.json");
            displayMgr.showInfoMsg("Failed to read in streets array from config.json");
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
                    displayMgr.showInfoMsg("Missing value for street tsid");
                    return false;
                }
                streetTSIDs.append(tsid);
            }
        }
        catch(Exception e)
        {
            println(e);
            println("Failed to read (exception) in street array from config.json");
            displayMgr.showInfoMsg("Failed to read (exception) in street array from config.json");
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
    
    public boolean readDebugSaveOrigAndNewJSONs()
    {
        return debugSaveOrigAndNewJSONs;
    }
    public boolean readWriteJSONsToPersdata()
    {
        return writeJSONsToPersdata;
    }
         
    public String readStreetTSID(int n)
    {
        if (n < streetTSIDs.size())
        {
            return streetTSIDs.get(n);
        }
        else
        {
            // error condition
            return "";
        }
    }
    
    public int readTotalJSONStreetCount()
    {
        return streetTSIDs.size();
    }
    
    public String readOutputFilename()
    {
        return outputFile;
    } 
    
    public int readSearchRadius()
    {
        return searchRadius;
    }
    
    public String readServerName()
    {
        return serverName;
    }
    
    public String readServerUsername()
    {
        return serverUsername;
    }
    
    public String readServerPassword()
    {
        return serverPassword;
    }
    public int readServerPort()
    {
        return serverPort;
    }
    
    public boolean readDebugShowBWFragments()
    {
        return debugShowBWFragments;
    }
    
}