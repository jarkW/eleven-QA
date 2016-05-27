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
    String itemClassTSID;
    JSONObject origJSON;
    JSONObject newJSON;
    String origFileName;
    String newFileName;
    // Set by the function that works out what type of object we have - so that I can return a boolean to handle success/failure
    Object extractedObject;

    public JSONDiff(String iTSID, String iClassTSID, String origJSONFileName, String newJSONFileName)
    {
        infoMsgList = new StringList();
        itemTSID = iTSID;
        itemClassTSID = iClassTSID;
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
            s = "ERROR found in comparison of new/old " + itemTSID + ".json";
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
            printToFile.printDebugLine(this, "Temporary copy of new JSON file " + newFileName + " does not exist", 3);
            return false;
        }
        
        try
        {
            //newJSON = loadJSONObject(newFileName);
            // The library loadJSONObject doesn't close the file ... so the subsequent move of this JSON file will fail
            newJSON = loadJSONObjectFromFile(newFileName);
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
            //origJSON = loadJSONObject(origFileName);
            // The library loadJSONObject doesn't close the file ... so the subsequent move of this JSON file will fail
            origJSON = loadJSONObjectFromFile(origFileName);
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
    
        s = "Keys in the JSON files " + origList.size() + " in original, " + newList.size() + " in new file";
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
                s = "New key in new JSON file is " + newList.get(i);
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
                    s = "ERROR - New key (" +  origList.get(j) + ") in old file = error (as have deleted key from the new file)";
                    infoMsgList.append(s);
                    printToFile.printOutputLine("JSONDIFF: ERROR in newly created " + newFileName + " - see debug_info.txt for more info");
                    return false;
                }
                else if (i >= newList.size())
                {
                    // New key at end of file - so can return true as nothing to compare at this point 
                    if (!checkValidKeyChange(newList.get(j)))
                    {
                        s = "ERROR - invalid new key (" +  newList.get(j) + ") at end of new file";
                        infoMsgList.append(s);
                        printToFile.printOutputLine("JSONDIFF: ERROR in newly created " + newFileName + " - see debug_info.txt for more info");
                        return false;
                    }
                    else
                    {
                        s = "Valid new key (" +  newList.get(j) + ") at end of new file";
                        infoMsgList.append(s);
                        return true;
                    }
                }
            }

            // If we get here then we have two keys with the same name
            if (!extractObjectFromJSONObject(origVersion, origList, j))
            {
                // Unexpected type of object in JSON
                printToFile.printOutputLine("JSONDIFF: ERROR in newly created " + newFileName + " - see debug_info.txt for more info");
                return false;
            }
            Object origObj = extractedObject; // set by extractObjectFromJSONObject
            if (!extractObjectFromJSONObject(newVersion, newList, i))
            {
                // Unexpected type of object in JSON
                printToFile.printOutputLine("JSONDIFF: ERROR in newly created " + newFileName + " - see debug_info.txt for more info");
                return false;
            }
            Object newObj = extractedObject;  // set by extractObjectFromJSONObject  
            

            // Handle the null cases first to avoid null pointer errors
            if ((newObj == null) && (origObj == null))
            {
                s = "Same values found for "  + itemTSID + ".json, at level " + level  + "/" + newList.get(i) + " new value is <null> was <null>";
                //infoMsgList.append(s);
            }
            else if (newObj == null)
            {
               // Would expect the case where a field is null in the new JSON file to be a mistake, so treat as error
               s = "ERROR found in " + itemTSID + ".json, at level " + level + "/" + newList.get(i) + "New key is null, orig key is non-null";
               infoMsgList.append(s);
               printToFile.printOutputLine("JSONDIFF: ERROR in newly created " + newFileName + " - see debug_info.txt for more info");
               return false;
            }
            else if (origObj == null)
            {
               // Not sure that this is an error - could this be the case when field not set, and we then set it correctly using the tool???
               // If it is an error - then return false
               s = "ERROR ??????? found in " + itemTSID + ".json, at level " + level + "/" + newList.get(i) + "New key is non-null, orig key is null";
               infoMsgList.append(s);
               printToFile.printOutputLine("JSONDIFF: ERROR ??????? in newly created " + newFileName + " - see debug_info.txt for more info");
            }      
            else if (newObj instanceof JSONObject && origObj instanceof JSONObject)
            {
                if (!compareJSONObjects((JSONObject)origObj, (JSONObject)newObj, level + "/" + newList.get(i)))
                {
                    s = "ERROR????????? found in " + itemTSID + ".json, at level " + level + "/" + newList.get(i) + "New key i is " + newList.get(i) +  " orig key j is " + origList.get(j);
                    infoMsgList.append(s);
                    printToFile.printOutputLine("JSONDIFF: ERROR ??????? in newly created " + newFileName + " - see debug_info.txt for more info");
                }
            }
            else if (newObj instanceof JSONObject || origObj instanceof JSONObject)
            {
                s = "Error - only one of new key and old key is a JSONObject" + "New key i is " + newList.get(i) +  " orig key j is " + origList.get(j);
                infoMsgList.append(s);
                printToFile.printOutputLine("JSONDIFF: ERROR in newly created " + newFileName + " - see debug_info.txt for more info");
                return false;
            }
            else if (newObj instanceof JSONArray && origObj instanceof JSONArray)
            {
                if (!compareJSONArrays((JSONArray)origObj, (JSONArray)newObj, level + "/" + newList.get(i)))
                {
                    s = "ERROR???????? found in " + itemTSID + ".json, at level " + level + "/" + newList.get(i) + "New key i is " + newList.get(i) +  " orig key j is " + origList.get(j);
                    infoMsgList.append(s);
                    printToFile.printOutputLine("JSONDIFF: ERROR ??????? in newly created " + newFileName + " - see debug_info.txt for more info");
                } 
            }
            else if (newObj instanceof JSONArray || origObj instanceof JSONArray)
            {
                s = "Error - only one of new key and old key is a JSONArray" + "New key i is " + newList.get(i) +  " orig key j is " + origList.get(j);
                infoMsgList.append(s);
                printToFile.printOutputLine("JSONDIFF: ERROR in newly created " + newFileName + " - see debug_info.txt for more info");
                return false;
            }
            else
            {
                // string/int/bool
                if (!newObj.equals(origObj))
                {
                    // Difference found in values for key
                    if (!checkValidKeyChange(newList.get(i)))
                    {
                        s = "ERROR - Different values found for invalid " + level + "/" + newList.get(i) + " new value is <" + newObj + "> was <" + origObj + ">";
                        infoMsgList.append(s);
                        printToFile.printOutputLine("JSONDIFF: ERROR in newly created " + newFileName + " - see debug_info.txt for more info");
                        return false;
                    }
                    else
                    {
                        s = "Different values found for valid " + level + "/" + newList.get(i) + " new value is <" + newObj + "> was <" + origObj + ">";
                        infoMsgList.append(s);
                    }
                }
                else
                {
                    s = "Same values found for " + level + "/" + newList.get(i) + " new value is <" + newObj + "> was <" + origObj + ">";
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
            s = "JSON arrays are not the same size - an element has been added/deleted";
            infoMsgList.append(s);
            printToFile.printOutputLine("JSONDIFF: ERROR in newly created " + newFileName + " - see debug_info.txt for more info");
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
                printToFile.printOutputLine("JSONDIFF: ERROR in newly created " + newFileName + " - see debug_info.txt for more info");
                return false;
            }
            Object origObj = extractedObject; // set by extractObjectFromJSONarray
            if (!extractObjectFromJSONArray(newVersion, i))
            {
                // unexpected object in array
                printToFile.printOutputLine("JSONDIFF: ERROR in newly created " + newFileName + " - see debug_info.txt for more info");
                return false;
            }
            Object newObj = extractedObject; // set by extractObjectFromJSONarray  
            
            // Handle the null cases first to avoid null pointer errors
            if ((newObj == null) && (origObj == null))
            {
                s = "Same values found for " + itemTSID + ".json, at level " + level + "/" + i + " new value is <null> was <null>";
                //infoMsgList.append(s);
            }
            else if (newObj == null)
            {
                // Don't expect to null out fields that were already set in the JSON file
               s = "ERROR found in " + itemTSID + ".json, at level " + level + "/" + i + "New index i is null orig index i is non-null";
               printToFile.printOutputLine("JSONDIFF: ERROR in newly created " + newFileName + " - see debug_info.txt for more info");
               infoMsgList.append(s);
               return false;
            }
            else if (origObj == null)
            {
               // This could be valid??? If the tool sets up a field which was originally null - return false if is an actual error
               s = "ERROR????????? found in " + itemTSID + ".json, at level " + level + "/" + i + "New index i is non-null orig index i is -null";
               infoMsgList.append(s);
               printToFile.printOutputLine("JSONDIFF??????: ERROR in newly created " + newFileName + " - see debug_info.txt for more info");
            } 
            else if (newObj instanceof JSONArray && origObj instanceof JSONArray)
            {
                if (!compareJSONArrays((JSONArray)origObj, (JSONArray)newObj, level + "/" + i))
                {
                    s = "ERROR??????????? found in " + itemTSID + ".json, at level " + level + "/" + i + " index i is " + i;
                    infoMsgList.append(s);
                    printToFile.printOutputLine("JSONDIFF: ERROR?????????? in newly created " + newFileName + " - see debug_info.txt for more info");
                }
            }
            else if (newObj instanceof JSONArray || origObj instanceof JSONArray)
            {
                s = "Error - only one of new object and old object is a JSONArray" + " index i is " + i;
                infoMsgList.append(s);
                printToFile.printOutputLine("JSONDIFF: ERROR in newly created " + newFileName + " - see debug_info.txt for more info");
                return false;
            }
            else if (newObj instanceof JSONObject)
            {
                if (!compareJSONObjects((JSONObject)origObj, (JSONObject)newObj, level + "/" + i))
                {
                    s = "ERROR??????? found in " + itemTSID + ".json, at level " + level + "/" +i + " index i is " + i;
                    infoMsgList.append(s);
                    printToFile.printOutputLine("JSONDIFF: ERROR???????? in newly created " + newFileName + " - see debug_info.txt for more info");
                }
            }
            else
            {
                // string/int/bool                
                if (!newObj.equals(origObj))
                {
                    // Difference found in values in array
                    s = "Different values found for " + level + "/" + i + " new value is <" + newObj + "> was <" + origObj + ">";
                    infoMsgList.append(s);
                    printToFile.printOutputLine("JARK JSON DIFF : change to JSONArray at " + level + "/" + i + " new value is <" + newObj + "> was <" + origObj + "> - check it out in " + newFileName);
                }
                else
                {
                    s = "Same values found for " + level + "/" + i + " new value is <" + newObj + "> was <" + origObj + ">";
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
        
        // First check to see if this is a null object - i.e. has the value null
        if (thisJSON.isNull(thisList.get(i)))
        {
            // Null value for key, so return null
            return true;
        }
        
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
                            s = "Unexpected field type for key " + thisList.get(i);
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
        
        // First check to see if this is a null object - i.e. has the value null
        if (thisJSON.isNull(i))
        {
            // Null value for key, so return null object
            return true;
        }

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
                            s = "Unexpected field type for index " + i;
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

    boolean checkValidKeyChange(String keyName)
    {
        
        // For each item - checks that any changed keys are as expected for the item type
        // Changes to co-ords of items are always valid
        if (keyName.equals("x") || keyName.equals("y"))
        {
            printToFile.printDebugLine(this, "Expected change to field " + keyName + " in JSON file ", 1);
            return true;
        }
        
        if (itemClassTSID.indexOf("npc_shrine_", 0) == 0)
        {
            if (!keyName.equals("dir"))
            {
                printToFile.printDebugLine(this, "ERROR - unexpected change to field " + keyName + " in shrine JSON file - should never be changed for this item class " + itemClassTSID, 3);
                return false;
            }
            else
            {
                printToFile.printDebugLine(this, "Expected change to field " + keyName + " in shrine JSON file ", 1);
                return true;
            }
        }
        
        boolean validKey = true;
        
        switch (itemClassTSID)
        {
            case "quoin": 
                switch (keyName)
                {
                    case "type":
                    case "class_name":
                    case "respawn_time":
                    case "is_random":
                    case "benefit":
                    case "benefit_floor":
                    case "benefit_ceil":
                    case "giant":
                        // All valid key types
                        break;
                    default:
                        validKey = false;
                        break;
                }
                break;
                 
            case "wood_tree":
            case "npc_mailbox":
            case "dirt_pile":
            case "wood_tree_enchanted":
                if (!keyName.equals("variant"))
                {
                    validKey = false;
                }
                break;
            
            case "mortar_barnacle":
            case "jellisac":       
                if (!keyName.equals("blister"))
                {
                    validKey = false;
                }
                break;  
                
            case "ice_knob":
                if (!keyName.equals("knob"))
                {
                    validKey = false;
                }
                break;
                
            case "dust_trap":
                if (!keyName.equals("trap_class"))
                {
                    validKey = false;
                }
                break;  
            
            case "subway_gate":
            case "npc_sloth":
               if (!keyName.equals("dir"))
                {
                    validKey = false;
                }
                break;              
            
            case "visiting_stone":
                if (!keyName.equals("dir") && !keyName.equals("state"))
                {
                    validKey = false;
                }
                break;
                
            default:
                // Should never reach this leg of the code
                validKey = false;
                break;
        }
        
        if (!validKey)
        {
            printToFile.printDebugLine(this, "ERROR - unexpected change to field " + keyName + " in " + newFileName + " - should never be changed for this item class " + itemClassTSID, 3);
            return false;
        }
        else
        {
            //printToFile.printDebugLine(this, "Expected change to field " + keyName + " in " + newFileName + " for item class " + itemClassTSID, 1);
            return true;
        }        
    }
    
    public void displayInfoMsg(boolean errDetected)
    {
        if (infoMsgList.size() <= 2)
        {
            // Allow for the starting/finishing messages which are always present
            printToFile.printDebugLine(this, "JSONDIFF: No changes for item " + itemTSID, 1);
            return;
        }
        // Changes found for street - print them all out
        for (int i = 0; i < infoMsgList.size(); i++)
        {
            if (errDetected)
            {
                // Make sure user sees the information - so dump all JSONDIFF info to debug file
                printToFile.printDebugLine(this, "JSONDIFF: Changes for item " + itemTSID + ":" + infoMsgList.get(i), 3);
            }
            else
            {
                // only seen if low level tracing requested and error-free
                printToFile.printDebugLine(this, "JSONDIFF: Changes for item " + itemTSID + ":" + infoMsgList.get(i), 1);
            }
        }
        
    }
    
}