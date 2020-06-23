library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.LK_Package.all;
use ieee.math_real.all;
use work.all;

entity NoiseRemoval  is
generic (
	PRECISION : integer := PRECISION; -- 1: 72 bits, 2: 144 bits, 3: 216, 4: 288
	EventWidth : integer := EventWidth; -- the width of each event timestamp: 64
	EventSearchRadius: integer := EventSearchRadius; -- 3: 3*3, 5: 5*5, 7: 7*7
    Address_Width : integer := Address_Width;  -- Address Width for 4096 locations: 12
    DWIDTH : integer := DWIDTH;  -- Data Width: 72
    NBPIPE : integer := NBPIPE;    -- Number of pipeline Registers: 3
	RAMBLOCKADDR : integer := RAMBLOCKADDR; -- the block addr width of event-based histogram: 3
	RAM2DBLOCK : integer := RAM2DBLOCK; -- the block dimension of event-based histogram : 8*8 
	TS_WIDTH : integer := TS_WIDTH; --  this is the width of each timestamp: 16-Size_Width
	AXIS_LENGTH : integer := AXIS_LENGTH; -- the width of x, y addresses in frame: 9
	DELTA_T_WIDTH : integer := DELTA_T_WIDTH; -- The width of delta_t timestamps
	Hist_Size : integer := Hist_Size; -- the capacity of number of events inside the rb array
	Size_Width : integer := Size_Width; -- the length of section inside the ring buffer that stores the number of events 
	DATA_WIDTH : integer := DATA_WIDTH; -- data_width = Size_Width + TS_WIDTH + DELTA_T_WIDTH*Hist_Size
	FIFO_DEPTH : integer :=  FIFO_DEPTH-- depth of FIFO ram depth
		 );
port    (
		NR_ts : in std_logic_vector((TS_WIDTH-1) downto 0); -- address of each block on search region dimension
		NR_border_in : in SearchElement; -- 64 border data input
		NR_in_data : in RAMArraySearchRegion; -- 64 URAM block data input
		NR_valid : out std_logic
		);
end NoiseRemoval;

architecture behavioral of NoiseRemoval is 
signal temp_ts : RAMNoiseSearchRegion2d;


begin
----- decode section for ts write ----------
row2:			for i in -NoiseSearchRadius to NoiseSearchRadius generate -- Y_addr
col2: 				for j in -NoiseSearchRadius to NoiseSearchRadius generate -- X_addr
					temp_ts(i)(j) <= (NR_ts - NR_in_data(i)(j)(((PRECISION*DWIDTH)- Size_Width - 1) downto ((PRECISION*DWIDTH)- Size_Width - TS_WIDTH)) - 1000) 
					when NR_border_in(i)(j)='0' else (others=>'0');
					end generate;
				end generate;
NR_valid <= (temp_ts(0)(0)(TS_WIDTH-1) and temp_ts(1)(1)(TS_WIDTH-1) and temp_ts(-1)(-1)(TS_WIDTH-1) and
temp_ts(-1)(0)(TS_WIDTH-1) and temp_ts(0)(-1)(TS_WIDTH-1)); -- if MSB is == 1 it means it is negative

end behavioral;