create_clock -name clk -period 10.0 [get_ports clk]
set_input_delay 1.0 -clock clk [get_ports start]
set_input_delay 1.0 -clock clk [get_ports reset_n]
set_output_delay 1.0 -clock clk [get_ports test_done]
set_output_delay 1.0 -clock clk [get_ports fail_flag]
set_output_delay 1.0 -clock clk [get_ports fail_addr[*]]
set_false_path -to [get_ports dbg_*]
set_false_path -from [get_ports reset_n]

set_property IOB TRUE [get_cells fail_addr_r_reg*]
set_property IOB TRUE [get_cells fail_flag_r_reg]
set_property IOB TRUE [get_cells test_done_r_reg]

set_multicycle_path 2 -setup -to [get_ports fail_addr*]
set_multicycle_path 2 -setup -to [get_ports fail_flag]
set_multicycle_path 2 -setup -to [get_ports test_done]

set_multicycle_path 1 -hold -to [get_ports fail_addr*]
set_multicycle_path 1 -hold -to [get_ports fail_flag]
set_multicycle_path 1 -hold -to [get_ports test_done]

#set_false_path -hold -to [get_ports fail_addr*]
#set_false_path -hold -to [get_ports fail_flag]
#set_false_path -hold -to [get_ports test_done]

set_false_path -hold -to [get_pins -hierarchical */CE]





