import java.util.Collections;
import java.util.List;
import processing.data.JSONObject;


class JSONDiff
{
    // Compares two JSON files - printing out any differences.
    // Will only be done in debug mode
    
    // Using list of information strings - so that if nothing found, just get simple one line message
    // User has to request the information be printed
    StringList infoMsgList;
    String itemTSID;
    JSONObject origJSON;
    JSONObject newJSON;
    String origFileName;
    String newFileName;
    // Set by the function that works out what type of object we have - so that I can return a boolean to handle success/failure
    Object extractedObject;

    public JSONDiff(String iTSID, String origJSONFileName, String newJSONFileName)
    {
        infoMsgList = new StringList();
        itemTSID = iTSID;
        origJSON = null;
        newJSON = null;
        origFileName = origJSONFileName;
        newFileName = newJSONFileName;
        extractedObject = null;
    }

    public boolean compareJSONFiles()
    { 
        String s;
        // Does the actual compare
        if (!loadJSONFiles())
        {
            return false;
        }
        
        s = "JSONDIFF: Starting compare of item file " + itemTSID + ".json";  
        infoMsgList.append(s);
        
        if (!compareJSONObjects(origJSON, newJSON, ""))
        {
            s = "JSONDIFF: ERROR found in comparison of new/old " + itemTSID + ".json";
            infoMsgList.append(s);
            return false;
        }
        s = "JSONDIFF: Completed compare of item file " + itemTSID + ".json";       
        infoMsgList.append(s);
        
        return true;
    }

    boolean loadJSONFiles()
    {
        File file = new File(newFileName);
        if (!file.exists())
        {
            printToFile.printDebugLine(this, "JSONDIFF: Temporary copy of new JSON file " + newFileName + " does not exist", 3);
            return false;
        }
        
        try
        {
            newJSON = loadJSONObject(newFileName);
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine(this, "Failed to load new JSON file " + newFileName, 3);
            return false;
        }
        
        file = new File(origFileName);
        if (!file.exists())
        {
            printToFile.printDebugLine(this, "Temporary copy of original JSON file " + newFileName + " does not exist", 3);
            return false;
        }
        try
        {
            origJSON = loadJSONObject(origFileName);
        }
        catch(Exception e)
        {
            println(e);
            printToFile.printDebugLine(this, "Failed to load original JSON file " + newFileName, 3);
            return false;
        }
        
        return true;
    }

    // Passing in the two JSON objects and the level we are currently searching at (used for information printing)
    boolean compareJSONObjects(JSONObject origVersion, JSONObject newVersion, String level)
    {
        String s;
        // Sort the keys in both objects
        List<String> newList = new ArrayList(newVersion.keys());
        Collections.sort(newList);
        List<String> origList = new ArrayList(origVersion.keys());
        Collections.sort(origList);
    
        s = "JSONDIFF: Keys in the JSON files " + origList.size() + " in original, " + newList.size() + " in new file";
        //infoMsgList.append(s);

        // Need to handle case where new JSON file may have additional keys in (I never delete them)
        // So need to handle the loop counter for the new/origList separately, but use the newList
        // as the master 
        // i for new, j for old
        int i;
        int j;
        for (i = 0, j = 0; i < newList.size() || j < origList.size(); i++, j++)
        {
            // These don't work in Processing - so have to use exception handling to extract the object type
            //Object newObj = newVersion.get(newList.get(i));
            //Object origObj = origVersion.get(origList.get(i));
            
            // Search for matching keys in file - trying to find a match in origList for the new key
            while (!newList.get(i).equals(origList.get(j)) && (i < newList.size()))
            {
                s = "JSONDIFF: New key in new JSON file is " + newList.get(i);
                infoMsgList.append(s);
                i++;
            }
            
            if (!newList.get(i).equals(origList.get(j)))
            {
                // Still don't have a match. This is OK if at end of new file - implies new key at end of new file
                // But if in the middle of the original JSON implies we have deleted a key = error
                if (j < origList.size())
                {
                    // in middle of old file, should have found a match for i
                    s = "JSONDIFF: New key (" +  origList.get(j) + ") in old file = error (as have deleted key from the new file)";
                    infoMsgList.append(s);
                    return false;
                }
                else if (i >= newList.size())
                {
                    // New key at end of file - so can return true as nothing to compare at this point 
                    s = "JSONDIFF: New key (" +  newList.get(j) + ") at end of new file";
                    infoMsgList.append(s);
                    return true;
                }
            }

            // If we get here then we have two keys with the same name
            if (!extractObjectFromJSONObject(origVersion, origList, j))
            {
                // Unexpected type of object in JSON
                return false;
            }
            Object origObj = extractedObject; // set by extractObjectFromJSONObject
            if (!extractObjectFromJSONObject(newVersion, newList, i))
            {
                // Unexpected type of object in JSON
                return false;
            }
            Object newObj = extractedObject;  // set by extractObjectFromJSONObject      
     
            if (newObj instanceof JSONObject && origObj instanceof JSONObject)
            {
                if (!compareJSONObjects((JSONObject)origObj, (JSONObject)newObj, level + "/" + newList.get(i)))
                {
                    s = "JSONDIFF: ERROR found in " + itemTSID + ".json, at level " + level + "/" + newList.get(i) + "New key i is " + newList.get(i) +  " orig key j is " + origList.get(j);
                    infoMsgList.append(s);
                }
            }
            else if (newObj instanceof JSONObject || origObj instanceof JSONObject)
            {
                s = "JSONDIFF: Error - only one of new key and old key is a JSONObject" + "New key i is " + newList.get(i) +  " orig key j is " + origList.get(j);
                infoMsgList.append(s);
                return false;
            }
            else if (newObj instanceof JSONArray && origObj instanceof JSONArray)
            {
                if (!compareJSONArrays((JSONArray)origObj, (JSONArray)newObj, level + "/" + newList.get(i)))
                {
                    s = "JSONDIFF: ERROR found in " + itemTSID + ".json, at level " + level + "/" + newList.get(i) + "New key i is " + newList.get(i) +  " orig key j is " + origList.get(j);
                    infoMsgList.append(s);
                } 
            }
            else if (newObj instanceof JSONArray || origObj instanceof JSONArray)
            {
                s = "JSONDIFF: Error - only one of new key and old key is a JSONArray" + "New key i is " + newList.get(i) +  " orig key j is " + origList.get(j);
                infoMsgList.append(s);
                return false;
            }
            else
            {
                // string/int/bool
                if (!newObj.equals(origObj))
                {
                    // Difference found in values for key
                    s = "JSONDIFF: Different values found for " + level + "/" + newList.get(i) + " new value is <" + newObj + "> was <" + origObj + ">";
                    infoMsgList.append(s);
                }
                else
                {
                    s = "JSONDIFF: Same values found for " + level + "/" + newList.get(i) + " new value is <" + newObj + "> was <" + origObj + ">";
                    //infoMsgList.append(s);
                }
            }
        }
        return true;
    }

    boolean compareJSONArrays(JSONArray origVersion, JSONArray newVersion, String level)
    {
        String s;
        
        // Will just go through the arrays, entry by entry.
        if (origVersion.size() != newVersion.size())
        {
            s = "JSONDIFF: JSON arrays are not the same size - an element has been added/deleted";
            infoMsgList.append(s);
            return false;
        }
    
    
        int i;
        for (i = 0; i < newVersion.size(); i++)
        {
            // These don't work in Processing - so have to use exception handling to extract the object type
            //Object newObj = newVersion.get(newList.get(i));
            //Object origObj = origVersion.get(origList.get(i)); 
            if (!extractObjectFromJSONArray(origVersion, i))
            {
                // unexpected object in array
                return false;
            }
            Object origObj = extractedObject; // set by extractObjectFromJSONarray
            if (!extractObjectFromJSONArray(newVersion, i))
            {
                // unexpected object in array
                return false;
            }
            Object newObj = extractedObject; // set by extractObjectFromJSONarray                

            if (newObj instanceof JSONArray && origObj instanceof JSONArray)
            {
                if (!compareJSONArrays((JSONArray)origObj, (JSONArray)newObj, level + "/" + i))
                {
                    s = "JSONDIFF: ERROR found in " + itemTSID + ".json, at level " + level + "/" + i + " index i is " + i;
                    infoMsgList.append(s);
                }
            }
            else if (newObj instanceof JSONArray || origObj instanceof JSONArray)
            {
                s = "JSONDIFF: Error - only one of new object and old object is a JSONArray" + " index i is " + i;
                infoMsgList.append(s);
                return false;
            }
            else if (newObj instanceof JSONObject)
            {
                if (!compareJSONObjects((JSONObject)origObj, (JSONObject)newObj, level + "/" + i))
                {
                    s = "JSONDIFF: ERROR found in " + itemTSID + ".json, at level " + level + "/" +i + " index i is " + i;
                    infoMsgList.append(s);
                }
            }
            else
            {
                // string/int/bool
                if (!newObj.equals(origObj))
                {
                    // Difference found in values in array
                    s = "JSONDIFF: Different values found for " + level + "/" + i + " new value is <" + newObj + "> was <" + origObj + ">";
                    infoMsgList.append(s);
                }
                else
                {
                    s = "JSONDIFF: Same values found for " + level + "/" + i + " new value is <" + newObj + "> was <" + origObj + ">";
                    //infoMsgList.append(s);
                }
            }       

        }
        return true;
    }

    // This is very hokey code which simply helps determing what kind of object we are dealing with
    // Couldn't find any other way of doing this given that we could not use the Object.get() method
    // in Processing - see https://github.com/processing/processing/issues/4334
    
    // As I need to return an error status from this function, a global variable is used to store the successfully 
    // returned object, and then used by the calling function.
    
    boolean extractObjectFromJSONObject(JSONObject thisJSON, List<String> thisList, int i)
    {
        JSONObject jsonObj = null;
        String strObj = "";
        JSONArray arrayObj = null;
        boolean boolObj = false;
        int intObj = -9999;
        String s;

        extractedObject = null;
        
        //Object newObj = thisJSON.get(thisList.get(i));
        try 
        {
            jsonObj = thisJSON.getJSONObject(thisList.get(i));
        }
        catch(Exception e)
        {   
            // So this is not a JSONObject ... so try to see if it is an array
            try 
            {
                arrayObj = thisJSON.getJSONArray(thisList.get(i));
            }
            catch(Exception e1)
            {               
                // Is not JSONObject or JSONArray - so just read as String (which will safely convert an int/bool for our purposes)
                try
                {
                    strObj = thisJSON.getString(thisList.get(i));
                }
                catch(Exception e2)
                {
                    try
                    {
                        // Is not JSONObject or JSONArray or String
                        boolObj = thisJSON.getBoolean(thisList.get(i));
                    }
                    catch(Exception e3)
                    {
                        try
                        {
                            // Is not JSONObject or JSONArray or String, or boolean - so try the final type of Int
                            intObj = thisJSON.getInt(thisList.get(i));
                        }
                        catch (Exception e4)
                        {
                            println(e4);
                            s = "JSONDIFF: Unexpected field type for key " + thisList.get(i);
                            infoMsgList.append(s);
                            return false;
                        }
                        extractedObject = intObj;
                        return true;
                    }
                    extractedObject = boolObj;
                    return true;
                }
                extractedObject = strObj;
                return true;
            }
            extractedObject = arrayObj;
            return true;
        }
        extractedObject = jsonObj;
        return true;
    }

    // This is very hokey code which simply helps determing what kind of object we are dealing with
    // Couldn't find any other way of doing this given that we could not use the Object.get() method
    // in Processing - see https://github.com/processing/processing/issues/4334
    
    // As I need to return an error status from this function, a global variable is used to store the successfully 
    // returned object, and then used by the calling function.
    
    boolean extractObjectFromJSONArray(JSONArray thisJSON, int i)
    {
        JSONObject jsonObj = null;
        String strObj = "";
        JSONArray arrayObj = null;
        boolean boolObj = false;
        int intObj = -9999;
        String s;
        
        extractedObject = null;

        //Object newObj = thisJSON.get(thisList.get(i));
        try 
        {
            jsonObj = thisJSON.getJSONObject(i);
        }
        catch(Exception e)
        {   
            // So this is not a JSONObject ... so try to see if it is an array
            try 
            {
                arrayObj = thisJSON.getJSONArray(i);
            }
            catch(Exception e1)
            {               
                // Is not JSONObject or JSONArray - so just read as String (which will safely convert an int/bool for our purposes)
                try
                {
                    strObj = thisJSON.getString(i);
                }
                catch(Exception e2)
                {
                    try
                    {
                        // Is not JSONObject or JSONArray or String
                        boolObj = thisJSON.getBoolean(i);
                    }
                    catch(Exception e3)
                    {
                        try
                        {
                            // Is not JSONObject or JSONArray or String, or boolean - so try the final type of Int
                            intObj = thisJSON.getInt(i);
                        }
                        catch (Exception e4)
                        {
                            println(e4);
                            s = "JSONDIFF: Unexpected field type for index " + i;
                            infoMsgList.append(s);
                            return false;
                        }
                        extractedObject = intObj;
                        return true;
                    }
                    extractedObject = boolObj;
                    return true;
                }
                extractedObject = strObj;
                return true;
            }
            extractedObject = arrayObj;
            return true;
        }
        extractedObject = jsonObj;
        return true;
    }

       
    public void displayInfoMsg()
    {
        if (infoMsgList.size() == 0)
        {
            printToFile.printDebugLine(this, "JSONDIFF: No changes for item" + itemTSID, 3);
            printToFile.printOutputLine("JSONDIFF: No changes for item" + itemTSID);
            return;
        }
        // Changes found for street - print them all out
        for (int i = 0; i < infoMsgList.size(); i++)
        {
            printToFile.printDebugLine(this, "JSONDIFF: Changes for item" + itemTSID + ":" + infoMsgList.get(i), 3);
            printToFile.printOutputLine("JSONDIFF: Changes for item" + itemTSID + ":" + infoMsgList.get(i));
        }
        
    }
}