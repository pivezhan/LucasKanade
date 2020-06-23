library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.LK_Package.all;
use work.all;

entity decompression_unit is
	generic(
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
	port(
		Data_In : in array_deltat;	 
		Previous_TS : in std_logic_vector((TS_WIDTH - 1) downto 0);
		Current_TS : in std_logic_vector((TS_WIDTH - 1) downto 0);
		Limitted_TS : out std_logic_vector((TS_WIDTH - 1) downto 0);
		Data_Out : out RingBuffer
	);
end entity;
--
architecture radix4_sklanski of decompression_unit is
constant ThresholdValue : integer:=100;

begin 
-- Limitted_TS <= Current_TS - std_logic_vector(to_unsigned(ThresholdValue, Limitted_TS'length));
Limitted_TS <= Current_TS - std_logic_vector(to_unsigned(100000, Limitted_TS'length));

Data_Out(0) <= Previous_TS;
DecompressedArray:	for i in 1 to Hist_Size generate
		Data_Out(i) <= Previous_TS - data_in(i-1);
end generate;	
-- combinational

end radix4_sklanski;			
					  