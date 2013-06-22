IIS7-Dispatcher
===============

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

INTRODUCING IIS7 DISPATCHER!!!!

(...ahem, ok, ok...it's just a really simple batch script - but it does help and can be modified to suit your needs!)


Setup
=====
You will need to download a copy of 7zip from here - http://www.7-zip.org/

After downloading and installing - add:
  - The installation directory for 7zip and..
  - C:\Windows\system32\inetsrv

...to your PATH system environment variable.


Configuration
=============
1. Open dispatcher.bat in your favourite text editor.
2. At the top of file is a set of variables for setting an app pool and website in IIS7. Ammend the settings to suit your needs
3. Run the batch script with administrative privelages.
4. If everything goes according to plan, your website should have been setup, backed up, deployed and running. Hey, haven't you got a party to go to?

*Disclaimer
This batch script is presented *as-is* and take no responsibility for any loss or damage without liability resulting from its execution.
