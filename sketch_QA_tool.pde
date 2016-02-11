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
 * set to 'mystery' unless the 'do_xy_only' flag is set in the config file.
 *
 * The new x,y values and variant information is written to JSON files in persdata.
 * The tool will eventually be able to write to either the server/vagrant depending on 
 * where the QA person is working. 
 *
 */

// TO DO
// Read in config from json file

// Use SearchMgr class which does the actual image stuff. 
// Street -> item -> do image stuff (so store loop counting, current image x,y as vars
// in this class rather than as globals. Depending on flag, can do all the loop (don't
// show the red moving frame), or just do one loop iteration before returning to 
// top level

// take the lowest y value for the quoin - i.e. least negative. Just overwrite the
// saved value - no -need to store in special array

//Do all processing for image in single loop - might be a lot quicker to do. Could be
// non-debug version? But won't be able to display images. Use flag in config.json

//Display the thing being searched for together with large image of snap.
// Have a wire frame that moves around to show what being compared with small image
// Save 'best fit so far' as pink box on image

// Need to check always working with the correct size png file - save the size of the first
// one opened? And check the others all the same (ignore files that are not?)
// Might also need to check that snap file not contain 'Subway' unless the street name
// also does. Otherwise GFJ will also pick up GFJ subway station
// When read in all the snaps - could check all same dimensions - if not
// then could give error message and continue?

// Have an option where only changes x,y in files (e.g. if on street where already started
// QA. Or could do something where if street is in persdata-qa, only change the x,y? 
// so that still does full changes on streets not yet QA'd? Could do reminder to 
// person in output file to do /qasave on those streets? Might be better option - 
// NO - IS BETTER FOR THE PERSON TO DECIDE, AS GIVING LIST OF TSIDS, THEY CAN
// RUN TOOL TWICE FOR STREETS ALREADY/NOT DONE WITH OPTION SET DIFFERENTLY.

// Compare the output json files with the originals to check no fields been
// accidentally deleted/changed
// Easiest to compare char count - if only change x,y = 4 char diff (might change to -ve, inc/dec by 1 char)
// but if setting variant field - OK as just changing number
// quoins - setting type 
// NB will know the original type, and know what setting it to - so can work out what difference
// is expected from this field. 
// class_name = "small random favor" (type = "favor")
// class_name = "fast tiny mood" (type = mood)
// class_name = "fast tiny energy" (type = energy)
// class_name = "fast tiny xp" (type = "xp")
// class_name = "fast tiny currants" (type = "currants")
// class_name = "fast tiny time" (type = "time")
// class_name = "placement tester" (type = "mystery")
//
// adding keys to visiting stone (so can count diff expected?)
//
//  Need to read in street region - to know if black/white or AL (changes the quoin settings). 
// And other different quoin regions (party?)
//
// Need to check using same size snaps - could confirm against found _zoi or _cleops? Or could bomb
// out if the street snaps vary in size and leave to user to sort out (if no _zoi/cleops).
//
// When reading in list of snaps need to make sure don't pick up subway snap when searching for GFJ
// So search for 'Subway' in street name - if absent, make sure don't pick up any by accident 
// Sabudana Drama (Aranna) - Towers/Towers Basement/Towers Floor 1-4 (need to separate Sabudana Drama and Sabudana Drama Towers out)
// Besara - Egret Taun - Towers/Towers Basement/Towers Floor 1-3 (need to separate Egret Taun and Egret Taun Towers out)
// Bortola - Hauki Seeks - Manor/Manor Basement/Manor Floor 1-3 (need to separate Hauki Seeks and Hauki Seeks Manor out)
// GM - Gregarious Towers/Towers Basement/Towers Floor 1-3 (need to separate Gregarious Towers out)
// Muufo - Hakusan Heaps - Towers/Towers Basement/Towers Floor 1-2 (need to separate Hakusan Heaps and Hakusan Heaps Towers out)
// May be have an option which says 'use all snaps in directory' so if name not work, can force it

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
StreetInfo thisStreetInfo;

// Keep track of which street we are on in the list from the config.json file
int streetNumberBeingProcessed;

// Differentiate between error/normal endings
boolean failNow = false;
boolean exitNow = false;

// Contains both debug and user input information output files
PrintToFile printToFile;
// 0 = no debug info 1=all debug info (useful for detailed stuff, rarely used), 
// 2= general tracing info 3= error debug info only
int debugLevel = 2;
boolean debugToConsole = true;

public void setup() 
{
    // Set size of Processing window
    size(750,550);
    
    // Set up config data
    configInfo = new ConfigInfo();
    if (!configInfo.readOkFlag())
    {
        failNow = true;
        return;
    }
    
    // Set up debug info dump file and output file
    printToFile = new PrintToFile();
    if (!printToFile.readOkFlag())
    {
        println("Error opening output files");
        failNow = true;
        return;
    }
    
    if (configInfo.readTotalStreetCount() < 1)
    {
        // No streets to process - exit
        printToFile.printDebugLine("No streets to process - exiting", 3);
        failNow = true;
        return;
    }
    
    // Start setting up the first street to be processed
    streetNumberBeingProcessed = 0;
    thisStreetInfo = new StreetInfo(configInfo.readStreetTSID(streetNumberBeingProcessed));
    printToFile.printDebugLine("Read street data for TSID " + configInfo.readStreetTSID(streetNumberBeingProcessed), 2); 
    if (!thisStreetInfo.readOkFlag())
    {
        println("Error creating street data structure");
        failNow = true;
        return;
    }
    if (!thisStreetInfo.initialiseStreetData())
    {
        println("Error populating street data structure");
        failNow = true;
        return;
    }
     
}

public void draw() 
{
    if (failNow)
    {
        println("failNow flag set - exiting with errors");
        printToFile.printOutputLine("failNow flag set - exiting with errors");
        printToFile.printDebugLine("failNow flag set - exiting with errors", 3);
        exit();
    }
    else if (exitNow)
    {
        println("Exit now - all work completed");
        printToFile.printOutputLine("Exit now - all work completed");
        printToFile.printDebugLine("Exit now - all work completed", 3);
        exit();
    }
    else
    {
        // Process street item unless due to move on to next street
        if (thisStreetInfo.readStreetFinished())
        {
            streetNumberBeingProcessed++;
            if (streetNumberBeingProcessed >= configInfo.readTotalStreetCount())
            {
                // Reached end of list of streets - normal ending
                exitNow = true;
            }
            else
            {
                // Read in data for this street
                thisStreetInfo = new StreetInfo(configInfo.readStreetTSID(streetNumberBeingProcessed));
                printToFile.printDebugLine("Read street data for TSID " + configInfo.readStreetTSID(streetNumberBeingProcessed), 2); 
                if (!thisStreetInfo.readOkFlag())
                {
                    println("Error creating street data structure");
                    failNow = true;
                }
                if (!thisStreetInfo.initialiseStreetData())
                {
                    println("Error populating street data structure");
                    failNow = true;
                }
            }
        }
        else
        {
            thisStreetInfo.processItem();
        }
    }
    
}