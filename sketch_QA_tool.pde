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
 
 // option to simply validate streets - i.e. not process the street, just inititialise. Might mean can quickly trap errors for a region? 
 // Rather than failing after an hour.
 
 // Need to see if know where the config.json is - if not, then dialog box so user can select.
 // Next time run program, screen shows the path of the json and gives user chance to change/accept
 
 // Need to load up all items we have at once - check how it impacts on the memory as currently cumulatively loading items
 // as process streets. 
 
 // Change image handling to store sets of item images as hashmaps ... then can easily access all in a loop, or pull out the
 // one image that is relevant using the class/info fields. So can return to doing visiting stones, wall button, postbox, x/y quoins, trees
 // in the correct order. 

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


//Display the thing being searched for together with large image of snap.
// Have a wire frame that moves around to show what being compared with small image
// Save 'best fit so far' as pink box on image

// Have an option where only changes x,y in files (e.g. if on street where already started
// QA. Or could do something where if street is in persdata-qa, only change the x,y? 
// so that still does full changes on streets not yet QA'd? Could do reminder to 
// person in output file to do /qasave on those streets? Might be better option - 
// NO - IS BETTER FOR THE PERSON TO DECIDE, AS GIVING LIST OF TSIDS, THEY CAN
// RUN TOOL TWICE FOR STREETS ALREADY/NOT DONE WITH OPTION SET DIFFERENTLY.


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
//ArrayList<StreetInfo> streetInfoArray;
StreetInfo streetInfo;

// Keep track of which street we are on in the list from the config.json file
int streetBeingProcessed;

// Hash map of all the item images needed to validate this street - will be used by all streets
ItemImages allItemImages;

// Hash map of all the item images needed to validate this street - will be used by all streets
FragmentOffsets allFragmentOffsets;

// Handles all output to screen
DisplayMgr display;

// missing item co-ordinates - if set to this, know not found
final int missCoOrds = 32700;

// States - used to determine next actions
int nextAction;
final int loadItemImages = 10;
final int loadFragmentOffsets = 11;
final int initStreet = 20;
final int processStreet = 30;
final int idling = 100;

// Differentiate between error/normal endings
boolean failNow = false;    // abnormal ending/error
boolean exitNow = false;    // normal ending
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

Memory memory = new Memory();

public void setup() 
{
    // Set size of Processing window
    // width, height
    // Must be first line in setup()
    size(1200,800);
    
    nextAction = 0;
    
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
        printToFile.printDebugLine(this, "No streets to process - exiting", 3);
        failNow = true;
        return;
    }
    
    //Set up ready to start adding images to this 
    allItemImages = new ItemImages();
    
    // Set up ready to start adding offsets to this
    allFragmentOffsets = new FragmentOffsets();
    
    // Ready to start with first street
    streetBeingProcessed = 0;
    nextAction = loadFragmentOffsets;
    
    // Display start up msg
    display.showInfoMsg("Loading item images for comparison ... please wait");
    
    memory.printMemoryUsage();
}

public void draw() 
{  

    // Each time we enter the loop check for error/end flags
    if (!okToContinue)
    {
        // Problem during validation of street - waiting for user to press c or any other key
        nextAction = idling;
        return;
    }
    else if (failNow)
    {
        println("failNow flag set - exiting with errors");
        printToFile.printOutputLine("failNow flag set - exiting with errors");
        printToFile.printDebugLine(this, "failNow flag set - exiting with errors", 3);
        nextAction = idling;
        exit();
    }
    else if (exitNow && !doNothing)
    {
        display.showSkippedStreetsMsg();
        printToFile.printOutputLine("All processing completed");
        printToFile.printDebugLine(this, "Exit now - All processing completed", 3);
        memory.printMemoryUsage();
        doNothing = true;
        nextAction = idling;
        exit();
    }
    
    // Carry out processing depending on whether setting up the street or processing it
    //println("nextAction is ", nextAction);
    switch (nextAction)
    {
        case idling:
            break;
                 
        case loadFragmentOffsets:
            // Validates/loads all item images 
            if(!allFragmentOffsets.loadFragmentDefaultsForItems())
            {
                printToFile.printDebugLine(this, "Error loading fragment offsets for images", 3);
                failNow = true;
                return;
            }
            printToFile.printDebugLine(this, allFragmentOffsets.sizeOf() + " offsets for fragment images now loaded", 1);
            memory.printMemoryUsage();
            
            nextAction = loadItemImages;
            break;
            
        case loadItemImages:
            // Validates/loads all item images 
            if(!allItemImages.loadAllItemImages())
            {
                printToFile.printDebugLine(this, "Error loading image snaps", 3);
                failNow = true;
                return;
            }
            printToFile.printDebugLine(this, allItemImages.sizeOf() + " sets of item images now loaded", 1);
            memory.printMemoryUsage();
            
            nextAction = initStreet;
            break;
            
        case initStreet:
            // Carries out the setting up of the street and associated items 
            
            if (!initialiseStreet())
            {
                // fatal error
                failNow = true;
                return;
            }
            if (!okToContinue)
            {
                // Need to wait for user input
                return;
            }
            
            // Reload up the first street image ready to go
            if (!streetInfo.loadStreetImage(0))
            {
                failNow = true;
                return;
            }
            
            if (!streetInfo.readStreetItemData())
            {
                printToFile.printDebugLine(this, "Error in readStreetItemData", 3);
                failNow = true;
                return;
            }
            
            // Reset the item done flags 
            streetInfo.initStreetItemVars();
             
            printToFile.printDebugLine(this, "street initialised is " + configInfo.readStreetTSID(streetBeingProcessed) + " (" + streetBeingProcessed + ")", 1);
            
            nextAction = processStreet;
            break;
            
        case processStreet:
            // Process the street, one street snap at a time, going over each item in turn 
        
            // Process street item unless due to move on to next street
            printToFile.printDebugLine(this, "Processing street  " + streetBeingProcessed + " streetFinished flag is " + streetInfo.readStreetFinished(), 1);
            if (streetInfo.readStreetFinished())
            {            
                streetBeingProcessed++;
                if (streetBeingProcessed >= configInfo.readTotalJSONStreetCount())
                {
                    // Reached end of list of streets - normal ending
                    streetInfo = null;
                    System.gc();
                    memory.printMemoryUsage();
                    exitNow = true;
                    return;
                }
                else
                {
                    // OK to move on to the next street
                    nextAction = initStreet;
                }
            }
            else
            {
                // Street yet not finished - move on to the next item and/or snap
                streetInfo.processItem();
                
                //okToContinue = false;
            }
            //printToFile.printDebugLine(this, "End top level processStreet memory", 1);
            //memory.printMemoryUsage();
            break;
           
        default:
            // Error condition
            printToFile.printDebugLine(this, "Unexpected next action - " + nextAction, 3);
            exit();
    }
}

boolean initialiseStreet()
{
        
    // Initialise street and then loads up the items on that street.
    String streetTSID = configInfo.readStreetTSID(streetBeingProcessed);
    if (streetTSID.length() == 0)
    {
        // Failure to retrieve TSID
        printToFile.printDebugLine(this, "Failed to read street TSID number " + str(streetBeingProcessed) + " from config.json", 3); 
        return false;
    }
    
    streetInfo = null;
    System.gc();
    streetInfo = new StreetInfo(streetTSID); 
            
    // Now read the error flag for the street array added
    if (!streetInfo.readOkFlag())
    {
       printToFile.printDebugLine(this, "Error creating street data structure", 3);
       return false;
    }
        
    printToFile.printDebugLine(this, "Read street data for TSID " + streetTSID, 2);
            
    // Now populate the street information
    if (!streetInfo.initialiseStreetData())
    {
        printToFile.printDebugLine(this, "Error populating street data structure", 3);
        return false;
    }
    
    if (streetInfo.readInvalidStreet())
    {
        // The L* file is missing for this street
        okToContinue = false;
        
        // Display the start up error messages
        display.clearDisplay();
        display.showSkippedStreetsMsg();
        display.showInfoMsg("Errors during initial processing of street - press 'c' to continue, 'x' to exit");
        return true;
    }
                 
    // All OK
    return true;
}

void keyPressed() 
{
    if ((key == 'c') || (key == 'C')) 
    {
        okToContinue = true;
        streetBeingProcessed++;
        if (streetBeingProcessed >= configInfo.readTotalJSONStreetCount())
        {
            // Reached end of list of streets - normal ending
            exitNow = true;
        }
        return;
    }
    else if ((key == 'x') || (key == 'X'))
    {
        exit();
    }
    
    else if (key == CODED && keyCode == RIGHT)
    {
        // debugging through images - need to set okToContinue flag after processItem call above
        okToContinue = true;
        nextAction = processStreet;
        return;
        
    }
}

   public static void printHashCodes(final Object object)
   {
      println("====== "
         + String.valueOf(object) + "/"
         + (object != null ? object.getClass().getName() : "null")
         + " ======");
      println(
           "Overridden hashCode: "
         + (object != null ? object.hashCode() : "N/A"));
      println("Identity   hashCode: " + System.identityHashCode(object));
   }