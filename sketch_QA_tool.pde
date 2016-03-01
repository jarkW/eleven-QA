/*
 * Reads in a list of street TSIDs from a config.json file, and then using the item
 * information/co-ordinates, searches street snaps with small item fragment images
 * to work out what the x,y needs to be for that item (rather than the guesses done manually 
 * during QA1). The item fragment images are stored in the data directory and were 
 * generated using the sketch_save_fragments programme - this saved the images together
 * with the fragment size and offset from item x,y - all information needed by this programme.
 *
 * The street/item files are read from persdata or fixtures (second choice). If a street
 * file does not exist then an error is reported, but the tool moves on to the next TSID
 * in the list.
 *
 * For some items such as quoins, dirt piles and other QA configurable items, the correct
 * version of the item is determined by comparing all versions of the item with the
 * street snap. 
 *
 * For quoins, all available snaps will be searched in order to provide as much information
 *( as possible about quoin types/x,y. Any quoins not located in this manner will be 
 * set to 'mystery' unless the 'do_xy_only' flag is set in the config file. NB This might change
 * functionality - as the setting to mystery forces a write of the quoin item file ... but could simply
 * add code that instead of checking diff in extra_info, instead always writes out quoin item files in that case
 *
 * The new x,y values and variant information is written to JSON files in persdata.
 * The tool will eventually be able to write to either the server/vagrant depending on 
 * where the QA person is working. 
 *
 * NB It is up to the user to ensure that snaps are correctly labelled with the street 
 * name as it appears in the game. 
 *
 */
 
 // Need to see if know where the config.json is - if not, then dialog box so user can select.
 // Next time run program, screen shows the path of the json and gives user chance to change/accept

// TO DO
// First of all load up all streets/items - so can check for missing L/snaps etc
// Give msg to screen - streets skipped - missng L* or snaps, snaps ignored (too small).
// Give user chance to abort then - so can fix problem, or continue.
// Unload all the snaps held in streets/items.
// Then process each street in turn - reloading snaps on that streets/each item as needed. Then
// unload when finished the street. Should be simple enough to have a street_unload_all_snaps - which 
// unloads the street snaps and then cycles through all the items, unloading the item images - i.e. set to null. 
// OR do this as part of Setup - once loaded the images to check everything, unlead before move onto next street (and could unload the item
// images before move on to next item). 
// Ditto for the load functionality. 
// Add 


//Do all processing for image in single loop - might be a lot quicker to do. Could be
// non-debug version? But won't be able to display images. Use flag in config.json

//Display the thing being searched for together with large image of snap.
// Have a wire frame that moves around to show what being compared with small image
// Save 'best fit so far' as pink box on image

// Have an option where only changes x,y in files (e.g. if on street where already started
// QA. Or could do something where if street is in persdata-qa, only change the x,y? 
// so that still does full changes on streets not yet QA'd? Could do reminder to 
// person in output file to do /qasave on those streets? Might be better option - 
// NO - IS BETTER FOR THE PERSON TO DECIDE, AS GIVING LIST OF TSIDS, THEY CAN
// RUN TOOL TWICE FOR STREETS ALREADY/NOT DONE WITH OPTION SET DIFFERENTLY.


// adding keys to visiting stone (so can count diff expected?)
// adding keys (dir) to shrines if not read in 'dir'
//
//  Need to read in street region - to know if black/white or AL (changes the quoin settings). 
// And other different quoin regions (party?)
//
//NEED TO CHECK USING ALL FUNCTION CALLS - I.E. READ/SET ONES


//
// Update files in vagrant or on server (need to update sftp library to 'put'

// NB Need to credit all people's code I use e.g. sftp (?) when submit to github
// 

// STILL MISSING:
//Mortar Barnacle:mortar_barnacle (instanceProps.blister 1-6), no dir
//Peat Bog:peat_1 no dir
//Peat Bog:peat_2 no dir
//Peat Bog:peat_3 no dir
//Jellisac Growth:jellisac (instanceProps.blister 1-4), no dir
//Ice Nubbin:ice_knob (instanceProps.knob 1-4), no dir
//Dirt Pile:dirt_pile (instanceProps.variant = dirt1 or dirt2), no dir
//Patch:patch no dir
//Dark Patch:patch_dark no dir
//Dust Trap:dust_trap (instanceProps.trap_class = A, B, C, D) no dir 
//Knocker:sloth_knocker no dir
//Sloth:npc_sloth (branch) instanceProps.dir = right/left (which also then sets dir=right/left
//Party ATM:party_atm - no dir
//Race Ticket Dispenser:race_ticket_dispenser no dir
//Wall Button:wall_button - dir = left/right (use def value first)
//Shrines - npc_shrine_firebog_*
// Shrines - npc_shrine_uralia_*
// shrines - npc_shrine_ix_

// Contains all the info read in from config.json
ConfigInfo configInfo;

// Information for this street i.e. the snaps of the street, items on the street
ArrayList<StreetInfo> streetInfoArray;

// Keep track of which street we are on in the list from the config.json file
int streetBeingProcessed;

// Hash map of all the item images needed to validate this street
ItemImages itemImagesHashMap;

// Handles all output to screen
DisplayMgr display;

// missing item co-ordinates - if set to this, know not found
final int missCoOrds = 32700;

// Differentiate between error/normal endings
boolean failNow = false;
boolean exitNow = false;
boolean doNothing = false; // useful if want to keep the window open to see error msg, used in dev only
boolean okToContinue = true;

// Contains both debug and user input information output files
PrintToFile printToFile;
// 0 = no debug info 1=all debug info (useful for detailed stuff, rarely used), 
// 2= general tracing info 3= error debug info only
int debugLevel = 1;
boolean debugToConsole = true;
boolean doDelay = true;
boolean writeJSONsToPersdata = false;  // until sure that the files are all OK, will be in newJSONs directory under processing sketch

public void setup() 
{
    // Set size of Processing window
    // width, height
    size(750,550);
    
    // Start up display manager
    display = new DisplayMgr();
    
    printToFile = new PrintToFile();
    if (!printToFile.readOkFlag())
    {
        println("Error setting up printToFile object");
        failNow = true;
        return;
    }
    
    // Set up config data
    configInfo = new ConfigInfo();
    if (!configInfo.readOkFlag())
    {
        failNow = true;
        return;
    }
    
    // Set up debug info dump file and output file
    if (!printToFile.initPrintToFile())
    {
        println("Error opening output files");
        failNow = true;
        return;
    }
    
    if (configInfo.readTotalJSONStreetCount() < 1)
    {
        // No streets to process - exit
        printToFile.printDebugLine("No streets to process - exiting", 3);
        failNow = true;
        return;
    }
    
    //Set up ready to start adding images to this 
    itemImagesHashMap = new ItemImages();
    
    // Loads up all streets and the items they contain
    // Means can check for missing files upfront before starting
    streetInfoArray = new ArrayList<StreetInfo>();
    if (!initialiseStreets() || display.checkIfFailedStreetsMsg())
    {
        //failNow = true;
        okToContinue = false;
        
        // Display the start up error messages
        display.showSkippedStreetsMsg();
        display.showInfoMsg("Errors during initial processing - press 'c' to continue, 'x' to exit");
        return;
    }
    
    if (!setForFirstStreet())
    {
        failNow = true;
        return;
    }
    
    MemoryDump memoryDump = new MemoryDump();
    memoryDump.printMemoryUsage();
}

public void draw() 
{    
    if (!okToContinue)
    {
        // Problem during startup - waiting for user to press c or any other key
        return;
    }
    
    if (failNow)
    {
        println("failNow flag set - exiting with errors");
        printToFile.printOutputLine("failNow flag set - exiting with errors");
        printToFile.printDebugLine("failNow flag set - exiting with errors", 3);
        exit();
    }
    else if (exitNow && !doNothing)
    {
        display.showSkippedStreetsMsg();
        printToFile.printOutputLine("All processing completed");
        printToFile.printDebugLine("Exit now - All processing completed", 3);
        doNothing = true;
        exit();
    }
    else
    {
        // NEED TO CHANGE THIS ALL
        // Work on one street at a time
        // Call street_init stuff (e.g. loading streetsnaps/pruning, which in turn calls item_init stuff (so the item could be repsonsible
        // for kicking off setting up the image snaps)? 
        // Then if error, handle
        // Then process the street.
        // Once done, set the street to null. And then start over again.
        // Add to the item snaps hashmap as needed, so subsequent streets will just be
        // able to access the files. 
        
        // Process street item unless due to move on to next street
        printToFile.printDebugLine("streetBeingProcessed is  " + streetBeingProcessed + " streetFinished flag is " + streetInfoArray.get(streetBeingProcessed).readStreetFinished(), 1);
        if (streetInfoArray.get(streetBeingProcessed).readStreetFinished())
        {
            // Need to free up memory for this finished street before move on
            // This won't work as then upsets the 'streetBeingProcessed variable'
            // But could just delete this array element, and then street being processed is always 0 as never return to it again.
            // Or write a function in streetInfo class which nulls all the pointers in the structure - which would then clean up memory
            //streetInfoArray.remove(streetBeingProcessed);
            
            streetBeingProcessed++;
            if (streetBeingProcessed >= streetInfoArray.size())
            {
                // Reached end of list of streets - normal ending
                exitNow = true;
            }
            else
            {
                // Reload images for street/items on street
                
                // Need to be redone as changed structures
                if (!streetInfoArray.get(streetBeingProcessed).loadStreetImages())
                {
                    failNow = true;
                }
                if (!streetInfoArray.get(streetBeingProcessed).loadAllItemImages())
                {
                    failNow = true;
                }
                streetInfoArray.get(streetBeingProcessed).initStreetVars();
                streetInfoArray.get(streetBeingProcessed).initStreetItemVars();
            }
        }
        else
        {
            streetInfoArray.get(streetBeingProcessed).processItem();
        }
    }
}

boolean initialiseStreets()
{
        
    // Initialises all the streets one by one, which in turn load up the items on that street.
    //streetBeingProcessed = -1;
    int i;
    for (i = 0, streetBeingProcessed = 0; i < configInfo.readTotalJSONStreetCount(); i++, streetBeingProcessed++)
    {
        //streetBeingProcessed++;
        String streetTSID = configInfo.readStreetTSID(i);
        if (streetTSID.length() == 0)
        {
            // Failure to retrieve TSID
            printToFile.printDebugLine("Failed to read street TSID number " + str(i + 1) + " from config.json", 3); 
            return false;
        }
            
        streetInfoArray.add(new StreetInfo(streetTSID));
            
        // Now read the error flag for the street array added
        if (!streetInfoArray.get(i).readOkFlag())
        {
           printToFile.printDebugLine("Error creating street data structure", 3);
           return false;
        }
        
        printToFile.printDebugLine("Read street data for TSID " + streetTSID, 2);
            
        // Now populate the street information
        if (!streetInfoArray.get(i).initialiseStreetData())
        {
            printToFile.printDebugLine("Error populating street data structure", 3);
            return false;
        }         
         
        // Can now unload the snaps for the street/items to free up memory
        // NB Need to remove these functions/redo
        if (!streetInfoArray.get(i).unloadStreetImages())
        {
             printToFile.printDebugLine("Unable to unload street images for " + streetInfoArray.get(i).readStreetName(), 3);
            return false;
        }
            
        if (!streetInfoArray.get(i).unloadAllItemImages())
        {
            printToFile.printDebugLine("Unable to unload item images for " + streetInfoArray.get(i).readStreetName(), 3);
            return false;
        }
       

    }
    
    
    
    // Go through and remove all the invalid streets
    for (int j = streetInfoArray.size() - 1; j >= 0; j--)
    {
        if (streetInfoArray.get(j).readInvalidStreet())
        {
            printToFile.printDebugLine("Removing invalid street (" + streetInfoArray.get(j).readStreetTSID() + ") from street array, reduced to " + (streetInfoArray.size()-1) + " streets", 2);
            streetInfoArray.remove(j);
        }
    }
        
        
    // All OK
    return true;
}

boolean setForFirstStreet()
{
        // Check that there are still streets left to process
    if (streetInfoArray.size() == 0)
    {
        printToFile.printDebugLine("No valid streets to process - exiting", 3);
        return false;
    }
    
    printToFile.printDebugLine("Number of streets left to process is " + streetInfoArray.size() + " (out of " + configInfo.readTotalJSONStreetCount() + ")", 3);
        
    // Start setting up the first street to be processed and reload snap images 
    streetBeingProcessed = 0;
    if (!streetInfoArray.get(streetBeingProcessed).loadStreetImages())
    {
        return false;
    }
    if (!streetInfoArray.get(streetBeingProcessed).loadAllItemImages())
    {
        return false;
    }
    streetInfoArray.get(streetBeingProcessed).initStreetVars();
    streetInfoArray.get(streetBeingProcessed).initStreetItemVars();
    
    printToFile.printDebugLine("DONE ALL INITIAL CHECKING: SET UP FOR FIRST STREET " + streetInfoArray.get(streetBeingProcessed).readStreetName(), 3);
    
    return true;
}

void keyPressed() 
{
    if ((key == 'c') || (key == 'C')) 
    {
        if (!setForFirstStreet())
        {
            failNow = true;
        }
        else
        {
            okToContinue = true;
        }
        return;
    }
    else if ((key == 'x') || (key == 'X'))
    {
        exit();
    }
}