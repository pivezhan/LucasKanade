library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.LK_Package.all;

entity decompression_unit is
	generic(
	TS_WIDTH : integer:=TS_WIDTH; --  this is the width of each timestamp
	AXIS_LENGTH : integer := AXIS_LENGTH; -- the width of x, y addresses in frame 
	ADDR_WIDTH : integer := ADDR_WIDTH; -- the address width for Ring buffer based block ram  
	DELTA_T_WIDTH : integer := DELTA_T_WIDTH; -- The width of delta_t timestamps
	DELTA_T_NUM : integer := DELTA_T_NUM; -- the capacity of number of events inside the rb array
	TS_SIZE : integer := TS_SIZE; -- the length of section inside the ring buffer that stores the number of events 
	DATA_WIDTH : integer := DATA_WIDTH -- data_width = TS_SIZE + TS_WIDTH + DELTA_T_WIDTH*DELTA_T_NUM
	);
	port(
		Data_In : in array_deltat;	 
		Previous_TS : in std_logic_vector((TS_SIZE - 1) downto 0);
		Current_TS : in std_logic_vector((TS_SIZE - 1) downto 0);
		Limitted_TS : out std_logic_vector((TS_SIZE - 1) downto 0);
		Data_Out : out RingBuffer
	);
end entity;
--
architecture radix4_sklanski of decompression_unit is
constant ThresholdValue : integer:=100;

begin 
Limitted_TS <= Current_TS - std_logic_vector(to_unsigned(ThresholdValue, Limitted_TS'length));
Data_Out(0) <= Previous_TS;
DecompressedArray:	for i in 1 to DELTA_T_NUM generate
		Data_Out(i) <= Previous_TS - data_in(i-1);
end generate;	
-- combinational

end radix4_sklanski;			
					  