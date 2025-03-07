

set GWSH=\Gowin\Gowin_V1.9.10.03_x64\IDE\bin\gw_sh

@REM echo
@REM echo "============ Building console60k with snes controller ==============="
@REM echo
@REM %GWSH% build.tcl console60k snes

echo
echo "============ Building console60k with ds2 controller ==============="
echo
%GWSH% build.tcl console60k ds2
if %errorlevel% neq 0 exit /b %errorlevel%

@REM echo
@REM echo "============ Building mega60k with snes controller ==============="
@REM echo
@REM %GWSH% build.tcl mega60k snes

echo
echo "============ Building mega60k with ds2 controller ==============="
echo
%GWSH% build.tcl mega60k ds2
if %errorlevel% neq 0 exit /b %errorlevel%

@REM echo
@REM echo "============ Building nano20k ==============="
@REM echo
@REM %GWSH% build.tcl nano20k

@REM echo
@REM echo "============ Building primer25k with snes controller ==============="
@REM echo
@REM %GWSH% build.tcl primer25k snes

echo
echo "============ Building primer25k with ds2 controller ==============="
echo
%GWSH% build.tcl primer25k ds2
if %errorlevel% neq 0 exit /b %errorlevel%

@REM echo
@REM echo "============ Building mega138k pro with snes controller ==============="
@REM echo
@REM %GWSH% build.tcl mega138k snes

echo
echo "============ Building mega138k pro with ds2 controller ==============="
echo
%GWSH% build.tcl mega138k ds2
if %errorlevel% neq 0 exit /b %errorlevel%

dir impl\pnr\*.fs

echo "All done."

