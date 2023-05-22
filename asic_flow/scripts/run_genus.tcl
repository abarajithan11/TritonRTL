set TOP model_baseline

#--------- CONFIG
set RTL_DIR ../rtl
set REPORT_DIR ../reports/
set_db hdl_max_loop_limit 10000000
set_db max_cpus_per_server 20

#--------- LIBRARIES
set LIB_DIR "../pdk/tsmc65gp"
set_db library "$LIB_DIR/lib/scadv10_cln65gp_lvt_ff_1p1v_m40c.lib"
set_db lef_library { ../pdk/tsmc65gp/lef/tsmc_cln65_a10_4X2Z_tech.lef ../pdk/tsmc65gp/lef/tsmc65_lvt_sc_adv10_macro.lef}
# set_db qrc_tech_file $LIB_DIR/other/icecaps.tch

#--------- READ
read_hdl -mixvlog [glob $RTL_DIR/*]

#--------- ELABORATE & CHECK
set_db lp_insert_clock_gating false
elaborate $TOP
check_design > ${REPORT_DIR}/check_design.log
uniquify $TOP

#--------- CONSTRAINTS
read_sdc ../constraints/${TOP}.sdc

#--------- RETIME OPTIONS
# set_db retime_async_reset true
# set_db design:${TOP} .retime true

#--------- SYNTHESIZE
set_db syn_global_effort low
syn_generic
syn_map
syn_opt

#--------- NETLIST
write -mapped > ../outputs/${TOP}.out.v
write_sdc > ../outputs/${TOP}.out.sdc

#--------- REPORTS
report_area > ${REPORT_DIR}/area.log
report_gates > ${REPORT_DIR}/gates.log
report_timing  -nworst 10 > ${REPORT_DIR}/timing.log
report_congestion > ${REPORT_DIR}/congestion.log
report_messages > ${REPORT_DIR}/messages.log
report_hierarchy > ${REPORT_DIR}/hierarchy.log
report_clock_gating > ${REPORT_DIR}/clock_gating.log

build_rtl_power_models -clean_up_netlist
report_power > ${REPORT_DIR}/power.log