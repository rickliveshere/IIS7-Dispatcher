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
call :setPipelineAndRuntime
call :createWebsite
call :setHostDirectory
call :setBinding
call :setAppPool
call :createHostDirectory
call :createBackupDirectory
call :stopWebsite
call :backup
call :deploy
call :startWebsite
call :recycleAppPool
call :end
goto:eof
rem ------- END OF SCRIPT EXECUTION -------

rem ------- FUNCTIONS -------

:displayQuestions
echo Welcome to II7 Dispatcher!
echo ---------------------------
echo ***************************
echo APP POOL SETTINGS
set /p AppPoolName= 1. What should your AppPool be called in IIS? [Enter name]: 
echo ***************************
set /p DotNetVersion= 2. Which .net version? [v2.0/v4.0]: 
echo ***************************
set /p PipelineMode= 3. What pipeline mode should the AppPool use? [Integrated/Classic]: 
echo ***************************
echo WEBSITE SETTINGS 
set /p WebsiteName= 4. What name should your website have within IIS? [Enter name]: 
echo ***************************
set /p HostingDirectory= 5. What is the path for the hosting directory of the website? [Enter path - for example - c:\inetpub\wwwroot]: 
if /i [%HostingDirectory:~-1%] NEQ [\] set HostingDirectory=%HostingDirectory%\
set HostingDirectory=%HostingDirectory%%WebsiteName%
echo ***************************
set /p BindingProtocol= 6. What binding protocol does the website use? [http/https]: 
echo ***************************
set BindingPort=80
if "%BindingProtocol%" EQU "https" set BindingPort=443
if "%BindingProtocol%" EQU "http" set /p BindingPort= 7. What binding port does the website use? [Enter number]: 
echo ***************************
set /p BindingIP= 8. What IP address should the website bind to? [For all IP addresses - enter *]: 
echo ***************************
set /p BindingHostHeader= 9. What host header should the website bind to? [Enter host header - for example - www.contoso.com]: 
echo ***************************
echo DEPLOYMENT SETTINGS
set /p SourceDirectory= 10. Where are the deployment files located? [Enter file path - for example - c:\deployment\contoso]: 
if /i [%SourceDirectory:~-1%] EQU [\] set SourceDirectory=%SourceDirectory:~0,-1%
echo ***************************
echo ***************************
echo ***************************
echo ***************************
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
echo ***************************
set /p SettingsCorrect= Confirm - Are these settings correct? [y/n]: 
if "%SettingsCorrect%" EQU "y" goto BEGINEXECUTION

goto:eof

:displayHelp
SETLOCAL
echo Welcome to II7 Dispatcher!
echo ---------------------------
echo ***************************
echo Your options:
echo -a    Automated mode - will use the paramters set inside the batch script for execution. Useful when you would like to automate dispatch without any prompts.
echo -m    Manual mode - provides prompts for providing information for the dispatcher to use.
echo -?    Help - displays these options.
echo ***************************
goto:eof
ENDLOCAL

call appcmd add apppool /name:%AppPoolName%
rem error code 183 returned for duplication
if %ERRORLEVEL% GTR 0 if %ERRORLEVEL% NEQ 183 goto :setError %ERRORLEVEL%
if %ERRORLEVEL% GTR 0 if %ERRORLEVEL% EQU 183 echo App pool %AppPoolName% already setup
if %ERRORLEVEL% EQU 0 echo App pool %AppPoolName% created
goto:eof
ENDLOCAL

:createAppPool
SETLOCAL
echo Creating app pool....
call appcmd add apppool /name:%AppPoolName%
rem error code 183 returned for duplication
if %ERRORLEVEL% GTR 0 if %ERRORLEVEL% NEQ 183 goto :setError %ERRORLEVEL%
if %ERRORLEVEL% GTR 0 if %ERRORLEVEL% EQU 183 echo App pool %AppPoolName% already setup
if %ERRORLEVEL% EQU 0 echo App pool %AppPoolName% created
goto:eof
ENDLOCAL

:setPipelineAndRuntime
SETLOCAL
echo Setting managed runtime and pipeline mode....
call appcmd set apppool /apppool.name:%AppPoolName% /managedRuntimeVersion:%DotNetVersion% /managedPipelineMode:"%PipelineMode%"
if %ERRORLEVEL% GTR 0 goto :setError %ERRORLEVEL%
echo Managed runtime set to %DotNetVersion%
echo Pipeline mode set to %PipelineMode%
goto:eof
ENDLOCAL

:createWebsite
SETLOCAL
echo Creating website....
call APPCMD add site /name:%WebsiteName% /physicalPath:"%HostingDirectory%"
if %ERRORLEVEL% GTR 0 if %ERRORLEVEL% NEQ 183 goto :setError %ERRORLEVEL%
if %ERRORLEVEL% GTR 0 if %ERRORLEVEL% EQU 183 echo Website %WebsiteName% already setup!
if %ERRORLEVEL% EQU 0 echo Website %WebsiteName% created
goto:eof
ENDLOCAL

:setHostDirectory
SETLOCAL
echo Setting host directory....
call APPCMD set vdir "%WebsiteName%/" -physicalPath:"%HostingDirectory%"
if %ERRORLEVEL% GTR 0 goto :setError %ERRORLEVEL%
echo Host directory set to %HostingDirectory%
goto:eof
ENDLOCAL

:setBinding
SETLOCAL
echo Setting bindings....
call APPCMD set site /site.name:%WebsiteName% /+bindings.[protocol='%BindingProtocol%',bindingInformation='%BindingIP%:%BindingPort%:%BindingHostHeader%']
if %ERRORLEVEL% GTR 0 if %ERRORLEVEL% NEQ 183 goto :setError %ERRORLEVEL%
if %ERRORLEVEL% GTR 0 if %ERRORLEVEL% EQU 183 echo Binding already setup!
echo Binding set to %BindingProtocol%://%BindingHostHeader% - port %BindingPort% (ip %BindingIP%)
goto:eof
ENDLOCAL

:setAppPool
SETLOCAL
echo Assign website to app pool....
call APPCMD set app "%WebsiteName%/" /applicationpool:%AppPoolName%
if %ERRORLEVEL% GTR 0 goto :setError %ERRORLEVEL%
echo %WebsiteName% assigned to %AppPoolName%
goto:eof
ENDLOCAL

:stopWebsite
SETLOCAL
echo Stopping website....
call APPCMD stop site "%WebsiteName%"
if %ERRORLEVEL% GTR 0 goto :setError %ERRORLEVEL%
goto:eof
ENDLOCAL

:createBackupDirectory
SETLOCAL
IF EXIST %BackupDirectory% GOTO BACKUPFOLDERCREATED
 	MKDIR "%BackupDirectory%"
 	echo Backup directory created
:BACKUPFOLDERCREATED
if %ERRORLEVEL% GTR 0 goto :setError %ERRORLEVEL%
goto:eof
ENDLOCAL

:createHostDirectory
SETLOCAL
IF EXIST %HostingDirectory% GOTO READYFORBACKUP
	echo Creating hosting directory %HostingDirectory%
	MKDIR "%HostingDirectory%"
 	echo Hosting directory created
:READYFORBACKUP
if %ERRORLEVEL% GTR 0 goto :setError %ERRORLEVEL%
goto:eof
ENDLOCAL

:backup
SETLOCAL
echo Backing up existing artifacts....
call 7z a -tzip "%BackupDirectory%\%ArchiveName%.zip" "%HostingDirectory%\*.*" -mx5
if %ERRORLEVEL% GTR 0 goto :setError %ERRORLEVEL%
echo Backup created - %BackupDirectory%\%ArchiveName%.zip
goto:eof
ENDLOCAL

:deploy
SETLOCAL
echo Deploying artifacts....
rem Create a temp deployment directory
mkdir "%HostingDirectory%-temp-%d%-%t%"

rem Check for archive directory
IF EXIST %ArchiveDirectory% GOTO READYFORARCHIVING
	echo Creating archive directory %ArchiveDirectory%
	MKDIR "%ArchiveDirectory%"
 	echo Archive directory created
:READYFORARCHIVING

echo Zipping up contents of source directory to archive
call 7z a -tzip "%ArchiveDirectory%\%ArchiveName%-deploy-%d%-%t%.zip" "%SourceDirectory%\*" -mx5
if %ERRORLEVEL% GTR 0 goto :setError %ERRORLEVEL%

echo Extracting deployment....
call 7z x %ArchiveDirectory%\%ArchiveName%-deploy-%d%-%t%.zip -o%HostingDirectory%-temp-%d%-%t% -y

echo Updating host directory....
rename %HostingDirectory% "%WebsiteName%-old-%d%-%t%"
if %ERRORLEVEL% GTR 0 goto :setError %ERRORLEVEL%

rename %HostingDirectory%-temp-%d%-%t% "%WebsiteName%"

rem If there is an issue replacing the temp deployment directory as the host directory - revert
if %ERRORLEVEL% EQU 0 goto ALLDEPLOYED

	echo Reverting to original host directory
	rename %HostingDirectory%-old-%d%-%t% "%WebsiteName%"
	
	echo Deleting temporary files   
	RD /S /Q %HostingDirectory%-temp-%d%-%t%
	goto :setError %ERRORLEVEL%	
:ALLDEPLOYED

echo Delete old hosting directory %HostingDirectory%-old-%d%-%t%
RD /S /Q %HostingDirectory%-old-%d%-%t%

echo Delete old archive
DEL %ArchiveDirectory%\%ArchiveName%-deploy-%d%-%t%.zip

echo Deployed
goto:eof
ENDLOCAL

:startWebsite
SETLOCAL
echo Starting website....
call APPCMD start site "%WebsiteName%"
goto:eof
ENDLOCAL

:recycleAppPool
SETLOCAL
echo Recycling app pool....
call APPCMD recycle apppool /apppool.name:%AppPoolName%
goto:eof
ENDLOCAL

:setError
SETLOCAL
if %ERRORLEVEL% GTR 0 echo There has been a problem dispatching the website. See the command log for details
if %ERRORLEVEL% GTR 0 Exit /B %1
goto:eof
ENDLOCAL

:end
SETLOCAL
echo End of dispatch
goto:eof
ENDLOCAL
rem ------- END OF FUNCTIONS -------

rem ------- END OF BATCH SCRIPT -------
