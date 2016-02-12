import java.io.File;
import java.io.FilenameFilter;

static class Utils
{
    
    // Loads up a list of png files with the right street name 
    // NB The names return do not include the path, just the filename
    static public String[] loadFilenames(String path, final String nameToFind) 
    {
        File folder = new File(path);
 
        FilenameFilter filenameFilter = new FilenameFilter() 
        {
            public boolean accept(File dir, String name) 
            {
                if (name.startsWith(nameToFind) && name.toLowerCase().endsWith(".png"))
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
        };
  
        return folder.list(filenameFilter);
    }

}