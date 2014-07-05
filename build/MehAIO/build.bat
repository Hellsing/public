@echo off

:: Defines
set buildFile="..\\..\\MehAIO.lua"
set version=1.0

:: Cleanup
del %buildFile%

:: Merge header
type header.lua >> %buildFile%
echo. >> %buildFile% & echo. >> %buildFile%

:: Merge champ scripts
for %%x in (champs\\*.lua) do (
    type "%%x" >> %buildFile%
    echo. >> %buildFile% & echo. >> %buildFile%
)

:: Merge footer
type footer.lua >> %buildFile%