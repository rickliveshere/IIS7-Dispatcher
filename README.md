It's Friday, 6pm, and your about to go home. Your boss wanders over and asks for a quick 5 minute favour.

"The client is getting nervous," they roar, "they want to see some code and they want to see some code yesterday!"

"I'm counting on you to deploy the website tonight - this could really make or break us!"

Your mind starts to boggle. You start to map out the process of setting up a new IIS 7 website:
  - Logon to the server
  - Open IIS7
  - Create a new application pool and configure the pipline mode, .net version and account to run under
  - Create a new website and configure the hosting directory and bindings
  - Associate the website with the app pool
  - Create a hosting directory and ensure it has appropriate permissions for the account running the app pool
  - Archive existing artefacts into backup directory (zipped up of course)
  - Stop the website
  - Deploy new code
  - Start the website

5 minutes right?

You slowly start banging your head against the desk.

Well - cheer up buddy - your going to make it to the party after all...

*INTRODUCING IIS7 DISPATCHER!*

...ahem, ok, ok...it's just a really simple batch script :) - but it does help and can be modified to suit your needs!

It utilizes AppCmd - a command line tool from Microsoft to administer IIS7. To learn how to use AppCmd if you want to modify the script - please goto http://www.iis.net/learn/get-started/getting-started-with-iis/getting-started-with-appcmdexe


###Setup
You will need to download nad install a copy of 7zip from here - http://www.7-zip.org/

Add the following to the PATH system environment variable:
  - The installation directory for 7zip and..
  - C:\Windows\system32\inetsrv

Optionally, you may also like to add the directory where IIS7-Dispatcher resides if you would like to execute it from the command line without having to specify the full installation path each time.

###Usage
Open a new command line window (with administrative privileges) on the server where the website is going to be setup. 

Enter the command:<br />
<code>dispatcher [switch]</code>

Switches:<br />
<code>-?    Displays the help menu</code><br />
<code>-m    Manual mode - guides you through a series of questions for setting up a website</code><br />
<code>-a    Automated mode - uses the settings provided in the batch file to execute. Useful for running the script as part of a build process without any prompts.</code><br />

If everything goes according to plan, your website should have been setup, backed up, deployed and running. Hey, haven't you got a party to go to?

####Disclaimer
This batch script is presented *as-is* and take no responsibility for any loss or damage without liability resulting from its execution.
