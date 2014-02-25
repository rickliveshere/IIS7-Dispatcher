@echo off
cls

rem ------- SETTINGS -------
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
set BindingHostHeader=www.contoso.com

rem ------- DEPLOYMENT SETTINGS -------
set SourceDirectory=C:\Deployment\%WebsiteName%

rem ------- BACKUP/ARCHIVING SETTINGS -------
set BackupDirectory=C:\Backup
set ArchiveDirectory=C:\Archive

rem --* The following code below will ensure your artifacts are backed up in a zip file labeled as [WebsiteName]-[Date]-[Time].zip *--
rem cut off fractional seconds
set t=%time:~0,8%
rem remove colons
set t=%t::=%
set t=%t: =%
rem remove slashes
set d=%date:/=%
set ArchiveName=%WebsiteName%-%d%-%t%
rem ------- END OF SETTINGS -------

set ErrorMessages=

rem ------- BATCH SCRIPT -------

rem Check for parameters
set command=%1

:RESET
if "%command%" NEQ "-?" goto CONTINUE
goto :displayHelp
goto:eof

:CONTINUE
if "%command%" EQU "-a" goto BEGINEXECUTION
if "%command%" EQU "-m" goto displayQuestions
goto :displayHelp
goto:eof

:BEGINEXECUTION

rem ------- SCRIPT EXECUTION -------
call :createAppPool
IF [%ErrorMessages%] NEQ [] goto :end

call :setPipelineAndRuntime
IF [%ErrorMessages%] NEQ [] goto :end

call :createWebsite
IF [%ErrorMessages%] NEQ [] goto :end

call :setHostDirectory
IF [%ErrorMessages%] NEQ [] goto :end

call :setBinding
IF [%ErrorMessages%] NEQ [] goto :end

call :setAppPool
IF [%ErrorMessages%] NEQ [] goto :end

call :createHostDirectory
IF [%ErrorMessages%] NEQ [] goto :end

call :createBackupDirectory
IF [%ErrorMessages%] NEQ [] goto :end

call :stopWebsite
IF [%ErrorMessages%] NEQ [] goto RESTARTWEBSITE

call :backup
IF [%ErrorMessages%] NEQ [] goto RESTARTWEBSITE

call :deploy
IF [%ErrorMessages%] NEQ [] goto RESTARTWEBSITE

call :deleteBackups
IF [%ErrorMessages%] NEQ [] goto RESTARTWEBSITE

:RESTARTWEBSITE
call :startWebsite
call :recycleAppPool
call :end
goto:eof
rem ------- END OF SCRIPT EXECUTION -------

rem ------- FUNCTIONS -------

:displayQuestions
echo Welcome to II7 Dispatcher!
echo ---------------------------
&& echo
echo APP POOL SETTINGS
set /p AppPoolName= 1. What should your AppPool be called in IIS? [Enter name]: 
echo.
set /p DotNetVersion= 2. Which .net version? [v2.0/v4.0]: 
echo.
set /p PipelineMode= 3. What pipeline mode should the AppPool use? [Integrated/Classic]: 
echo.
echo WEBSITE SETTINGS 
set /p WebsiteName= 4. What name should your website have within IIS? [Enter name]: 
echo.
set /p HostingDirectory= 5. What is the path for the hosting directory of the website? [Enter path - for example - c:\inetpub\wwwroot]: 
if /i [%HostingDirectory:~-1%] NEQ [\] set HostingDirectory=%HostingDirectory%\
set HostingDirectory=%HostingDirectory%%WebsiteName%
echo.
set /p BindingProtocol= 6. What binding protocol does the website use? [http/https]: 
echo.
set BindingPort=80
if "%BindingProtocol%" EQU "https" set BindingPort=443
if "%BindingProtocol%" EQU "http" set /p BindingPort= 6a. What binding port does the website use? [Enter number]: 
echo.
set /p BindingIP= 7. What IP address should the website bind to? [For all IP addresses - enter *]: 
echo.
set /p BindingHostHeader= 8. What host header should the website bind to? [Enter host header - for example - www.contoso.com]: 
echo.
echo DEPLOYMENT SETTINGS
set /p SourceDirectory= 9. Where are the deployment files located? [Enter file path - for example - c:\deployment\contoso]: 
if /i [%SourceDirectory:~-1%] EQU [\] set SourceDirectory=%SourceDirectory:~0,-1%
echo.
echo.
echo.
echo.
echo YOUR SETTINGS:
echo App pool: %AppPoolName%
echo .Net Version: %DotNetVersion%
echo Pipeline mode: %PipelineMode%
echo Website name: %WebsiteName%
echo Host directory: %HostingDirectory%
echo Binding protocol: %BindingProtocol%
echo Binding port: %BindingPort%
echo Binding IP: %BindingIP%
echo Host Header: %BindingHostHeader%
echo Directory where files will be deployed from: %SourceDirectory%
echo.
set /p SettingsCorrect= Confirm - Are these settings correct? [y/n]: 
if "%SettingsCorrect%" EQU "y" goto BEGINEXECUTION
goto:eof

:displayHelp
echo Welcome to II7 Dispatcher!
echo ---------------------------
echo.
echo Your options:
echo -a    Automated mode 
echo       Will use the paramters set inside the batch script for execution. 
echo       Useful when you would like to automate dispatch without any prompts.
echo.
echo -m    Manual mode 
echo       Provides prompts for providing information for the dispatcher to use.
echo.
echo -?    Help
echo       Displays these options.
echo.
echo.
goto:eof

:createAppPool
echo Creating app pool....
echo.
call appcmd add apppool /name:%AppPoolName%
rem error code 183 returned for duplication
if %ERRORLEVEL% GTR 0 if %ERRORLEVEL% NEQ 183 call :setError "There has been a problem creating the App Pool %AppPoolName%"
if %ERRORLEVEL% GTR 0 if %ERRORLEVEL% EQU 183 echo App pool %AppPoolName% already setup
if %ERRORLEVEL% EQU 0 echo App pool %AppPoolName% created
echo.
goto:eof

:setPipelineAndRuntime
echo Setting managed runtime and pipeline mode....
echo.
call appcmd set apppool /apppool.name:%AppPoolName% /managedRuntimeVersion:%DotNetVersion% /managedPipelineMode:"%PipelineMode%"
if %ERRORLEVEL% GTR 0 call :setError "Failed to set .net version and pipeline mode for app pool %AppPoolName%"
echo Managed runtime set to %DotNetVersion%
echo.
echo Pipeline mode set to %PipelineMode%
echo.
goto:eof

:createWebsite
echo Creating website....
echo.
call APPCMD add site /name:%WebsiteName% /physicalPath:"%HostingDirectory%"
if %ERRORLEVEL% GTR 0 if %ERRORLEVEL% NEQ 183 call :setError "Failed to create website %WebsiteName%"
if %ERRORLEVEL% GTR 0 if %ERRORLEVEL% EQU 183 echo Website %WebsiteName% already setup!
if %ERRORLEVEL% EQU 0 echo Website %WebsiteName% created
echo.
goto:eof

:setHostDirectory
echo Setting host directory....
echo.
call APPCMD set vdir "%WebsiteName%/" -physicalPath:"%HostingDirectory%"
if %ERRORLEVEL% GTR 0 call :setError "Failed to set host directory to %HostingDirectory% for website %WebsiteName%"
echo Host directory set to %HostingDirectory%
echo.
goto:eof

:setBinding
echo Setting bindings....
echo.
call APPCMD set site /site.name:%WebsiteName% /+bindings.[protocol='%BindingProtocol%',bindingInformation='%BindingIP%:%BindingPort%:%BindingHostHeader%']
if %ERRORLEVEL% GTR 0 if %ERRORLEVEL% NEQ 183 call :setError "Failed to set binding for website %WebsiteName%"
if %ERRORLEVEL% GTR 0 if %ERRORLEVEL% EQU 183 echo Binding already setup!
echo Binding set to %BindingProtocol%://%BindingHostHeader% - port %BindingPort% (ip %BindingIP%)
echo.
goto:eof

:setAppPool
echo Assign website to app pool....
echo.
call APPCMD set app "%WebsiteName%/" /applicationpool:%AppPoolName%
if %ERRORLEVEL% GTR 0 call :setError "Failed to assign app pool %AppPoolName% to website %WebsiteName%"
echo %WebsiteName% assigned to %AppPoolName%
echo.
goto:eof

:stopWebsite
echo Stopping website....
echo.
call APPCMD stop site "%WebsiteName%"
if %ERRORLEVEL% GTR 0 call :setError "Failed to stop website %WebsiteName%"
echo.
goto:eof

:createBackupDirectory
IF EXIST %BackupDirectory% GOTO BACKUPFOLDERCREATED
 	MKDIR "%BackupDirectory%"
 	echo Backup directory created
	echo.
:BACKUPFOLDERCREATED
if %ERRORLEVEL% GTR 0 call :setError "Failed to create backup %BackupDirectory%"
goto:eof

:createHostDirectory
IF EXIST %HostingDirectory% GOTO READYFORBACKUP
	echo Creating hosting directory %HostingDirectory%
	MKDIR "%HostingDirectory%"
 	echo Hosting directory created
	echo.
:READYFORBACKUP
if %ERRORLEVEL% GTR 0 call :setError "Failed to create host directory %HostingDirectory%"
goto:eof

:backup
echo Backing up existing artifacts....
echo.
call 7z a -tzip "%BackupDirectory%\%ArchiveName%.zip" "%HostingDirectory%\*.*" -mx5
if %ERRORLEVEL% GTR 0 call :setError "Failed to backup host directory %HostingDirectory%"
echo Backup created - %BackupDirectory%\%ArchiveName%.zip
echo.
goto:eof

:deploy
echo Deploying artifacts....
echo.

rem Create a temp deployment directory
mkdir "%HostingDirectory%-temp-%d%-%t%"
if %ERRORLEVEL% GTR 0 call :setError "Failed to create a temporary deployment directory %HostingDirectory%-temp-%d%-%t%"

rem Check for archive directory
IF EXIST %ArchiveDirectory% GOTO READYFORARCHIVING
	echo Creating archive directory %ArchiveDirectory%
	echo.
	MKDIR "%ArchiveDirectory%"
 	echo Archive directory created
	echo.
:READYFORARCHIVING
if %ERRORLEVEL% GTR 0 call :setError "Failed to create a archive directory %ArchiveDirectory%"

echo Zipping up contents of source directory to archive
echo.
call 7z a -tzip "%ArchiveDirectory%\%ArchiveName%-deploy-%d%-%t%.zip" "%SourceDirectory%\*" -mx5
if %ERRORLEVEL% GTR 0 call :setError "Failed to zip up contents of deployment directory %SourceDirectory%"

echo Extracting deployment....
echo.
call 7z x %ArchiveDirectory%\%ArchiveName%-deploy-%d%-%t%.zip -o%HostingDirectory%-temp-%d%-%t% -y
if %ERRORLEVEL% GTR 0 call :setError "Failed to extract contents of %ArchiveName%-deploy-%d%-%t%.zip to temporary deployment directory %HostingDirectory%-temp-%d%-%t%"

echo Updating host directory....
echo.
rename %HostingDirectory% "%WebsiteName%-old-%d%-%t%"
if %ERRORLEVEL% GTR 0 call :setError "Failed to update existing host directory %HostingDirectory% - nothing has changed"

rename %HostingDirectory%-temp-%d%-%t% "%WebsiteName%"

rem If there is an issue replacing the temp deployment directory as the host directory - revert
if %ERRORLEVEL% EQU 0 goto ALLDEPLOYED

	echo Reverting to original host directory....
	echo.
	rename %HostingDirectory%-old-%d%-%t% "%WebsiteName%"
	
	if %ERRORLEVEL% EQU 0 goto CONTINUEREVERTDEPLOYMENT	
	call :setError "Failed to revert host directory from %WebsiteName%-old-%d%-%t% back to %WebsiteName% - manual update required!"
	
	:CONTINUEREVERTDEPLOYMENT	
:ALLDEPLOYED

echo Deleting temporary files....
echo.  
RD /S /Q %HostingDirectory%-temp-%d%-%t%
if %ERRORLEVEL% GTR 0 call :setError "Failed to delete temporary deployment directory %HostingDirectory%-temp-%d%-%t%"

IF NOT EXIST %HostingDirectory%-old-%d%-%t% GOTO DELETEARCHIVE
echo Deleting old hosting directory %HostingDirectory%-old-%d%-%t%
echo.
RD /S /Q %HostingDirectory%-old-%d%-%t%
if %ERRORLEVEL% GTR 0 call :setError "Failed to delete old hosting directory directory %HostingDirectory%-old-%d%-%t% - manual deletion required!"

:DELETEARCHIVE
echo Deleting old deployment archive....
echo.
DEL %ArchiveDirectory%\%ArchiveName%-deploy-%d%-%t%.zip
if %ERRORLEVEL% GTR 0 call :setError "Failed to delete deployment archive %ArchiveDirectory%\%ArchiveName%-deploy-%d%-%t%.zip - manual deletion required!"

echo Deployed!
echo.
goto:eof

:deleteBackups
echo Deleting old backups....
echo.
echo Looking for %BackupDirectory%\%WebsiteName%*.zip
forfiles /p "%BackupDirectory%" /s /m "%WebsiteName%*.zip" /D -20 /C "cmd /c del @PATH"
if %ERRORLEVEL% GTR 0 call :setError "Failed to delete old backups for %WebsiteName%"
echo.
goto:eof

:startWebsite
echo Starting website....
echo.
call APPCMD start site "%WebsiteName%"
if %ERRORLEVEL% GTR 0 call :setError "Failed to start website %WebsiteName%"
echo.
goto:eof

:recycleAppPool
echo Recycling app pool....
echo.
call APPCMD recycle apppool /apppool.name:%AppPoolName%
if %ERRORLEVEL% GTR 0 call :setError "Failed to recycle app pool %AppPoolName%"
echo.
goto:eof

:setError
set error=%1
call :dequote error
set ErrorMessages="%ErrorMessages%#%error%"
goto:eof

:deQuote
for /f "delims=" %%A in ('echo %%%1%%') do set %1=%%~A
Goto :eof
:end
echo End of dispatch

IF [%ErrorMessages%] EQU [] goto NOERRORS
echo.
color F4
echo ********************************************************************************
echo There were errors dispatching the website. Please review:
echo.
FOR /f "delims=#" %%F IN (%ErrorMessages%) DO (
  ECHO  - %%F
)
echo.
echo.
echo ********************************************************************************
:NOERRORS
echo.
goto:eof
rem ------- END OF FUNCTIONS -------

rem ------- END OF BATCH SCRIPT -------
