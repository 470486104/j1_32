#create_clock -name clk_in -period 20 [get_ports clk_in]

set_property IOSTANDARD LVCMOS33 [get_ports clk_in]
set_property PACKAGE_PIN F3 [get_ports rx]
set_property PACKAGE_PIN E3 [get_ports tx]
set_property PACKAGE_PIN M21 [get_ports clk_in]
set_property IOSTANDARD LVCMOS33 [get_ports rx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]

#set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets cpu/arbiter/new_cpu_data]
#set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets cpu/arbiter/new_cpu_inst]
#set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets cpu/arbiter/sel_inst]
#set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets cpu/arbiter/sel_data]

#set_property SEVERITY {Warning}  [get_drc_checks LUTLP-1]
#set_property SEVERITY {Warning} [get_drc_checks NSTD-1]

set_property SEVERITY {Warning}  [get_drc_checks LUTLP-1]
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]


set_property PACKAGE_PIN H7 [get_ports rst_in]
#set_property IOSTANDARD LVCMOS33 [get_ports key2]
set_property IOSTANDARD LVCMOS33 [get_ports rst_in]
#set_property PACKAGE_PIN M6 [get_ports key2]
