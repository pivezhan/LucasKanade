-- Note: I didn't include border regions in my analysis
-- The collector should deal with matrix input and 
-- the generic processing needs a vectorized implemementation
-------------------------------------------------------------------------
-- Mohammad Pivezhandi
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------
-- Module: pipeline with Rising-edge Clock
-- Active-high Synchronous Clear
-- Active-high Clock Enable
-- File: Addr4BlockSearch2dSyncReg.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.LK_Package.all;
use work.all;
use ieee.math_real.all;

entity Collector is
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
	dx2_in : in histsize2d_grad; -- input d*d matrix sptial derivation second order
	dy2_in : in histsize2d_grad; -- input d*d matrix sptial derivation second order
	dxdy_in : in histsize2d_grad;  -- input d*d matrix sptial derivation second order
	dxdt_in : in histsize2d_grad; -- input d*d matrix temporal and spatial derivation
	dydt_in : in histsize2d_grad; -- input d*d matrix temporal and spatial derivation
	dy2_out : out std_logic_vector((2*Size_Width-1) downto 0); -- output sum of sptial derivation second order
	dx2_out : out std_logic_vector((2*Size_Width-1) downto 0); -- output sum of sptial derivation second order
	dxdy_out : out std_logic_vector((2*Size_Width-1) downto 0); -- output sum of sptial derivation second order
	dxdt_out : out std_logic_vector((2*Size_Width-1) downto 0); -- output sum of sptial and tempral derivation second order
	dydt_out : out std_logic_vector((2*Size_Width-1) downto 0)); -- output sum of sptial and temporal derivation second order
end Collector;

architecture behavioral of Collector is 

constant allzeros : std_logic_vector(Size_Width-1 downto 0):=(others => '0');
constant allzeros_1 : std_logic_vector(Size_Width-2 downto 0):=(others => '0');

type addervectorarray is array (HalfGradientSearch2D-1 downto 0) of std_logic_vector((2*Size_Width-1) downto 0);
type addervectorarray2d is array ((EventSearchRadius+4) downto 0) of addervectorarray;
signal dx2_vec : addervectorarray2d:=(others => (others => (others => '0')));
signal dy2_vec : addervectorarray2d:=(others => (others => (others => '0')));
signal dxdy_vec : addervectorarray2d:=(others => (others => (others => '0')));
signal dxdt_vec : addervectorarray2d:=(others => (others => (others => '0')));
signal dydt_vec : addervectorarray2d:=(others => (others => (others => '0')));

begin

---Matrix based addition and change to vector for the first stage
-- vertical summation
xaxis1: for i in -GradientSearchDistance to GradientSearchDistance generate -- X_addr
	yaxis1: for j in 1 to GradientSearchDistance generate -- Y_addr
		dx2_vec(0)(((i+GradientSearchDistance)*GradientSearchDistance) + j-1) <= dx2_in(i)(j) + dx2_in(i)(-j); --
		dy2_vec(0)(((i+GradientSearchDistance)*GradientSearchDistance) + j-1) <= dy2_in(i)(j) + dy2_in(i)(-j); --
		dxdy_vec(0)(((i+GradientSearchDistance)*GradientSearchDistance) + j-1) <= dxdy_in(i)(j) + dxdy_in(i)(-j); --
		dxdt_vec(0)(((i+GradientSearchDistance)*GradientSearchDistance) + j-1) <= dxdt_in(i)(j) + dxdt_in(i)(-j); --
		dydt_vec(0)(((i+GradientSearchDistance)*GradientSearchDistance) + j-1) <= dydt_in(i)(j) + dydt_in(i)(-j); --
	end generate;
end generate;

xaxis2: for i in 1 to GradientSearchDistance generate -- X_addr
		dx2_vec(0)(i+(GradientSearchDistance*GradientSearchDiameter)-1) <= dx2_in(i)(0) + dx2_in(-i)(0); --
		dy2_vec(0)(i+(GradientSearchDistance*GradientSearchDiameter)-1) <= dy2_in(i)(0) + dy2_in(-i)(0); --
		dxdy_vec(0)(i+(GradientSearchDistance*GradientSearchDiameter)-1) <= dxdy_in(i)(0) + dxdy_in(-i)(0); --
		dxdt_vec(0)(i+(GradientSearchDistance*GradientSearchDiameter)-1) <= dxdt_in(i)(0) + dxdt_in(-i)(0); --
		dydt_vec(0)(i+(GradientSearchDistance*GradientSearchDiameter)-1) <= dydt_in(i)(0) + dydt_in(-i)(0); --
end generate;

dx2_vec(0)(HalfGradientSearch2D-1) <= dx2_in(0)(0); --
dy2_vec(0)(HalfGradientSearch2D-1) <= dy2_in(0)(0); --
dxdy_vec(0)(HalfGradientSearch2D-1) <= dxdy_in(0)(0); --
dxdt_vec(0)(HalfGradientSearch2D-1) <= dxdt_in(0)(0); --
dydt_vec(0)(HalfGradientSearch2D-1) <= dydt_in(0)(0); --

outerloop: for k in 1 to GradientSearchDistance-1 generate
	innerloop: for l in 0 to integer(floor(real(GradientSearch2D)*(2*(-(k+1))))) generate
		ifcondition: if ((l mod 2) == 0) generate
			dx2_vec(l)(k) <= dx2_vec(l-1)(k) + dx2_vec(l-1)(k+1); --
			dy2_vec(l)(k) <= dy2_vec(l-1)(k) + dy2_vec(l-1)(k+1); --
			dxdy_vec(l)(k) <= dxdy_vec(l-1)(k) + dxdy_vec(l-1)(k+1); --
			dxdt_vec(l)(k) <= dxdt_vec(l-1)(k) + dxdt_vec(l-1)(k+1); --
			dydt_vec(l)(k) <= dydt_vec(l-1)(k) + dydt_vec(l-1)(k+1); --
		end generate;
	end generate;
end generate;
end behavioral;