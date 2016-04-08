import java.nio.file.Path;

class StreetInfo
{
    boolean okFlag;
    boolean streetFinished;
    boolean invalidStreet;
    
    // passed to constructor - read in originally from config.json
    String streetTSID;
    
    // Read in from L* file
    JSONArray streetItems;
    String streetName;
    String hubID;
    
    // list of street snaps and associated images
    ArrayList<PNGFile> streetSnaps;
    int streetSnapBeingUsed;
    
    // List of item results - so can sort e.g. on skipped items
    ArrayList<SummaryChanges> itemResults;
    
    // Data read in from each I* file
    int itemBeingProcessed;
    ArrayList<ItemInfo> itemInfo;
    
    // Data read in from G* 
    int geoTintColor;
    int geoContrast;
    int geoTintAmount;
    int geoSaturation;
    int geoBrightness;
    int geoHeight;
    int geoWidth;
    
    // constructor/initialise fields
    public StreetInfo(String tsid)
    {
        okFlag = true;
        
        itemBeingProcessed = 0;
        streetSnapBeingUsed = 0;
        streetFinished = false;
        invalidStreet = false;

        streetTSID = tsid;       
        itemInfo = new ArrayList<ItemInfo>();
        streetSnaps = new ArrayList<PNGFile>();
        itemResults = new ArrayList<SummaryChanges>();
         
        geoTintColor = 0;
        geoContrast = 0;
        geoTintAmount = 0;
        geoSaturation = 0;
        geoBrightness = 0;
        geoHeight = 0;
        geoWidth = 0;
    }
    
    boolean readStreetData()
    {
        // Now read in item list and street from L* file - use the version which has been downloaded/copied to OrigJSONs
        String locFileName = workingDir + File.separatorChar + "OrigJSONs" + File.separatorChar+ streetTSID + ".json";
     
        // First check L* file exists - if it wasn't copied/downloaded, then report that skipping this street
        File file = new File(locFileName);
        if (!file.exists())
        {
            printToFile.printDebugLine(this, "SKIPPING MISSING street location file - " + streetTSID, 3);
            printToFile.printOutputLine("\nSKIPPING - MISSING street location file for " + streetTSID +"\n");
            displayMgr.setSkippedStreetsMsg("Skipping street - Missing location JSON file for TSID " + streetTSID);
            invalidStreet = true;
            return false;
        } 
                
        JSONObject json;
        try
        {
            // load L* file
            json = loadJSONObject(locFileName);
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine(this, "Fail to load street JSON file " + locFileName, 3);
            return false;
        } 
        printToFile.printDebugLine(this, "Reading location file " + locFileName, 2);
        
        // Read in street name
                
        streetName = Utils.readJSONString(json, "label", true);
        if (!Utils.readOkFlag() || streetName.length() == 0)
        {
            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
            printToFile.printDebugLine(this, "Fail to read in street name from street JSON file " + locFileName, 3);
            return false;
        }
  
        printToFile.printDebugLine(this, "Street name is " + streetName, 2);
        
        // Read in the region id
        hubID = Utils.readJSONString(json, "hubid", true);
        if (!Utils.readOkFlag() || hubID.length() == 0)
        {
            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
            printToFile.printDebugLine(this, "Fail to read in hub id from street JSON file " + locFileName, 3);
            return false;
        }
        
        printToFile.printDebugLine(this, "Region/hub id is " + hubID, 2);
    
        // Read in the list of street items
        streetItems = Utils.readJSONArray(json, "items", true);
        if (!Utils.readOkFlag())
        {
            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
            printToFile.printDebugLine(this, "Fail to read in item array in street JSON file " + locFileName, 3);
            return false;
        } 
 
         // Everything OK   
        return true;
    }
    
    public boolean getStreetJSONFiles()
    {
        // Get the street L* file
        if (!getJSONFile(streetTSID))
        {
            // Unable to get L* file
            printToFile.printDebugLine(this, "Failed to copy/download street JSON file for " + streetTSID, 3);
            return false;
        }
        
        // Get the street G* file
        if (!getJSONFile(streetTSID.replaceFirst("L", "G")))
        {
            // Unable to get G* file
            printToFile.printDebugLine(this, "Failed to copy/download street JSON file for " + streetTSID.replaceFirst("L", "G"), 3);
            return false;
        }
        
          // Now read in item list and street from L* file - use the version which has been downloaded/copied to OrigJSONs
        String locFileName = workingDir + File.separatorChar + "OrigJSONs" + File.separatorChar+ streetTSID + ".json";
     
        // First check L* file exists - should only reach this point if the L* file was retrieved successfully, this 
        // should never happen
        File file = new File(locFileName);
        if (!file.exists())
        {
            printToFile.printDebugLine(this, "Unexpected error -  street location file - " + locFileName + " is missing from OrigJSONs directory", 3);
            return false;
        } 
                
        JSONObject json;
        try
        {
            // load L* file
            json = loadJSONObject(locFileName);
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine(this, "Fail to load street JSON file " + locFileName, 3);
            return false;
        } 
    
        // Read in the list of street items
        streetItems = Utils.readJSONArray(json, "items", true);
        if (!Utils.readOkFlag())
        {
            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
            printToFile.printDebugLine(this, "Fail to read in item array in street JSON file " + locFileName, 3);
            return false;
        } 
        
        // Now loop through the item array retrieving each item file  
        for (int i = 0; i < streetItems.size(); i++) 
        {
            String itemTSID = Utils.readJSONString(streetItems.getJSONObject(i), "tsid", true); 
            
            if (!getJSONFile(itemTSID))
            {
                // Unable to get L* file
                printToFile.printDebugLine(this, "Failed to copy/download item JSON file for " + itemTSID, 3);
                return false;
            }  
        }   
             
        // Everything OK
        return true;
    }
       
    public boolean getJSONFile(String TSID)
    {
        String JSONFileName = TSID + ".json";
        String sourcePath; 
        String destPath = workingDir + File.separatorChar + "OrigJSONs" + File.separatorChar + JSONFileName;
        
        if (configInfo.readUseVagrantFlag())
        {
           sourcePath = configInfo.readPersdataPath() + File.separatorChar + JSONFileName;
            // First check file exists in persdata
            File file = new File(sourcePath);
            if (!file.exists())
            {
                // Retrieve from fixtures
                if (TSID.startsWith("L") || TSID.startsWith("G"))
                {
                    sourcePath = configInfo.readFixturesPath() + File.separatorChar + "locations-json" + File.separatorChar + JSONFileName;
                }
                else
                {
                    sourcePath = configInfo.readFixturesPath() + File.separatorChar + "world-items" + File.separatorChar + JSONFileName;
                }
                file = new File(sourcePath);
                if (!file.exists())
                {
                    // Can't get file so give up - error will be reported when do actual processing
                    printToFile.printDebugLine(this, "Unable to find file on vagrant - " + sourcePath, 3);
                    return false;
                }

            }                          
            // copy file to OrigJSONs directory
            if (!copyFile(sourcePath, destPath))
            {
                printToFile.printDebugLine(this, "Unable to copy JSON file - " + sourcePath + " to " + destPath, 3);
                return false;
            }
            printToFile.printDebugLine(this, "Copied JSON file - " + sourcePath + " to " + destPath, 1);
        }
        else
        {
            // Use sftp to download the file from server
            sourcePath = configInfo.readPersdataPath() + "/" + JSONFileName;
            // See if file exists in persdata     
            if (!QAsftp.executeCommand("get", sourcePath, destPath))
            {
                // See if file exists in fixtures
                if (TSID.startsWith("L") || TSID.startsWith("G"))
                {
                    sourcePath = configInfo.readFixturesPath() + "/locations-json/" + JSONFileName;
                }
                else
                {
                    sourcePath = configInfo.readFixturesPath() + "/world-items/" + JSONFileName;
                }
                
                if (!QAsftp.executeCommand("get", sourcePath, destPath))
                {
                    // Can't get JSON file from fixtures either - so give up - error will be reported when do actual processing
                    printToFile.printDebugLine(this, "Unable to find JSON file on server - " + sourcePath, 3);
                    return false;
                }
            } 
            
            printToFile.printDebugLine(this, "Downloaded JSON file - " + sourcePath + " to " + destPath, 1);
        }
        return true;
    }
    
    boolean putStreetItemJSONFiles()
    {
        // Retrieves the list of item files from the L* file - and if they exist in the NewJSONs dir, 
        // then uploads/copies to persdata and moves the file to the UploadedJSONs dir
               
        String locFileName = workingDir + File.separatorChar + "OrigJSONs" + File.separatorChar+ streetTSID + ".json";
     
        // First check L* file exists - if it wasn't copied/downloaded, then this is an error
        File file = new File(locFileName);
        if (!file.exists())
        {
            printToFile.printDebugLine(this, "MISSING street location file in OrigJSONs dir - " + streetTSID, 3);
            failNow = true;
            return false;
        } 
                
        JSONObject json;
        try
        {
            // load L* file
            json = loadJSONObject(locFileName);
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine(this, "Fail to load street JSON file " + locFileName, 3);
            return false;
        } 
        printToFile.printDebugLine(this, "Reading location file " + locFileName, 2);
    
        // Read in the list of street items
        streetItems = Utils.readJSONArray(json, "items", true);
        if (!Utils.readOkFlag())
        {
            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
            printToFile.printDebugLine(this, "Fail to read in item array in street JSON file " + locFileName, 3);
            return false;
        } 
        
         // Now loop through the item array copying files to persdata if they exist in NewJSONs
         // and moving to UploadedJSONs
        for (int i = 0; i < streetItems.size(); i++) 
        {
            String itemTSID = Utils.readJSONString(streetItems.getJSONObject(i), "tsid", true); 
            
            if (!putJSONFile(itemTSID))
            {
                // Unable to copy/upload file
                printToFile.printDebugLine(this, "Failed to copy/upload item JSON file for " + itemTSID, 3);
                return false;
            }  
        }          
 
         // Everything OK   
        return true;
        
    }
    
    boolean putJSONFile(String TSID)
    {
        String JSONFileName = TSID + ".json";
        String sourcePath = workingDir + File.separatorChar + "NewJSONs" + File.separatorChar + JSONFileName; 
        String destPath = workingDir + File.separatorChar + "UploadedJSONs" + File.separatorChar + JSONFileName;
        
        File sFile = new File(sourcePath);
        if (!sFile.exists())
        {
            // If this does not exist in NewJSONs then there is nothing to upload - return success
            return true;
        }
        
        if (configInfo.readUseVagrantFlag())
        {
            // Copy file to persdata
            if (!copyFile(sourcePath, configInfo.readPersdataPath() + File.separatorChar + JSONFileName))
            {
                printToFile.printDebugLine(this, "Unable to copy JSON file - " + sourcePath + " to " + configInfo.readPersdataPath() + File.separatorChar + JSONFileName, 3);
                printToFile.printOutputLine("FAILED TO COPY " + TSID + ".json file to " + configInfo.readPersdataPath());
                return false;
            }
            printToFile.printDebugLine(this, "Success copying " + TSID + ".json file to " + configInfo.readPersdataPath(), 3);
            printToFile.printOutputLine("Success copying " + TSID + ".json file to " + configInfo.readPersdataPath());
        }
        else
        {
            // Use sftp to download the file from server  
            if (!QAsftp.executeCommand("put", sourcePath, configInfo.readPersdataPath() + "/" + JSONFileName))
            {
                 printToFile.printDebugLine(this, "Unable to upload JSON file from " + sourcePath + " to persdata on server - " + configInfo.readPersdataPath() + "/" + JSONFileName, 3);
                 printToFile.printOutputLine("FAILED TO UPLOAD " + TSID + ".json file to " + configInfo.readPersdataPath());
                 return false;   
            } 
            
            printToFile.printDebugLine(this, "Success uploading " + TSID + ".json file to " + configInfo.readPersdataPath(), 3);
            printToFile.printOutputLine("Success uploading " + TSID + ".json file to " + configInfo.readPersdataPath());
        }
        
        // Only reach here if file uploaded OK - so move from     
        // newJSONs to uploadedJSONs directory
        File dFile = new File(destPath);
        if (!sFile.renameTo(dFile))
        {
            printToFile.printDebugLine(this, "Unable to move JSON file from " + sourcePath + " to " + destPath, 3);
            return false;
        }
        printToFile.printDebugLine(this, "Moved JSON file " + JSONFileName + " from " + workingDir + File.separatorChar + "NewJSONs" + " to " + workingDir + File.separatorChar + "UploadedJSONs", 1);
        
        return true;
    } 
    
    boolean readStreetItemData()
    {
        printToFile.printDebugLine(this, "Read item TSID from street L file", 2);   
        // First set up basic information for each street - i.e. item TSID
        for (int i = 0; i < streetItems.size(); i++) 
        {
            itemInfo.add(new ItemInfo(streetItems.getJSONObject(i))); 
            
            // Now read the error flag for the last street item array added
            int total = itemInfo.size();
            ItemInfo itemData = itemInfo.get(total-1);
                       
            if (!itemData.readOkFlag())
            {
               printToFile.printDebugLine(this, "Error parsing item basic TSID information", 3);
               return false;
            }
            
        }
        
        // Now fill in the all the rest of the item information for this street
        int skippedItemCount = 0;
        for (int i = 0; i < streetItems.size(); i++) 
        {                                  
            if (!itemInfo.get(i).initialiseItemInfo())
            {
                // actual error
                printToFile.printDebugLine(this, "Error reading in additional information for item from I* file", 3);
                return false;
            }
            if (itemInfo.get(i).readSkipThisItem())
            {
                skippedItemCount++;
            }
        }

        // Everything OK
        printToFile.printDebugLine(this, " Initialised street = " + streetName + " street TSID = " + streetTSID + " with item count " + str(itemInfo.size()) + " of which " + skippedItemCount + " will be skipped", 2);  
        return true;
    }
    
    boolean readStreetGeoInfo()
    {
        
        // Now read in information about contrast etc from the G* file if it exists - should have been downloaded to OrigJSONs dir
        String geoFileName = workingDir + File.separatorChar + "OrigJSONs" + File.separatorChar + streetTSID.replaceFirst("L", "G") + ".json";  
        // First check G* file exists
        File file = new File(geoFileName);
        if (!file.exists())
        {
            printToFile.printDebugLine(this, "SKIPPING - MISSING street geo file - " + geoFileName, 3);
            printToFile.printOutputLine("\nSKIPPING - MISSING street geo file for " + streetTSID + "\n");
            displayMgr.setSkippedStreetsMsg("Skipping street - Missing geo JSON file for TSID " + streetTSID);
            invalidStreet = true;
            return false;
        } 
                
        JSONObject json;
        try
        {
            // load G* file
            json = loadJSONObject(geoFileName);
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine(this, "Fail to load street geo JSON file " + geoFileName, 3);
            return false;
        } 
        printToFile.printDebugLine(this, "Reading geo file " + geoFileName, 2);

        // Now chain down to get at the fields in the geo file
        geoTintColor = 0;
        geoContrast = 0;
        geoTintAmount = 0;
        geoSaturation = 0;
        geoBrightness = 0;
                
        JSONObject dynamic = Utils.readJSONObject(json, "dynamic", false);
        if (!Utils.readOkFlag() || dynamic == null)
        {
            // the dynamic level is sometimes missing ... so just set it to point at the original json object and continue on
            printToFile.printDebugLine(this, "Reading geo file - failed to read dynamic " + geoFileName, 2);
            if (dynamic == null)
            {
                printToFile.printDebugLine(this, "Reading geo file - dynamic 1 is null " + geoFileName, 2);
            }
            dynamic = json;
            if (dynamic == null)
            {
                printToFile.printDebugLine(this, "Reading geo file - dynamic 2 is null " + geoFileName, 2);
            }
        }
        JSONObject layers = Utils.readJSONObject(dynamic, "layers", true);
        
        if (Utils.readOkFlag() && layers != null)
        {
            JSONObject middleground = Utils.readJSONObject(layers, "middleground", true);
            if (Utils.readOkFlag() && middleground != null)
            {
                // Always read in the w/l values as needed for street snap validation.
                geoWidth = Utils.readJSONInt(middleground, "w", true);
                if (!Utils.readOkFlag() || geoWidth == 0)
                {
                    printToFile.printDebugLine(this, "Failed to read width of street from geo JSON file " + geoFileName, 3);
                    return false;
                }
                geoHeight = Utils.readJSONInt(middleground, "h", true);
                if (!Utils.readOkFlag() || geoHeight == 0)
                {
                    printToFile.printDebugLine(this, "Failed to read height of street from geo JSON file " + geoFileName, 3);
                    return false;
                }
                printToFile.printDebugLine(this, "Geo JSON file " + geoFileName + " gives street snap height " + geoHeight + " snap width " + geoWidth, 1);
                                // Only bother reading in the remaining geo information if not using a black/white comparison method
                if (!usingBlackWhiteComparison)
                {
                    // Don't always have a filtersNew on this layer
                    JSONObject filtersNEW = Utils.readJSONObject(middleground, "filtersNEW", false);
                
                    if (Utils.readOkFlag() && filtersNEW != null)
                    {
                        printToFile.printDebugLine(this, "size of filtersNew is " + filtersNEW.size() + " in " + geoFileName, 2);
                        // extract the fields inside
                        JSONObject filtersNewObject = Utils.readJSONObject(filtersNEW, "tintColor", true);
                        if (Utils.readOkFlag() && filtersNewObject != null)
                        {
                            geoTintColor = filtersNewObject.getInt("value", 0);
                        }
                        filtersNewObject = Utils.readJSONObject(filtersNEW, "contrast", true);
                        if (Utils.readOkFlag() && filtersNewObject != null)
                        {
                            geoContrast = filtersNewObject.getInt("value", 0);
                        }
                        filtersNewObject = Utils.readJSONObject(filtersNEW, "tintAmount", true);
                        if (Utils.readOkFlag() && filtersNewObject != null)
                        {
                            geoTintAmount = filtersNewObject.getInt("value", 0);
                        } 
                        filtersNewObject = Utils.readJSONObject(filtersNEW, "saturation", true);
                        if (Utils.readOkFlag() && filtersNewObject != null)
                        {
                            geoSaturation = filtersNewObject.getInt("value", 0);
                        } 
                        filtersNewObject = Utils.readJSONObject(filtersNEW, "brightness", true);
                        if (Utils.readOkFlag() && filtersNewObject != null)
                        {
                            geoBrightness = filtersNewObject.getInt("value", 0);
                        } 
                    }
                    else
                    {
                        printToFile.printDebugLine(this, "Reading geo file - failed to read filtersNEW " + geoFileName, 2);
                    }
                }// end if !using B&W comparison 
            } // if middleground not null
            else
            {
                // This counts as an error as need the snap size from the file
                 printToFile.printDebugLine(this, "Reading geo file - failed to read middleground " + geoFileName, 3);
                 return false;
            }
         } // layers not null
         else
         {
             printToFile.printDebugLine(this, "Reading geo file - failed to read layers " + geoFileName, 2);
         }
         printToFile.printDebugLine(this, "After reading geo file  " + geoFileName + " TintColor = " + geoTintColor + " TintAmount = " + geoTintAmount +
                                         " geoContrast = " + geoContrast + " geoSaturation = " + geoSaturation + " Brightness = " + geoBrightness, 1);  
          
         // Everything OK   
        return true;
    }
    
    boolean validateStreetSnaps()
    {
        // Using the street name, loads up all the street snaps from the QA snap directory
        // Are only interested in street snaps with the correct h/w which matches the values read from the json geo file
        
        // NB smaller images are removed from the list of snaps automatically
        // Will unload the street snaps immediately - as only interested in the list of valid street snaps for now
        // Work out how many street snaps exist
        String [] snapFilenames = Utils.loadFilenames(configInfo.readStreetSnapPath(), streetName);

        if (snapFilenames == null || snapFilenames.length == 0)
        {
            printToFile.printDebugLine(this, "SKIPPING STREET - No street image files found in " + configInfo.readStreetSnapPath() + " for street " + streetName, 3);
            printToFile.printOutputLine("\nSKIPPING - No street image files found for " + streetName + "(" + streetTSID + ")\n");
            displayMgr.setSkippedStreetsMsg("Skipping street " + streetName + ": No street snaps found");
            invalidStreet = true;
            return false;
        }
        int i;
        StringList archiveSnapFilenames = new StringList();
 
        for (i = 0; i < snapFilenames.length; i++)
        {
            // Go through each name - only keep valid names for this street.
            // Stripping out files which start with the same name, but which are other streets
            // e.g. Tallish Crest/ Tallish Crest Subway Station. Otherwise the size check later 
            // will fail as these streets are different sizes.

            // First deal with specific cases of towers on streets
            // Aranna: Sabudana Drama - Sabudana Drama Towers - Sabudana Drama Towers Basement (unique) - Sabudana Drama Towers Floor 1-4 (unique)
            // Besara: Egret Taun - Egret Taun Towers - Egret Taun Towers Basement (unique) - Egret Taun Towers Floor 1-3 (unique)
            // Bortola: Hauki Seeks - Hauki Seeks Manor - Hauki Seeks Manor Basement (unique) - Hauki Seeks Manor Floor 1-3 (unique)
            // Groddle Meadow: Gregarious Towers - Gregarious Towers Basement (unique) - Gregarious Towers Floor 1-3 (unique)
            // Muufo: Hakusan Heaps - Hakusan Heaps Towers - Hakusan Heaps Towers Basement (unique) - Hakusan Heaps Towers Floor 1-2 (unique)
            if ((streetName.equals("Sabudana Drama")) || (streetName.equals("Egret Taun")) ||
                (streetName.equals("Hauki Seeks")) || (streetName.equals("Hakusan Heaps")))
            {
                // Need to strip out any of the Tower/Manor streets
                if ((snapFilenames[i].indexOf("Towers") == -1) && (snapFilenames[i].indexOf("Manor") == -1))
                {
                    // Is the actual street we want, so copy
                    archiveSnapFilenames.append(snapFilenames[i]);
                }
            }
            if ((streetName.equals("Sabudana Drama Towers")) || (streetName.equals("Egret Taun Towers")) ||
                (streetName.equals("Hauki Seeks Manor")) || (streetName.equals("Hakusan Heaps Towers")) ||
                (streetName.equals("Gregarious Towers")))
            {
                // Need to strip out the Basement/Floors streets
                if ((snapFilenames[i].indexOf("asement") == -1) && (snapFilenames[i].indexOf("loor") == -1))
                {
                    // Is the actual street we want, so copy
                    archiveSnapFilenames.append(snapFilenames[i]);
                } 
            }       
            else if (streetName.indexOf("Subway") == -1)
            { 
                // Street is not a subway - so remove any subway snaps
                if (snapFilenames[i].indexOf("Subway") == -1)
                {
                    // Snap is not the subway station, so keep
                    archiveSnapFilenames.append(snapFilenames[i]);
                }
                
            }
            else
            {
                // Valid subway street snap so keep
                archiveSnapFilenames.append(snapFilenames[i]);

            }
        }
        
        if (archiveSnapFilenames.size() == 0)
        {
            printToFile.printDebugLine(this, "No files found in rebuilt snap array = BUG for street " + streetName, 3);
            return false;
        } 
        
        // Now load up each of the snaps
        int j = 0;
        for (i = 0; i < archiveSnapFilenames.size(); i++) 
        {
            // This currently never returns an error
            streetSnaps.add(new PNGFile(archiveSnapFilenames.get(i), true));
            
            // load up the image
            if (!streetSnaps.get(j).setupPNGImage())
            {
                printToFile.printDebugLine(this, "Failed to load up image " + archiveSnapFilenames.get(i), 3);
                return false;
            }
            
            if (streetSnaps.get(j).readPNGImageWidth() != geoWidth || streetSnaps.get(j).readPNGImageHeight() != geoHeight)
            {
                printToFile.printDebugLine(this, "Skipping street snap " + streetSnaps.get(j).readPNGImageName() + " because resolution is smaller than " + 
                geoWidth + "x" + geoHeight + "pixels", 3);
                streetSnaps.remove(j);
            }
            else 
            {
                // valid snap - so keep and unload
                streetSnaps.get(j).unloadPNGImage();
                j++;
            }
        }  
        
        // If not found any of the right size - then need to return error
        if (streetSnaps.size() == 0)
        {
            printToFile.printDebugLine(this, "SKIPPING STREET - No valid street image files found in " + configInfo.readStreetSnapPath() + " for street " + streetName + " with resolution " + geoWidth + " x " + geoHeight + " pixels", 3);
            printToFile.printOutputLine("\nSKIPPING - No valid street image files found for " + streetName + "(" + streetTSID + ") with resolution " + geoWidth + " x " + geoHeight + " pixels\n");
            displayMgr.setSkippedStreetsMsg("Skipping street " + streetName + ": No valid street snaps found with resolution " + geoWidth + " x " + geoHeight + " pixels");
            invalidStreet = true;
            return false;
        }
        
        printToFile.printDebugLine(this, "Number of valid street snaps is " + streetSnaps.size(), 1);
        // Everything OK
        return true;
    }
    
    public boolean initialiseStreetData()
    {

        // Read in street data - list of item TSIDs 
        if (!readStreetData()) //<>//
        {
            if (invalidStreet)
            {
                // i.e. need to skip this street as location information not available
                printToFile.printDebugLine(this, "Skipping missing location JSON file", 3);
                printToFile.printOutputLine("SKIPPING STREET - missing location JSON file for TSID " + streetTSID);
                return true; // continue
            }
            else
            {
                // error - need to stop
                printToFile.printDebugLine(this, "Error in readStreetData", 3);
                okFlag = false;
                return false;
            }
        }

        displayMgr.setStreetName(streetName, streetTSID, streetBeingProcessed + 1, configInfo.readTotalJSONStreetCount());
        displayMgr.showStreetName();
        displayMgr.showStreetProcessingMsg();
        
        // Read in the G* file and load up the contrast settings etc (currently not used as searching on black/white)
        if (!readStreetGeoInfo())
        {
            if (invalidStreet)
            {
                // i.e. need to skip this street as location information not available
                printToFile.printDebugLine(this, "Skipping missing geo JSON file", 3);
                printToFile.printOutputLine("SKIPPING STREET - missing geo JSON file for TSID " + streetTSID);
                return true; // continue
            }
            else
            {
                // error - need to stop
                printToFile.printDebugLine(this, "Error in readStreetGeoInfo", 3);
                okFlag = false;
                return false;
            }
        }
        
        if (!validateStreetSnaps())
        {
            if (invalidStreet)
            {
                // i.e. need to skip this street as missing street snaps for street
                printToFile.printDebugLine(this, "Skipping street - missing/invalid street snaps", 3);
                return true; // continue
            }
            else
            {
                // error - need to stop
                printToFile.printDebugLine(this, "Error loading up street snaps for " + streetName, 3);
                okFlag = false;
                return false;
            }
        }
       
        return true;
    }
    
    
    public void processItem()
    {

        // Skip items that we're not interested in, or items which have been already found (and which are not quoins/QQ)
        if (!itemValidToContinueSearchingFor(itemBeingProcessed))
        {
            // Item needs to be skipped/or has already been found
            // Move onto next one
            printToFile.printDebugLine(this, "Skipping item " + itemInfo.get(itemBeingProcessed).readItemClassTSID() + "(" + 
                                       itemInfo.get(itemBeingProcessed).readOrigItemExtraInfo() + ") " + itemInfo.get(itemBeingProcessed).readItemTSID(), 1);
                                       
            // As we just want to pass control back up, don't care about the succes/failure - top level will handle that
            if (moveToNextItem())
            {
            }
            return;
        }
       
        //printToFile.printDebugLine(this, "Enter processItem memory ", 1);
        //memory.printMemoryUsage();
        
        // Does the main work - passes control down to the item structure
        //ItemInfo itemData = itemInfo.get(itemBeingProcessed);      
        
        // Display information
        //displayMgr.setStreetName(streetName, streetTSID, streetBeingProcessed + 1, configInfo.readTotalJSONStreetCount());
        displayMgr.setItemProgress(itemInfo.get(itemBeingProcessed).itemClassTSID, itemInfo.get(itemBeingProcessed).itemTSID, itemBeingProcessed+1, itemInfo.size());
        
        // Search the snap for this image/item
        if (!itemInfo.get(itemBeingProcessed).searchSnapForImage())
        {
             failNow = true;
             return;
        }
        
        if (itemInfo.get(itemBeingProcessed).readItemFinished())
        {            
            // Move onto next one
            if (!moveToNextItem())
            {
                // Either error condition or at end of street/items - so need to return to top level to start over with new snap/street
                //failNow = true;
                return;
            }
            else
            {
                // Next item is safe to procced to
                       
                // Set up fragFind in item ready to start the next item/streetsnap search combo
                // i.e. loads up pointers to correct street snap and item images
                // Only do this for items we still need to search for
                if (itemValidToContinueSearchingFor(itemBeingProcessed))
                {
                    if (!itemInfo.get(itemBeingProcessed).resetReadyForNewItemSearch())
                    {
                        failNow = true;
                        return;
                    }
                    printToFile.printDebugLine(this, "PROCESSING ITEM " + itemBeingProcessed + " ON STREET SNAP " + streetSnapBeingUsed, 1);
                }
                else
                {
                   printToFile.printDebugLine(this, "Skipping item/item Found " + itemInfo.get(itemBeingProcessed).readItemClassTSID() + "(" + 
                                               itemInfo.get(itemBeingProcessed).readOrigItemExtraInfo() + ") " + 
                                               itemInfo.get(itemBeingProcessed).readItemTSID(), 1); 
                }
            }
            
        }
        //printToFile.printDebugLine(this, "Exit 2 processItem memory ", 1);
        //memory.printMemoryUsage();

    }
    
    boolean moveToNextItem()
    {
        // Handles all the checking to see if past end of of item count, and whether more snaps to process
        // Returns true - if OK to handle the next item on the street
        // Returns false for error conditions, or if moving on to next street/street snap - calling function needs to check failNow flag
        itemBeingProcessed++;
        if (itemBeingProcessed >= itemInfo.size())
        {
            // Finished all items on the street
            // So move onto the next street snap after unloading the current one
            streetSnaps.get(streetSnapBeingUsed).unloadPNGImage();
              
            streetSnapBeingUsed++;
            if (streetSnapBeingUsed >= streetSnaps.size() || ifAllItemsFound())
            {
                // Reached end of street snaps so mark street as finished OR all the valid items have been found
                // First need to write all the item changes to file
                for (int i = 0; i < itemInfo.size(); i++)
                {
                    
                    // Now save the item changes
                    if (!itemInfo.get(i).saveItemChanges())
                    {
                        failNow = true;
                        return false;
                    }
                    // Add info to the results array for subsequent printing out
                    itemResults.add(new SummaryChanges(itemInfo.get(i)));
                }
                
                
                streetFinished = true;
                
                // Now print out the summary array
                if (! printToFile.printSummary(itemResults))
                {
                    failNow = true;
                    return false;
                }

                //printToFile.printDebugLine(this, "Exit 1 processItem memory ", 1);
                //memory.printMemoryUsage();
                return false;
            }
            else
            {
                // Start with the first item again on the new street snap
                if (!loadStreetImage(streetSnapBeingUsed))
                {
                    failNow = true;
                    return false;
                }
                itemBeingProcessed = 0;
                printToFile.printDebugLine(this, "STARTING WITH FIRST ITEM ON STREET SNAP " + streetSnapBeingUsed, 1);
                
                if (itemValidToContinueSearchingFor(itemBeingProcessed))
                {
                    if (!itemInfo.get(itemBeingProcessed).resetReadyForNewItemSearch())
                    {
                        failNow = true;
                        return false;
                    }
                    printToFile.printDebugLine(this, "PROCESSING ITEM " + itemBeingProcessed + " ON STREET SNAP " + streetSnapBeingUsed, 1);
                }
                
            }
            //return false;
            
        } // if past end of item list
        else
        {
            // Valid next item found - reset ready for the search to happen
            if (itemValidToContinueSearchingFor(itemBeingProcessed))
            {
                if (!itemInfo.get(itemBeingProcessed).resetReadyForNewItemSearch())
                {
                    failNow = true;
                    return false;
                }
                printToFile.printDebugLine(this, "PROCESSING ITEM " + itemBeingProcessed + " ON STREET SNAP " + streetSnapBeingUsed, 1);
            }
        }
        return true;
    }
    
    boolean ifAllItemsFound()
    {
        boolean allFound = true;
        for (int i = 0; i < itemInfo.size(); i++)
        { 
           if (itemValidToContinueSearchingFor(i))
           {
               // Item is valid for searching BUT has not been found
               allFound = false;
           }
        }
        return allFound;
    }
    
    boolean itemValidToContinueSearchingFor(int n)
    {
        //println("itemBeingProcessed is ", n);
        if (itemInfo.get(n).readSkipThisItem())
        {
            // Item is not one we ever search for e.g. street spirit
            return false;
        }
        else if (itemInfo.get(n).readItemFound())
        {
            // Item has been found - for non quoins/QQ, the search ends once it has been found
            if (!itemInfo.get(n).readItemClassTSID().equals("quoin") &&
                    !itemInfo.get(n).readItemClassTSID().equals("marker_qurazy"))
            {
                return false;
            }
        }
        return true;
    }
    
    // Simple functions to read/set variables
    public boolean readStreetFinished()
    {
        return streetFinished;
    }
    
    public boolean readOkFlag()
    {
        return okFlag;
    } 
    
    public String readStreetName()
    {
        return streetName;
    }
    
    public String readHubID()
    {
        return hubID;
    }
    
    public String readStreetTSID()
    {
        return streetTSID;
    }
    
    public PNGFile readCurrentStreetSnap()
    {
        if (streetSnaps.get(streetSnapBeingUsed).readPNGImage() == null)
        {
            printToFile.printDebugLine(this, "readCurrentStreetSnap - Null street image pointer for current street snaps " + streetSnapBeingUsed, 3);
        }
        return streetSnaps.get(streetSnapBeingUsed);
    }
          
    public boolean loadStreetImage(int n)
    {
        if (!streetSnaps.get(n).loadPNGImage())
        {
            return false;
        }
        if (streetSnaps.get(n).readPNGImage() == null)
        {
            printToFile.printDebugLine(this, "Null street image pointer returned from loadPNGImage for current street snaps " + streetSnapBeingUsed, 3);
            return false;
        }
        return true;
    }
    
    public void initStreetItemVars()
    {
        for  (int i = 0; i < itemInfo.size(); i++)
        {
            itemInfo.get(i).initItemVars();
        }
    }
    
    public boolean readInvalidStreet()
    {
        return invalidStreet;
    }
    
    public int readGeoTintColor()
    {
            return geoTintColor;
    }

    public int readGeoContrast()
    {
        return geoContrast;
    }
    
    public int readGeoTintAmount()
    {
        return geoTintAmount;
    }
     
    public int readGeoSaturation()
    {
        return geoSaturation;
    }
    
    public int readGeoBrightness()
    {
        return geoBrightness;
    }
    
    public int readGeoHeight()
    {
        return geoHeight;
    }
    
    public int readGeoWidth()
    {
        return geoWidth;
    }
    
}