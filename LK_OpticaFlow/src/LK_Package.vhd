library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package LK_Package is
--- Independent Data Definition
	constant PRECISION : integer := 1; -- 1: 72 bits, 2: 144 bits, 3: 216, 4: 288
	constant Hist_Size : integer := 8; -- the number of events: 8, 12, 16 inside the rb array
	constant DELTA_T_WIDTH : integer := 4; -- The width of delta_t timestamps: 4, 8, 12, 16, 20
	constant EventWidth : integer := 64; -- the width of each event timestamp
    constant Address_Width : integer := 12;  -- Address Width for 4096 locations
    constant DWIDTH : integer := 72;  -- Data Width
    constant NBPIPE : integer := 3;    -- Number of pipeline Registers
	constant AXIS_LENGTH : integer := 10; -- the width of x, y addresses in frame 
	constant RAMBLOCK : integer := 8; -- the block dimension of event-based histogram
	constant EventSearchRadius: integer := 3; -- 1: 3*3, 3: 5*5, 5: 7*7	
	constant FIFO_DEPTH : integer:=6;
	constant NoiseSearchRadius : integer:= 1;

--- Dependent Data Definition
	constant Size_Width : integer := integer(ceil(log2(real(Hist_Size))));	-- the length of section inside the ring buffer that stores the number of events 

	constant DATA_WIDTH : integer := PRECISION*DWIDTH; -- the length of section inside the ring buffer that stores the number of events 
	constant TS_WIDTH : integer := DATA_WIDTH - (Hist_Size*DELTA_T_WIDTH) - Size_Width;--  this is the width of each timestamp
	constant RAMBLOCKADDR : integer := integer(ceil(log2(real(RAMBLOCK)))); -- the block addr width of event-based histogram
	constant RAM2DBLOCK : integer := RAMBLOCK*RAMBLOCK; -- the block dimension of event-based histogram
	constant EventSearchDiameter : integer := (2*EventSearchRadius)+1; -- diameter of circle
	constant EventSearch2D : integer := EventSearchDiameter*EventSearchDiameter; -- two dimensional area
--- threshold values
	constant NoiseThreshold : std_logic_vector((TS_WIDTH-1) downto 0):=(others=>'1');
	constant DeltaThreshold : std_logic_vector((TS_WIDTH-1) downto 0):=(others=>'1');

-- Data Type Definition
	subtype RAMWidth is std_logic_vector((DATA_WIDTH-1) downto 0); -- Width of RAM row: 72, 144, 216, 288 bits
	type RAMArraySearchRegion1d is array (EventSearchRadius downto -EventSearchRadius) of RAMWidth; -- 49 means 7*7 blocks of search region
	type RAMArraySearchRegion is array (EventSearchRadius downto -EventSearchRadius) of RAMArraySearchRegion1d; -- 49 means 7*7 blocks of search region

	subtype RAMAddr is std_logic_vector((AXIS_LENGTH-1) downto 0); --  address length for both x and y axis
	type RAMAddrArraySearchRegion1d is array (EventSearchRadius downto -EventSearchRadius) of RAMAddr; -- 49 means 7*7 blocks of search region
	type RAMAddrArraySearchRegion is array (EventSearchRadius downto -EventSearchRadius) of RAMAddrArraySearchRegion1d; -- 49 means 7*7 blocks of search region


	subtype TSArray is std_logic_vector((TS_WIDTH-1) downto 0);
	subtype element is std_logic; -- element array for search region
	
	subtype ts_datawidth is std_logic_vector((TS_WIDTH-1) downto 0);
	type RAMNoiseSearchRegion1d is array (NoiseSearchRadius downto -NoiseSearchRadius) of ts_datawidth; -- element array for search region
	type RAMNoiseSearchRegion2d is array (NoiseSearchRadius downto -NoiseSearchRadius) of RAMNoiseSearchRegion1d; -- 49 means 7*7 blocks of search region
	

	type SearchElement1d is array (EventSearchRadius downto -EventSearchRadius) of element; -- -3:0:3 means 7*7 blocks of search region
	type SearchElement is array (EventSearchRadius downto -EventSearchRadius) of SearchElement1d; -- -3:0:3 means 7*7 blocks of search region


--	constant Threshold_Value : TSArray := (x"AA", others => '0'); -- the width of x, y addresses in frame 
type RAMAddrArray is array((RAM2DBLOCK-1) downto 0) of RAMAddr; -- 63 means 8*8 blocks of UltraRAM	

subtype RAMSubAddrY is std_logic_vector((AXIS_LENGTH-2) downto 0); -- subaddr for block index
subtype RAMSubAddrX is std_logic_vector((AXIS_LENGTH-1) downto 0); -- subaddr for block index
subtype RAMVectorAddr is std_logic_vector(((2*AXIS_LENGTH)+1) downto 0); -- subaddr for block index

type SearchRegion1dY is array (EventSearchRadius downto -EventSearchRadius) of RAMSubAddrY; -- 49 means 7*7 blocks of search region
type SearchRegionY is array (EventSearchRadius downto -EventSearchRadius) of SearchRegion1dY; -- 49 means 7*7 blocks of search region
type SearchRegion1dX is array (EventSearchRadius downto -EventSearchRadius) of RAMSubAddrX; -- 49 means 7*7 blocks of search region
type SearchRegionX is array (EventSearchRadius downto -EventSearchRadius) of SearchRegion1dX; -- 49 means 7*7 blocks of search region
type VectorSearchRegion is array (((((2*EventSearchRadius)+1)*((2*EventSearchRadius)+1))-1) downto 0) of RAMVectorAddr; -- 49 means 7*7 blocks of search region
type VectorElement is array (((((2*EventSearchRadius)+1)*((2*EventSearchRadius)+1))-1) downto 0) of element; -- 49 means 7*7 blocks of search region
type VectorURAM is array ((RAM2DBLOCK-1) downto 0) of RAMWidth; -- 63 means 8*8 blocks of UltraRAM

subtype AddrWithinBlock is std_logic_vector((Address_Width -1) downto 0);
type VectorAddrWithinBlockArray is array((RAM2DBLOCK-1) downto 0) of AddrWithinBlock; -- 63 means 8*8 blocks of UltraRAM	
type array_deltat is array(Hist_Size-1 downto 0) of TSArray;
type array_deltatsec is array(Size_Width downto 0) of array_deltat;

type RingBuffer is array(Hist_Size downto 0) of TSArray; -- array of ring buffer

type array_deltat1d is array (EventSearchRadius downto -EventSearchRadius) of array_deltat;
type array_deltat2d is array (EventSearchRadius downto -EventSearchRadius) of array_deltat1d;

type RingBuffer1d is array (EventSearchRadius downto -EventSearchRadius) of RingBuffer;
type RingBuffer2d is array (EventSearchRadius downto -EventSearchRadius) of RingBuffer1d;

type ts_array1d is array (EventSearchRadius downto -EventSearchRadius) of TSArray;
type ts_array2d is array (EventSearchRadius downto -EventSearchRadius) of ts_array1d;

type size_array1d is array (EventSearchRadius downto -EventSearchRadius) of std_logic_vector((Hist_Size - 1) downto 0);
type size_array2d is array (EventSearchRadius downto -EventSearchRadius) of size_array1d;

subtype BlockSearchWidth is std_logic_vector(5 downto 0); -- the address of ram block can be defined with 6 bits from xaddr and yaddr
type Addr4BlockSearch1d is array (EventSearchRadius downto -EventSearchRadius) of BlockSearchWidth; -- -3:0:3 means 7*7 blocks of search region
type Addr4BlockSearch2d is array (EventSearchRadius downto -EventSearchRadius) of Addr4BlockSearch1d; -- -3:0:3 means 7*7 blocks of search region

type AddrWithinBlockSearch1d is array (EventSearchRadius downto -EventSearchRadius) of AddrWithinBlock; -- -3:0:3 means 7*7 blocks of search region
type AddrWithinBlockSearch2d is array (EventSearchRadius downto -EventSearchRadius) of AddrWithinBlockSearch1d; -- -3:0:3 means 7*7 blocks of search region

subtype std_array1d is std_logic_vector((RAM2DBLOCK-1) downto 0);
type std_array2d is array (EventSearchRadius downto -EventSearchRadius) of std_array1d;
type std_array3d is array (EventSearchRadius downto -EventSearchRadius)  of std_array2d;

type std_vec_array1d is array ((RAM2DBLOCK-1) downto 0) of std_logic_vector((Address_Width-1) downto 0);
type std_vec_array2d is array (EventSearchRadius downto -EventSearchRadius) of std_vec_array1d;
type std_vec_array3d is array (EventSearchRadius downto -EventSearchRadius)  of std_vec_array2d;

type data_std_array1d is array ((RAM2DBLOCK-1) downto 0) of std_logic_vector((DATA_WIDTH-1) downto 0);
type data_std_array2d is array (EventSearchRadius downto -EventSearchRadius) of data_std_array1d;
type data_std_array3d is array (EventSearchRadius downto -EventSearchRadius)  of data_std_array2d;

subtype histsize is std_logic_vector((Size_Width-1) downto 0);
type histsize1d is array (EventSearchRadius downto -EventSearchRadius) of histsize;
type histsize2d is array (EventSearchRadius downto -EventSearchRadius) of histsize1d;

end package;
