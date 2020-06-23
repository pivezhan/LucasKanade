library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.LK_Package.all;
use work.all;


entity PrefixAdder is
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
	data_in : in std_logic_vector((DATA_WIDTH - 1) downto 0);
	data_out : out array_deltat
	);
end entity;

--architecture kogge_stone of PrefixAdder is
--	signal prefixarray : array_deltatsec:=(others=>(others=>(others => '0')));
--begin 
--initailize:	for i in 0 to (Hist_Size - 1) generate
--		prefixarray(0)(i)((DELTA_T_WIDTH - 1) downto 0) <= data_in((DATA_WIDTH-TS_WIDTH-Size_Width-((Hist_Size-i-1)*DELTA_T_WIDTH)-1) downto (DATA_WIDTH-TS_WIDTH-Size_Width-((Hist_Size-i)*DELTA_T_WIDTH)));
--	end generate;	
--Level_j:		for j in 0 to Size_Width-1 generate
--Array_i:			for i in 0 to (Hist_Size - 1) generate
--Cond_add:					if (i >= 2**j) generate
--								prefixarray(j+1)(i) <= prefixarray(j)(i) + prefixarray(j)(i-2**j);
--							end generate;
--Cond_pass:					if (i < 2**j) generate
--								prefixarray(j+1)(i) <= prefixarray(j)(i);
--							end generate;
--					end generate;
--				end generate;
--	data_out <= prefixarray(Size_Width);
--end kogge_stone;

architecture radix4_sklanski of PrefixAdder is
	signal prefixarray : array_deltatsec:=(others=>(others=>(others => '0')));
begin 
initailize:	for i in 0 to (Hist_Size - 1) generate
		prefixarray(0)(i)((DELTA_T_WIDTH - 1) downto 0) <= data_in((DATA_WIDTH-TS_WIDTH-Size_Width-((Hist_Size-i-1)*DELTA_T_WIDTH)-1) downto (DATA_WIDTH-TS_WIDTH-Size_Width-((Hist_Size-i)*DELTA_T_WIDTH)));
end generate;	
-- combinational
Level_j:		for j in 0 to Size_Width-1 generate
Array_i:			for i in 0 to (Hist_Size - 1) generate
Radix4_Reduce:			if (j < 2) generate	  -- Reduce stage of radix4_sklanski
Cond_Add1:					if ((i mod 4) >= 2**j) generate
								prefixarray(j+1)(i) <= prefixarray(j)(i) + prefixarray(j)(i-(2**j));
							end generate;
Cond_Pass1:					if ((i mod 4) < 2**j) generate
								prefixarray(j+1)(i) <= prefixarray(j)(i);
							end generate;
						end generate;
Radix4_Propagate:			if (j >= 2) generate		-- propagate stage of radix4_sklanski
Cond_Add2:					if ((i mod 2**(j+1)) >= (2**j)) generate
								prefixarray(j+1)(i) <= prefixarray(j)(i) + prefixarray(j)(i-(i mod 2**(j+1))+(2**j)-1);
							end generate;
Cond_Pass2:					if ((i mod 2**(j+1)) < (2**j)) generate
								prefixarray(j+1)(i) <= prefixarray(j)(i);
							end generate;
					   	end generate;
					end generate;
end generate;	
--
data_out <= prefixarray(Size_Width); -- write the result into the output array
end radix4_sklanski;			
					  