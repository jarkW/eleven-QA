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
    String validationInfo;
    String itemTSID;
    String itemClassTSID;
    JSONObject origJSON;
    JSONObject newJSON;
    String origFileName;
    String newFileName;

    public JSONDiff(String iTSID, String iClassTSID, String origJSONFileName, String newJSONFileName)
    {
        infoMsgList = new StringList();
        validationInfo = "";
        itemTSID = iTSID;
        itemClassTSID = iClassTSID;
        origJSON = null;
        newJSON = null;
        origFileName = origJSONFileName;
        newFileName = newJSONFileName;
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
        if (configInfo.readDebugValidationRun())
        {
            validationInfo = "JSONDIFF: " + itemTSID + ": ";
        }
        
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
        Object newObj;
        Object origObj;
        
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
            // Search for matching keys in file - trying to find a match in origList for the new key
            while (!newList.get(i).equals(origList.get(j)) && (i < newList.size()))
            {
                newObj = newVersion.get(newList.get(i));
                
                if (!(newObj == null) && !(newObj instanceof JSONObject) && !(newObj instanceof JSONArray))
                {
                    // Means we have a bool/int/String we can dump out
                    s = "New key in new JSON file is " + newList.get(i) + " set to " + newObj;
                    if (configInfo.readDebugValidationRun())
                    {
                        validationInfo = validationInfo + newList.get(i) + " (new->" + newObj + "); ";
                    }
                }
                else
                {
                    s = "New key in new JSON file is " + newList.get(i) + " set to ????????";
                    if (configInfo.readDebugValidationRun())
                    {
                        validationInfo = validationInfo + newList.get(i) + " (new->????); ";
                    }
                }
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
                    return false;
                }
                else if (i >= newList.size())
                {
                    // New key at end of file - so can return true as nothing to compare at this point 
                    if (!checkValidKeyChange(newList.get(j), false, null))
                    {
                        s = "ERROR - invalid new key (" +  newList.get(j) + ") at end of new file";
                        infoMsgList.append(s);
                        return false;
                    }
                    else
                    { 
                        newObj = newVersion.get(newList.get(j));

                        if (!(newObj == null) && !(newObj instanceof JSONObject) && !(newObj instanceof JSONArray))
                        {
                            // Means we have a bool/int/String we can dump out
                            s = "Valid new key at end of file - " +  newList.get(j) + " set to " + newObj;
                            if (configInfo.readDebugValidationRun())
                            {
                                validationInfo = validationInfo + newList.get(j) + " (new (end file)->" + newObj + "); ";
                            }
                        }
                        else
                        {
                            s = "Valid new key at end of file - " +  newList.get(j) + " set to ????????";
                            if (configInfo.readDebugValidationRun())
                            {
                                validationInfo = validationInfo + newList.get(j) + " (new (end file)->????); ";
                            }
                        }
                        infoMsgList.append(s);
                        return true;
                    }
                }
            }

            // If we get here then we have two keys with the same name
            origObj = origVersion.get(origList.get(j));
            newObj = newVersion.get(newList.get(i));           

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
               return false;
            }
            else if (origObj == null)
            {
               // Could this be the case when field not set, and we then set it correctly using the tool
               if (!(newObj instanceof JSONObject) && !(newObj instanceof JSONArray))
               {
                    // Means we have a bool/int/String we can dump out
                    s = "WARNING " + itemTSID + ".json, at level " + level + "/" + newList.get(i) + " new key is set to " + newObj + " orig key is null";
                    if (configInfo.readDebugValidationRun())
                    {
                        validationInfo = validationInfo + newList.get(i) + " (null->" + newObj + "); ";
                    }
               }
               else
               {
                    s = "WARNING " + itemTSID + ".json, at level " + level + "/" + newList.get(i) + " new key is set to ??????? orig key is null";
                    if (configInfo.readDebugValidationRun())
                    {
                        validationInfo = validationInfo + newList.get(i) + " (null->????); ";
                    }
               }               
               infoMsgList.append(s);
            }
            else if (newObj instanceof JSONObject && origObj instanceof JSONObject)
            {
                if (!compareJSONObjects((JSONObject)origObj, (JSONObject)newObj, level + "/" + newList.get(i)))
                {
                    // Means that some kind of error has been detected e.g. changed a field int he JSON file that we shouldn't be touching
                    s = "ERROR found in object in " + itemTSID + ".json, at level " + level + "/" + newList.get(i) + " New key i is " + newList.get(i) +  " orig key j is " + origList.get(j);
                    infoMsgList.append(s);
                    return false;
                }
            }
            else if (newObj instanceof JSONObject || origObj instanceof JSONObject)
            {
                s = "ERROR - only one of new key and old key is a JSONObject" + "New key i is " + newList.get(i) +  " orig key j is " + origList.get(j);
                infoMsgList.append(s);
                return false;
            }
            else if (newObj instanceof JSONArray && origObj instanceof JSONArray)
            {
                if (!compareJSONArrays((JSONArray)origObj, (JSONArray)newObj, level + "/" + newList.get(i)))
                {
                    // Means that some kind of error has been detected e.g. changed a field int he JSON file that we shouldn't be touching
                    s = "ERROR found in array in " + itemTSID + ".json, at level " + level + "/" + newList.get(i) + "New key i is " + newList.get(i) +  " orig key j is " + origList.get(j);
                    infoMsgList.append(s);
                    return false;
                } 
            }
            else if (newObj instanceof JSONArray || origObj instanceof JSONArray)
            {
                s = "ERROR - only one of new key and old key is a JSONArray" + "New key i is " + newList.get(i) +  " orig key j is " + origList.get(j);
                infoMsgList.append(s);
                return false;
            }
            else
            {
                // string/int/bool
                if (!newObj.equals(origObj))
                {
                    // Difference found in values for key
                    if (!checkValidKeyChange(newList.get(i), true, newObj))
                    {
                        s = "ERROR - Different values found for invalid " + level + "/" + newList.get(i) + " new value is <" + newObj + "> was <" + origObj + ">";
                        infoMsgList.append(s);
                        return false;
                    }
                    else
                    {
                        s = "Different values found for valid " + level + "/" + newList.get(i) + " new value is <" + newObj + "> was <" + origObj + ">";
                        infoMsgList.append(s);
                        if (configInfo.readDebugValidationRun())
                        {
                            validationInfo = validationInfo + newList.get(i) + "(" + origObj + "->" + newObj + "); ";
                        }
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
        Object origObj;
        Object newObj;
        
        // Will just go through the arrays, entry by entry.
        if (origVersion.size() != newVersion.size())
        {
            s = "ERROR - JSON arrays are not the same size - an element has been added/deleted";
            infoMsgList.append(s);
            return false;
        }
       
        int i;
        for (i = 0; i < newVersion.size(); i++)
        {            
            origObj = origVersion.get(i);
            newObj = newVersion.get(i);
            
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
               infoMsgList.append(s);
               return false;
            }
            else if (origObj == null)
            {
               // This could be valid if the tool sets up a field which was originally null
               if (!(newObj instanceof JSONObject) && !(newObj instanceof JSONArray))
               {
                    // Means we have a bool/int/String we can dump out
                    s = "WARNING " + itemTSID + ".json, at level " + level + "/" + i + " new value is " + newObj + " orig value is null";
                    if (configInfo.readDebugValidationRun())
                    {
                        validationInfo = validationInfo + level + "/" + i + " (WARNING null->" + newObj + "); ";
                    }
               }
               else
               {
                    s = "WARNING " + itemTSID + ".json, at level " + level + "/" + i + " new value is ??????? orig value is null";
                    if (configInfo.readDebugValidationRun())
                    {
                        validationInfo = validationInfo + level + "/" + i + " (WARNING null->???????); ";
                    }
               }
               infoMsgList.append(s);
            } 
            else if (newObj instanceof JSONArray && origObj instanceof JSONArray)
            {
                if (!compareJSONArrays((JSONArray)origObj, (JSONArray)newObj, level + "/" + i))
                {
                    s = "ERROR found in " + itemTSID + ".json, at level " + level + "/" + i + " index i is " + i;
                    infoMsgList.append(s);
                    return false;
                }
            }
            else if (newObj instanceof JSONArray || origObj instanceof JSONArray)
            {
                s = "ERROR - only one of new object and old object is a JSONArray" + " index i is " + i;
                infoMsgList.append(s);
                return false;
            }
            else if (newObj instanceof JSONObject)
            {
                // Dealing with two JSONObj if reach this leg of the code
                if (!compareJSONObjects((JSONObject)origObj, (JSONObject)newObj, level + "/" + i))
                {
                    s = "ERROR found in " + itemTSID + ".json, at level " + level + "/" +i + " index i is " + i;
                    infoMsgList.append(s);
                    return false;
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
                    if (configInfo.readDebugValidationRun())
                    {
                        validationInfo = validationInfo + level + "/" + i + "(" + origObj + "->" + newObj + "); ";
                    }
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

    boolean checkValidKeyChange(String keyName, boolean checkValue, Object value)
    {
        
        // For each item - checks that any changed keys are as expected for the item type
        // Changes to co-ords of items are always valid
        if (keyName.equals("x") || keyName.equals("y"))
        {
            //printToFile.printDebugLine(this, "Expected change to field " + keyName + " in JSON file ", 1);
            return true;
        }
        
        if (streetInfo.readChangeItemXYOnly())
        {
            // Should never reach this point - as the only changes permitted are x,y changes. So report an error if this happens
            String s;
            s = "ERROR - unexpected change to field - " + keyName + " - should never be changed when change_xy_only option is set in ";
            if (streetInfo.readStreetNotInPersdataQA())
            {
                s = s + "non_persdata_qa_streets in QABot_config.json";
            }
            else
            {
                s = s + "persdata_qa_streets in QABot_config.json";
            }
            s = ", for this item class " + itemClassTSID;
            
            printToFile.printDebugLine(this, s, 3);
            return false;
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
                if (!keyName.equals("variant"))
                {
                    validKey = false;
                }
                else
                {
                    // Need to check that the variant of the wood_tree is valid - 1-4 - just to confirm sanity and that my code hasn't inserted some odd string
                    // when extracting info from the matching tree name.
                    // This is only needed for wood trees because no variant should be present for other trees - would be trapped in the default case below.
                    // This leg of code was needed to trap a bug I found where the class_tsid of the snap tree appeared in the wood_tree variant field.
                    if (checkValue && !value.equals("1") && !value.equals("2") && !value.equals("3") && !value.equals("4"))
                    {
                        printToFile.printDebugLine(this, "Unexpected change to field " + keyName + " in wood_tree JSON file - set to " + value, 3);
                        return false;
                    }
                }
                printToFile.printDebugLine(this, "Expected change to field " + keyName + " in wood_tree JSON file ", 1);
                break;            

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
        if (errDetected)
        {
            // If an error has been detected in the JSON file, then report this to the output file so it can be acted on
            printToFile.printOutputLine("JSONDIFF: ERROR in newly created " + newFileName + " - see debug_info.txt for more info");
        }
        
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
    
    public String readValidationInfo()
    {
        return validationInfo;
    }
    
}