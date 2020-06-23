# Load Design
#vsim system
# Set Stimulus
#force -freeze sim:/system/sys_clk 1 0, 0 {10 ns} -r 20 ns
#force -freeze sim:/system/sys_reset 1
#force -freeze sim:/system/sys_reset 0 100 ns, 1 {200 ns}

#add wave -position insertpoint \
#sim:/parahisttest/ParaHistdut/*
#mem load -infile ../../temp/uram.hex -format hex /parahisttest/ParaHistdut/SelectPrecision(0)/GenLoopInst(0)/filtering_RAM_Inst/

## stage 1a: Event Fetch FIFO
add wave -noupdate -radixshowbase 0 -color white -group "stage1a_InputFIFO" -label clk -radix hexadecimal /parahisttest/ParaHistdut/clk
add wave -noupdate -radixshowbase 0 -color red -group "stage1a_InputFIFO" -label rst -radix hexadecimal /parahisttest/ParaHistdut/rst
add wave -noupdate -radixshowbase 0 -color green -group "stage1a_InputFIFO" -label input_data -radix hexadecimal /parahisttest/ParaHistdut/input_data
add wave -noupdate -radixshowbase 0 -color green -group "stage1a_InputFIFO" -label FIFO_data_out -radix hexadecimal /parahisttest/ParaHistdut/FIFO_data_out

## stage 1b: Neighborhood address generator
add wave -noupdate -radixshowbase 0 -color green -group "stage1b_EventFetch_NeighborhoodAddressGenerator" -label EF_NAG_in -radix hexadecimal /parahisttest/ParaHistdut/EF_NAG_in
add wave -noupdate -radixshowbase 0 -color green -group "stage1b_EventFetch_NeighborhoodAddressGenerator" -label EF_NAG_out -radix hexadecimal /parahisttest/ParaHistdut/EF_NAG_out

## Neighborhood address generator
add wave -noupdate -radixshowbase 0 -color green -group "NeighborhoodAddressGenerator" -label NAGUM_border_in -radix hexadecimal /parahisttest/ParaHistdut/NAGUM_border_in
add wave -noupdate -radixshowbase 0 -color green -group "NeighborhoodAddressGenerator" -label NAGUM_ts_in -radix hexadecimal /parahisttest/ParaHistdut/NAGUM_ts_in
add wave -noupdate -radixshowbase 0 -color green -group "NeighborhoodAddressGenerator" -label NAGUM_addr_of_block_search_in -radix hexadecimal /parahisttest/ParaHistdut/NAGUM_addr_of_block_search_in
add wave -noupdate -radixshowbase 0 -color green -group "NeighborhoodAddressGenerator" -label NAGUM_addr_within_block_search_in -radix hexadecimal /parahisttest/ParaHistdut/NAGUM_addr_within_block_search_in
add wave -noupdate -radixshowbase 0 -color blue -group "NeighborhoodAddressGenerator" -label temp_addr_X -radix hexadecimal /parahisttest/ParaHistdut/NeighborhoodAddressGenerator1/temp_addr_X
add wave -noupdate -radixshowbase 0 -color blue -group "NeighborhoodAddressGenerator" -label temp_addr_Y -radix hexadecimal /parahisttest/ParaHistdut/NeighborhoodAddressGenerator1/temp_addr_Y
add wave -noupdate -radixshowbase 0 -color blue -group "NeighborhoodAddressGenerator" -label NAG_in_addr_x -radix hexadecimal /parahisttest/ParaHistdut/NeighborhoodAddressGenerator1/NAG_in_addr_x
add wave -noupdate -radixshowbase 0 -color blue -group "NeighborhoodAddressGenerator" -label NAG_in_addr_y -radix hexadecimal /parahisttest/ParaHistdut/NeighborhoodAddressGenerator1/NAG_in_addr_y

## stage 1c: URAM address mapping
add wave -noupdate -radixshowbase 0 -color green -group "stage1c_NeighborhoodAddressGenerator_URAMAddressMapper" -label NAGUM_ts_out -radix hexadecimal /parahisttest/ParaHistdut/NAGUM_ts_out
add wave -noupdate -radixshowbase 0 -color green -group "stage1c_NeighborhoodAddressGenerator_URAMAddressMapper" -label NAGUM_border_out -radix hexadecimal /parahisttest/ParaHistdut/NAGUM_border_out
add wave -noupdate -radixshowbase 0 -color green -group "stage1c_NeighborhoodAddressGenerator_URAMAddressMapper" -label NAGUM_addr_of_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/NAGUM_addr_of_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "stage1c_NeighborhoodAddressGenerator_URAMAddressMapper" -label NAGUM_addr_within_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/NAGUM_addr_within_block_search_out

## URAMAddressMapper1
add wave -noupdate -radixshowbase 0 -color green -group "URAMAddressMapper" -label URAMAM_URAMDA_addr_within_block_vec_in -radix hexadecimal /parahisttest/ParaHistdut/URAMAM_URAMDA_addr_within_block_vec_in
add wave -noupdate -radixshowbase 0 -color green -group "URAMAddressMapper" -label URAMAM_URAMDA_ReadEnable_vec_in -radix hexadecimal /parahisttest/ParaHistdut/URAMAM_URAMDA_ReadEnable_vec_in

## stage 1d: URAM data access
add wave -noupdate -radixshowbase 0 -color green -group "stage1d_URAMAddressMapper_URAMDataAccess" -label URAMAM_URAMDA_ts_out -radix hexadecimal /parahisttest/ParaHistdut/URAMAM_URAMDA_ts_out
add wave -noupdate -radixshowbase 0 -color green -group "stage1d_URAMAddressMapper_URAMDataAccess" -label URAMAM_URAMDA_border_out -radix hexadecimal /parahisttest/ParaHistdut/URAMAM_URAMDA_border_out
add wave -noupdate -radixshowbase 0 -color green -group "stage1d_URAMAddressMapper_URAMDataAccess" -label URAMAM_URAMDA_addr_within_block_vec_out -radix hexadecimal /parahisttest/ParaHistdut/URAMAM_URAMDA_addr_within_block_vec_out
add wave -noupdate -radixshowbase 0 -color green -group "stage1d_URAMAddressMapper_URAMDataAccess" -label URAMAM_URAMDA_addr_of_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/URAMAM_URAMDA_addr_of_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "stage1d_URAMAddressMapper_URAMDataAccess" -label URAMAM_URAMDA_addr_within_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/URAMAM_URAMDA_addr_within_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "xilinx_ultraram_true_dual_port" -label URAMAM_URAMDA_doutb -radix hexadecimal /parahisttest/ParaHistdut/URAMAM_URAMDA_doutb
add wave -noupdate -radixshowbase 0 -color green -group "xilinx_ultraram_true_dual_port" -label URAMAM_URAMDA_ReadEnable_vec_out -radix hexadecimal /parahisttest/ParaHistdut/URAMAM_URAMDA_ReadEnable_vec_out

## stage 1e: Neighborhood data extraction
add wave -noupdate -radixshowbase 0 -color green -group "stage1e_URAMDataAccess_NeighborhoodDataExtraction" -label URAMDA_NDE_ts_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDA_NDE_ts_out
add wave -noupdate -radixshowbase 0 -color green -group "stage1e_URAMDataAccess_NeighborhoodDataExtraction" -label URAMDA_NDE_border_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDA_NDE_border_out
add wave -noupdate -radixshowbase 0 -color green -group "stage1e_URAMDataAccess_NeighborhoodDataExtraction" -label URAMDA_NDE_ReadEnable_vec_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDA_NDE_ReadEnable_vec_out
add wave -noupdate -radixshowbase 0 -color green -group "stage1e_URAMDataAccess_NeighborhoodDataExtraction" -label URAMDA_NDE_addr_within_block_vec_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDA_NDE_addr_within_block_vec_out
add wave -noupdate -radixshowbase 0 -color green -group "stage1e_URAMDataAccess_NeighborhoodDataExtraction" -label URAMDA_NDE_addr_within_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDA_NDE_addr_within_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "stage1e_URAMDataAccess_NeighborhoodDataExtraction" -label URAMDA_NDE_doutb_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDA_NDE_doutb_out
add wave -noupdate -radixshowbase 0 -color green -group "NeighborhoodDataExtraction" -label URAMDA_NDE_addr_of_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDA_NDE_addr_of_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "NeighborhoodDataExtraction" -label URAMDA_NDE_doutb_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDA_NDE_doutb_out
add wave -noupdate -radixshowbase 0 -color green -group "NeighborhoodDataExtraction" -label URAMDA_NDE_out_data -radix hexadecimal /parahisttest/ParaHistdut/URAMDA_NDE_out_data

## stage 2: Noise Removal
add wave -noupdate -radixshowbase 0 -color green -group "stage2_NeighborhoodDataExtraction_NoiseRemoval" -label NDE_NR_ReadEnable_vec_out -radix hexadecimal /parahisttest/ParaHistdut/NDE_NR_ReadEnable_vec_out
add wave -noupdate -radixshowbase 0 -color green -group "stage2_NeighborhoodDataExtraction_NoiseRemoval" -label NDE_NR_addr_within_block_vec_out -radix hexadecimal /parahisttest/ParaHistdut/NDE_NR_addr_within_block_vec_out
add wave -noupdate -radixshowbase 0 -color green -group "stage2_NeighborhoodDataExtraction_NoiseRemoval" -label NDE_NR_addr_within_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/NDE_NR_addr_within_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "stage2_NeighborhoodDataExtraction_NoiseRemoval" -label URAMDA_NDE_addr_within_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDA_NDE_addr_within_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "stage2_NeighborhoodDataExtraction_NoiseRemoval" -label NDE_NR_doutb_out -radix hexadecimal /parahisttest/ParaHistdut/NDE_NR_doutb_out
add wave -noupdate -radixshowbase 0 -color green -group "NoiseRemoval" -label NDE_NR_ts_out -radix hexadecimal /parahisttest/ParaHistdut/NDE_NR_ts_out
add wave -noupdate -radixshowbase 0 -color green -group "NoiseRemoval" -label NDE_NR_border_out -radix hexadecimal /parahisttest/ParaHistdut/NDE_NR_border_out
add wave -noupdate -radixshowbase 0 -color green -group "NoiseRemoval" -label NDE_NR_out_data_out -radix hexadecimal /parahisttest/ParaHistdut/NDE_NR_out_data_out
add wave -noupdate -radixshowbase 0 -color green -group "NoiseRemoval" -label NDE_NR_valid -radix hexadecimal /parahisttest/ParaHistdut/NDE_NR_valid
add wave -noupdate -radixshowbase 0 -color green -group "NoiseRemoval" -label NDE_NR_valid -radix hexadecimal /parahisttest/ParaHistdut/NoiseRemoval1/temp_ts

## stage 3: Prefix adder
add wave -noupdate -radixshowbase 0 -color green -group "stage3_NoiseRemoval_PrefixAdder" -label NR_PA_ts_out -radix hexadecimal /parahisttest/ParaHistdut/NR_PA_ts_out
add wave -noupdate -radixshowbase 0 -color green -group "stage3_NoiseRemoval_PrefixAdder" -label NR_PA_border_out -radix hexadecimal /parahisttest/ParaHistdut/NR_PA_border_out
add wave -noupdate -radixshowbase 0 -color green -group "stage3_NoiseRemoval_PrefixAdder" -label NR_PA_ReadEnable_vec_out -radix hexadecimal /parahisttest/ParaHistdut/NR_PA_ReadEnable_vec_out
add wave -noupdate -radixshowbase 0 -color green -group "stage3_NoiseRemoval_PrefixAdder" -label NR_PA_addr_within_block_vec_out -radix hexadecimal /parahisttest/ParaHistdut/NR_PA_addr_within_block_vec_out
add wave -noupdate -radixshowbase 0 -color green -group "stage3_NoiseRemoval_PrefixAdder" -label NR_PA_addr_of_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/NR_PA_addr_of_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "stage3_NoiseRemoval_PrefixAdder" -label NR_PA_addr_within_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/NR_PA_addr_within_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "stage3_NoiseRemoval_PrefixAdder" -label NR_PA_doutb_out -radix hexadecimal /parahisttest/ParaHistdut/NR_PA_doutb_out
add wave -noupdate -radixshowbase 0 -color green -group "stage3_NoiseRemoval_PrefixAdder" -label NR_PA_valid_out -radix hexadecimal /parahisttest/ParaHistdut/NR_PA_valid_out

add wave -noupdate -radixshowbase 0 -color green -group "Prefixadder" -label NR_PA_out_data_out -radix hexadecimal /parahisttest/ParaHistdut/NR_PA_out_data_out
add wave -noupdate -radixshowbase 0 -color green -group "Prefixadder" -label NR_PA_prefixadder_out -radix hexadecimal /parahisttest/ParaHistdut/NR_PA_prefixadder_out

## stage 4: Decompression 
add wave -noupdate -radixshowbase 0 -color green -group "stage4_PrefixAdder_Decompression" -label PA_De_border_out -radix hexadecimal /parahisttest/ParaHistdut/PA_De_border_out
add wave -noupdate -radixshowbase 0 -color green -group "stage4_PrefixAdder_Decompression" -label PA_De_ReadEnable_vec_out -radix hexadecimal /parahisttest/ParaHistdut/PA_De_ReadEnable_vec_out
add wave -noupdate -radixshowbase 0 -color green -group "stage4_PrefixAdder_Decompression" -label PA_De_addr_within_block_vec_out -radix hexadecimal /parahisttest/ParaHistdut/PA_De_addr_within_block_vec_out
add wave -noupdate -radixshowbase 0 -color green -group "stage4_PrefixAdder_Decompression" -label PA_De_addr_of_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/PA_De_addr_of_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "stage4_PrefixAdder_Decompression" -label PA_De_doutb_out -radix hexadecimal /parahisttest/ParaHistdut/PA_De_doutb_out
add wave -noupdate -radixshowbase 0 -color green -group "stage4_PrefixAdder_Decompression" -label PA_De_valid_out -radix hexadecimal /parahisttest/ParaHistdut/PA_De_valid_out
add wave -noupdate -radixshowbase 0 -color green -group "stage4_PrefixAdder_Decompression" -label PA_De_prefixadder_out -radix hexadecimal /parahisttest/ParaHistdut/PA_De_prefixadder_out

add wave -noupdate -radixshowbase 0 -color green -group "decompression_unit" -label PA_DE_prefixadder_out -radix hexadecimal /parahisttest/ParaHistdut/PA_DE_prefixadder_out
add wave -noupdate -radixshowbase 0 -color green -group "decompression_unit" -label PA_De_out_data_out -radix hexadecimal /parahisttest/ParaHistdut/PA_De_out_data_out
add wave -noupdate -radixshowbase 0 -color green -group "decompression_unit" -label PA_De_ts_out -radix hexadecimal /parahisttest/ParaHistdut/PA_De_ts_out
add wave -noupdate -radixshowbase 0 -color green -group "decompression_unit" -label PA_De_Limitted_TS -radix hexadecimal /parahisttest/ParaHistdut/PA_De_Limitted_TS
add wave -noupdate -radixshowbase 0 -color green -group "decompression_unit" -label PA_De_decompressed_out -radix hexadecimal /parahisttest/ParaHistdut/PA_De_decompressed_out

## stage 5: comparison
add wave -noupdate -radixshowbase 0 -color green -group "stage5_Decompression_Comparison" -label De_CP_border_out -radix hexadecimal /parahisttest/ParaHistdut/De_CP_border_out
add wave -noupdate -radixshowbase 0 -color green -group "stage5_Decompression_Comparison" -label De_CP_ReadEnable_vec_out -radix hexadecimal /parahisttest/ParaHistdut/De_CP_ReadEnable_vec_out
add wave -noupdate -radixshowbase 0 -color green -group "stage5_Decompression_Comparison" -label De_CP_addr_within_block_vec_out -radix hexadecimal /parahisttest/ParaHistdut/De_CP_addr_within_block_vec_out
add wave -noupdate -radixshowbase 0 -color green -group "stage5_Decompression_Comparison" -label De_CP_addr_of_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/De_CP_addr_of_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "stage5_Decompression_Comparison" -label De_CP_addr_within_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/De_CP_addr_within_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "stage5_Decompression_Comparison" -label De_CP_doutb_out -radix hexadecimal /parahisttest/ParaHistdut/De_CP_doutb_out
add wave -noupdate -radixshowbase 0 -color green -group "stage5_Decompression_Comparison" -label De_CP_valid_out -radix hexadecimal /parahisttest/ParaHistdut/De_CP_valid_out
add wave -noupdate -radixshowbase 0 -color green -group "stage5_Decompression_Comparison" -label De_CP_prefixadder_out -radix hexadecimal /parahisttest/ParaHistdut/De_CP_prefixadder_out

add wave -noupdate -radixshowbase 0 -color green -group "ComparisonUnit" -label De_CP_out_data_out -radix hexadecimal /parahisttest/ParaHistdut/De_CP_out_data_out
add wave -noupdate -radixshowbase 0 -color green -group "ComparisonUnit" -label De_CP_decompressed_out -radix hexadecimal /parahisttest/ParaHistdut/De_CP_decompressed_out
add wave -noupdate -radixshowbase 0 -color green -group "ComparisonUnit" -label De_CP_ts_out -radix hexadecimal /parahisttest/ParaHistdut/De_CP_ts_out
add wave -noupdate -radixshowbase 0 -color green -group "ComparisonUnit" -label De_CP_limited_ts_out -radix hexadecimal /parahisttest/ParaHistdut/De_CP_limited_ts_out
add wave -noupdate -radixshowbase 0 -color green -group "ComparisonUnit" -label De_CP_data_out -radix hexadecimal /parahisttest/ParaHistdut/De_CP_data_out

## stage 6: Data Mapping
add wave -noupdate -radixshowbase 0 -color green -group "stage6_Comparison_URAMDataMapper" -label CP_URAMDM_ts_out -radix hexadecimal /parahisttest/ParaHistdut/CP_URAMDM_ts_out
add wave -noupdate -radixshowbase 0 -color green -group "stage6_Comparison_URAMDataMapper" -label CP_URAMDM_limited_ts_out -radix hexadecimal /parahisttest/ParaHistdut/CP_URAMDM_limited_ts_out
add wave -noupdate -radixshowbase 0 -color green -group "stage6_Comparison_URAMDataMapper" -label CP_URAMDM_border_out -radix hexadecimal /parahisttest/ParaHistdut/CP_URAMDM_border_out
add wave -noupdate -radixshowbase 0 -color green -group "stage6_Comparison_URAMDataMapper" -label CP_URAMDM_ReadEnable_vec_out -radix hexadecimal /parahisttest/ParaHistdut/CP_URAMDM_ReadEnable_vec_out
add wave -noupdate -radixshowbase 0 -color green -group "stage6_Comparison_URAMDataMapper" -label CP_URAMDM_addr_within_block_vec_out -radix hexadecimal /parahisttest/ParaHistdut/CP_URAMDM_addr_within_block_vec_out
add wave -noupdate -radixshowbase 0 -color green -group "stage6_Comparison_URAMDataMapper" -label CP_URAMDM_addr_of_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/CP_URAMDM_addr_of_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "stage6_Comparison_URAMDataMapper" -label CP_URAMDM_addr_within_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/CP_URAMDM_addr_within_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "stage6_Comparison_URAMDataMapper" -label CP_URAMDM_doutb_out -radix hexadecimal /parahisttest/ParaHistdut/CP_URAMDM_doutb_out
add wave -noupdate -radixshowbase 0 -color green -group "stage6_Comparison_URAMDataMapper" -label CP_URAMDM_out_data_out -radix hexadecimal /parahisttest/ParaHistdut/CP_URAMDM_out_data_out
add wave -noupdate -radixshowbase 0 -color green -group "stage6_Comparison_URAMDataMapper" -label CP_URAMDM_valid_out -radix hexadecimal /parahisttest/ParaHistdut/CP_URAMDM_valid_out
add wave -noupdate -radixshowbase 0 -color green -group "stage6_Comparison_URAMDataMapper" -label CP_URAMDM_prefixadder_out -radix hexadecimal /parahisttest/ParaHistdut/CP_URAMDM_prefixadder_out
add wave -noupdate -radixshowbase 0 -color green -group "stage6_Comparison_URAMDataMapper" -label CP_URAMDM_decompressed_out -radix hexadecimal /parahisttest/ParaHistdut/CP_URAMDM_decompressed_out
add wave -noupdate -radixshowbase 0 -color green -group "stage6_Comparison_URAMDataMapper" -label CP_URAMDM_compared_data_out -radix hexadecimal /parahisttest/ParaHistdut/CP_URAMDM_compared_data_out

add wave -noupdate -radixshowbase 0 -color green -group "URAMdataMapper" -label CP_URAMDM_addr_of_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/CP_URAMDM_addr_of_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "URAMdataMapper" -label CP_URAMDM_compared_data_out -radix hexadecimal /parahisttest/ParaHistdut/CP_URAMDM_compared_data_out
add wave -noupdate -radixshowbase 0 -color green -group "URAMdataMapper" -label COM_URAMDM_data_within_block_vec -radix hexadecimal /parahisttest/ParaHistdut/COM_URAMDM_data_within_block_vec

## stage 7: Write back
add wave -noupdate -radixshowbase 0 -color green -group "stage7_URAMDataMapper_WriteBack" -label URAMDM_WB_ts_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDM_WB_ts_out
add wave -noupdate -radixshowbase 0 -color green -group "stage7_URAMDataMapper_WriteBack" -label URAMDM_WB_limited_ts_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDM_WB_limited_ts_out
add wave -noupdate -radixshowbase 0 -color green -group "stage7_URAMDataMapper_WriteBack" -label URAMDM_WB_border_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDM_WB_border_out
add wave -noupdate -radixshowbase 0 -color green -group "stage7_URAMDataMapper_WriteBack" -label URAMDM_WB_addr_of_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDM_WB_addr_of_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "stage7_URAMDataMapper_WriteBack" -label URAMDM_WB_addr_within_block_search_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDM_WB_addr_within_block_search_out
add wave -noupdate -radixshowbase 0 -color green -group "stage7_URAMDataMapper_WriteBack" -label URAMDM_WB_doutb_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDM_WB_doutb_out
add wave -noupdate -radixshowbase 0 -color green -group "stage7_URAMDataMapper_WriteBack" -label URAMDM_WB_out_data_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDM_WB_out_data_out
add wave -noupdate -radixshowbase 0 -color green -group "stage7_URAMDataMapper_WriteBack" -label URAMDM_WB_valid_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDM_WB_valid_out
add wave -noupdate -radixshowbase 0 -color green -group "stage7_URAMDataMapper_WriteBack" -label URAMDM_WB_prefixadder_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDM_WB_prefixadder_out
add wave -noupdate -radixshowbase 0 -color green -group "stage7_URAMDataMapper_WriteBack" -label URAMDM_WB_decompressed_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDM_WB_decompressed_out
add wave -noupdate -radixshowbase 0 -color green -group "stage7_URAMDataMapper_WriteBack" -label URAMDM_WB_compared_data_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDM_WB_compared_data_out

add wave -noupdate -radixshowbase 0 -color green -group "xilinx_ultraram_true_dual_port" -label URAMDM_WB_ReadEnable_vec_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDM_WB_ReadEnable_vec_out
add wave -noupdate -radixshowbase 0 -color green -group "xilinx_ultraram_true_dual_port" -label URAMDM_WB_dina_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDM_WB_dina_out
add wave -noupdate -radixshowbase 0 -color green -group "xilinx_ultraram_true_dual_port" -label URAMDM_WB_addr_within_block_vec_out -radix hexadecimal /parahisttest/ParaHistdut/URAMDM_WB_addr_within_block_vec_out

## the rest
add wave -position insertpoint -group "rest" -r sim:/parahisttest/*

run 500

#quit