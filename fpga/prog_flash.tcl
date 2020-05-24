# start the hardware server
open_hw
connect_hw_server
open_hw_target

# find the fpga
set device [lindex [get_hw_devices] 0]
current_hw_device $device
refresh_hw_device -update_hw_probes false $device

# tell vivado about the spi flash
create_hw_cfgmem -hw_device $device [lindex [get_cfgmem_parts s25fl128sxxxxxx0-spi-x1_x2_x4] 0]

# program the spi flash
set cfgmem [get_property PROGRAM.HW_CFGMEM $device]
set_property PROGRAM.BLANK_CHECK 0 $cfgmem
set_property PROGRAM.ERASE 1 $cfgmem
set_property PROGRAM.CFG_PROGRAM 1 $cfgmem
set_property PROGRAM.VERIFY 1 $cfgmem
set_property PROGRAM.CHECKSUM 0 $cfgmem
refresh_hw_device $device

set_property PROGRAM.ADDRESS_RANGE use_file $cfgmem
set_property PROGRAM.FILES [list top.mcs] $cfgmem
set_property PROGRAM.PRM_FILE top.prm $cfgmem
set_property PROGRAM.UNUSED_PIN_TERMINATION pull-none $cfgmem

startgroup
if {![string equal [get_property PROGRAM.HW_CFGMEM_TYPE $device] [get_property MEM_TYPE [get_property CFGMEM_PART $cfgmem]]]} {
    create_hw_bitstream -hw_device $device [get_property PROGRAM.HW_CFGMEM_BITFILE $device]
    program_hw_devices $device
}
program_hw_cfgmem -hw_cfgmem $cfgmem
endgroup

# boot the fpga
boot_hw_device [current_hw_device]

# stop the hardware server
close_hw_target
disconnect_hw_server
close_hw
