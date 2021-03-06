import sftp.*;
import java.text.DecimalFormat;

// v2.0.4 - uses Processing 3.3.7

/*
 * Reads in a list of street TSIDs from a QABot_config.json file, and then using the item
 * information/co-ordinates, searches street snaps with small item fragment images
 * to work out what the x,y needs to be for that item (rather than the guesses done manually 
 * during QA1). The item fragment images are stored in the data directory and were 
 * generated using the sketch_save_fragments programme - this saved the images together
 * with the fragment size and offset from item x,y - all information needed by this programme.
 *
 * The street/item files are read from persdata or fixtures (second choice). If a street
 * file does not exist then an error is reported, but the tool moves on to the next TSID
 * in the list. Similarly, if the street is in persdata-qa (has been QA'd) then the street
 * is skipped (unless the xy_only option has been selected, thereby saving the quoin types
 * of quoins not found in the snaps).
 *
 * For some items such as quoins, dirt piles and other QA configurable items, the correct
 * version of the item is determined by comparing all versions of the item with the
 * street snap. 
 *
 * For quoins, all available snaps of the correct resolution (as given in the G* file)
 * will be searched in order to provide as much information
 *( as possible about quoin types/x,y. Any quoins not located in this manner will be 
 * set to 'mystery' unless the 'do_xy_only' flag is set in the config file. 
 *
 * The new x,y values and variant information are written to JSON files in persdata.
 *
 * The output file contains details of the changed files and the success of copying/uploading.
 * Warnings are also given if items are found to have the same x,y which can happen for a group
 * of closely spaced quoins - the program has no way of knowing if the quoin 20px away is the 
 * missing neighbour or an incorrectly placed quoin to that neighbour. 
 *
 * NB It is up to the user to ensure that snaps are correctly labelled with the street 
 * name as it appears in the game i.e. with spaces between words. Snaps which do not match
 * the resolution as given in the G* file will be ignored.
 *
 */
 
 // option to simply validate streets - i.e. not process the street, just inititialise. Might mean can quickly trap errors for a region? 
 // Rather than failing after an hour. So would just check all the JSON files exist for each
 // of the streets.
 
 // Might need to add support for different examples of trees - I've come across 2 different spice trunks in GF for example. But
 // will be difficult to work out the offsets as I can't grown these other forms of tree. So might be better to just accept that
 // some trees won't be found.

//NEED TO CHECK USING ALL FUNCTION CALLS - I.E. READ/SET ONES

// Default memory in preferences to 300mb to help offset Processing memory problems with (un)loading snaps



// Directory where QABot_config.json is, and all saved JSON files - both original/new
String workingDir;
// Contains all the info read in from QABot_config.json
ConfigInfo configInfo = null;

// Information for this street i.e. the snaps of the street, items on the street
StreetInfo streetInfo;

// Keep track of which street we are on in the list from the QABot_config.json file
int streetBeingProcessed;

// Hash map of all the item images needed to validate this street - will be used by all streets
ItemImages allItemImages;

// Hash map of all the item images needed to validate this street - will be used by all streets
FragmentOffsets allFragmentOffsets;

// Handles all output to screen
DisplayMgr displayMgr;
String uploadString;
String downloadString;

// Handles connection to server
Sftp QAsftp;

// Handles all text output
OutputFile debugOutput;
OutputFile infoOutput;
OutputFile validationSummaryOutput;

// missing item co-ordinates - if set to this, know not found
final static int MISSING_COORDS = 32700;

// search result for fragment
final static int PERFECT_MATCH = 300;
final static int GOOD_MATCH = 200;
final static int NO_MATCH = 100;

// States - used to determine next actions
int nextAction;
final static int USER_INPUT_CONFIG_FOLDER = 10;
final static int CONTINUE_SETUP = 11;
final static int WAIT_FOR_SERVER_START = 20;
final static int LOAD_ITEM_IMAGES = 30;
final static int LOAD_FRAGMENT_OFFSETS = 31;
final static int INIT_STREET = 40;
final static int INIT_ITEM_DATA = 41;
final static int SHOW_FAILED_STREET_MSG = 42;
final static int PROCESS_STREET = 50;
final static int WRITE_ITEM_JSON = 60;
final static int SHOW_FAILED_STREETS_MSG = 70;
final static int WAITING_FOR_INPUT = 80;
final static int IDLING = 100;
final static int EXIT_NOW = 110;

// Differentiate between error/normal endings
boolean failNow = false;    // abnormal ending/error

// Contains both debug and user input information output files
PrintToFile printToFile;
// 0 = no debug info 1=all debug info (useful for detailed stuff, rarely used), 
// 2= general tracing info 3= error debug info only
// This will be reset when the QABot_config.json is read
int debugLevel = 3;
boolean debugToConsole = true;

Memory memory = new Memory();

public void setup() 
{
    // Set size of Processing window
    // width, height
    // Must be first line in setup()
    //size(1200,800);
    size(1200,700); 
    
    // Used for final application title bar
    surface.setTitle("QA tool for setting co-ordinates and variants of items in Ur"); 
    
    // Used to handle different ways user can close the program
    prepareExitHandler();
    
    nextAction = 0;
    
    // Start up display manager
    displayMgr = new DisplayMgr();
    displayMgr.clearDisplay();
    
    printToFile = new PrintToFile();
    if (!printToFile.readOkFlag())
    {
        println("Error setting up printToFile object");
        displayMgr.showErrMsg("Error setting up printToFile object", true);
        failNow = true;
        return;
    }
                     
    // Find the directory that contains the QABot_config.json 
    workingDir = "";
    if (!validConfigJSONLocation())
    {
        nextAction = USER_INPUT_CONFIG_FOLDER;
        selectInput("Select QABot_config.json in working folder:", "configJSONFileSelected");
    }
    else
    {
        nextAction = CONTINUE_SETUP;
    }
}

public void draw() 
{  
    String currentItemTSID;

    // Each time we enter the loop check for error/end flags
    if (failNow && nextAction != EXIT_NOW)
    {
        // Give the user a chance to see any saved error message which could not be displayed earlier
        // In particular when user selected invalid QABot_config.json (e.g. with hidden .txt suffix)
        displayMgr.showSavedErrMsg();       
        nextAction = WAITING_FOR_INPUT;
    }
    
    // Carry out processing depending on whether setting up the street or processing it
    //println("nextAction is ", nextAction);
    //memory.printMemoryUsage();
    //memory.printUsedMemory("start");
    switch (nextAction)
    {
        case IDLING:
        case WAITING_FOR_INPUT:
            break;
            
        case USER_INPUT_CONFIG_FOLDER:
            // Need to get user to input valid location of QABot_config.json
            // Come here whilst wait for user to select the input
            if (workingDir.length() > 0)
            {
                nextAction = CONTINUE_SETUP;
            }
            break;
            
        case CONTINUE_SETUP:
        
            // Now we have the working directory, we can set up the debug output file - so can report useful QABot_config.json errors
            if (!printToFile.initPrintToDebugFile())
            {
                println("Error creating debug output file");
                displayMgr.showErrMsg("Error creating debug output file", true);
                failNow = true;
                return;
            }

            // Set up config data
            configInfo = new ConfigInfo();
            if (!configInfo.readOkFlag())
            {
                // Error message already set up in this function
                failNow = true;
                return;
            }
    
            // Set up output file
            if (!printToFile.initPrintToOutputFile())
            {
                println("Error opening output file");
                displayMgr.showErrMsg("Error opening output file", true);
                failNow = true;
                return;
            }
            
            // Set up the file which will contain a summary of validation changes (easier to compare against previous validation runs)
            if (configInfo.readDebugValidationRun())
            {
                if (!printToFile.initPrintToValidationSummaryOutputFile())
                {
                    println("Error opening output file");
                    displayMgr.showErrMsg("Error opening output file", true);
                    failNow = true;    
                    return;
                }
            }
            
            printToFile.printDebugLine(this, "Timestamp: " + nf(hour(),2) + nf(minute(),2) + nf(second(),2), 1);
    
            if (configInfo.readTotalJSONStreetCount() < 1)
            {
                // No streets to process - exit
                printToFile.printDebugLine(this, "No streets to process - exiting", 3);
                displayMgr.showErrMsg("No streets to process - exiting", true);
                failNow = true;
                return;
            }

            if (!setupWorkingDirectories())
            {
                printToFile.printDebugLine(this, "Problems creating working directories", 3);
                displayMgr.showErrMsg("Problems creating working directories", true);
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
                nextAction = WAIT_FOR_SERVER_START;
            }
            else
            {
                QAsftp = null;
    
                // Ready to start with first street
                streetBeingProcessed = 0;
                nextAction = LOAD_FRAGMENT_OFFSETS;
    
                // Display start up msg
                displayMgr.clearDisplay();
                displayMgr.showInfoMsg("Copying street/item JSON files for street " + configInfo.readStreetTSID(streetBeingProcessed) + " ... please wait");
            }
            break;
            
        case WAIT_FOR_SERVER_START:
            
            if (QAsftp != null)
            {
                if (QAsftp.readSessionConnect())
                {
                    // Server has been connected successfully - so can continue
                    printToFile.printDebugLine(this, "Timestamp: " + nf(hour(),2) + nf(minute(),2) + nf(second(),2), 1);
                    // First validate the fixtures/persdata/persdata-qa paths on the server
                    if (!QAsftp.executeCommand("ls", configInfo.readFixturesPath(), "silent"))
                    {
                        println("Fixtures directory ", configInfo.readFixturesPath(), " does not exist on server");
                        displayMgr.showErrMsg("Fixtures directory " + configInfo.readFixturesPath() + " does not exist on server", true);
                        failNow = true;
                        return;
                    }
                    if (!QAsftp.executeCommand("ls", configInfo.readPersdataPath(), "silent"))
                    {
                        println("Persdata directory ", configInfo.readPersdataPath(), " does not exist on server");
                        displayMgr.showErrMsg("Persdata directory " + configInfo.readPersdataPath() + " does not exist on server", true);
                        failNow = true;
                        return;
                    }
                    if (!QAsftp.executeCommand("ls", configInfo.readPersdataQAPath(), "silent"))
                    {
                        println("Persdata-qa directory ", configInfo.readPersdataQAPath(), " does not exist on server");
                        displayMgr.showErrMsg("Persdata-qa directory " + configInfo.readPersdataQAPath() + " does not exist on server", true);
                        failNow = true;
                        return;
                    }
    
                    // Ready to start with first street
                    streetBeingProcessed = 0;
                    nextAction = LOAD_FRAGMENT_OFFSETS;
    
                    // Display start up msg
                    displayMgr.showInfoMsg("Loading item images for comparison ... please wait");
                }
                else
                {
                    // Session still not connected
                    // Abort if the error flag is set
                    if (!QAsftp.readRunningFlag())
                    {
                        displayMgr.showErrMsg("Problems connecting to server", true);
                        failNow = true;
                        return;
                    }
                }
            }
            break;
                   
        case LOAD_FRAGMENT_OFFSETS:
            // Validates/loads all item images 
            printToFile.printDebugLine(this, "Timestamp: " + nf(hour(),2) + nf(minute(),2) + nf(second(),2), 1);
    
            // Set up ready to start adding offsets to this
            allFragmentOffsets = new FragmentOffsets();
            
            if(!allFragmentOffsets.loadFragmentDefaultsForItems())
            {
                printToFile.printDebugLine(this, "Error loading fragment offsets for images", 3);
                displayMgr.showErrMsg("Error loading fragment offsets for images", true);
                failNow = true;
                return;
            }
            printToFile.printDebugLine(this, allFragmentOffsets.sizeOf() + " offsets for fragment images now loaded", 1);
            memory.printMemoryUsage();
            
            displayMgr.showInfoMsg("Loading item images for comparison ... please wait");
            nextAction = LOAD_ITEM_IMAGES;
            break;
            
        case LOAD_ITEM_IMAGES:
            // Validates/loads all item images 
            //Set up ready to start adding images to this 
            allItemImages = new ItemImages();

            printToFile.printDebugLine(this, "Timestamp: " + nf(hour(),2) + nf(minute(),2) + nf(second(),2), 1);
            if(!allItemImages.loadAllItemImages())
            {
                printToFile.printDebugLine(this, "Error loading image snaps", 3);
                displayMgr.showErrMsg("Error loading image snaps", true);
                failNow = true;
                return;
            }
            printToFile.printDebugLine(this, allItemImages.sizeOf() + " sets of item images now loaded", 1);
            memory.printMemoryUsage();
            
            // Ready to start with first street
            streetBeingProcessed = 0;
            displayMgr.clearDisplay();
            displayMgr.showInfoMsg(downloadString + " street JSON files for street " + configInfo.readStreetTSID(streetBeingProcessed) + " ... please wait");
            nextAction = INIT_STREET;
            break;
            
        case INIT_STREET:
            // Carries out the setting up of the street and associated items 
            printToFile.printDebugLine(this, "Timestamp: " + nf(hour(),2) + nf(minute(),2) + nf(second(),2), 1);        
            printToFile.printDebugLine(this, "Read street data for TSID " + configInfo.readStreetTSID(streetBeingProcessed), 2);
                       
            if (!initialiseStreet())
            {
                // fatal error
                displayMgr.showErrMsg("Error setting up street data", true);
                failNow = true;
                return;
            }
            
            if (streetInfo.readInvalidStreet())
            {
                // The L* or G* file is missing for this street, or invalid data of some sort - so skip the street       
                // Display the start up error messages
                displayMgr.showThisSkippedStreetMsg(true);
                nextAction = SHOW_FAILED_STREET_MSG;
                return;
            }
            else if (streetInfo.readSkipStreet())
            {
                displayMgr.showThisSkippedStreetMsg(false);
                nextAction = SHOW_FAILED_STREET_MSG;
                return;
            }
            
            memory.printMemoryUsage();
            currentItemTSID = streetInfo.readCurrentItemTSIDBeingProcessed();
            if (currentItemTSID.length() == 0)
            {
                failNow = true;
                return;
            }
            displayMgr.showInfoMsg(downloadString + " item JSON file " + currentItemTSID + ".json for street " + configInfo.readStreetTSID(streetBeingProcessed) + " ... please wait");
            nextAction = INIT_ITEM_DATA;
            break;
            
        case SHOW_FAILED_STREET_MSG:
           // pause things for 5 seconds for actual errors - so user can see previous output about failed street - then move on to next one
            if (streetInfo.readInvalidStreet())
            {
                delay(5000);
            }
            else
            {
                // Just delay for 1s to show skipping street for legitimate reasons
                delay(1000);
            }
            displayMgr.clearDisplay();
            streetBeingProcessed++;
            if (streetBeingProcessed >= configInfo.readTotalJSONStreetCount())
            {
                // Reached end of list of streets - normal ending
                boolean nothingToShow = displayMgr.showAllSkippedStreetsMsg(); 
                String duration = "(" + printToFile.scanDuration() + ")";
                printToFile.printOutputLine("\n\nALL PROCESSING COMPLETED " + duration + "\n\n");
                printToFile.printDebugLine(this, "Exit now - All processing completed " + duration, 3);
                if (nothingToShow)
                {
                    // Display success message as no error message present
                    displayMgr.showSuccessMsg();
                }
                nextAction = WAITING_FOR_INPUT;
                return;
            }
            displayMgr.showInfoMsg(downloadString + " street JSON files for street " + configInfo.readStreetTSID(streetBeingProcessed) + " ... please wait");
            nextAction = INIT_STREET;
            break;
            
        case INIT_ITEM_DATA:
            printToFile.printDebugLine(this, "Timestamp: " + nf(hour(),2) + nf(minute(),2) + nf(second(),2), 1);
            
            // NEED TO LOOP THROUGH THIS UNTIL ALL ITEMS INIT/JSONS GOT
            // shoud we also get it to show a display message for each JSON??? 
            // would be done
            
            // If fails to load I* file - then give up - means the server connection is down or problems copying files
            if (!streetInfo.readStreetItemData())
            {
                // Error message set by this function
                println("Error detected in readStreetItemData");
                failNow = true;
                return;
            }
            
            if (streetInfo.readStreetInitialisationFinished())
            {
                // Loaded up all the information from street and item JSON files - can now start processing this street
                // First street image has already been loaded up (after did validation of snaps
                 printToFile.printDebugLine(this, "street initialised is " + configInfo.readStreetTSID(streetBeingProcessed) + " (" + streetBeingProcessed + ")", 1);
                memory.printMemoryUsage();
                nextAction = PROCESS_STREET;
            }
            else
            {
                currentItemTSID = streetInfo.readCurrentItemTSIDBeingProcessed();
                if (currentItemTSID.length() == 0)
                {
                    failNow = true;
                    return;
                }
                displayMgr.showInfoMsg(downloadString + " item JSON file " + currentItemTSID + ".json for street " + configInfo.readStreetTSID(streetBeingProcessed) + " ... please wait");
            }
            break;
            
        case PROCESS_STREET:
            // Process the street, one street snap at a time, going over each item in turn 
        
            // Process street item unless due to move on to next street
            printToFile.printDebugLine(this, "Processing street  " + streetBeingProcessed + " streetFinished flag is " + streetInfo.readStreetProcessingFinished(), 1);
            if (streetInfo.readStreetProcessingFinished())
            {    
                // Can now start writing the new JSONs to file
                if (!configInfo.readWriteJSONsToPersdata())
                {
                    // Do not want to write stuff to persdata - so just move on to next street
                    streetBeingProcessed++;
                    if (streetBeingProcessed >= configInfo.readTotalJSONStreetCount())
                    {
                        // Reached end of list of streets - normal ending
                        streetInfo = null;
                        System.gc();
                    
                        // Display any messages about failed streets before ending
                        nextAction = SHOW_FAILED_STREETS_MSG;
                    }
                    else
                    {
                        displayMgr.showInfoMsg(downloadString + " street JSON files for street " + configInfo.readStreetTSID(streetBeingProcessed) + " ... please wait");
                        nextAction = INIT_STREET;
                    }
                }
                else
                {
                    currentItemTSID = streetInfo.readCurrentItemTSIDBeingProcessed();
                    if (currentItemTSID.length() == 0)
                    {
                        failNow = true;
                        return;
                    }
                    //displayMgr.showInfoMsg("NEEDS CHANGING - PRINT IN LOWER LEVEL???Uploading item JSON file " + currentItemTSID + ".json for street " + configInfo.readStreetTSID(streetBeingProcessed) + " ... please wait");
                    nextAction = WRITE_ITEM_JSON;
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
            
        case WRITE_ITEM_JSON:
        
            if (!streetInfo.uploadStreetItemData())
            {
                delay(1000);
            }
            
            if (streetInfo.readStreetWritingItemsFinished())
            {
                // Have written all the item JSON files - so now move onto the next street
                streetBeingProcessed++;
                if (streetBeingProcessed >= configInfo.readTotalJSONStreetCount())
                {
                    // Reached end of list of streets - normal ending
                    streetInfo = null;
                    System.gc();
                    
                    // Display any messages about failed streets before ending
                    nextAction = SHOW_FAILED_STREETS_MSG;
                }  
                else
                {
                    displayMgr.showInfoMsg(downloadString + " street JSON files for street " + configInfo.readStreetTSID(streetBeingProcessed) + " ... please wait");
                    nextAction = INIT_STREET;
                }

            }
            else
            {
                currentItemTSID = streetInfo.readCurrentItemTSIDBeingProcessed();
                if (currentItemTSID.length() == 0)
                {
                    failNow = true;
                    return;
                }
                //displayMgr.showInfoMsg("NEEDS CHANGING - PRINT IN LOWER LEVEL???Uploading item JSON file " + currentItemTSID + ".json for street " + configInfo.readStreetTSID(streetBeingProcessed) + " ... please wait");
            }           
            break;
          
        case SHOW_FAILED_STREETS_MSG:
            boolean nothingToShow = displayMgr.showAllSkippedStreetsMsg();  
            String duration = "(" + printToFile.scanDuration() + ")";
            printToFile.printOutputLine("\n\nALL PROCESSING COMPLETED " + duration + "\n\n");
            printToFile.printDebugLine(this, "Exit now - All processing completed " + duration, 3);
            if (nothingToShow)
            {
                // Can go ahead and display success message as there are no error messages to show
                displayMgr.showSuccessMsg();
            }
            nextAction = WAITING_FOR_INPUT;
            break;
            
        case EXIT_NOW: 
            doExitCleanUp();
            memory.printMemoryUsage();
            exit();
            //break;
           
        default:
            // Error condition
            printToFile.printDebugLine(this, "Unexpected next action - " + nextAction, 3);
            exit();
    }
    //memory.printUsedMemory("end");
}

void doExitCleanUp()
{

    // Close sftp session
    if (QAsftp != null && QAsftp.readRunningFlag())
    {
        if (!QAsftp.executeCommand("exit", "session", null))
        {
            println("exit session failed");
        }
    }
    
    // Give warning if NewJSONs directory not empty
    String dirName = workingDir + File.separatorChar + "NewJSONs";
    File myDir = new File(dirName);
    
    // Only check that the NewJSONs directory is empty for the case where we are writing to persdata - if this flag is false, then 
    // NewJSONs will contain all the waiting new JSON files, which is not an error condition.
    if (configInfo != null && configInfo.readWriteJSONsToPersdata())
    {
        if (myDir.exists())
        {
            // No point reporting error if it does not exist. So only continue if the directory if found
            File[] contents = myDir.listFiles();
            if (contents != null && contents.length > 0) 
            {
                printToFile.printOutputLine("\n WARNING: Following changed item file(s) NOT been copied/uploaded correctly - may need to be manually added to persdata\n");
                printToFile.printDebugLine(this, "\n WARNING: Following changed item file(s) have NOT been copied/uploaded correctly - may need to be manually added to persdata\n", 3);
                for (int i=0; i< contents.length; i++)
                {
                    printToFile.printOutputLine("\t" + dirName + File.separatorChar + contents[i].getName());
                    printToFile.printDebugLine(this, "\t" + dirName + File.separatorChar + contents[i].getName(), 3);
                }
            }
        }
    }
    
    // Close the output/debug files
    printToFile.closeOutputFile();
    printToFile.closeDebugFile();
    printToFile.closevalidationSummaryOutputFile();
}

boolean initialiseStreet()
{       
    // Initialise street and then loads up the items on that street.
    displayMgr.clearDisplay();
    
    String streetTSID = configInfo.readStreetTSID(streetBeingProcessed);
    if (streetTSID.length() == 0)
    {
        // Failure to retrieve TSID
        printToFile.printDebugLine(this, "Failed to read street TSID number " + str(streetBeingProcessed) + " from QABot_config.json", 3); 
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
    // Retrieves the G/L* JSON files and places them in OrigJSONs
    // Reads in the item array, reads in info from G* file and validates the snaps
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
    // If they exist - then empty them if not keeping the files becase debug option set 
    if (!Utils.setupDir(workingDir + File.separatorChar +"NewJSONs", false))
    {
        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
        return false;
    }
    
    if (!Utils.setupDir(workingDir + File.separatorChar + "OrigJSONs", false))
    {
        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
        return false;
    }
    
    if (!Utils.setupDir(workingDir + File.separatorChar +"UploadedJSONs", false))
    {
        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
        return false;
    }
    
    // Default location for street output images is cleared each time the tool is run.
    // If the user has specified a path for these files, then they are not cleared - up to the user
    // Means that images are not lost when the tool is rerun for a single street for that region.
    if (!Utils.setupDir(workingDir + File.separatorChar +"StreetSummaries", false))
    {
        printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
        return false;
    }
    
    if (configInfo.readDebugDumpDiffImages())
    {
        if (!Utils.setupDir(workingDir + File.separatorChar +"BestMatchImages", false))
        {
            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
            return false;
        }
    }
    else
    {
        // remove the directory if present
        if (!Utils.deleteDir(workingDir + File.separatorChar +"BestMatchImages"))
        {
            printToFile.printDebugLine(this, Utils.readErrMsg(), 3);
            return false;
        }
        
    }
    
    return true; 
}


void keyPressed() 
{
    if ((key == 'x') || (key == 'X') || (key == 'q') || (key == 'Q'))
    {
        nextAction = EXIT_NOW;
        return;
    }
    
    // Make sure ESC closes window cleanly - and closes window
    if(key==27)
    {
        key = 0;
        nextAction = EXIT_NOW;
        return;
    }
}

boolean validConfigJSONLocation()
{
    // Searches for the configLocation.txt file which contains the saved location of the QABot_config.json file
    // That location is returned by this function.
    String  configLocation = "";
    File file = new File(sketchPath("configLocation.txt"));
    if (!file.exists())
    {
        return false;
    }
    
    // File exists - now validate
    //Read contents - first line is QABot_config.json location
    String [] configFileContents = loadStrings(sketchPath("configLocation.txt"));
    configLocation = configFileContents[0];
    
    // Have read in location - check it exists
    if (configLocation.length() > 0)
    {        
        file = new File(configLocation + File.separatorChar + "QABot_config.json");
        if (!file.exists())
        {
            println("Missing QABot_config.json file from ", configLocation);
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
        println("Window was closed or the user hit cancel");
        displayMgr.setSavedErrMsg("Window was closed or the user hit cancel");
        failNow = true;
        return;
    }      
    else 
    {
        println("User selected " + selection.getAbsolutePath());

        // Check that not selected QABot_config.json.txt which might look like QABot_config.json in the picker (as not seeing file suffixes for known file types on PC)
        if (!selection.getAbsolutePath().endsWith("QABot_config.json"))
        {
            println("Please select a QABot_config.json file (check does not have hidden .txt ending)");
            displayMgr.setSavedErrMsg("Please select a QABot_config.json file (check does not have hidden .txt ending)");
            failNow = true;
            return;
        }
        
        // User selected correct file name so now save
        String[] list = new String[1];
        // Strip out QABot_config.json part of name - to just get folder name
        list[0] = selection.getAbsolutePath().replace(File.separatorChar + "QABot_config.json", "");
        try
        {
            saveStrings(sketchPath("configLocation.txt"), list);
        }
        catch (Exception e)
        {
            println(e);
            println("error detected saving QABot_config.json location to configLocation.txt in program directory");
            displayMgr.setSavedErrMsg("Error detected saving QABot_config.json location to configLocation.txt in program directory");
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
   
  public JSONObject loadJSONObjectFromFile(String filename)
  {    
      // Alternative to official loadJSONObject() which does not close the file after reading the JSON object
      // Which means subsequent file delete/remove fails
      // Only needed when reading files in NewJSONs i.e. when do the JSONDiff functionality
    File file = new File(filename);
    BufferedReader reader = createReader(file);
    JSONObject result = new JSONObject(reader);
    try
    {
        reader.close();
    }
    catch (IOException e) 
    {
        e.printStackTrace();
        println("I/O exception closing ");
        printToFile.printDebugLine(this, "I/O exception closing " + filename, 3);
        return null;
    }
    
    return result;

   }

   
   public boolean copyFile(String sourcePath, String destPath)
    {
        
        InputStream is = createInput(sourcePath);
        OutputStream os = createOutput(destPath);
        
        if (is == null || os == null)
        {
            // Error setting up streams.
            printToFile.printDebugLine(this, "Error setting up streams for " + sourcePath + " and/or " + destPath, 3);
            return false;
        }
        
        byte[] buf = new byte[1024];
        int len;
        try 
        {
            while ((len = is.read(buf)) > 0) 
            {
                os.write(buf, 0, len);
            }
            
        }
        catch (IOException e) 
        {
            e.printStackTrace();
            printToFile.printDebugLine(this, "I/O exception copying " + sourcePath + " to " + destPath, 3);
            return false;
        }
        finally 
        {
            try 
            {
                is.close();
                os.flush();
                os.close();

            } 
            catch (IOException e) 
            {
                e.printStackTrace();
                printToFile.printDebugLine(this, "I/O exception closing " + sourcePath + " and/or " + destPath, 3);
                return false;
            }
        }
        
        return true;
    }
    
    // This makes sure that if user clicks on 'x', the program shuts cleanly.
    // Handles all kinds of exit.
    private void prepareExitHandler () 
    {

        Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {

        public void run () 
        {

           //System.out.println("SHUTDOWN HOOK");

           // application exit code here
           //nextAction = EXIT_NOW;
           // Have to call the exit handling functionality directly
           doExitCleanUp();
        }

    }));
   
}
