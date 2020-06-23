library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.LK_Package.all;
use ieee.math_real.all;
use work.all;


entity NeighborhoodDataExtraction  is
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
		NDE_in_search_addr : in Addr4BlockSearch2d; -- address of each block on search region dimension
		-- NDE_in_border : in SearchElement; -- 64 border data input
		NDE_in_data : in data_std_array1d; -- 64 URAM block data input
		NDE_out_data : out RAMArraySearchRegion -- 7*7 * 72*Precision data output	
		);
end NeighborhoodDataExtraction;

architecture behavioral of NeighborhoodDataExtraction is
signal NDE_temp_data : data_std_array3d;

begin				

----- Decode section for ts write ----------
ramblocks: 	for k in 0 to (RAM2DBLOCK-1) generate
row1:			for i in -EventSearchRadius to EventSearchRadius generate -- Y_addr
col1: 				for j in -EventSearchRadius to EventSearchRadius generate -- X_addr
					NDE_temp_data(i)(j)(k) <= NDE_in_data(k)
					when (unsigned(NDE_in_search_addr(i)(j)) = k) else (others => '0');
					end generate;
				end generate;
			end generate;

----- Reduction to search region size ----------
row2:			for i in -EventSearchRadius to EventSearchRadius generate -- Y_addr
col2: 				for j in -EventSearchRadius to EventSearchRadius generate -- X_addr
	NDE_out_data(i)(j) <= NDE_temp_data(i)(j)(0) or NDE_temp_data(i)(j)(1) or 
	NDE_temp_data(i)(j)(2) or NDE_temp_data(i)(j)(3) or 
	NDE_temp_data(i)(j)(4) or NDE_temp_data(i)(j)(5) or 
	NDE_temp_data(i)(j)(6) or NDE_temp_data(i)(j)(7) or 
	NDE_temp_data(i)(j)(8) or NDE_temp_data(i)(j)(9) or 
	NDE_temp_data(i)(j)(10) or NDE_temp_data(i)(j)(11) or 
	NDE_temp_data(i)(j)(12) or NDE_temp_data(i)(j)(13) or 
	NDE_temp_data(i)(j)(14) or NDE_temp_data(i)(j)(15) or 
	NDE_temp_data(i)(j)(16) or NDE_temp_data(i)(j)(17) or 
	NDE_temp_data(i)(j)(18) or NDE_temp_data(i)(j)(19) or 
	NDE_temp_data(i)(j)(20) or NDE_temp_data(i)(j)(21) or 
	NDE_temp_data(i)(j)(22) or NDE_temp_data(i)(j)(23) or 
	NDE_temp_data(i)(j)(24) or NDE_temp_data(i)(j)(25) or 
	NDE_temp_data(i)(j)(26) or NDE_temp_data(i)(j)(27) or 
	NDE_temp_data(i)(j)(28) or NDE_temp_data(i)(j)(29) or 
	NDE_temp_data(i)(j)(30) or NDE_temp_data(i)(j)(31) or 
	NDE_temp_data(i)(j)(32) or NDE_temp_data(i)(j)(33) or 
	NDE_temp_data(i)(j)(34) or NDE_temp_data(i)(j)(35) or 
	NDE_temp_data(i)(j)(36) or NDE_temp_data(i)(j)(37) or 
	NDE_temp_data(i)(j)(38) or NDE_temp_data(i)(j)(39) or 
	NDE_temp_data(i)(j)(40) or NDE_temp_data(i)(j)(41) or 
	NDE_temp_data(i)(j)(42) or NDE_temp_data(i)(j)(43) or 
	NDE_temp_data(i)(j)(44) or NDE_temp_data(i)(j)(45) or 
	NDE_temp_data(i)(j)(46) or NDE_temp_data(i)(j)(47) or 
	NDE_temp_data(i)(j)(48) or NDE_temp_data(i)(j)(49) or 
	NDE_temp_data(i)(j)(50) or NDE_temp_data(i)(j)(51) or 
	NDE_temp_data(i)(j)(52) or NDE_temp_data(i)(j)(53) or 
	NDE_temp_data(i)(j)(54) or NDE_temp_data(i)(j)(55) or 
	NDE_temp_data(i)(j)(56) or NDE_temp_data(i)(j)(57) or 
	NDE_temp_data(i)(j)(58) or NDE_temp_data(i)(j)(59) or 
	NDE_temp_data(i)(j)(60) or NDE_temp_data(i)(j)(61) or 
	NDE_temp_data(i)(j)(62) or NDE_temp_data(i)(j)(63);
					end generate;
				end generate;
end behavioral;