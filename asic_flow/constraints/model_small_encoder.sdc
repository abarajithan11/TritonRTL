set clock_cycle 25
set io_delay 5 

create_clock -name clk -period $clock_cycle [get_ports clk]
# set_false_path -from [get_ports "rstn"]

set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [all_inputs]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [all_outputs]
 