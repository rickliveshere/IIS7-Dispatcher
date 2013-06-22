@echo off

rem ------- APP POOL SETTINGS ------- 
set AppPoolName=DemoWebsite

rem Which .net version - can either be v2.0 or v4.0
set DotNetVersion=v4.0

rem Pipeline mode - can either be Integrated or Classic
set PipelineMode=Integrated

rem ------- WEBSITE SETTINGS ------- 
set WebsiteName=DemoWebsite
set HostingDirectory=C:\inetpub\wwwroot\%WebsiteName%
set BindingProtocol=http
set BindingIP=*
set BindingPort=80
set BindingHostHeader=www.ssereward.com
set BackupDirectory=C:\Backup

echo "Creating app pool...."
call appcmd add apppool /name:%AppPoolName% /managedRuntimeVersion:%DotNetVersion% /managedPipelineMode:"%PipelineMode%"
if ERRORLEVEL 0 echo "App pool already setup!"

echo "Creating website...."
call APPCMD add site /name:%WebsiteName% /physicalPath:"%HostingDirectory%"
if ERRORLEVEL 0 echo "Website already setup!"

echo "Setting bindings...."
call APPCMD set site /site.name:%WebsiteName% /+bindings.[protocol='%BindingProtocol%',bindingInformation='%BindingIP%:%BindingPort%:%BindingHostHeader%']

echo "Assign website to app pool...."
call APPCMD set app "%WebsiteName%/" /applicationpool:%AppPoolName%

echo "Stopping website...."
call APPCMD stop site "%WebsiteName%"

IF EXIST C:\Backup GOTO BACKUPFOLDERCREATED
 	MKDIR "%BackupDirectory%"
 	echo "Backup directory created"
:BACKUPFOLDERCREATED

IF EXIST %HostingDirectory% GOTO READYFORBACKUP
	echo "Creating hosting directory %HostingDirectory%"
	MKDIR "%HostingDirectory%"
 	echo "Hosting directory created"
:READYFORBACKUP

echo "Backing up existing artifacts...."
rem cut off fractional seconds
set t=%time:~0,8%
rem replace colons with dashes
set t=%t::=%
set d=%date:/=%
set ArchiveName=%WebsiteName%-%d%-%t%

call 7z a -tzip "%BackupDirectory%\%ArchiveName%.zip" "%HostingDirectory%\*.*" -mx5

echo "Deploying artifacts...."



echo "Deployed"

echo "Starting website...."
call APPCMD start site "%WebsiteName%"

echo "Website started"