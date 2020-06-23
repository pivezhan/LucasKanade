library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.LK_Package.all;
use work.all;


entity PrefixAdder_tb is
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
end entity;

architecture behavioral of PrefixAdder_tb is
	signal data_in: std_logic_vector((DATA_WIDTH - 1) downto 0);
	signal data_out1,data_out2 : array_deltat;

begin
	


	DUT1: entity work.PrefixAdder(radix4_sklanski)
	Generic map(PRECISION, EventWidth, EventSearchRadius, Address_Width, DWIDTH, NBPIPE, RAMBLOCKADDR, RAM2DBLOCK, TS_WIDTH, AXIS_LENGTH, DELTA_T_WIDTH, Hist_Size, Size_Width, DATA_WIDTH, FIFO_DEPTH)
	port map (data_in => data_in,data_out => data_out1);

	DUT2: entity work.PrefixAdder(kogge_stone)
	Generic map(PRECISION, EventWidth, EventSearchRadius, Address_Width, DWIDTH, NBPIPE, RAMBLOCKADDR, RAM2DBLOCK, TS_WIDTH, AXIS_LENGTH, DELTA_T_WIDTH, Hist_Size, Size_Width, DATA_WIDTH, FIFO_DEPTH)
	port map (data_in => data_in,data_out => data_out2);

	process
	begin
		data_in <= std_logic_vector(to_unsigned(8, Size_Width)) & 
		std_logic_vector(to_unsigned(20, TS_WIDTH)) & 
		std_logic_vector(to_unsigned(1, DELTA_T_WIDTH)) & 
		std_logic_vector(to_unsigned(1, DELTA_T_WIDTH)) & 
		std_logic_vector(to_unsigned(1, DELTA_T_WIDTH)) & 
		std_logic_vector(to_unsigned(1, DELTA_T_WIDTH)) & 
		std_logic_vector(to_unsigned(1, DELTA_T_WIDTH)) &  
		std_logic_vector(to_unsigned(1, DELTA_T_WIDTH)) & 
		std_logic_vector(to_unsigned(1, DELTA_T_WIDTH)) & 
		std_logic_vector(to_unsigned(1, DELTA_T_WIDTH)) &
		std_logic_vector(to_unsigned(0, DELTA_T_WIDTH)) &
		std_logic_vector(to_unsigned(0, DELTA_T_WIDTH)) &
		std_logic_vector(to_unsigned(0, DELTA_T_WIDTH)) &
		std_logic_vector(to_unsigned(0, DELTA_T_WIDTH));
		wait for 100 ns;
	end process;

end behavioral;