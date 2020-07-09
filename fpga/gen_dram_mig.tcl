##################################################################
# CHECK VIVADO VERSION
##################################################################

set scripts_vivado_version 2019.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
  catch {common::send_msg_id "IPS_TCL-100" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_ip_tcl to create an updated script."}
  return 1
}

##################################################################
# START
##################################################################

set_part xc7s50csga324-1

##################################################################
# CHECK IPs
##################################################################

set bCheckIPs 1
set bCheckIPsPassed 1
if { $bCheckIPs == 1 } {
  set list_check_ips { xilinx.com:ip:mig_7series:4.2 }
  set list_ips_missing ""
  common::send_msg_id "IPS_TCL-1001" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

  foreach ip_vlnv $list_check_ips {
  set ip_obj [get_ipdefs -all $ip_vlnv]
  if { $ip_obj eq "" } {
    lappend list_ips_missing $ip_vlnv
    }
  }

  if { $list_ips_missing ne "" } {
    catch {common::send_msg_id "IPS_TCL-105" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
    set bCheckIPsPassed 0
  }
}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "IPS_TCL-102" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 1
}

##################################################################
# dram_mig FILES
##################################################################

proc write_prj_file {filepath} {
  set file_obj [open $filepath w+]

  puts $file_obj {﻿<?xml version="1.0" encoding="UTF-8" standalone="no" ?>}
  puts $file_obj {<!-- IMPORTANT: This is an internal file that has been generated by the MIG software. Any direct editing or changes made to this file may result in unpredictable behavior or data corruption. It is strongly advised that users do not edit the contents of this file. Re-run the MIG GUI with the required settings if any of the options provided below need to be altered. -->}
  puts $file_obj {<Project NoOfControllers="1">}
  puts $file_obj {  <ModuleName>dram_mig</ModuleName>}
  puts $file_obj {  <dci_inouts_inputs>1</dci_inouts_inputs>}
  puts $file_obj {  <dci_inputs>1</dci_inputs>}
  puts $file_obj {  <Debug_En>OFF</Debug_En>}
  puts $file_obj {  <DataDepth_En>1024</DataDepth_En>}
  puts $file_obj {  <LowPower_En>ON</LowPower_En>}
  puts $file_obj {  <XADC_En>Enabled</XADC_En>}
  puts $file_obj {  <TargetFPGA>xc7s50-csga324/-1</TargetFPGA>}
  puts $file_obj {  <Version>4.2</Version>}
  puts $file_obj {  <SystemClock>Single-Ended</SystemClock>}
  puts $file_obj {  <ReferenceClock>No Buffer</ReferenceClock>}
  puts $file_obj {  <SysResetPolarity>ACTIVE LOW</SysResetPolarity>}
  puts $file_obj {  <BankSelectionFlag>FALSE</BankSelectionFlag>}
  puts $file_obj {  <InternalVref>1</InternalVref>}
  puts $file_obj {  <dci_hr_inouts_inputs>50 Ohms</dci_hr_inouts_inputs>}
  puts $file_obj {  <dci_cascade>0</dci_cascade>}
  puts $file_obj {  <Controller number="0">}
  puts $file_obj {    <MemoryDevice>DDR3_SDRAM/Components/MT41K128M16XX-15E</MemoryDevice>}
  puts $file_obj {    <TimePeriod>3077</TimePeriod>}
  puts $file_obj {    <VccAuxIO>1.8V</VccAuxIO>}
  puts $file_obj {    <PHYRatio>2:1</PHYRatio>}
  puts $file_obj {    <InputClkFreq>99.997</InputClkFreq>}
  puts $file_obj {    <UIExtraClocks>1</UIExtraClocks>}
  puts $file_obj {    <MMCM_VCO>649</MMCM_VCO>}
  puts $file_obj {    <MMCMClkOut0> 3.250</MMCMClkOut0>}
  puts $file_obj {    <MMCMClkOut1>1</MMCMClkOut1>}
  puts $file_obj {    <MMCMClkOut2>1</MMCMClkOut2>}
  puts $file_obj {    <MMCMClkOut3>1</MMCMClkOut3>}
  puts $file_obj {    <MMCMClkOut4>1</MMCMClkOut4>}
  puts $file_obj {    <DataWidth>16</DataWidth>}
  puts $file_obj {    <DeepMemory>1</DeepMemory>}
  puts $file_obj {    <DataMask>1</DataMask>}
  puts $file_obj {    <ECC>Disabled</ECC>}
  puts $file_obj {    <Ordering>Normal</Ordering>}
  puts $file_obj {    <BankMachineCnt>4</BankMachineCnt>}
  puts $file_obj {    <CustomPart>FALSE</CustomPart>}
  puts $file_obj {    <NewPartName/>}
  puts $file_obj {    <RowAddress>14</RowAddress>}
  puts $file_obj {    <ColAddress>10</ColAddress>}
  puts $file_obj {    <BankAddress>3</BankAddress>}
  puts $file_obj {    <MemoryVoltage>1.35V</MemoryVoltage>}
  puts $file_obj {    <UserMemoryAddressMap>ROW_BANK_COLUMN</UserMemoryAddressMap>}
  puts $file_obj {    <PinSelection>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="U2" SLEW="" VCCAUX_IO="" name="ddr3_addr[0]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="P6" SLEW="" VCCAUX_IO="" name="ddr3_addr[10]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="T5" SLEW="" VCCAUX_IO="" name="ddr3_addr[11]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="R6" SLEW="" VCCAUX_IO="" name="ddr3_addr[12]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="U6" SLEW="" VCCAUX_IO="" name="ddr3_addr[13]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="R4" SLEW="" VCCAUX_IO="" name="ddr3_addr[1]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="V2" SLEW="" VCCAUX_IO="" name="ddr3_addr[2]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="V4" SLEW="" VCCAUX_IO="" name="ddr3_addr[3]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="T3" SLEW="" VCCAUX_IO="" name="ddr3_addr[4]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="R7" SLEW="" VCCAUX_IO="" name="ddr3_addr[5]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="V6" SLEW="" VCCAUX_IO="" name="ddr3_addr[6]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="T6" SLEW="" VCCAUX_IO="" name="ddr3_addr[7]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="U7" SLEW="" VCCAUX_IO="" name="ddr3_addr[8]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="V7" SLEW="" VCCAUX_IO="" name="ddr3_addr[9]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="V5" SLEW="" VCCAUX_IO="" name="ddr3_ba[0]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="T1" SLEW="" VCCAUX_IO="" name="ddr3_ba[1]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="U3" SLEW="" VCCAUX_IO="" name="ddr3_ba[2]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="V3" SLEW="" VCCAUX_IO="" name="ddr3_cas_n"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="DIFF_SSTL135" PADName="T4" SLEW="" VCCAUX_IO="" name="ddr3_ck_n[0]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="DIFF_SSTL135" PADName="R5" SLEW="" VCCAUX_IO="" name="ddr3_ck_p[0]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="T2" SLEW="" VCCAUX_IO="" name="ddr3_cke[0]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="R3" SLEW="" VCCAUX_IO="" name="ddr3_cs_n[0]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="K4" SLEW="" VCCAUX_IO="" name="ddr3_dm[0]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="M3" SLEW="" VCCAUX_IO="" name="ddr3_dm[1]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="K2" SLEW="" VCCAUX_IO="" name="ddr3_dq[0]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="N1" SLEW="" VCCAUX_IO="" name="ddr3_dq[10]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="N5" SLEW="" VCCAUX_IO="" name="ddr3_dq[11]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="M2" SLEW="" VCCAUX_IO="" name="ddr3_dq[12]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="P1" SLEW="" VCCAUX_IO="" name="ddr3_dq[13]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="M1" SLEW="" VCCAUX_IO="" name="ddr3_dq[14]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="P2" SLEW="" VCCAUX_IO="" name="ddr3_dq[15]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="K3" SLEW="" VCCAUX_IO="" name="ddr3_dq[1]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="L4" SLEW="" VCCAUX_IO="" name="ddr3_dq[2]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="M6" SLEW="" VCCAUX_IO="" name="ddr3_dq[3]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="K6" SLEW="" VCCAUX_IO="" name="ddr3_dq[4]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="M4" SLEW="" VCCAUX_IO="" name="ddr3_dq[5]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="L5" SLEW="" VCCAUX_IO="" name="ddr3_dq[6]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="L6" SLEW="" VCCAUX_IO="" name="ddr3_dq[7]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="N4" SLEW="" VCCAUX_IO="" name="ddr3_dq[8]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="R1" SLEW="" VCCAUX_IO="" name="ddr3_dq[9]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="DIFF_SSTL135" PADName="L1" SLEW="" VCCAUX_IO="" name="ddr3_dqs_n[0]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="DIFF_SSTL135" PADName="N2" SLEW="" VCCAUX_IO="" name="ddr3_dqs_n[1]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="DIFF_SSTL135" PADName="K1" SLEW="" VCCAUX_IO="" name="ddr3_dqs_p[0]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="DIFF_SSTL135" PADName="N3" SLEW="" VCCAUX_IO="" name="ddr3_dqs_p[1]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="P5" SLEW="" VCCAUX_IO="" name="ddr3_odt[0]"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="U1" SLEW="" VCCAUX_IO="" name="ddr3_ras_n"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="J6" SLEW="" VCCAUX_IO="" name="ddr3_reset_n"/>}
  puts $file_obj {      <Pin IN_TERM="" IOSTANDARD="SSTL135" PADName="P7" SLEW="" VCCAUX_IO="" name="ddr3_we_n"/>}
  puts $file_obj {    </PinSelection>}
  puts $file_obj {    <System_Clock>}
  puts $file_obj {      <Pin Bank="34" PADName="R2(MRCC_P)" name="sys_clk_i"/>}
  puts $file_obj {    </System_Clock>}
  puts $file_obj {    <System_Control>}
  puts $file_obj {      <Pin Bank="Select Bank" PADName="No connect" name="sys_rst"/>}
  puts $file_obj {      <Pin Bank="Select Bank" PADName="No connect" name="init_calib_complete"/>}
  puts $file_obj {      <Pin Bank="Select Bank" PADName="No connect" name="tg_compare_error"/>}
  puts $file_obj {    </System_Control>}
  puts $file_obj {    <TimingParameters>}
  puts $file_obj {      <Parameters tcke="5.625" tfaw="45" tras="36" trcd="13.5" trefi="7.8" trfc="160" trp="13.5" trrd="7.5" trtp="7.5" twtr="7.5"/>}
  puts $file_obj {    </TimingParameters>}
  puts $file_obj {    <mrBurstLength name="Burst Length">8 - Fixed</mrBurstLength>}
  puts $file_obj {    <mrBurstType name="Read Burst Type and Length">Sequential</mrBurstType>}
  puts $file_obj {    <mrCasLatency name="CAS Latency">5</mrCasLatency>}
  puts $file_obj {    <mrMode name="Mode">Normal</mrMode>}
  puts $file_obj {    <mrDllReset name="DLL Reset">No</mrDllReset>}
  puts $file_obj {    <mrPdMode name="DLL control for precharge PD">Slow Exit</mrPdMode>}
  puts $file_obj {    <emrDllEnable name="DLL Enable">Enable</emrDllEnable>}
  puts $file_obj {    <emrOutputDriveStrength name="Output Driver Impedance Control">RZQ/6</emrOutputDriveStrength>}
  puts $file_obj {    <emrMirrorSelection name="Address Mirroring">Disable</emrMirrorSelection>}
  puts $file_obj {    <emrCSSelection name="Controller Chip Select Pin">Enable</emrCSSelection>}
  puts $file_obj {    <emrRTT name="RTT (nominal) - On Die Termination (ODT)">RZQ/6</emrRTT>}
  puts $file_obj {    <emrPosted name="Additive Latency (AL)">0</emrPosted>}
  puts $file_obj {    <emrOCD name="Write Leveling Enable">Disabled</emrOCD>}
  puts $file_obj {    <emrDQS name="TDQS enable">Enabled</emrDQS>}
  puts $file_obj {    <emrRDQS name="Qoff">Output Buffer Enabled</emrRDQS>}
  puts $file_obj {    <mr2PartialArraySelfRefresh name="Partial-Array Self Refresh">Full Array</mr2PartialArraySelfRefresh>}
  puts $file_obj {    <mr2CasWriteLatency name="CAS write latency">5</mr2CasWriteLatency>}
  puts $file_obj {    <mr2AutoSelfRefresh name="Auto Self Refresh">Enabled</mr2AutoSelfRefresh>}
  puts $file_obj {    <mr2SelfRefreshTempRange name="High Temparature Self Refresh Rate">Normal</mr2SelfRefreshTempRange>}
  puts $file_obj {    <mr2RTTWR name="RTT_WR - Dynamic On Die Termination (ODT)">Dynamic ODT off</mr2RTTWR>}
  puts $file_obj {    <PortInterface>NATIVE</PortInterface>}
  puts $file_obj {  </Controller>}
  puts $file_obj {</Project>}

  flush $file_obj
  close $file_obj
}

##################################################################
# CREATE IP dram_mig
##################################################################

set ip_name dram_mig
file mkdir ip
create_ip -name mig_7series -vendor xilinx.com -library ip -version 4.2 -module_name $ip_name -dir ip

set ip_obj [get_ips $ip_name]
write_prj_file [file join [get_property IP_DIR $ip_obj] mig.prj]
set_property -dict { 
  CONFIG.XML_INPUT_FILE {mig.prj}
  CONFIG.RESET_BOARD_INTERFACE {Custom}
  CONFIG.MIG_DONT_TOUCH_PARAM {Custom}
  CONFIG.BOARD_MIG_PARAM {Custom}
  CONFIG.SYSTEM_RESET.INSERT_VIP {0}
  CONFIG.CLK_REF_I.INSERT_VIP {0}
  CONFIG.RESET.INSERT_VIP {0}
  CONFIG.DDR3_RESET.INSERT_VIP {0}
  CONFIG.DDR2_RESET.INSERT_VIP {0}
  CONFIG.LPDDR2_RESET.INSERT_VIP {0}
  CONFIG.QDRIIP_RESET.INSERT_VIP {0}
  CONFIG.RLDII_RESET.INSERT_VIP {0}
  CONFIG.RLDIII_RESET.INSERT_VIP {0}
  CONFIG.CLOCK.INSERT_VIP {0}
  CONFIG.MMCM_CLKOUT0.INSERT_VIP {0}
  CONFIG.MMCM_CLKOUT1.INSERT_VIP {0}
  CONFIG.MMCM_CLKOUT2.INSERT_VIP {0}
  CONFIG.MMCM_CLKOUT3.INSERT_VIP {0}
  CONFIG.MMCM_CLKOUT4.INSERT_VIP {0}
  CONFIG.S_AXI_CTRL.INSERT_VIP {0}
  CONFIG.S_AXI.INSERT_VIP {0}
  CONFIG.SYS_CLK_I.INSERT_VIP {0}
  CONFIG.ARESETN.INSERT_VIP {0}
  CONFIG.C0_RESET.INSERT_VIP {0}
  CONFIG.C0_DDR3_RESET.INSERT_VIP {0}
  CONFIG.C0_DDR2_RESET.INSERT_VIP {0}
  CONFIG.C0_LPDDR2_RESET.INSERT_VIP {0}
  CONFIG.C0_QDRIIP_RESET.INSERT_VIP {0}
  CONFIG.C0_RLDII_RESET.INSERT_VIP {0}
  CONFIG.C0_RLDIII_RESET.INSERT_VIP {0}
  CONFIG.C0_CLOCK.INSERT_VIP {0}
  CONFIG.C0_MMCM_CLKOUT0.INSERT_VIP {0}
  CONFIG.C0_MMCM_CLKOUT1.INSERT_VIP {0}
  CONFIG.C0_MMCM_CLKOUT2.INSERT_VIP {0}
  CONFIG.C0_MMCM_CLKOUT3.INSERT_VIP {0}
  CONFIG.C0_MMCM_CLKOUT4.INSERT_VIP {0}
  CONFIG.S0_AXI_CTRL.INSERT_VIP {0}
  CONFIG.S0_AXI.INSERT_VIP {0}
  CONFIG.C0_SYS_CLK_I.INSERT_VIP {0}
  CONFIG.C0_ARESETN.INSERT_VIP {0}
  CONFIG.C1_RESET.INSERT_VIP {0}
  CONFIG.C1_DDR3_RESET.INSERT_VIP {0}
  CONFIG.C1_DDR2_RESET.INSERT_VIP {0}
  CONFIG.C1_LPDDR2_RESET.INSERT_VIP {0}
  CONFIG.C1_QDRIIP_RESET.INSERT_VIP {0}
  CONFIG.C1_RLDII_RESET.INSERT_VIP {0}
  CONFIG.C1_RLDIII_RESET.INSERT_VIP {0}
  CONFIG.C1_CLOCK.INSERT_VIP {0}
  CONFIG.C1_MMCM_CLKOUT0.INSERT_VIP {0}
  CONFIG.C1_MMCM_CLKOUT1.INSERT_VIP {0}
  CONFIG.C1_MMCM_CLKOUT2.INSERT_VIP {0}
  CONFIG.C1_MMCM_CLKOUT3.INSERT_VIP {0}
  CONFIG.C1_MMCM_CLKOUT4.INSERT_VIP {0}
  CONFIG.S1_AXI_CTRL.INSERT_VIP {0}
  CONFIG.S1_AXI.INSERT_VIP {0}
  CONFIG.C1_SYS_CLK_I.INSERT_VIP {0}
  CONFIG.C1_ARESETN.INSERT_VIP {0}
  CONFIG.C2_RESET.INSERT_VIP {0}
  CONFIG.C2_DDR3_RESET.INSERT_VIP {0}
  CONFIG.C2_DDR2_RESET.INSERT_VIP {0}
  CONFIG.C2_LPDDR2_RESET.INSERT_VIP {0}
  CONFIG.C2_QDRIIP_RESET.INSERT_VIP {0}
  CONFIG.C2_RLDII_RESET.INSERT_VIP {0}
  CONFIG.C2_RLDIII_RESET.INSERT_VIP {0}
  CONFIG.C2_CLOCK.INSERT_VIP {0}
  CONFIG.C2_MMCM_CLKOUT0.INSERT_VIP {0}
  CONFIG.C2_MMCM_CLKOUT1.INSERT_VIP {0}
  CONFIG.C2_MMCM_CLKOUT2.INSERT_VIP {0}
  CONFIG.C2_MMCM_CLKOUT3.INSERT_VIP {0}
  CONFIG.C2_MMCM_CLKOUT4.INSERT_VIP {0}
  CONFIG.S2_AXI_CTRL.INSERT_VIP {0}
  CONFIG.S2_AXI.INSERT_VIP {0}
  CONFIG.C2_SYS_CLK_I.INSERT_VIP {0}
  CONFIG.C2_ARESETN.INSERT_VIP {0}
  CONFIG.C3_RESET.INSERT_VIP {0}
  CONFIG.C3_DDR3_RESET.INSERT_VIP {0}
  CONFIG.C3_DDR2_RESET.INSERT_VIP {0}
  CONFIG.C3_LPDDR2_RESET.INSERT_VIP {0}
  CONFIG.C3_QDRIIP_RESET.INSERT_VIP {0}
  CONFIG.C3_RLDII_RESET.INSERT_VIP {0}
  CONFIG.C3_RLDIII_RESET.INSERT_VIP {0}
  CONFIG.C3_CLOCK.INSERT_VIP {0}
  CONFIG.C3_MMCM_CLKOUT0.INSERT_VIP {0}
  CONFIG.C3_MMCM_CLKOUT1.INSERT_VIP {0}
  CONFIG.C3_MMCM_CLKOUT2.INSERT_VIP {0}
  CONFIG.C3_MMCM_CLKOUT3.INSERT_VIP {0}
  CONFIG.C3_MMCM_CLKOUT4.INSERT_VIP {0}
  CONFIG.S3_AXI_CTRL.INSERT_VIP {0}
  CONFIG.S3_AXI.INSERT_VIP {0}
  CONFIG.C3_SYS_CLK_I.INSERT_VIP {0}
  CONFIG.C3_ARESETN.INSERT_VIP {0}
  CONFIG.C4_RESET.INSERT_VIP {0}
  CONFIG.C4_DDR3_RESET.INSERT_VIP {0}
  CONFIG.C4_DDR2_RESET.INSERT_VIP {0}
  CONFIG.C4_LPDDR2_RESET.INSERT_VIP {0}
  CONFIG.C4_QDRIIP_RESET.INSERT_VIP {0}
  CONFIG.C4_RLDII_RESET.INSERT_VIP {0}
  CONFIG.C4_RLDIII_RESET.INSERT_VIP {0}
  CONFIG.C4_CLOCK.INSERT_VIP {0}
  CONFIG.C4_MMCM_CLKOUT0.INSERT_VIP {0}
  CONFIG.C4_MMCM_CLKOUT1.INSERT_VIP {0}
  CONFIG.C4_MMCM_CLKOUT2.INSERT_VIP {0}
  CONFIG.C4_MMCM_CLKOUT3.INSERT_VIP {0}
  CONFIG.C4_MMCM_CLKOUT4.INSERT_VIP {0}
  CONFIG.S4_AXI_CTRL.INSERT_VIP {0}
  CONFIG.S4_AXI.INSERT_VIP {0}
  CONFIG.C4_SYS_CLK_I.INSERT_VIP {0}
  CONFIG.C4_ARESETN.INSERT_VIP {0}
  CONFIG.C5_RESET.INSERT_VIP {0}
  CONFIG.C5_DDR3_RESET.INSERT_VIP {0}
  CONFIG.C5_DDR2_RESET.INSERT_VIP {0}
  CONFIG.C5_LPDDR2_RESET.INSERT_VIP {0}
  CONFIG.C5_QDRIIP_RESET.INSERT_VIP {0}
  CONFIG.C5_RLDII_RESET.INSERT_VIP {0}
  CONFIG.C5_RLDIII_RESET.INSERT_VIP {0}
  CONFIG.C5_CLOCK.INSERT_VIP {0}
  CONFIG.C5_MMCM_CLKOUT0.INSERT_VIP {0}
  CONFIG.C5_MMCM_CLKOUT1.INSERT_VIP {0}
  CONFIG.C5_MMCM_CLKOUT2.INSERT_VIP {0}
  CONFIG.C5_MMCM_CLKOUT3.INSERT_VIP {0}
  CONFIG.C5_MMCM_CLKOUT4.INSERT_VIP {0}
  CONFIG.S5_AXI_CTRL.INSERT_VIP {0}
  CONFIG.S5_AXI.INSERT_VIP {0}
  CONFIG.C5_SYS_CLK_I.INSERT_VIP {0}
  CONFIG.C5_ARESETN.INSERT_VIP {0}
  CONFIG.C6_RESET.INSERT_VIP {0}
  CONFIG.C6_DDR3_RESET.INSERT_VIP {0}
  CONFIG.C6_DDR2_RESET.INSERT_VIP {0}
  CONFIG.C6_LPDDR2_RESET.INSERT_VIP {0}
  CONFIG.C6_QDRIIP_RESET.INSERT_VIP {0}
  CONFIG.C6_RLDII_RESET.INSERT_VIP {0}
  CONFIG.C6_RLDIII_RESET.INSERT_VIP {0}
  CONFIG.C6_CLOCK.INSERT_VIP {0}
  CONFIG.C6_MMCM_CLKOUT0.INSERT_VIP {0}
  CONFIG.C6_MMCM_CLKOUT1.INSERT_VIP {0}
  CONFIG.C6_MMCM_CLKOUT2.INSERT_VIP {0}
  CONFIG.C6_MMCM_CLKOUT3.INSERT_VIP {0}
  CONFIG.C6_MMCM_CLKOUT4.INSERT_VIP {0}
  CONFIG.S6_AXI_CTRL.INSERT_VIP {0}
  CONFIG.S6_AXI.INSERT_VIP {0}
  CONFIG.C6_SYS_CLK_I.INSERT_VIP {0}
  CONFIG.C6_ARESETN.INSERT_VIP {0}
  CONFIG.C7_RESET.INSERT_VIP {0}
  CONFIG.C7_DDR3_RESET.INSERT_VIP {0}
  CONFIG.C7_DDR2_RESET.INSERT_VIP {0}
  CONFIG.C7_LPDDR2_RESET.INSERT_VIP {0}
  CONFIG.C7_QDRIIP_RESET.INSERT_VIP {0}
  CONFIG.C7_RLDII_RESET.INSERT_VIP {0}
  CONFIG.C7_RLDIII_RESET.INSERT_VIP {0}
  CONFIG.C7_CLOCK.INSERT_VIP {0}
  CONFIG.C7_MMCM_CLKOUT0.INSERT_VIP {0}
  CONFIG.C7_MMCM_CLKOUT1.INSERT_VIP {0}
  CONFIG.C7_MMCM_CLKOUT2.INSERT_VIP {0}
  CONFIG.C7_MMCM_CLKOUT3.INSERT_VIP {0}
  CONFIG.C7_MMCM_CLKOUT4.INSERT_VIP {0}
  CONFIG.S7_AXI_CTRL.INSERT_VIP {0}
  CONFIG.S7_AXI.INSERT_VIP {0}
  CONFIG.C7_SYS_CLK_I.INSERT_VIP {0}
  CONFIG.C7_ARESETN.INSERT_VIP {0}
} $ip_obj

##################################################################

#set_property GENERATE_SYNTH_CHECKPOINT 0 [get_files [get_property IP_FILE $ip_obj]]
generate_target all $ip_obj
synth_ip $ip_obj
