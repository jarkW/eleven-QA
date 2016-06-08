/*
 * Code for JAVA SFTP library
 * For use with Processing.org
 * Heavily based off of examples from JSCH: http://www.jcraft.com/jsch/
 * Oh, and doesn't work at all without JSCH: http://www.jcraft.com/jsch/
 * 
 * Daniel Shiffman, June 2007
 * http://www.shiffman.net
 * 
 * JSCH:
 * Copyright (c) 2002,2003,2004,2005,2006,2007 Atsuhiko Yamanaka, JCraft,Inc. 
 * All rights reserved
 *
 * Added support for port - as we don't use port 22
 * Changed interface to execute function so that I pass each part of the command as a separate
 * parameter - otherwise splitting the string at " " means that file names with spaces in
 * cause a problem e.g. for get command.
 * Changed execute function to return true/false depending on whether it succeeded or not.
 * 
 */

//package sftp;

import com.jcraft.jsch.Channel;
import com.jcraft.jsch.ChannelSftp;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.JSchException;
import com.jcraft.jsch.Session;
import com.jcraft.jsch.SftpException;
import com.jcraft.jsch.SftpProgressMonitor;
import com.jcraft.jsch.UserInfo;

public class Sftp extends Thread {

    String host;
    String user;
    int myPort;
    boolean running;
    JSch jsch;
    Session session;
    ChannelSftp sftp;
    
    boolean prompt;
    String password;
    

    public Sftp(String h, String u, boolean p, int port) 
    {
        host = h;
        user = u;
        prompt = p;
        myPort = port;
        password = "";
    }

    public void start() 
    {
        super.start();
        running = true;
    }

    public void run() 
    {
        try 
        {
            System.out.println("Attempting to connect.");
            jsch=new JSch();
            //session = jsch.getSession(user, host, 22);
            try
            {
                session = jsch.getSession(user, host, myPort);
            }
            catch (Exception e)
            {
                println(e);
                printToFile.printDebugLine(this, "Failed to get session - reason " + e.getClass(), 3);
                running = false;
                return;
            }
            UserInfo ui=new PromptUser(prompt,password);
            session.setUserInfo(ui);
            System.out.println("Logging in.");
            
            try
            {
                session.connect();
            }
            catch (JSchException e)
            {
                if (e.getCause() != null && e.getCause().getClass().equals(java.net.UnknownHostException.class))
                {
                    printToFile.printDebugLine(this, "Failed to login - unrecognised host " + host, 3);
                }
                else if (e.getCause() != null && e.getCause().getClass().equals(java.net.ConnectException.class))
                {
                    printToFile.printDebugLine(this, "Failed to login - connection failure - is port " + myPort + " correct?", 3);
                }
                else if (e.getMessage().equals("Auth fail"))
                {
                    printToFile.printDebugLine(this, "Failed to login - connection failure - are username " + user + " and password " + password + " correct?", 3);
                }
                else
                {
                    printToFile.printDebugLine(this, "Failed to login - JSchException - " + e.getMessage(), 3);
                }
                running = false;
                return;
            }
            catch (Exception e)
            {
                printToFile.printDebugLine(this, "Failed to login - generalised exception " + e.getClass() + ": " + e.getMessage(), 3);
                running = false;
                return;
            }

            System.out.println("Connected, session started.");
            Channel channel;
            try
            {
                channel= session.openChannel("sftp");
            }
            catch (JSchException e)
            { 
                printToFile.printDebugLine(this, "Failed to open channel - JSchException - " + e.getClass()+ ": " + e.getMessage(), 3);
                running = false;
                return;
            }
            catch (Exception e)
            {
                printToFile.printDebugLine(this, "Failed to open channel - generalised exception " + e.getClass()+ ": " + e.getMessage(), 3);
                running = false;
                return;
            }
            
            try
            {
                channel.connect();
            }
            catch (JSchException e)
            { 
                printToFile.printDebugLine(this, "Failed to connect to channel - JSchException - " + e.getClass()+ ": " + e.getMessage(), 3);
                running = false;
                return;
            }
            catch (Exception e)
            {
                printToFile.printDebugLine(this, "Failed to connect to channel - generalised exception " + e.getClass()+ ": " + e.getMessage(), 3);
                running = false;
                return;
            }
            
            sftp=(ChannelSftp)channel;
            
            while (running) 
            {
                Thread.sleep(1000);
                // do nothing;

            }
            sftp.exit();
            session.disconnect();
            
        } 
 
        catch (InterruptedException e) 
        {
            System.out.println("Thread interuppted");
            e.printStackTrace();
            printToFile.printDebugLine(this, "SFTP Thread interrupted " + e.getClass(), 3);
            running = false;
        }
        catch (Exception e) 
        {
            e.printStackTrace();
            printToFile.printDebugLine(this, "SFTP Thread general exception " + e.getClass(), 3);
            running = false;
        }
    }

    public boolean executeCommand(String s1, String s2, String s3) 
    {
        // Need to separate out command in calling function - otherwise file name cannot contain spaces
        // so can't rely on splitting a string by space in order to separate out command/parameters
        String[] cmds = new String[3];
        cmds[0] = s1;
        cmds[1] = s2;
        cmds[2] = s3;
        
        if (sftp == null)
        {
            return false;
        }

        if (cmds[0].equals("quit"))
        {
            sftp.quit();
            if (cmds[1] != null && cmds[1].equals("session"))
            {
                running = false;
            }
            return true;
        }
        
        if (cmds[0].equals("exit"))
        {
            sftp.exit();
            if (cmds[1] != null && cmds[1].equals("session"))
            {
                running = false;
            }
            
            return true;
        }
        
        if (cmds[0].equals("pwd") || cmds[0].equals("lpwd"))
        {
            String str=(cmds[0].equals("pwd")?"Remote":"Local");
            str+=" working directory: ";
            if (cmds[0].equals("pwd"))
            {
                str+=sftp.pwd();
            }
            else 
            {
                str+=sftp.lpwd();
            }
            System.out.println(str);
            return true;
        }
        
        if (cmds[0].equals("ls") || cmds[0].equals("dir"))
        {
            String path=".";
            boolean silent = false;
            
            if (s2 != null)
            {
                path=s2;
            }
            if ((s3 != null) && s3.equals("silent"))
            {
                silent = true;
            }
            try
            {
                if (!silent)
                {
                    println("path ", path, "sftp ", sftp);
                }
                java.util.Vector vv=sftp.ls(path);
                if (vv!=null)
                {
                    for (int ii=0; ii<vv.size(); ii++)
                    {
                        Object obj=vv.elementAt(ii);
                        if (obj instanceof com.jcraft.jsch.ChannelSftp.LsEntry)
                        {
                            if (!silent)
                            {
                                System.out.println(((com.jcraft.jsch.ChannelSftp.LsEntry)obj).getLongname());
                            }
                        }
                    }
                }
            }
            catch(SftpException e)
            {
                if (e.getMessage().equals("No such file"))
                {
                    // Only print this warning message if a non-silent ls command - silent ls is used to test whether a file exists, when a failure is not an error, just information
                    if (!silent)
                    {
                        printToFile.printDebugLine(this, "SFTP LS FAILED: \"no such file\" : check source folder/file exists for " + s2, 1);
                    }
                }
                else
                {
                    printToFile.printDebugLine(this, "SFTP LS FAILED with SftpException: " + e.getMessage(), 3);
                }
                return false;
            }
            catch (Exception e)
            {
                printToFile.printDebugLine(this, "SFTP LS FAILED with Exception: " + e.getMessage(), 3);
                return false;
            }
            
            return true;
        }

        if (cmds[0].equals("get")) 
        {
            String p1=cmds[1];
            String p2=".";
            if (s3 != null)
            {
                p2=s3;
            }
            
            // Check status
            if (!readSessionConnect())
            {
                printToFile.printDebugLine(this, " SFTP GET failed (session down): " + p1 + " to " + p2, 3);
                return false;
            }
            SftpProgressMonitor monitor=new Progress();
            int mode=ChannelSftp.OVERWRITE;
            try 
            {
                printToFile.printDebugLine(this, " SFTP GET: " + p1 + " to " + p2, 1);
                sftp.get(p1, p2, monitor, mode);
            } 
            catch (SftpException e) 
            { 
                //e.printStackTrace();
                if (e.getMessage().equals("No such file"))
                {
                    printToFile.printDebugLine(this, "SFTP GET FAILED: \"no such file\" : check source folder/file exists for " + p1, 1);
                }
                else if (e.getCause() != null && e.getCause().getClass().equals(java.io.FileNotFoundException.class))
                {
                    printToFile.printDebugLine(this, "SFTP GET FAILED: Cannot write destination file - check folder permissions for "+ p2, 3);
                }
                else if (e.getCause() != null && e.getCause().getClass().equals(java.lang.NullPointerException.class))
                {
                    printToFile.printDebugLine(this, "SFTP GET FAILED: sftp connection is down", 3);
                }
                else
                {
                    printToFile.printDebugLine(this, "SFTP GET FAILED with SftpException: " + e.getMessage(), 3);
                }
                return false;
            }
            catch (Exception e)
            {
                printToFile.printDebugLine(this, "SFTP GET FAILED with Exception: " + e.getMessage(), 3);
            }
            printToFile.printDebugLine(this, " SFTP GET suceeded: " + p1 + " to " + p2, 1);
            return true;
        }
        
        if (cmds[0].equals("put")) 
        {
            String p1=cmds[1];
            String p2=".";
            if (s3 != null)
            {
                p2=s3;
            }
            // Check status
            if (!readSessionConnect())
            {
                printToFile.printDebugLine(this, " SFTP PUT failed (session down): " + p1 + " to " + p2, 3);
                return false;
            }
            
            SftpProgressMonitor monitor=new Progress();
            int mode=ChannelSftp.OVERWRITE;
            try 
            {
                printToFile.printDebugLine(this, " SFTP PUT: " + p1 + " to " + p2, 1);
                sftp.put(p1, p2, monitor, mode);
            } 
            catch (SftpException e) 
            {
                //e.printStackTrace();
                if (e.getMessage().equals("No such file"))
                {
                    printToFile.printDebugLine(this, "SFTP PUT FAILED: \"no such file\" : check destination folder exists or has correct permissions for " + p2, 3);
                }
                else if (e.getCause() != null && e.getCause().getClass().equals(java.io.FileNotFoundException.class))
                {
                    printToFile.printDebugLine(this, "SFTP PUT FAILED: Cannot find file "+ p1, 3);
                }
                else if (e.getCause() != null && e.getCause().getClass().equals(java.lang.NullPointerException.class))
                {
                    printToFile.printDebugLine(this, "SFTP PUT FAILED: sftp connection is down", 3);
                }
                else
                {
                    printToFile.printDebugLine(this, "SFTP PUT FAILED with SftpException: " + e.getMessage(), 3);
                }
                return false;
            }
            catch (Exception e)
            {
                printToFile.printDebugLine(this, "SFTP PUT FAILED with Exception: " + e.getMessage(), 3);
            }
            printToFile.printDebugLine(this, " SFTP PUT succeeded: " + p1 + " to " + p2, 1);
            return true;
        }

        if (cmds[0].equals("version"))
        {
            System.out.println("SFTP protocol version "+sftp.version());
            return true;
        }
        
        if (cmds[0].equals("help") || cmds[0].equals("?"))
        {    
            System.out.println("help");
            return true;
        }
        
        System.out.println("unimplemented command: "+cmds[0]);
        return false;
    
    }

    public void setPassword(String s) 
    {
        // DANGER IF WE'RE NOT USING A PROMPT
        password = s;
        
    }
    
    public boolean readSessionConnect()
    {
        if (sftp != null && readRunningFlag() && (session != null && session.isConnected()))
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    
    public boolean readRunningFlag()
    {
        return running;
    }
}

//System.exit(0);