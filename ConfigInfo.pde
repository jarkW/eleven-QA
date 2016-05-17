class ConfigInfo {
    
    boolean okFlag;
    
    boolean useVagrant;
    String elevenPath;
    String fixturesPath;
    String persdataPath;
    String persdataQAPath;
    String streetSnapPath;
    boolean changeXYOnly;
    int searchRadius;
    int percentMatchCriteria;
    String serverName;
    String serverUsername;
    String serverPassword;
    int serverPort;
    boolean writeJSONsToPersdata;  // until sure that the files are all OK, will be in NewJSONs directory under processing sketch
    
    boolean debugShowBWFragments;
    boolean debugDumpBWDiffImages;
    
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
            // displayMgr.showErrMsg("Error in readConfigData", true); - not do this as overwrites the information given by readConfigData call to this function
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
            displayMgr.showErrMsg("Missing config.json file from " + workingDir, true);
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
            println("Failed to load config.json file - check file is correctly formatted by pasting contents into http://jsonlint.com/");
            displayMgr.showErrMsg("Failed to load config.json file - check file is correctly formatted by pasting contents into http://jsonlint.com/", true);
            return false;
        }
        
        // Now read in the different fields
        useVagrant = Utils.readJSONBool(json, "use_vagrant_dirs", true);  
        if (!Utils.readOkFlag())
        {
            println(Utils.readErrMsg());
            println("Failed to read use_vagrant_dirs in config.json file");
            displayMgr.showErrMsg("Failed to read use_vagrant_dirs in config.json file", true);
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
                displayMgr.showErrMsg("Failed to read vagrant_info in config.json file", true);
                return false;
            }           
            serverName = "";
            serverUsername = "";
            serverPassword = "";
            serverPort = 0;
            uploadString = "Copying";
            downloadString = "Copying";
        }
        else
        {
            // Read in server details
            JSONObject serverInfo = Utils.readJSONObject(json, "server_info", true); 
            if (!Utils.readOkFlag())
            {
                println(Utils.readErrMsg());
                println("Failed to read server_info in config.json file");
                displayMgr.showErrMsg("Failed to read server_info in config.json file", true);
                return false;
            }  
            serverName = Utils.readJSONString(serverInfo, "host", true);
            if (!Utils.readOkFlag())
            {
                println(Utils.readErrMsg());
                println("Failed to read server host name in config.json file");
                displayMgr.showErrMsg("Failed to read server host name in config.json file", true);
                return false;
            }  
            serverUsername = Utils.readJSONString(serverInfo, "username", true);
            if (!Utils.readOkFlag())
            {
                 println(Utils.readErrMsg());
                 println("Failed to read server username in config.json file");
                 displayMgr.showErrMsg("Failed to read server username in config.json file", true);
                 return false;
            }            
            serverPassword = Utils.readJSONString(serverInfo, "password", true);
            if (!Utils.readOkFlag())
            {
               println(Utils.readErrMsg());
               println("Failed to read server password in config.json file");
               displayMgr.showErrMsg("Failed to read server password in config.json file", true);
               return false;
            }
            serverPort = Utils.readJSONInt(serverInfo, "port", true);
            if (!Utils.readOkFlag())
            {
               println(Utils.readErrMsg());
               println("Failed to read port in config.json file");
               displayMgr.showErrMsg("Failed to read port in config.json file", true);
               return false;
            }
            
            fileSystemInfo = Utils.readJSONObject(serverInfo, "server_dirs", true);
            if (!Utils.readOkFlag())
            {
                println(Utils.readErrMsg());
                println("Failed to read server_dirs in config.json file");
                displayMgr.showErrMsg("Failed to read server_dirs in config.json file", true);
                return false;
            }
            uploadString = "Uploading";
            downloadString = "Downloading";
        }
        
        // Now read in the appropriate dirs that contain JSON files
        elevenPath = Utils.readJSONString(fileSystemInfo, "eleven_path", true); 
        if (!Utils.readOkFlag() || elevenPath.length() == 0)
        {
            println(Utils.readErrMsg());
            if (useVagrant)
            {
                println("Failed to read eleven_path from vagrant_dirs in config.json file");
                displayMgr.showErrMsg("Failed to read eleven_path from vagrant_dirs in config.json file", true);
            }
            else
            {
                println("Failed to read eleven_path from server_dirs in config.json file");
                displayMgr.showErrMsg("Failed to read eleven_path from server_dirs in config.json file", true);
            }
            return false;
        }
        
        // Just in case someone has non-standard paths
        // If this is present, then use it, otherwise construct the paths
        fixturesPath = Utils.readJSONString(fileSystemInfo, "fixtures_path", false);
        if (fixturesPath.length() == 0)
        {
            // Use default path
            if (useVagrant)
            {
                fixturesPath = elevenPath + File.separatorChar + "eleven-fixtures";
            }
            else
            {
                fixturesPath = elevenPath + "/eleven-fixtures";
            }
        }
        persdataPath = Utils.readJSONString(fileSystemInfo, "persdata_path", false);
        if (persdataPath.length() == 0)
        {
            // Use default path
            if (useVagrant)
            {
                persdataPath = elevenPath + File.separatorChar + "eleven-throwaway-server" + File.separatorChar + "persdata";
            }
            else
            {
                persdataPath = elevenPath + "/eleven-throwaway-server/persdata";
            }
        }
        
        persdataQAPath = Utils.readJSONString(fileSystemInfo, "persdata_qa_path", false);
        if (persdataQAPath.length() == 0)
        {
            // Use default path
            if (useVagrant)
            {
                persdataQAPath = elevenPath + File.separatorChar + "eleven-throwaway-server" + File.separatorChar + "persdata-qa";
            }
            else
            {
                persdataQAPath = elevenPath + "/eleven-throwaway-server/persdata-qa";
            }
        }
        
        // Check that the directories exist
        if (useVagrant)
        {
            File myDir = new File(fixturesPath);
            if (!myDir.exists())
            {
                println("Fixtures directory ", fixturesPath, " does not exist");
                displayMgr.showErrMsg("Fixtures directory " + fixturesPath + " does not exist", true);
                return false;
            }
            myDir = new File(persdataPath);
            if (!myDir.exists())
            {
                println("Persdata directory ", persdataPath, " does not exist");
                displayMgr.showErrMsg("Persdata directory " + persdataPath + " does not exist", true);
                return false;
            }
            myDir = new File(persdataQAPath);
            if (!myDir.exists())
            {
                println("Persdata-qa directory ", persdataQAPath, " does not exist");
                displayMgr.showErrMsg("Persdata-qa directory " + persdataQAPath + " does not exist", true);
                return false;
            }
            
        }
        else
        {
            // Will validate the fixtures/persdata/persdata-qa paths on server once session has been established
        }

        streetSnapPath = Utils.readJSONString(json, "street_snap_path", true);
        if (!Utils.readOkFlag() || streetSnapPath.length() == 0)
        {
            println(Utils.readErrMsg());
            println("Failed to read street_snap_path in config.json file");
            displayMgr.showErrMsg("Failed to read street_snap_path in config.json file", true);
            return false;
        }
        File myDir = new File(streetSnapPath);
        if (!myDir.exists())
        {
            println("Street snap archive directory ", streetSnapPath, " does not exist");
            displayMgr.showErrMsg("Street snap archive directory " + streetSnapPath + " does not exist", true);
            return false;
        }
               
        outputFile = Utils.readJSONString(json, "output_file", true);
        if (!Utils.readOkFlag() || outputFile.length() == 0)
        {
            println(Utils.readErrMsg());
            println("Failed to read output_file in config.json file");
            displayMgr.showErrMsg("Failed to read output_file in config.json file", true);
            return false;
        }        
        // Need to check that output file is a text file
        if (outputFile.indexOf(".txt") == -1)
        {
            println("Output file (output_file) needs to be a .txt file");
            displayMgr.showErrMsg("Output file (output_file) needs to be a .txt file", true);
            return false;
        } 
        
        writeJSONsToPersdata = Utils.readJSONBool(json, "write_JSONs_To_persdata", true);
        if (!Utils.readOkFlag())
        {
            println("Failed to read write_JSONs_To_persdata in config.json file");
            displayMgr.showErrMsg("Failed to read write_JSONs_To_persdata in config.json file", true);
            return false;
        }
        
        
        
        // The following options are OPTIONAL - so don't need to be in the JSON file
        changeXYOnly = Utils.readJSONBool(json, "change_xy_only", false);
        if (!Utils.readOkFlag())
        {
            changeXYOnly = false;
        }
        
        searchRadius = Utils.readJSONInt(json, "search_radius", false);
        if (!Utils.readOkFlag())
        {
            searchRadius = 25;
        }
        else if (searchRadius < 1)
        {
            println("Please enter a search_radius which is larger than 0 in config.json file");
            displayMgr.showErrMsg("Please enter a search_radius which is larger than 0 in config.json file", true);
            return false;
        }
        
        percentMatchCriteria = Utils.readJSONInt(json, "percent_match_criteria", false);
        if (!Utils.readOkFlag())
        {
            percentMatchCriteria = 90;
        }
        else if ((percentMatchCriteria < 1) || (percentMatchCriteria > 100))
        {
            println("Please enter a valid value for percent_match_criteria which is between 1-100 in config.json file");
            displayMgr.showErrMsg("Please enter a valid value for percent_match_criteria which is between 1-100 in config.json file", true);
            return false;
        }
        
        debugLevel = Utils.readJSONInt(json, "tracing_level", false);
        if (!Utils.readOkFlag())
        {
            debugLevel = 3;
        }
        else if ((debugLevel < 0) || (debugLevel > 3))
        {
            println("Please enter a valid value for tracing_level which is between 0-3 (0 is off, 1 gives much information, 3 reports errors only) in config.json file");
            displayMgr.showErrMsg("Please enter a valid value for tracing_level which is between 0-3 (0 is off, 1 gives much information, 3 reports errors only) in config.json file", true);
            return false;
        }
        
        debugDumpBWDiffImages = Utils.readJSONBool(json, "debug_dump_bw_diff_images", false);
        if (!Utils.readOkFlag())
        {
            debugDumpBWDiffImages = false;
        }
        
        if (!usingBlackWhiteComparison && debugDumpBWDiffImages)
        {
            println("usingBlackWhiteComparison is set to false, so debug_dump_bw_diff_images in config.json cannot be set to true");
            displayMgr.showErrMsg("usingBlackWhiteComparison is set to false, so debug_dump_bw_diff_images in config.json cannot be set to true", true);
            return false;
        }
        
        // THESE ARE ONLY USED FOR DEBUG TESTING - so not error if missing
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
            displayMgr.showErrMsg("Failed to read in streets array from config.json", true);
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
                    displayMgr.showErrMsg("Missing value for street tsid", true);
                    return false;
                }
                streetTSIDs.append(tsid);
            }
        }
        catch(Exception e)
        {
            println(e);
            println("Failed to read (exception) in street array from config.json");
            displayMgr.showErrMsg("Failed to read (exception) in street array from config.json", true);
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
    
    public String readElevenPath()
    {
        return elevenPath;
    }
    
    public String readPersdataQAPath()
    {
        return persdataQAPath;
    }
    
    public int readPercentMatchCriteria()
    {
        return percentMatchCriteria;
    }
    
    public boolean readDebugDumpBWDiffImages()
    {
        return debugDumpBWDiffImages;
    }
    
}