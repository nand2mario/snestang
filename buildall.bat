

set GWSH=..\..\Gowin_V1.9.10.03_x64\IDE\bin\gw_sh

echo
echo "============ Building console60k with snes controller ==============="
echo
%GWSH% build.tcl console60k snes

echo
echo "============ Building console60k with ds2 controller ==============="
echo
%GWSH% build.tcl console60k ds2

echo
echo "============ Building mega60k with snes controller ==============="
echo
%GWSH% build.tcl mega60k snes

echo
echo "============ Building mega60k with ds2 controller ==============="
echo
%GWSH% build.tcl mega60k ds2

echo
echo "============ Building nano20k ==============="
echo
%GWSH% build.tcl nano20k

echo
echo "============ Building primer25k with snes controller ==============="
echo
%GWSH% build.tcl primer25k snes

echo
echo "============ Building primer25k with ds2 controller ==============="
echo
%GWSH% build.tcl primer25k ds2

echo
echo "============ Building mega138k pro with snes controller ==============="
echo
%GWSH% build.tcl mega138k snes

echo
echo "============ Building mega138k pro with ds2 controller ==============="
echo
%GWSH% build.tcl mega138k ds2

dir impl\pnr\*.fs

echo "All done."

