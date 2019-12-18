library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package LK_Package is 
	constant DELTA_T_WIDTH : integer:=4; -- The width of delta_t timestamps
	constant DELTA_T_NUM : integer:=8; -- the capacity of number of events inside the rb array
	constant TS_SIZE : integer:=integer(ceil(log2(real(DELTA_T_NUM))));	-- the length of section inside the ring buffer that stores the number of events 
	constant TS_WIDTH : integer:=(4*DELTA_T_WIDTH)-TS_SIZE;--  this is the width of each timestamp
	constant DATA_WIDTH : integer := DELTA_T_WIDTH*DELTA_T_NUM + TS_SIZE + TS_WIDTH; -- the length of section inside the ring buffer that stores the number of events 
	constant ADDR_WIDTH : integer:=16;	-- the address width for Ring buffer based block ram
	constant AXIS_LENGTH : integer:=8; -- the width of x, y addresses in frame 
	subtype TSArray is std_logic_vector((TS_WIDTH-1) downto 0);
--	constant Threshold_Value : TSArray := (x"AA", others => '0'); -- the width of x, y addresses in frame 
	type array_deltat is array(DELTA_T_NUM-1 downto 0) of TSArray;
	type RingBuffer is array(DELTA_T_NUM downto 0) of TSArray; -- array of ring buffer
	type array_deltat2d is array(TS_SIZE+1 downto 0) of array_deltat;
end package;
