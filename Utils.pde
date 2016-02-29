import java.io.File;
import java.io.FilenameFilter;

static boolean okFlag;
static int byteCount;
static String errMsg;

static class Utils
{
    
    // Loads up a list of png files with the right street name 
    // NB The names return do not include the path, just the filename
    static public String[] loadFilenames(String path, final String nameToFind) 
    {
        File folder = new File(path);
 
        FilenameFilter filenameFilter = new FilenameFilter() 
        {
            public boolean accept(File dir, String name) 
            {
                if (name.startsWith(nameToFind) && name.toLowerCase().endsWith(".png"))
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
        // In addition to writing the value to file, it also records the expected JSON file size difference as result
        // of this change
        // Calling function needs to read this value
        okFlag = true;
        byteCount = 0;
        
        if (key.length() == 0)
        {
            okFlag = false;
            errMsg = "Null key passed to setJSONInt";
            return false;
        }
              
        int existingValue = readJSONInt(jsonFile, key, false);
        if (!okFlag)
        {
            // this is a new key to be added
            // Will be of form "'key_name': int_val,"
            // Exclude " and spaces
            byteCount = key.length() + 1 + str(value).length() + 2; // include extra EOL char as well as comma
        }
        else
        {
            // updating key, so only need to take into account difference in value size e.g. 99 changing to 100
            byteCount = str(value).length() - str(existingValue).length();
        }
                
        try
        {
            // OK for key to be absent, will just be inserted
            //if (jsonFile.isNull(key) == true) 
            //{
            //    printToFile.printDebugLine("Missing key " + key + " in json file", 3);
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
    
        // In addition to writing the value to file, it also records the expected JSON file size difference as result
        // of this change
        // Calling function needs to read this value
        okFlag = true;
        byteCount = 0;
        String cleanKey = key;
        String cleanValue = value;
        String cleanExistingValue;
        
        if (key.length() == 0)
        {
            okFlag = false;
            errMsg = "Null key passed to setJSONString";
            return false;
        }
        
        // Clean spaces and " out of the key/value for subsequent file length checking
        // Means that a field which is set to a string will be the same 'length' as one
        // set to an int. Only used for sanity checking file lengths and is needed because the original 
        // json files often had fields such as benefit_ceil set to int, whereas the /qasave tool
        // sets this field as a string (which matches quoin.js).
        cleanKey = cleanKey.replaceAll(" ", "");
        cleanKey = cleanKey.replaceAll("\"", "");
        cleanValue = cleanValue.replaceAll(" ", "");
        cleanValue = cleanValue.replaceAll("\"", "");
              
        String existingValue = readJSONString(jsonFile, key, false);
        cleanExistingValue = existingValue.replaceAll(" ", "");
        cleanExistingValue = existingValue.replaceAll("\"", "");
        
        if (!okFlag)
        {
            // this is a new key to be added
            // Will be of form 'key_name': 'value_str',
            // Exclude " and spaces
            //byteCount = key.length() + 1 + value.length() + 2; // include extra EOL char and comma
            byteCount = cleanKey.length() + 1 + cleanValue.length() + 2; // include extra EOL char and comma
            println("Adding new key ", key, " with value <", value, "> change in JSON = ", byteCount);
        }
        else if (existingValue.length() == 0)
        {
            // this is a new key to be added ?????
            // Will be of form 'key_name': 'value_str',  ?????? so will need to reduce char count added
            byteCount = 1 + key.length() + 4 + value.length() + 3; // include extra EOL char
            okFlag = false;
            errMsg = "ERROR Existing key has no value assigned " + key + " with value <" + value + "> change in JSON = " + byteCount;
            return false;
        }
        else
        {
            // updating key, so only need to take into account difference in value size e.g. "left" changing to "right"
            //byteCount = value.length() - existingValue.length();
            byteCount = cleanValue.length() - cleanExistingValue.length();
            println("Changing key ", key, " with value <", value, "> change in JSON = ", byteCount);
        }
                        
        try
        {
            // OK for key to be absent, will just be inserted
            //if (jsonFile.isNull(key) == true) 
            //{
            //    printToFile.printDebugLine("Missing key " + key + " in json file", 3);
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
    
    static public boolean readOkFlag()
    {
        return okFlag;
    }
    
    static public int readByteCount()
    {
        return byteCount;
    }
    
    static public String readErrMsg()
    {
        return errMsg;
    }

}