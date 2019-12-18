library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.LK_Package.all;

entity shifter is
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
		data_in : in std_logic_vector((DATA_WIDTH - 1) downto 0);		  -- input data from input ring buffer
		Current_ts : in std_logic_vector((TS_SIZE - 1) downto 0);  -- TS - Threshold value
		data_out : out std_logic_vector((DATA_WIDTH - 1) downto 0);	   -- output to shifter size unit
	);
end entity;
architecture behavioral of shifter is
begin	

Omission:	for i in 0 to (DELTA_T_NUM-1) generate
			data_out((DATA_WIDTH - TS_SIZE - TS_WIDTH - (i*DELTA_T_WIDTH) - 1) downto (DATA_WIDTH - TS_SIZE - TS_WIDTH - ((i+1)*DELTA_T_WIDTH)))
			<= data_in((DATA_WIDTH - TS_SIZE - TS_WIDTH - (i*DELTA_T_WIDTH) - 1) downto (DATA_WIDTH - TS_SIZE - TS_WIDTH - ((i+1)*DELTA_T_WIDTH))) when tempring(i)(TS_SIZE - 1) = '1' else zerodelta; 
			-- move data in ring buffer
			end generate;

end behavioral;