# A macro file to setup the waves for the processor
##Global display types
radix define ALUops_in {
    "0" "add" -color green,
    "1" "sub" -color green,
    "2" "and" -color green,
    "3" "nand" -color green,
    "4" "or" -color green,
    "5" "nor" -color green,
    "6" "xor" -color green,
    "7" "xnor" -color green,
    "8" "sltu" -color green,
    "9" "slt" -color green,
    "10" "sll" -color green,
    "11" "srl" -color green,
    "12" "sra" -color green,
    "13" "mul" -color green,
    -default unsigned
}

radix define ALUops_out {
    "0" "add" -color white,
    "1" "sub" -color white,
    "2" "and" -color white,
    "3" "nand" -color white,
    "4" "or" -color white,
    "5" "nor" -color white,
    "6" "xor" -color white,
    "7" "xnor" -color white,
    "8" "sltu" -color white,
    "9" "slt" -color white,
    "10" "sll" -color white,
    "11" "srl" -color white,
    "12" "sra" -color white,
    "13" "mul" -color white,
    -default unsigned
}

radix define MipsMemSize_in {
    "0" "byte" -color green,
    "1" "half" -color green,
    "2" "word" -color green,
    -default unsigned
}

radix define MipsMemSize_out {
    "0" "byte" -color white,
    "1" "half" -color white,
    "2" "word" -color white,
    -default unsigned
}

radix define ALU_forwardSource_in {
    "0" "RegFile" -color green,
    "1" "WB.RSLT" -color green,
    "2" "MEM.ALU" -color green,
    -default unsigned
}

radix define ALU_forwardSource_out {
    "0" "RegFile" -color white,
    "1" "WB.RSLT" -color white,
    "2" "MEM.ALU" -color white,
    -default unsigned
}

radix define Memory_forwardSource_in {
    "0" "RegFile" -color green,
    "1" "WB.RSLT" -color green,
    -default symbolic
}

radix define Memory_forwardSource_out {
    "0" "RegFile" -color white,
    "1" "WB.RSLT" -color white,
    -default symbolic
}

#Clear current contents to prevent duplicates
delete wave *

## Global signals (control, address, instruction, etc)
add wave -noupdate -divider -height 20 Global
add wave -noupdate -radixshowbase 0 -color "light blue" -radix Symbolic -label Reset /toplevel/reset
add wave -noupdate -radixshowbase 0 -color "light blue" -radix Symbolic -label Clock /toplevel/clk

## IF
add wave -noupdate -radixshowbase 0 -color green -group "IF" -label PC -radix hexadecimal /toplevel/IF_PC_val
add wave -noupdate -radixshowbase 0 -color green -group "IF" -label "ID.Branch|ID.Jump" -radix hexadecimal /toplevel/ID_updatePC
add wave -noupdate -radixshowbase 0 -color green -group "IF" -label "!PC Stall" -radix hexadecimal /toplevel/PC_wren
add wave -noupdate -radixshowbase 0 -color white -group "IF" -label PC+4 -radix hexadecimal /toplevel/IF_PC_plus_4
add wave -noupdate -radixshowbase 0 -color white -group "IF" -label nPC -radix hexadecimal /toplevel/ID_nPC

add wave -noupdate -radixshowbase 0 -color white -group "IF" -group "Hazard" -label stall -radix hexadecimal /toplevel/stall

## ID
#add wave -noupdate -group "ID" -group "Jump/Branch" -divider -height 15 Inputs
add wave -noupdate -radixshowbase 0 -color green -group "ID" -label PC -radix hexadecimal /toplevel/ID_PC_val
add wave -noupdate -radixshowbase 0 -color green -group "ID" -label Instruction -radix hexadecimal /toplevel/ID_instruction

add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Jump/Branch" -group "Forwarding" -label "Source A" -radix ALU_forwardSource_in /toplevel/ID_forwardA
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Jump/Branch" -group "Forwarding" -label "Source B" -radix ALU_forwardSource_in /toplevel/ID_forwardB
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Jump/Branch" -label "Branch on Zero" -radix symbolic /toplevel/branch_eq
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Jump/Branch" -label "Branch on !Zero" -radix symbolic /toplevel/branch_neq
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Jump/Branch" -label "Take Branch?" -radix symbolic /toplevel/ID_takeBranch
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Jump/Branch" -label "Jump?" -radix symbolic /toplevel/ID_jump
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Jump/Branch" -label "Jump Register?" -radix symbolic /toplevel/ID_isJumpRegister
#add wave -noupdate -group "ID" -group "Jump/Branch"-divider -height 15 Outputs
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Jump/Branch" -label "Branch Target" -radix hexadecimal /toplevel/ID_branchTarget

add wave -noupdate -radixshowbase 0 -color green -group "ID" -group "Jump/Branch" -group "ALU" -label Operation -radix ALUops_in /toplevel/branch_ALU/Operation
add wave -noupdate -radixshowbase 0 -color green -group "ID" -group "Jump/Branch" -group "ALU" -label A -radix hexadecimal /toplevel/branch_ALU/A
add wave -noupdate -radixshowbase 0 -color green -group "ID" -group "Jump/Branch" -group "ALU" -label B -radix hexadecimal /toplevel/branch_ALU/B
#add wave -noupdate -group "ALU" -divider -height 15 Outputs
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Jump/Branch" -group "ALU" -label Out -radix hexadecimal /toplevel/branch_ALU/o_F
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Jump/Branch" -group "ALU" -label Zero -radix hexadecimal /toplevel/branch_ALU/Zero
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Jump/Branch" -group "ALU" -label Carry -radix hexadecimal /toplevel/branch_ALU/Carry
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Jump/Branch" -group "ALU" -label Overflow -radix hexadecimal /toplevel/branch_ALU/Overflow

##Control Logic
#add wave -noupdate -group "Control Logic" -divider -height 15 Inputs
add wave -noupdate -radixshowbase 0 -color green -group "ID" -group "Control Logic" -label Instruction -radix hexadecimal /toplevel/ID_Instruction
#add wave -noupdate -group "Control Logic" -divider -height 15 Outputs
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Control Logic" -label "Read 1" -radix unsigned /toplevel/ID_r_addr_1
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Control Logic" -label "Read 2" -radix unsigned /toplevel/ID_r_addr_2
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Control Logic" -label "Write" -radix unsigned /toplevel/ID_w_addr
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Control Logic" -label "Immediate" -radix hexadecimal /toplevel/ID_imm
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Control Logic" -label "ALU Operation" -radix ALUops_out /toplevel/branch_ALU_op

add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Control Logic" -group "Instruction Fetch" -label "Branch on Zero" -radix symbolic /toplevel/branch_eq
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Control Logic" -group "Instruction Fetch" -label "Branch on !Zero" -radix symbolic /toplevel/branch_neq
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Control Logic" -group "Instruction Fetch" -label "Jump?" -radix symbolic /toplevel/ID_jump
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Control Logic" -group "Instruction Fetch" -label "Jump Register?" -radix symbolic /toplevel/ID_isJumpRegister

## Register File
#add wave -noupdate -group "Register File" -divider -height 15 Inputs
add wave -noupdate -radixshowbase 0 -color green -group "ID" -group "Register File" -label "Read 1 Address" -radix unsigned /toplevel/b2v_RegFile/r_addr_1
add wave -noupdate -radixshowbase 0 -color green -group "ID" -group "Register File" -label "Read 2 Address" -radix unsigned /toplevel/b2v_RegFile/r_addr_2
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Register File" -label "Read 1 Data" -radix hexadecimal /toplevel/b2v_RegFile/r_data_1
add wave -noupdate -radixshowbase 0 -color white -group "ID" -group "Register File" -label "Read 2 Data" -radix hexadecimal /toplevel/b2v_RegFile/r_data_2
add wave -noupdate -radixshowbase 0 -color "grey" -group "ID" -group "Register File" -expand -group "Contents" -label "All" -radix hexadecimal /toplevel/b2v_RegFile/data
add wave -noupdate -radixshowbase 0 -color "grey" -group "ID" -group "Register File" -group "Contents" -label "\$v0(\$2)" -radix hexadecimal /toplevel/b2v_RegFile/data(2)
add wave -noupdate -radixshowbase 0 -color "grey" -group "ID" -group "Register File" -group "Contents" -label "\$v1(\$3)" -radix hexadecimal /toplevel/b2v_RegFile/data(3)
add wave -noupdate -radixshowbase 0 -color "grey" -group "ID" -group "Register File" -group "Contents" -label "\$a0(\$4)" -radix hexadecimal /toplevel/b2v_RegFile/data(4)
add wave -noupdate -radixshowbase 0 -color "grey" -group "ID" -group "Register File" -group "Contents" -label "\$a1(\$5)" -radix hexadecimal /toplevel/b2v_RegFile/data(5)
add wave -noupdate -radixshowbase 0 -color "grey" -group "ID" -group "Register File" -group "Contents" -label "\$t0(\$8)" -radix hexadecimal /toplevel/b2v_RegFile/data(8)
add wave -noupdate -radixshowbase 0 -color "grey" -group "ID" -group "Register File" -group "Contents" -label "\$t1(\$9)" -radix hexadecimal /toplevel/b2v_RegFile/data(9)
add wave -noupdate -radixshowbase 0 -color "grey" -group "ID" -group "Register File" -group "Contents" -label "\$t2(\$10)" -radix hexadecimal /toplevel/b2v_RegFile/data(10)
add wave -noupdate -radixshowbase 0 -color "grey" -group "ID" -group "Register File" -group "Contents" -label "\$t3(\$11)" -radix hexadecimal /toplevel/b2v_RegFile/data(11)
add wave -noupdate -radixshowbase 0 -color "grey" -group "ID" -group "Register File" -group "Contents" -label "\$ra(\$31)" -radix hexadecimal /toplevel/b2v_RegFile/data(31)
#add wave -noupdate -group "Instruction Fetch" -divider -height 15 Outputs

## EX
add wave -noupdate -radixshowbase 0 -color green -group "EX" -label PC -radix hexadecimal /toplevel/EX_PC_val
add wave -noupdate -radixshowbase 0 -color green -group "EX" -label Instruction -radix hexadecimal /toplevel/EX_instruction

##Forwarding
add wave -noupdate -radixshowbase 0 -color white -group "EX" -group "Forwarding" -label "Source A" -radix ALU_forwardSource_in /toplevel/EX_forwardA
add wave -noupdate -radixshowbase 0 -color white -group "EX" -group "Forwarding" -label "Source B" -radix ALU_forwardSource_in /toplevel/EX_forwardB

## Control Logic
add wave -noupdate -radixshowbase 0 -color white -group "EX" -group "Control Logic" -group "Assert Control" -label "Is Assert?" -radix symbolic /toplevel/EX_isTest
add wave -noupdate -radixshowbase 0 -color white -group "EX" -group "Control Logic" -group "Assert Control" -label "Is Negative Assert?" -radix symbolic /toplevel/EX_isNegativeAssert
add wave -noupdate -radixshowbase 0 -color white -group "EX" -group "Control Logic" -group "Assert Control" -label "Is Immediate Assert?" -radix symbolic /toplevel/EX_asrti
add wave -noupdate -radixshowbase 0 -color grey -group "EX" -group "Control Logic" -group "Assert Control" -label "Expected" -radix hexadecimal /toplevel/b2v_Asserter/expected
add wave -noupdate -radixshowbase 0 -color grey -group "EX" -group "Control Logic" -group "Assert Control" -label "Actual" -radix hexadecimal /toplevel/b2v_Asserter/actual

## ALU signals (control, in, out, flags)
#add wave -noupdate -group "ALU" -divider -height 15 "Associated (External)"
add wave -noupdate -radixshowbase 0 -color green -group "EX" -group "ALU" -label "Using Immediate" -radix symbolic /toplevel/EX_ALU_useImm
#add wave -noupdate -group "ALU" -divider -height 15 Inputs
add wave -noupdate -radixshowbase 0 -color green -group "EX" -group "ALU" -label Operation -radix ALUops_in /toplevel/b2v_ALU/Operation
add wave -noupdate -radixshowbase 0 -color green -group "EX" -group "ALU" -label A -radix hexadecimal /toplevel/b2v_ALU/A
add wave -noupdate -radixshowbase 0 -color green -group "EX" -group "ALU" -label B -radix hexadecimal /toplevel/b2v_ALU/B
#add wave -noupdate -group "ALU" -divider -height 15 Outputs
add wave -noupdate -radixshowbase 0 -color white -group "EX" -group "ALU" -label Out -radix hexadecimal /toplevel/b2v_ALU/o_F
add wave -noupdate -radixshowbase 0 -color white -group "EX" -group "ALU" -label Zero -radix hexadecimal /toplevel/b2v_ALU/Zero
add wave -noupdate -radixshowbase 0 -color white -group "EX" -group "ALU" -label Carry -radix hexadecimal /toplevel/b2v_ALU/Carry
add wave -noupdate -radixshowbase 0 -color white -group "EX" -group "ALU" -label Overflow -radix hexadecimal /toplevel/b2v_ALU/Overflow
add wave -noupdate -radixshowbase 0 -color white -group "EX" -label "Reg 2 Out" -radix hexadecimal /toplevel/EX_reg2out

## Data Memory signals
add wave -noupdate -radixshowbase 0 -color green -group "MEM" -label PC -radix hexadecimal /toplevel/MEM_PC_val
add wave -noupdate -radixshowbase 0 -color green -group "MEM" -label Instruction -radix hexadecimal /toplevel/MEM_instruction

add wave -noupdate -radixshowbase 0 -color green -group "MEM" -label "ALU Out" -radix hexadecimal /toplevel/MEM_alu_out

add wave -noupdate -radixshowbase 0 -color green -group "MEM" -group "Forwarding" -label "RS" -radix unsigned /toplevel/MEM_forwardingUnit/RS
add wave -noupdate -radixshowbase 0 -color green -group "MEM" -group "Forwarding" -label "WB.RD" -radix unsigned /toplevel/MEM_forwardingUnit/WB_RD
add wave -noupdate -radixshowbase 0 -color white -group "MEM" -group "Forwarding" -label "Data Source" -radix Memory_forwardSource_out /toplevel/MEM_forward

add wave -noupdate -radixshowbase 0 -color white -group "MEM" -group "Control Logic" -group "Data Memory" -label "Data Access Type" -radix MipsMemSize_out /toplevel/MEM_data_mem_access_size
add wave -noupdate -radixshowbase 0 -color white -group "MEM" -group "Control Logic" -group "Data Memory" -label "Data Access Signed" -radix symbolic /toplevel/MEM_data_mem_signed
add wave -noupdate -radixshowbase 0 -color white -group "MEM" -group "Control Logic" -group "Data Memory" -label "Data Memory Write" -radix symbolic /toplevel/MEM_data_mem_wren

#add wave -noupdate -group "Data Memory" -divider -height 15 Inputs
add wave -noupdate -radixshowbase 0 -color "light blue" -group "MEM" -group "Data Memory" -label Clock -radix hexadecimal /toplevel/b2v_dmem/clock
add wave -noupdate -radixshowbase 0 -color green -group "MEM" -group "Data Memory" -label Address -radix hexadecimal /toplevel/b2v_dmem/address
add wave -noupdate -radixshowbase 0 -color green -group "MEM" -group "Data Memory" -label In -radix hexadecimal /toplevel/b2v_dmem/data
add wave -noupdate -radixshowbase 0 -color green -group "MEM" -group "Data Memory" -label Size -radix MipsMemSize_in /toplevel/b2v_dmem/access_size
add wave -noupdate -radixshowbase 0 -color green -group "MEM" -group "Data Memory" -label Signed -radix symbolic /toplevel/b2v_dmem/signed
add wave -noupdate -radixshowbase 0 -color green -group "MEM" -group "Data Memory" -label "Write Enable" -radix symbolic /toplevel/b2v_dmem/wren
#add wave -noupdate -group "Data Memory" -divider -height 15 Outputs
add wave -noupdate -radixshowbase 0 -color white -group "MEM" -group "Data Memory" -label Out -radix hexadecimal /toplevel/b2v_dmem/data_out
add wave -noupdate -radixshowbase 0 -color grey -group "MEM" -group "Data Memory" -label Memory -radix hexadecimal /toplevel/b2v_dmem/dmem/mem

## WB
add wave -noupdate -radixshowbase 0 -color green -group "WB" -label PC -radix hexadecimal /toplevel/WB_PC_val
add wave -noupdate -radixshowbase 0 -color green -group "WB" -label Instruction -radix hexadecimal /toplevel/WB_instruction

add wave -noupdate -radixshowbase 0 -color green -group "WB" -label "ALU Out" -radix hexadecimal /toplevel/WB_alu_out
add wave -noupdate -radixshowbase 0 -color green -group "WB" -label "Memory Out" -radix hexadecimal /toplevel/WB_mem_out

add wave -noupdate -radixshowbase 0 -color white -group "WB" -group "Register File" -label "Write Address" -radix unsigned /toplevel/b2v_RegFile/w_addr
add wave -noupdate -radixshowbase 0 -color white -group "WB" -group "Register File" -label "Write Data" -radix hexadecimal /toplevel/b2v_RegFile/w_data

## Instruction Memory signals
#add wave -noupdate -group "Instruction Memory" -divider -height 15 Inputs
add wave -noupdate -radixshowbase 0 -color "light blue" -group "Instruction Memory" -label Clock -radix hexadecimal /toplevel/b2v_imem/clock
add wave -noupdate -radixshowbase 0 -color green -group "Instruction Memory" -label Address -radix hexadecimal /toplevel/b2v_imem/address
#add wave -noupdate -group "Instruction Memory" -divider -height 15 Outputs
add wave -noupdate -radixshowbase 0 -color white -group "Instruction Memory" -label Out -radix hexadecimal /toplevel/b2v_imem/q
add wave -noupdate -radixshowbase 0 -color grey -group "Instruction Memory" -label Memory -radix hexadecimal /toplevel/b2v_imem/mem








configure wave -namecolwidth 185
configure wave -valuecolwidth 80
configure wave -snapdistance 50




update