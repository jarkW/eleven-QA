import sftp.*;

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
 * The new x,y values and variant information are written to JSON files in persdata.
 *
 * NB It is up to the user to ensure that snaps are correctly labelled with the street 
 * name as it appears in the game i.e. with spaces between words. 
 *
 */
 
 // Can dump out exception.class - to see actual error returned e.g. for missing files
 // Also test out trying to save to dir that write protected (set persdata to program files dir)
 // As well as testing for specific failures, incude def final catch Exception so that info
 // gets dumped (and failed returned)
 // for file get/put - break the connection - then do the get/put and see what class of 
 // error returns - so can trap it specifically
 // For any errors in getting, stop the program. But for errors putting ... carry on
 // because user can then manually update them to Tii (give message about having to
 // remove remaining files in data/NewJSONs manually (or rerunning tool)
 
 // BUG? xy variant only
 // Does it load up the single image for other non-quoin items with variant field?
 // Except wood trees - where still needs to test all tree images.
 // Also in JSON diff, ensure that only x,y have changed, error otherwise
 
 
 
 // TO DO - need to upload all the L*/G*/I* files to OrigJSONs (or copy from vagrant dir) ... 
 // and as go through them,
 // delete the skipped I files at some point so don't accumulate in the directory
 // then don't need the place where save the Orig JSON files anymore. Do this as part of 
 // setup - if I/L* files missing, then mark street as skipped and delete all the I/L* files that
 // do have
 // As upload the newJSON files to persdata - move to uploadedJSONs. At end of program
 // if newJSONs is empty ... successful end. Otherwise could list the JSONs on the screen 
 // or just do count of files in newJSONs.
 // Create/replace the errStrings array which is reported at the end? Or create new one for
 // failed JSONs so that it can be reported on new section of screen, just need display.setFailedJSON or something
 // Should also report failure to upload JSON files in the output directory
 // When using vagrant - need to check if fail trying to write files e.g. c:program files/temp or something - so catch that kind of error in all places
 //
 // 
 // Need to do a test to see if file arrived safely - see http://stackoverflow.com/questions/23918070/how-to-tell-if-an-sftp-upload-was-successful-using-jsch
 // Could implement the stat/lstat command - pass "stat", "--format "%Y"" "filename" which 
 // will give the time of last modification in seconds since Epoch (so would need to know
 // the baseline value loaded when start programe). But might just be simpler to assume
 // it has worked ... if no errors.
 
 // TO DO Change all the places where I do '/' in paths and replace with File.separatorChar so
 // that works on Mac and PC
 
 // Check that all PC defined paths exist in config loading - abort otherwise
 // Also empty all files from OrigJSONs/NewJSONs/UploadedJSONs
 
 // Should I check in JSONDiff that the only fields changed are the expected ones???
 // i.e. x,y, variant, and some added fields. 
 
 // TO DO update the quoin type settings for all the other regions. 
 
 // Seeing more failures in grey region of Brillah. Might need different way of comparing the images so more reliable? For now just leave it.
 
 // POSSIBLE FUTURE BUG - need to take account of the contrast/brightness of each street and change my item images to reflect this
 // Currently I am doing this with simple black/white setting.
 // Butdo collect the values in readStreetGeoInfo() even though not used. usingGeoInfo flag
 // But at some point might need to be more sophisticated - see eleven-client/src/com/quasimodo/geom/ColorMatrix.as
 // Might need to apply
 // cm.colorize(tin colour, tint amount/100)  tint colour is the RGB but in decimal (in the G* file)
 // cm.adjustContrast(contrast/100)
 // cm.adjustSaturation(saturation/100)
 // cm.adjustBrightness(brightness)
 // restore? cm.filter
 // Basically I think the code just creates a matrix which is then applied to each pixel (in my case the item fragment)
 // in turn.
    

 // option to simply validate streets - i.e. not process the street, just inititialise. Might mean can quickly trap errors for a region? 
 // Rather than failing after an hour. So would just check all the JSON files exist for each
 // of the streets.
 
 // Need to see if know where the config.json is - if not, then dialog box so user can select.
 // Next time run program, screen shows the path of the json and gives user chance to change/accept
 
 

// Have an option where only changes x,y in files (e.g. if on street where already started
// QA. Or could do something where if street is in persdata-qa, only change the x,y? 
// so that still does full changes on streets not yet QA'd? Could do reminder to 
// person in output file to do /qasave on those streets? Might be better option - 
// NO - IS BETTER FOR THE PERSON TO DECIDE, AS GIVING LIST OF TSIDS, THEY CAN
// RUN TOOL TWICE FOR STREETS ALREADY/NOT DONE WITH OPTION SET DIFFERENTLY.


//  Need to read in street region - to know if black/white or AL (changes the quoin settings). 
// And other different quoin regions (party?)
//
//NEED TO CHECK USING ALL FUNCTION CALLS - I.E. READ/SET ONES


//
// Update files in vagrant or on server (need to update sftp library to 'put'

// NB Need to credit all people's code I use e.g. sftp (?) when submit to github
// 

// NB TEST WHAT HAPPENS IF TRY TO FIND DUST trap of type B on a street - does it reset it to A and give msg???

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

String workingDir;
// Contains all the info read in from config.json
ConfigInfo configInfo;

// Information for this street i.e. the snaps of the street, items on the street
StreetInfo streetInfo;

// Keep track of which street we are on in the list from the config.json file
int streetBeingProcessed;

// Hash map of all the item images needed to validate this street - will be used by all streets
ItemImages allItemImages;

// Hash map of all the item images needed to validate this street - will be used by all streets
FragmentOffsets allFragmentOffsets;

// Handles all output to screen
DisplayMgr displayMgr;

// Handles connection to server
Sftp QAsftp;

// missing item co-ordinates - if set to this, know not found
final static int MISSING_COORDS = 32700;

// States - used to determine next actions
int nextAction;
final static int USER_INPUT_CONFIG_FOLDER = 10;
final static int CONTINUE_SETUP = 11;
final static int START_SERVER = 20;
final static int LOAD_ITEM_IMAGES = 30;
final static int LOAD_FRAGMENT_OFFSETS = 31;
final static int INIT_STREET = 40;
final static int INIT_STREET_DATA = 41;
final static int SHOW_FAILED_STREET_MSG = 42;
final static int PROCESS_STREET = 50;
final static int WAITING_FOR_INPUT = 90;
final static int IDLING = 100;
final static int EXIT_NOW = 110;

// Differentiate between error/normal endings
boolean failNow = false;    // abnormal ending/error

// Contains both debug and user input information output files
PrintToFile printToFile;
// 0 = no debug info 1=all debug info (useful for detailed stuff, rarely used), 
// 2= general tracing info 3= error debug info only
int debugLevel = 1;
boolean debugToConsole = true;
boolean doDelay = false;
boolean usingBlackWhiteComparison = true; // using black/white comparison if this is false, otherwise need to apply the street tint/contrast to item images

Memory memory = new Memory();

public void setup() 
{
    // Set size of Processing window
    // width, height
    // Must be first line in setup()
    size(1200,800);
    
    nextAction = 0;
    
    // Start up display manager
    displayMgr = new DisplayMgr();
    displayMgr.clearDisplay();
    
    printToFile = new PrintToFile();
    if (!printToFile.readOkFlag())
    {
        println("Error setting up printToFile object");
        failNow = true;
        return;
    }
    
    // Find the directory that contains the config.json 
    workingDir = "";
    if (!validConfigJSONLocation())
    {
        nextAction = USER_INPUT_CONFIG_FOLDER;
        selectInput("Select config.json in working folder:", "configJSONFileSelected");
    }
    else
    {
        nextAction = CONTINUE_SETUP;
    }

}

public void draw() 
{  

    // Each time we enter the loop check for error/end flags
    if (failNow)
    {
        println("failNow flag set - exiting with errors");
        printToFile.printOutputLine("\n\n!!!!! EXITING WITH ERRORS !!!!!\n\n");
        printToFile.printDebugLine(this, "failNow flag set - exiting with errors", 3);
        nextAction = EXIT_NOW;;
    }
    
    // Carry out processing depending on whether setting up the street or processing it
    //println("nextAction is ", nextAction);
    switch (nextAction)
    {
        case IDLING:
        case WAITING_FOR_INPUT:
            break;
            
        case USER_INPUT_CONFIG_FOLDER:
            // Need to get user to input valid location of config.json
            // Come here whilst wait for user to select the input
            
            if (workingDir.length() > 0)
            {
                nextAction = CONTINUE_SETUP;
            }
            break;
            
        case CONTINUE_SETUP:
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
    
            if (!setupWorkingDirectories())
            {
                printToFile.printDebugLine(this, "Problems creating working directories", 3);
                failNow = true;
                return;
            }
    
            // Set up connection to remote server if not using vagrant
            if (!configInfo.readUseVagrantFlag())
            {

                QAsftp = new Sftp(configInfo.readServerName(), configInfo.readServerUsername(), false, configInfo.readServerPort());  
                QAsftp.setPassword(configInfo.readServerPassword());
                QAsftp.start(); // start the thread
                displayMgr.showInfoMsg("Connecting to server ... please wait");
                nextAction = START_SERVER;
            }
            else
            {
                QAsftp = null;
        
                //Set up ready to start adding images to this 
                allItemImages = new ItemImages();
    
                // Set up ready to start adding offsets to this
                allFragmentOffsets = new FragmentOffsets();
    
                // Ready to start with first street
                streetBeingProcessed = 0;
                nextAction = LOAD_FRAGMENT_OFFSETS;
    
                // Display start up msg
                displayMgr.showInfoMsg("Loading item images for comparison ... please wait");
         
                memory.printMemoryUsage();
            }
            break;
            
        case START_SERVER:
            
            if (QAsftp != null)
            {
                if (QAsftp.readSessionConnect())
                {
                    // Server has been connected successfully - so can continue
                    
                    // First validate the fixtures/persdata paths on the server
                    if (!QAsftp.executeCommand("ls", configInfo.readFixturesPath(), "silent"))
                    {
                        println("Fixtures directory ", configInfo.readFixturesPath(), " does not exist on server");
                        failNow = true;
                        return;
                    }
                    if (!QAsftp.executeCommand("ls", configInfo.readPersdataPath(), "silent"))
                    {
                        println("Persdata directory ", configInfo.readPersdataPath(), " does not exist on server");
                        failNow = true;
                        return;
                    }

                    //Set up ready to start adding images to this 
                    allItemImages = new ItemImages();
    
                    // Set up ready to start adding offsets to this
                    allFragmentOffsets = new FragmentOffsets();
    
                    // Ready to start with first street
                    streetBeingProcessed = 0;
                    nextAction = LOAD_FRAGMENT_OFFSETS;
    
                    // Display start up msg
                    displayMgr.showInfoMsg("Loading item images for comparison ... please wait");
            
                    memory.printMemoryUsage();
                }
                else
                {
                    // Session still not connected
                    // Abort if the error flag is set
                    if (!QAsftp.readRunningFlag())
                    {
                        failNow = true;
                        return;
                    }
                }
            }
            break;
                 
        case LOAD_FRAGMENT_OFFSETS:
            // Validates/loads all item images 
            if(!allFragmentOffsets.loadFragmentDefaultsForItems())
            {
                printToFile.printDebugLine(this, "Error loading fragment offsets for images", 3);
                failNow = true;
                return;
            }
            printToFile.printDebugLine(this, allFragmentOffsets.sizeOf() + " offsets for fragment images now loaded", 1);
            memory.printMemoryUsage();
            
            nextAction = LOAD_ITEM_IMAGES;
            break;
            
        case LOAD_ITEM_IMAGES:
            // Validates/loads all item images 
            if(!allItemImages.loadAllItemImages())
            {
                printToFile.printDebugLine(this, "Error loading image snaps", 3);
                failNow = true;
                return;
            }
            printToFile.printDebugLine(this, allItemImages.sizeOf() + " sets of item images now loaded", 1);
            memory.printMemoryUsage();
            
            nextAction = INIT_STREET;
            break;
            
        case INIT_STREET:
            // Carries out the setting up of the street and associated items 
            displayMgr.clearDisplay();
            if (!initialiseStreet())
            {
                // fatal error
                failNow = true;
                return;
            }
            
            if (streetInfo.readInvalidStreet())
            {
                // The L* file is missing for this street       
                // Display the start up error messages
                displayMgr.showThisSkippedStreetMsg();
                nextAction = SHOW_FAILED_STREET_MSG;
                return;
            }
            
            /*
            if (!okToContinue)
            {
                // Need to wait for user input
                return;
            }*/
            
            // Reload up the first street image ready to go
            if (!streetInfo.loadStreetImage(0))
            {
                failNow = true;
                return;
            }
            
            nextAction = INIT_STREET_DATA;
            break;
            
        case SHOW_FAILED_STREET_MSG:
           // pause things for 2 seconds - so user can see previous output about failed street - then move on to next one
            delay(2000);
            displayMgr.clearDisplay();
            streetBeingProcessed++;
            if (streetBeingProcessed >= configInfo.readTotalJSONStreetCount())
            {
                // Reached end of list of streets - normal ending
                boolean nothingToShow = displayMgr.showAllSkippedStreetsMsg();       
                printToFile.printOutputLine("\n\nALL PROCESSING COMPLETED\n\n");
                printToFile.printDebugLine(this, "Exit now - All processing completed", 3);
                if (nothingToShow)
                {
                    nextAction = EXIT_NOW;
                }
                else
                {
                    nextAction = WAITING_FOR_INPUT;
                }
                return;
            }
            nextAction = INIT_STREET;
            break;
            
        case INIT_STREET_DATA:
        
            if (!streetInfo.readStreetItemData())
            {
                printToFile.printDebugLine(this, "Error in readStreetItemData", 3);
                failNow = true;
                return;
            }
            
            // Reset the item done flags 
            streetInfo.initStreetItemVars();
             
            printToFile.printDebugLine(this, "street initialised is " + configInfo.readStreetTSID(streetBeingProcessed) + " (" + streetBeingProcessed + ")", 1);
            
            nextAction = PROCESS_STREET;
            break;
            
        case PROCESS_STREET:
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
                                        
                    boolean nothingToShow = displayMgr.showAllSkippedStreetsMsg();       
                    printToFile.printOutputLine("\n\nALL PROCESSING COMPLETED\n\n");
                    printToFile.printDebugLine(this, "Exit now - All processing completed", 3);
                    if (nothingToShow)
                    {
                        nextAction = EXIT_NOW;
                    }
                    else
                    {
                        nextAction = WAITING_FOR_INPUT;
                    }
                    return;
                }
                else
                {
                    // OK to move on to the next street
                    nextAction = INIT_STREET;
                }
            }
            else
            {
                // Street yet not finished - move on to the next item and/or snap
                streetInfo.processItem();
            }
            //printToFile.printDebugLine(this, "End top level processStreet memory", 1);
            //memory.printMemoryUsage();
            break;
            
        case EXIT_NOW:            
            memory.printMemoryUsage();
            // Close sftp session
            if (QAsftp != null && QAsftp.readRunningFlag())
            {
                if (!QAsftp.executeCommand("exit", "session", null))
                {
                    println("exit session failed");
                }
            }
            println("exit() issued");
            exit();
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
                 
    // All OK
    return true;
}

boolean setupWorkingDirectories()
{
    // Checks that we have working directories for the JSONs - create them if they don't exist
    // If they exist - then empty them
    
    //Need to have a hardcoded path for this - datapath + NewJSONs
    //Also need 3rd dirctory - uploadedJSONs
    
    if (!Utils.emptyDir(workingDir + File.separatorChar +"NewJSONs"))
    {
        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
        return false;
    }
    
    if (!Utils.emptyDir(workingDir + File.separatorChar + "OrigJSONs"))
    {
        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
        return false;
    }
    
    if (!Utils.emptyDir(workingDir + File.separatorChar +"UploadedJSONs"))
    {
        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
        return false;
    }
    
    return true; 
}

void keyPressed() 
{
    if ((key == 'x') || (key == 'X'))
    {
        nextAction = EXIT_NOW;
        println("x pressed");
        return;
    }
}

boolean validConfigJSONLocation()
{
    // Searches for the configLocation.txt file which contains the saved location of the config.json file
    // That location is returned by this function.
    String  configLocation = "";
    File file = new File(sketchPath("configLocation.txt"));
    if (!file.exists())
    {
        return false;
    }
    
    // File exists - now validate
    //Read contents - first line is config.json location
    String [] configFileContents = loadStrings(sketchPath("configLocation.txt"));
    configLocation = configFileContents[0];
    
    // Have read in location - check it exists
    if (configLocation.length() > 0)
    {
        file = new File(configLocation + File.separatorChar + "config.json");
        if (!file.exists())
        {
            println("Missing config.json file from ", configLocation);
            return false;
        }
    }
    workingDir = configLocation;  
    return true;
    
}

void configJSONFileSelected(File selection)
{
    if (selection == null) 
    {
        println("Window was closed or the user hit cancel.");
        failNow = true;
        return;
    }      
    else 
    {
        println("User selected " + selection.getAbsolutePath());
        if (selection.getAbsolutePath().indexOf("config.json") == -1)
        {
            println("Please select a config.json file");
            failNow = true;
            return;
        }
        
        // User selected correct file name so now save
        String[] list = new String[1];
        // Strip out config.json part of name - to just get folder name
        list[0] = selection.getAbsolutePath().replace(File.separatorChar + "config.json", "");
        try
        {
            saveStrings(sketchPath("configLocation.txt"), list);
        }
        catch (Exception e)
        {
            println(e);
            println("error detected saving config.json location to configLocation.txt");
            failNow = true;
            return;
        }
        workingDir = list[0];
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