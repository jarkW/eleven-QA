class QuoinFields
{
    // Contains the additional fields needed for quoins - i.e. fields in instanceProps
    String className;
    int respawnTime;
    String isRandom;
    String benefit;
    String benefitFloor;
    String benefitCeiling;
    String giant;
            
    public boolean defaultFields(String region, String streetTSID, String quoinType)
    {
        // Set up the fields for use in the instanceProps structure in quoins - will depend on the region the quoin is in
        giant = "";

         
        // At some point need to set up different values here depending on region (streetInfo.hubID) and/or street TSID
            
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
                printToFile.printDebugLine("Unrecognised new quoin type " + quoinType, 3);
                return false;
        }
            
        return true;  
        
           /* See quoin.js for party spaces, ticket to paradise, platforming hubs, baqala and rainbow run (might need to reset quoin type to mood) */
           // see config_prod.js for regions? List of TSID for paradise/party spaces for example
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

}