// Timing constraints for Tang Console 60K (GW5AT-LV60PG484AC1/I0)

create_clock -name sys_clk -period 20.0 [get_nets {sys_clk}]       // 50 MHz
create_clock -name hclk5 -period 2.6936 [get_nets {hclk5}]          // 371.25 MHz

report_timing -hold -from_clock [get_clocks {*clk*}] -to_clock [get_clocks {*clk*}] -max_paths 25 -max_common_paths 1
report_timing -setup -from_clock [get_clocks {*clk*}] -to_clock [get_clocks {*clk*}] -max_paths 25 -max_common_paths 1
