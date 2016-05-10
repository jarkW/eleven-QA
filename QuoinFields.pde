class QuoinFields
{
    // Contains the additional fields needed for quoins - i.e. fields in instanceProps
   // Taken from quoin.js, config_prod.js and inc_data_prods_map.js
    String className;
    int respawnTime;
    String isRandom;
    String benefit;
    String benefitFloor;
    String benefitCeiling;
    String giant;
    String type; 
    String specialDefaultingInfo;
    String warningInfo;
            
    public boolean defaultFields(String region, String streetTSID, String quoinType)
    {
        // Set up the fields for use in the instanceProps structure in quoins - will depend on the region the quoin is in
        giant = "";
        
        // This field is not changed - unless Rainbow Run encounters a problem - which means the quoins are reset and a warning message given to user
        // In that case, the type field will be changed and read by the calling function. Otherwise this field is ignored
        type = quoinType;
        
        // Only set up an information message for the streets where special quoin values are used - otherwise nothing will be reported back to the user
        specialDefaultingInfo = "";
        warningInfo = "";

        switch (region)
        {
            case "86": // Baqala
            case "90": // Choru
            case "95": // Xalanga 
            case "91": // Zhambu
                // Ancestral Lands
                specialDefaultingInfo = "Defaulting quoins for Ancestral Lands - remember to change any mystery quoins to 'RANDOM BAQALA' class_name";
                if (!setAncestralLandsValues(quoinType))
                {
                    // Should never happen
                    return false;
                }
                break;
               
            case "108": 
                // Party spaces such as Toxic Moon
                specialDefaultingInfo = "Defaulting quoins for Party locations - remember to change any mystery quoins which are found to be xp/xurrants/mood/energy to 'PARTY' class_name";
                if (!setShardingPartySpaceValues(quoinType))
                {
                    // Should never happen
                    return false;
                }
                break;
                
            case "130": // Paradise locations i.e. upgrade cards
                specialDefaultingInfo = "Defaulting quoins for Upgrade cards/Paradise Locations - remember to change any mystery quoins which are found to be currents/xp to 'PARADISE' class_name";
                if (!setUpgradeCardsValues(quoinType))
                {
                    // Should never happen
                    return false;
                }
                break;
                
            case "126": // Roobrik
            case "128": // Balzare (128)
            case "131": // Haoma (131)
            case "133": // Kloro (133)
            case "136": // Jal (136)
            case "140": //Samudra (140)
                // Quoin Platforming Hubs - streets containing lots of quoins
                specialDefaultingInfo = "Defaulting quoins for Quoin Platforming Hubs - remember to change any mystery quoins which are found to be currents/xp to 'QUOIN HUB' class_name";
                if (!setQuoinPlatformingHubValues(quoinType))
                {
                    // Should never happen
                    return false;
                }
                break;
                
            default:
                // Apart from the special case of Rainbow Run, just use the default settings for quoins
                switch (streetTSID)
                {
                    case "LM4105MGKMSLT":
                    case "LIF9NRCLF273JBA":
                        // Rainbow Run
                        specialDefaultingInfo = "Defaulting quoins for Rainbow Run (expecting currants, but will also convert any mood to currants to reflect old quoin.js code) - remember to change any mystery quoins which are found to be 'RAINBOW RUN' class_name)";
                        if (!setRainbowRunValues(quoinType))
                        {
                            // Should never happen
                            return false;
                        }                  
                        break;
                        
                    default:
                        // Default setting for this quoin - i.e. all other streets for all regions outside the ones listed above
                        if (!setDefaultValues(quoinType))
                        {
                            // Should never happen
                            return false;
                        }
                        break;
                 }

        } // end switch region
                              
        return true;                  
    }
    
    boolean setDefaultValues(String quoinType)
    {
        // This function is used for most common regions - i.e. the default case
        // Also used to default quoins in the special streets/regions which don't have a particular special setting   
        
        switch (quoinType)
        {
            case "xp":       
                className = "fast tiny xp";
                respawnTime = 60;
                isRandom = "0";
                benefit = "1";
                benefitFloor = "0";
                benefitCeiling = "0";
                break;              
                        
            case "energy":
                className = "fast tiny energy";
                respawnTime = 3*60;
                isRandom = "0";
                benefit = "1";
                benefitFloor = "0";
                benefitCeiling = "0";                      
                break;
                            
           case "mood":
                className = "fast tiny mood";
                respawnTime = 4*60;
                isRandom = "0";
                benefit = "1";
                benefitFloor = "0";
                benefitCeiling = "0";                      
                break;
 
           case "currants":
                className = "fast tiny currants";
                respawnTime = 40;
                isRandom = "0";
                benefit = "1";
                benefitFloor = "0";
                benefitCeiling = "0";  
                break;
                        
            case "favor":
                className = "small random favor";
                respawnTime = 5*60;
                isRandom = "1";
                benefit = "0";
                benefitFloor = "1";
                benefitCeiling = "3";  
                giant = "all";
                break;                            
                            
           case "time":
                className = "fast tiny time";
                respawnTime = 60;
                isRandom = "0";
                benefit = "1";
                benefitFloor = "0";
                benefitCeiling = "0";  
                break;

            case "mystery":
                className = "placement tester";
                respawnTime = 1;
                isRandom = "0";
                benefit = "0";
                benefitFloor = "0";
                benefitCeiling = "0";  
                break;
                            
            default:
                printToFile.printDebugLine(this, "Unrecognised new quoin type " + quoinType, 3);
                return false;
        }
        
        return true;
    }
    
    boolean setAncestralLandsValues(String quoinType)
    {
        // Ancestral Lands          
        switch (quoinType)
        {
            case "xp":       
                className = "random baqala xp";
                respawnTime = 10*60;
                isRandom = "1";
                benefit = "0";
                benefitFloor = "6";
                benefitCeiling = "17";
                break;              
                        
            case "energy":
                className = "random baqala energy";
                respawnTime = 10*60;
                isRandom = "1";
                benefit = "0";
                benefitFloor = "6";
                benefitCeiling = "17";                      
                break;
                            
           case "mood":
                className = "random baqala mood";
                respawnTime = 10*60;
                isRandom = "1";
                benefit = "0";
                benefitFloor = "6";
                benefitCeiling = "17";                      
                break;
 
           case "currants":
                className = "random baqala currants";
                respawnTime = 10*60;
                isRandom = "1";
                benefit = "0";
                benefitFloor = "6";
                benefitCeiling = "17";  
                break;
                        
            case "favor":
                className = "random baqala favor";
                respawnTime = 10*60;
                isRandom = "1";
                benefit = "0";
                benefitFloor = "1";
                benefitCeiling = "4";  
                giant = "all";
                break;   
                            
           case "time":
                className = "random baqala time";
                respawnTime = 10*60;
                isRandom = "1";
                benefit = "0";
                benefitFloor = "6";
                benefitCeiling = "17";  
                break;

            case "mystery":
                if (!setDefaultValues(quoinType))
                {
                    return false;
                }
                break;
                            
            default:
                printToFile.printDebugLine(this, "Unrecognised new quoin type " + quoinType, 3);
                return false;
        }
        
        return true;
    }
    
    boolean setUpgradeCardsValues(String quoinType)
    {
        // This function is used for Upgrade cards - most quoin types set to default, with just 2 (xp/xurrants) set to special values
        switch (quoinType)
        {
            case "xp": 
                className = "paradise iMG";
                respawnTime = 400000;
                isRandom = "0";
                benefit = "1";
                benefitFloor = "0";
                benefitCeiling = "0";
                break;
                
           case "currants":
                className = "paradise currants";
                respawnTime = 400000;
                isRandom = "0";
                benefit = "1";
                benefitFloor = "0";
                benefitCeiling = "0";  
                break;
                
           case "energy":
           case "mood":
           case "favor":
           case "time":
           case "mystery":
               // No special values specified, so use the default settings
               if (!setDefaultValues(quoinType))
               {
                   return false;
               }
               break;
   
            default:
                printToFile.printDebugLine(this, "Unrecognised new quoin type " + quoinType, 3);
                return false;
        }
        
        return true;
    }
 
    boolean setShardingPartySpaceValues(String quoinType)
    {
        // This function is used for Party locations - xp/xurrants/mood/energy set to special values, others use defaulted values
        switch (quoinType)
        {
            case "mood":
                className = "party mood";
                respawnTime = 2*60;
                isRandom = "0";
                benefit = "1";
                benefitFloor = "0";
                benefitCeiling = "0";
                break;  
                
             case "energy":
                className = "party energy";
                respawnTime = 2*60;
                isRandom = "0";
                benefit = "1";
                benefitFloor = "0";
                benefitCeiling = "0";
                break;      
                
            case "xp":
                className = "party iMG";
                respawnTime = 90;
                isRandom = "0";
                benefit = "1";
                benefitFloor = "0";
                benefitCeiling = "0";
                break;  
                
            case "currants":
                className = "party currants";
                respawnTime = 60;
                isRandom = "0";
                benefit = "1";
                benefitFloor = "0";
                benefitCeiling = "0";
                break; 

           case "favor":
           case "time":
           case "mystery":
               // No special values specified, so use the default settings
               if (!setDefaultValues(quoinType))
               {
                   return false;
               }
               break;
   
            default:
                printToFile.printDebugLine(this, "Unrecognised new quoin type " + quoinType, 3);
                return false;
        }
        
        return true;
    }
    
    boolean setQuoinPlatformingHubValues(String quoinType)
    {
        // This function is used for quoin platforming Hubs - xp/xurrants set to special values, others use defaulted values
        switch (quoinType)
        {                
            case "xp":
                className = "quoin hub fast iMG";
                respawnTime = 60;
                isRandom = "1";
                benefit = "0";
                benefitFloor = "1";
                benefitCeiling = "3";
                break;  
                
            case "currants":
                className = "quoin hub fast currants";
                respawnTime = 40;
                isRandom = "1";
                benefit = "0";
                benefitFloor = "1";
                benefitCeiling = "3";
                break; 

           case "energy":
           case "mood":
           case "favor":
           case "time":
           case "mystery":
               // No special values specified, so use the default settings
               if (!setDefaultValues(quoinType))
               {
                   return false;
               }
               break;
   
            default:
                printToFile.printDebugLine(this, "Unrecognised new quoin type " + quoinType, 3);
                return false;
        }
        
        return true;
    }
    
    boolean setRainbowRunValues(String quoinType)
    {
        // This function is used for Rainbow Run - if the quoin is a currant/mood then accept but default to currant
        // Existing video evidence shows currants, but the code implies mood for rainbow_run which will be coded to currants in the near future. 
        // All other cases, set to mystery as should not happen
        switch (quoinType)
        {
            case "currants":
                className = "rainbow run";
                respawnTime = 15;
                isRandom = "0";
                benefit = "1";
                benefitFloor = "0";
                benefitCeiling = "0";  
                break;
                
            case "mood":
                // The original quoin.js had rainbow_run set to be mood quoins. So just in case we are comparing snaps which show mood quoins on this street
                // accept the match as valid, but default to be currants.
                // Give message to user though.
                className = "rainbow run";
                type = "currants"; // reset from mood to currants
                respawnTime = 15;
                isRandom = "0";
                benefit = "1";
                benefitFloor = "0";
                benefitCeiling = "0"; 
                printToFile.printDebugLine(this, "Warning: Resetting mood quoin to be currants, reflecting changes to quoin.js for 'rainbow run' to be currants rather than mood", 3);
                warningInfo = "Warning: Resetting mood quoin to be currants, reflecting changes made to quoin.js for 'rainbow run' to be currants rather than mood";
                break;
            
           case "energy":
           case "xp":
           case "favor":
           case "time":
           case "mystery":
               // Whilst mystery quoins are allowed, no other sorts of quoins should have been found on snaps - so reset back to mystery quoins for user to sort out
               if (!quoinType.equals("mystery"))
               {
                   printToFile.printDebugLine(this, "Warning: Unexpected quoin type " + quoinType + " found, (expecting currants/mood for Rainbow Run) so reset to mystery", 3);
                   warningInfo = "Warning: Unexpected quoin type " + quoinType + " found, (expecting currants/mood for Rainbow Run) so reset to mystery";
                   type = "mystery";
               }
               if (!setDefaultValues("mystery"))
               {
                   return false;
               }
               break;
   
            default:
                printToFile.printDebugLine(this, "Unrecognised new quoin type " + quoinType, 3);
                return false;
        }
        
        return true;
    }
    
    public String readClassName()
    {
        return className;
    }
    public int readRespawnTime()
    {
        return respawnTime;
    }
    public String readIsRandom()
    {
        return isRandom;
    }
    public String readBenefit()
    {
        return benefit;
    }
    public String readBenefitFloor()
    {
        return benefitFloor;
    }
    public String readBenefitCeiling()
    {
        return benefitCeiling;
    }
    public String readGiant()
    {
        return giant;
    }
    
    public String readQuoinType()
    {
        return type;
    }
    
    public String readSpecialDefaultingInfo()
    {
        return specialDefaultingInfo;
    }
    
    public String readWarningInfo()
    {
        return warningInfo;
    }

}