-- I didn't include border regions in my analysis
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.LK_Package.all;
use work.all;
use ieee.math_real.all;

entity Collector_tb is
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
end Collector_tb;

architecture behavioral of Collector_tb is 
signal dx2_in : histsize2d_grad; -- sptial derivation second order
signal dy2_in : histsize2d_grad; -- sptial derivation second order
signal dxdy_in : histsize2d_grad;  -- sptial derivation second order
signal dxdt_in : histsize2d_grad; -- temporal and spatial derivation
signal dydt_in : histsize2d_grad; -- temporal and spatial derivation
signal dx2_out : histsizegrad;
signal dy2_out : histsizegrad;
signal dxdy_out : histsizegrad;
signal dxdt_out : histsizegrad;
signal dydt_out : histsizegrad;

component Collector is
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
	dx2_in : in histsize2d_grad; -- sptial derivation second order
	dy2_in : in histsize2d_grad; -- sptial derivation second order
	dxdy_in : in histsize2d_grad;  -- sptial derivation second order
	dxdt_in : in histsize2d_grad; -- temporal and spatial derivation
	dydt_in : in histsize2d_grad; -- temporal and spatial derivation
	dx2_out : out histsizegrad;
	dy2_out : out histsizegrad;
	dxdy_out : out histsizegrad;
	dxdt_out : out histsizegrad;
	dydt_out : out histsizegrad);
end component;

begin
Collector1: Collector Generic map(PRECISION, EventWidth, EventSearchRadius, Address_Width, DWIDTH, NBPIPE, RAMBLOCKADDR, RAM2DBLOCK, TS_WIDTH, AXIS_LENGTH, DELTA_T_WIDTH, Hist_Size, Size_Width, DATA_WIDTH, FIFO_DEPTH)
	 port map (dx2_in => dx2_in,    -- 7*7 border definition
	 dy2_in => dy2_in, -- 7*7 addr of each element inside block on search region dimension 
	 dxdy_in => dxdy_in,
	 dxdt_in => dxdt_in,
	 dydt_in => dydt_in,
	 dx2_out => dx2_out,
	 dy2_out => dy2_out,
	 dxdy_out => dxdy_out,
	 dxdt_out => dxdt_out,
	 dydt_out => dydt_out);	-- vector data according to the blocks 63:0


process(dx2_in, dy2_in, dxdy_in, dxdt_in, dydt_in)
begin

dx2_in <= (others => (others => (others => '0')));
dy2_in <= (others => (others => (others => '1')));
dxdy_in <= (others => (others => (others => '1')));
dxdt_in <= (others => (others => (others => '1')));
dydt_in <= (others => (others => (others => '1')));

end process;


end behavioral;