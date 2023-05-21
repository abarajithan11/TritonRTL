
call F:Xilinx\Vivado\2022.1\bin\xvlog -sv ..\sv\model_tb.sv ..\..\rtl\model.sv ..\..\rtl\qact.sv ..\..\rtl\add.sv ..\..\rtl\qconv2d.sv ..\..\rtl\qdense.sv ..\..\rtl\register.v ..\..\rtl\tmr.v 
IF %ERRORLEVEL% NEQ 0 exit
call F:Xilinx\Vivado\2022.1\bin\xelab model_tb --snapshot model_tb -log elaborate.log --debug typical
IF %ERRORLEVEL% NEQ 0 exit
call F:Xilinx\Vivado\2022.1\bin\xsim model_tb --tclbatch xsim_cfg.tcl
IF %ERRORLEVEL% NEQ 0 exit
