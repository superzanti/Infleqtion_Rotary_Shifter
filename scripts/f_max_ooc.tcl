# synth_fmax_search.tcl
reset_project

# read sources
read_vhdl ./src/rot_shifter.vhd
read_vhdl ./src/rot_shifter_axi.vhd
# read XDC if you have one (it should define clocks or we create clocks below)
read_xdc ./constraints/rot_shifter_axi.xdc

# synth OOC
synth_design -top rot_shifter_axi -mode out_of_context \
    -flatten_hierarchy none \
    -keep_equivalent_registers \
    -no_lc \
    -directive RuntimeOptimized

# Implementation
opt_design
place_design
route_design

report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -routable_nets -name timing_1