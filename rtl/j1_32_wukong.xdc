create_clock -name clk_in -period 20 [get_ports clk_in]

set_property IOSTANDARD LVCMOS33 [get_ports clk_in]
set_property PACKAGE_PIN F3 [get_ports rx]
set_property PACKAGE_PIN E3 [get_ports tx]
set_property PACKAGE_PIN M21 [get_ports clk_in]
set_property IOSTANDARD LVCMOS33 [get_ports rx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]



set_property PACKAGE_PIN H7 [get_ports rst_in]
set_property IOSTANDARD LVCMOS33 [get_ports rst_in]



