##Background
It's Friday, 6pm, and your about to go home. Your boss wanders over and asks for a quick 5 minute favour.

"The client is getting nervous," they roar, "they want to see some code and they want to see some code yesterday!"

"I'm counting on you to deploy the website tonight - this could really make or break us!"

Your mind starts to boggle. You start to map out the process of setting up a new IIS 7 website.

5 minutes right?

You slowly start banging your head against the desk.

Well - cheer up buddy - your going to make it to the party after all...

##IIS7 Dispatcher
It's just a really simple batch script - but it does help and can be modified to suit your needs :)

It utilizes AppCmd - a command line tool from Microsoft to administer IIS7. To learn how to use AppCmd please goto http://www.iis.net/learn/get-started/getting-started-with-iis/getting-started-with-appcmdexe

IIS7 Dispatcher when run will perform the following actions:
  - Create an app pool (if it doesn't already exist)
  - Set the app pool pipeline mode
  - Set the app pool .net runtime
  - Create a website and root virtual directory (if it doesn't already exist)
  - Setup a website binding (including protocol, ip address and host header)
  - Associate the website with the app pool
  - Create a host directory (if it doesn't already exist)
  - Create a backup directory (if it doesn't already exist)
  - Stop the website
  - Backup the host directory into a timestamped zip archive
  - Deploy the website artifacts to the host directory
  - Start the website
  - Recycle the app pool

##Setup
You will need to download nad install a copy of 7zip from here - http://www.7-zip.org/

Add the following to the PATH system environment variable:
  - The installation directory for 7zip and..
  - C:\Windows\system32\inetsrv

Optionally, you may also like to add the directory where IIS7-Dispatcher resides.

##Usage
Open a new command line window (with administrative privileges) on the server where the website is going to be setup. 

Enter the command:<br />
<code>dispatcher [switch]</code>

Switches:<br />
<code>-?&nbsp;&nbsp;&nbsp;&nbsp;Displays the help menu</code><br />
<code>-m&nbsp;&nbsp;&nbsp;&nbsp;Manual mode - guides you through a series of questions for setting up a website</code><br />
<code>-a&nbsp;&nbsp;&nbsp;&nbsp;Automated mode - uses default settings to execute. These settings can be changed by opening the script in your<br />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;favourite text editor. Useful when executed as part of an automated build process.</code><br />

If everything goes according to plan, your website should have been setup, backed up, deployed and running. Hey, haven't you got a party to go to?

####Disclaimer
This batch script is presented *as-is* and its creator or contributors take no responsibility for any loss or damage without liability resulting from its execution.
