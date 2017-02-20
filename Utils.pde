import java.io.File;
import java.io.FilenameFilter;

static boolean okFlag;
static String errMsg;

static class Utils
{
    
    // Loads up a list of png files with the right street name 
    // NB The names return do not include the path, just the filename
    static public String[] loadFilenames(String path, final String nameToFind, final String fileSuffix) 
    {
        File folder = new File(path);
 
        FilenameFilter filenameFilter = new FilenameFilter() 
        {
            public boolean accept(File dir, String name) 
            {
                if (name.startsWith(nameToFind) && name.toLowerCase().endsWith(fileSuffix))
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
        };
  
        return folder.list(filenameFilter);
    }
    
    // My version for reading/setting values in JSON file - so all error checking done here    
    static public String readJSONString(JSONObject jsonFile, String key, boolean reportError)
    {
        okFlag = true;
        
        if (key.length() == 0)
        {
            okFlag = false;
            errMsg = "Null key passed to readJSONString";
            return "";
        }
        
        // Don't always want to report an error - sometimes just checking to see if key needs
        // to be added
        String readString = "";
        try
        {
            if (jsonFile.isNull(key) == true) 
            {
                if (reportError)
                {
                    errMsg = "Missing key " + key + " in json file";
                }
                okFlag = false;
                return "";
            }
            readString = jsonFile.getString(key, "");
        }
        catch(Exception e)
        {
            if (reportError)
            {
                println(e);
                errMsg = "Failed to read string from json file with key " + key;
            }
            okFlag = false;
            return "";
        }
        if (readString.length() == 0)
        {
            // Leave error reporting up to calling function
            return "";
        }
        return readString;
    }

    
    static public int readJSONInt(JSONObject jsonFile, String key, boolean reportError)
    {
        okFlag = true;
        
        if (key.length() == 0)
        {
            okFlag = false;
            errMsg = "Null key passed to readJSONInt";
            return 0;
        }
        // Don't always want to report an error - sometimes just checking to see if key needs
        // to be added
        int readInt;
        try
        {
            if (jsonFile.isNull(key) == true) 
            {
                if (reportError)
                {
                    errMsg = "Missing key " + key + " in json file";
                }
                okFlag = false;
                return 0;
            }
            readInt = jsonFile.getInt(key, 0);
        }
        catch(Exception e)
        {
            if (reportError)
            {
                println(e);
                errMsg = "Failed to read int from json file with key " + key;
            }
            okFlag = false;
            return 0;
        }

        return readInt;
    }
    
    static public boolean readJSONBool(JSONObject jsonFile, String key, boolean reportError)
    {
        okFlag = true;
        
        if (key.length() == 0)
        {
            okFlag = false;
            errMsg = "Null key passed to readJSONBool";
            return false;
        }
        // Don't always want to report an error - sometimes just checking to see if key needs
        // to be added
        boolean readBool;
        try
        {
            if (jsonFile.isNull(key) == true) 
            {
                if (reportError)
                {
                    errMsg = "Missing key " + key + " in json file";
                }
                okFlag = false;
                return false;
            }
            readBool = jsonFile.getBoolean(key, false);
        }
        catch(Exception e)
        {
            if (reportError)
            {
                println(e);
                errMsg = "Failed to read boolean from json file with key " + key;
            }
            okFlag = false;
            return false;
        }

        return readBool;
    }
    
    static public JSONObject readJSONObject(JSONObject jsonFile, String key, boolean reportError)
    {
        okFlag = true;
        
        if (key.length() == 0)
        {
            okFlag = false;
            errMsg = "Null key passed to readJSONObject";
            return null;
        }
        // Don't always want to report an error - sometimes just checking to see if key needs
        // to be added
        JSONObject readObj;
        try
        {
            if (jsonFile.isNull(key) == true) 
            {
                if (reportError)
                {
                    errMsg = "Missing JSON object key " + key + " in json file";
                }
                okFlag = false;
                return null;
            }
            readObj = jsonFile.getJSONObject(key); 
        }
        catch(Exception e)
        {
            if (reportError)
            {
                println(e);
                errMsg = "Failed to read JSON object from json file with key " + key;
            }
            okFlag = false;
            return null;
        }

        return readObj;
    }
    
    static public JSONObject readJSONObjectFromJSONArray(JSONArray jsonArray, int index, boolean reportError)
    {
        okFlag = true;
        
        if (index < 0 || index >= jsonArray.size())
        {
            okFlag = false;
            errMsg = "Index " + index + " passed to read JSONArray is out of bounds - less than 0 or greater than " + str(jsonArray.size()-1);
            return null;
        }

        // Don't always want to report an error - sometimes just checking to see if key needs
        // to be added
        JSONObject readObj;
        try
        {
            readObj = jsonArray.getJSONObject(index); 
        }
        catch(Exception e)
        {
            if (reportError)
            {
                println(e);
                errMsg = "Failed to read JSON object from json array with index " + index;
            }
            okFlag = false;
            return null;
        }

        return readObj;
    }
   
    static public JSONArray readJSONArray(JSONObject jsonFile, String key, boolean reportError)
    {
        okFlag = true;
        if (key.length() == 0)
        {
            okFlag = false;
            errMsg = "Null key passed to readJSONArray";
            return null;
        }
        // Don't always want to report an error - sometimes just checking to see if key needs
        // to be added
        JSONArray readArray;
        try
        {
            if (jsonFile.isNull(key) == true) 
            {
                if (reportError)
                {
                    errMsg = "Missing JSON array key " + key + " in json file";
                }
                okFlag = false;
                return null;
            }
            readArray = jsonFile.getJSONArray(key);
        }
        catch(Exception e)
        {
            if (reportError)
            {
                println(e);
                errMsg = "Failed to read JSON array from json file with key " + key;
            }
            okFlag = false;
            return null;
        }

        return readArray;
    }
        
    static public boolean setJSONInt(JSONObject jsonFile, String key, int value)
    {
        okFlag = true;
        
        if (key.length() == 0)
        {
            okFlag = false;
            errMsg = "Null key passed to setJSONInt";
            return false;
        }
                              
        try
        {
            // OK for key to be absent, will just be inserted
            //if (jsonFile.isNull(key) == true) 
            //{
            //    printToFile.printDebugLine(this, "Missing key " + key + " in json file", 3);
            //    return false;
            //}
            jsonFile.setInt(key, value);
        }
        catch(Exception e)
        {
            println(e);
            errMsg = "Failed to set int in json file with key " + key + " and value " + value;
            return false;
        }

        return true;
    }
        
    static public boolean setJSONString(JSONObject jsonFile, String key, String value)
    {
    
        okFlag = true;
        
        if (key.length() == 0)
        {
            okFlag = false;
            errMsg = "Null key passed to setJSONString";
            return false;
        }
                                
        try
        {
            // OK for key to be absent, will just be inserted
            //if (jsonFile.isNull(key) == true) 
            //{
            //    printToFile.printDebugLine(this, "Missing key " + key + " in json file", 3);
            //    return false;
            //}
            jsonFile.setString(key, value);
        }
        catch(Exception e)
        {
            println(e);
            errMsg = "Failed to set String in json file with key " + key + " and value " + value;
            return false;
        }

        return true;
    }
    
    static public String formatItemInfoString(String itemInfo)
    {
        // Simply returns the field, if present, inside brackets
        String s = "";
        if (itemInfo.length() > 0)
        {
            s = " (" + itemInfo + ")";
        }

        return s;
    }
        
    static public boolean readOkFlag()
    {
        return okFlag;
    }
        
    static public String readErrMsg()
    {
        return errMsg;
    }
    
    static public boolean setupDir(String dirName, boolean keepFileContents)
    {
        File myDir = new File(dirName);
        if (!myDir.exists())
        {
            // create directory
            try
            {
                myDir.mkdir();
            }
            catch(Exception e)
            {
                println(e);
                errMsg = "Failed to create " + dirName + " folder";
                return false;
            } 
        
        }
        else
        {
            // Delete all the contents of the file - if not keeping the contents for debug purposes
            if (!keepFileContents)
            {
                File[] contents = myDir.listFiles();
                if (contents != null) 
                {
                    for (int i=0; i< contents.length; i++)
                    {
                        try
                        {
                            if (!contents[i].delete())
                            {
                                errMsg = "Failed to delete file in " + dirName + " folder";
                                return false;
                            }
                        }
                        catch (SecurityException e)
                        {
                            println(e);
                            errMsg = "Security Exception - Failed to delete file in " + dirName + " folder";
                            return false;
                        }
                    }
                }
            }
        }
        return true;
    }
    
    static public boolean deleteDir(String dirName)
    {
        File myDir = new File(dirName);
        if (myDir.exists())
        {
            File[] contents = myDir.listFiles();
            if (contents != null) 
            {
                for (int i=0; i< contents.length; i++)
                {
                    try
                    {
                        if (!contents[i].delete())
                        {
                            errMsg = "Failed to delete file in " + dirName + " folder";
                            return false;
                        }
                    }
                    catch (SecurityException e)
                    {
                        println(e);
                        errMsg = "Security Exception - Failed to delete file in " + dirName + " folder";
                        return false;
                    }
                }
            }

            // Can now delete the directory itself
            try
            {
                if (!myDir.delete())
                {
                    errMsg = "Failed to delete " + dirName + " folder";
                    return false;
                }
            }
            catch (SecurityException e)
            {
                println(e);
                errMsg = "Security Exception - Failed to delete " + dirName + " folder";
                return false;
            }
        }
        return true;
    }
    
    static public float distanceBetweenX1Y1_X2Y2(int x1, int y1, int x2, int y2)
    {
         int xd = x1 - x2;
         int yd = y1 - y2;
         return (sqrt((xd * xd) + (yd * yd)));
    }
    


}