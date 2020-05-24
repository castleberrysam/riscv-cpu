# start the hardware server
open_hw
connect_hw_server
open_hw_target

# find the fpga
set device [lindex [get_hw_devices] 0]
current_hw_device $device
refresh_hw_device -update_hw_probes false $device

# program the fpga
set_property PROGRAM.FILE top.bit $device
program_hw_devices $device
refresh_hw_device $device

# stop the hardware server
close_hw_target
disconnect_hw_server
close_hw
