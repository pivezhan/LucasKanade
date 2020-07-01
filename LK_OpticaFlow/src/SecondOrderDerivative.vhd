-- I didn't include border regions in my analysis
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.LK_Package.all;
use ieee.math_real.all;
use work.all;

entity SecondOrderDerivative is
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
port (dt : in histsize2d_grad; -- 64 URAM block data input
	dx : in histsize2d_grad;
	dy : in histsize2d_grad;
	dx2 : out histsize2d_grad;
	dy2 : out histsize2d_grad;
	dxdy : out histsize2d_grad;
	dxdt : out histsize2d_grad;
	dydt : out histsize2d_grad);
end SecondOrderDerivative;

architecture behavioral of SecondOrderDerivative is 
constant AllOnes : std_logic_vector(Size_Width-1 downto 0):=(others => '1');
constant AllZeros : std_logic_vector(Size_Width-1 downto 0):=(others => '0');

begin
xaxis1: for i in -GradientSearchDistance to GradientSearchDistance generate -- Y_addr
	yaxis1: for j in -GradientSearchDistance to GradientSearchDistance generate -- X_addr
		dx2(i)(j) <= dx(i)(j)((Size_Width-1) downto 0) * dx(i)(j)((Size_Width-1) downto 0); 
		dy2(i)(j) <= dy(i)(j)((Size_Width-1) downto 0) * dy(i)(j)((Size_Width-1) downto 0); 
		dxdy(i)(j) <= dx(i)(j)((Size_Width-1) downto 0) * dy(i)(j)((Size_Width-1) downto 0); 
		dxdt(i)(j) <= dx(i)(j)((Size_Width-1) downto 0) * dt(i)(j)((Size_Width-1) downto 0); 
		dydt(i)(j) <= dy(i)(j)((Size_Width-1) downto 0) * dt(i)(j)((Size_Width-1) downto 0); 
	end generate;
end generate;

end behavioral;