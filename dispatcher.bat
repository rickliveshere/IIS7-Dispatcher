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
set BindingHostHeader=www.contoso.com

rem ------- DEPLOYMENT SETTINGS -------
set SourceDirectory=C:\Deployment\%WebsiteName%

rem ------- BACKUP/ARCHIVING SETTINGS -------
set BackupDirectory=C:\Backup

rem --* The following code below will ensure your artifacts are backed up in a zip file labeled as [WebsiteName]-[Date]-[Time].zip *--
rem cut off fractional seconds
set t=%time:~0,8%
rem remove colons
set t=%t::=%
set t=%t: =%
rem remove slashes
set d=%date:/=%
set ArchiveName=%WebsiteName%-%d%-%t%

rem ------- START OF BATCH SCRIPT -------

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
copy /Y /B /V %SourceDirectory%\* "%HostingDirectory%-temp-%d%-%t%"
if %ERRORLEVEL% GTR 0 goto :setError %ERRORLEVEL%

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
