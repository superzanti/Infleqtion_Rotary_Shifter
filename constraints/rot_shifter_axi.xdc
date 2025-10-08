# Create a virtual clock for simulation (critical!)
create_clock -name clk -period 1.600 [get_ports clk]

# Input constraints (for timing analysis only)
set_input_delay 0.1 -clock clk [get_ports s_axis_tdata]
set_input_delay 0.1 -clock clk [get_ports s_axis_tuser]
set_input_delay 0.1 -clock clk [get_ports s_axis_tvalid]
set_input_delay 0.1 -clock clk [get_ports m_axis_tready]

# Output constraints (for timing analysis only)
set_output_delay 0.1 -clock clk [get_ports m_axis_tdata]
set_output_delay 0.1 -clock clk [get_ports m_axis_tvalid]
set_output_delay 0.1 -clock clk [get_ports s_axis_tready]

# Reset comes from out of fpga
set_false_path -from [get_ports rst_n]

# Out of context module
# We don't need to route out anything
# It is up to the implementer of the design to make sure this is registered properly to meet timing
set_false_path -from [get_pins {pipeline_out.m_axis_tdata_reg[*]/C}] -to [get_ports {m_axis_tdata[*]}]
set_false_path -from [get_pins pipeline_out.s_axis_tready_reg/C] -to [get_ports s_axis_tready]
set_false_path -from [get_pins pipeline_out.m_axis_tvalid_reg/C] -to [get_ports m_axis_tvalid]
set_false_path -from [get_ports {s_axis_tuser[*]}] -to [get_pins {shift_amt_reg[*]/D}]
set_false_path -from [get_ports {s_axis_tuser[*]}] -to [get_pins {pipeline_in.s_axis_tuser_int_reg[*]/D}]
set_false_path -from [get_ports {s_axis_tdata[*]}] -to [get_pins {pipeline_in.s_axis_tdata_int_reg[*]/D}]
set_false_path -from [get_ports {s_axis_tdata[*]}] -to [get_pins {data_in_reg[*]/D}]
set_false_path -from [get_ports s_axis_tvalid] -to [get_pins pipeline_out.s_axis_tready_reg/D]
set_false_path -from [get_ports s_axis_tvalid] -to [get_pins pipeline_out.m_axis_tvalid_reg/D]
set_false_path -from [get_ports s_axis_tvalid] -to [get_pins pipeline_in.s_axis_tvalid_int_reg/D]
set_false_path -from [get_ports s_axis_tvalid] -to [get_pins {data_in_reg[*]/CE}]
set_false_path -from [get_ports s_axis_tvalid] -to [get_pins {shift_amt_reg[*]/CE}]
set_false_path -from [get_ports m_axis_tready] -to [get_pins pipeline_in.m_axis_tready_int_reg/D]