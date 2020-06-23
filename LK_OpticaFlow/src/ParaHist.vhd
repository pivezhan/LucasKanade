library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.LK_Package.all;
use work.all;

entity ParaHist is
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
		clk : in std_logic;
		rst : in std_logic;
		FIFO_Read_En : in std_logic; -- read enable for FIFO ram
		FIFO_Write_En : in std_logic; -- write enable for FIFO ram
		input_data : in std_logic_vector((EventWidth - 1) downto 0);
--		Packet_Event_En : out std_logic;
--		valid_out : out std_logic; -- valid when finishing
		empty : out std_logic; -- fifo is empty
		full : out std_logic; -- fifo is full
		NDE_NR_valid : out std_logic; -- valid means the ts is within the noise threshold value so no stall condition
		hist_size_out : out histsize2d; -- size of each elements in corresponding window
		hist_border : out SearchElement ---border of the histogram window
		-- URAMDA_NDE_out : out std_logic_vector((RAM2DBLOCK*DATA_WIDTH) + RAM2DBLOCK*13 + TS_WIDTH + 7*EventSearch2D -1  downto 0)
	);
end entity;

architecture behavioral of ParaHist is
constant EF_NAG_length : integer := EventWidth; -- event fetch and neighborhood address generator length
constant URAMDA_NDE_length : integer := (RAM2DBLOCK*DATA_WIDTH) + RAM2DBLOCK*13 + TS_WIDTH + 7*EventSearch2D; -- URAM data access to neighborhood data extraction pipeline
constant NDE_NR_length : integer := (EventSearch2D*DATA_WIDTH) + (RAM2DBLOCK*12) + RAM2DBLOCK + 7*EventSearch2D + TS_WIDTH; -- neighborhood data extraction to noise removal pipeline
constant NR_PA_length : integer := (EventSearch2D*DATA_WIDTH) + (RAM2DBLOCK*12) + RAM2DBLOCK + 7*EventSearch2D + TS_WIDTH; -- noise removal to prefix adder pipeline
constant PA_DE_length : integer := (EventSearch2D*Hist_Size*TS_WIDTH)  + (EventSearch2D*DATA_WIDTH) + (RAM2DBLOCK*12) + RAM2DBLOCK + (7*EventSearch2D) + TS_WIDTH; -- prefix adder to decompression unit pipeline
constant De_CP_length : integer := EventSearch2D*(Hist_Size+1)*TS_WIDTH + (RAM2DBLOCK*12) + (EventSearch2D*TS_WIDTH) + (EventSearch2D*DATA_WIDTH) + RAM2DBLOCK + 7*EventSearch2D + TS_WIDTH; -- Decompression unit to comparison and shift pipeline
constant COM_URAMDM_length : integer := (EventSearch2D*DATA_WIDTH) + (RAM2DBLOCK*12) + RAM2DBLOCK + 7*EventSearch2D + TS_WIDTH; -- comparison and shift to URAM data mapping pipeline
constant URAMDM_WB_length : integer := DATA_WIDTH; -- comparison and shift to URAM data mapping pipeline
constant NAG_URAMAM_length : integer := (20*EventSearch2D)+TS_WIDTH; -- neighborhood address generator and URAM address mapping pipeline
constant URAMAM_URAMDA_length : integer := (RAM2DBLOCK*DATA_WIDTH) + (RAM2DBLOCK*12) + RAM2DBLOCK + TS_WIDTH + 7*EventSearch2D; -- URAM address mapping  to URAM data access pipeline
constant URAMDM_WriteBack_length : integer:= (RAM2DBLOCK*DATA_WIDTH) + (RAM2DBLOCK*12) +  RAM2DBLOCK;
constant timestamp_begining_point: integer:= 23;



-- component URAMarray  is
-- generic (
	-- PRECISION : integer := PRECISION; -- 1: 72 bits, 2: 144 bits, 3: 216, 4: 288
	-- EventWidth : integer := EventWidth; -- the width of each event timestamp: 64
	-- EventSearchRadius: integer := EventSearchRadius; -- 3: 3*3, 5: 5*5, 7: 7*7
    -- Address_Width : integer := Address_Width;  -- Address Width for 4096 locations: 12
    -- DWIDTH : integer := DWIDTH;  -- Data Width: 72
    -- NBPIPE : integer := NBPIPE;    -- Number of pipeline Registers: 3
	-- RAMBLOCKADDR : integer := RAMBLOCKADDR; -- the block addr width of event-based histogram: 3
	-- RAM2DBLOCK : integer := RAM2DBLOCK; -- the block dimension of event-based histogram : 8*8 
	-- TS_WIDTH : integer := TS_WIDTH; --  this is the width of each timestamp: 16-Size_Width
	-- AXIS_LENGTH : integer := AXIS_LENGTH; -- the width of x, y addresses in frame: 9
	-- DELTA_T_WIDTH : integer := DELTA_T_WIDTH; -- The width of delta_t timestamps
	-- Hist_Size : integer := Hist_Size; -- the capacity of number of events inside the rb array
	-- Size_Width : integer := Size_Width; -- the length of section inside the ring buffer that stores the number of events 
	-- DATA_WIDTH : integer := DATA_WIDTH; -- data_width = Size_Width + TS_WIDTH + DELTA_T_WIDTH*Hist_Size
	-- FIFO_DEPTH : integer :=  FIFO_DEPTH-- depth of FIFO ram depth
		 -- );
-- port    (
		-- clk : in std_logic;                                  -- Clock 
		-- rst : in std_logic;                                  -- Reset
		-- in_we : in std_logic_vector((RAM2DBLOCK-1) downto 0); -- Write Enable                                  -- Write Enable
		-- d_ince : in std_logic_vector((RAM2DBLOCK-1) downto 0); -- Output Register Enable
		-- in_mem_en : in std_logic_vector((RAM2DBLOCK-1) downto 0); -- Output Memory Enable
		-- in_din : in VectorURAM;
		-- in_addr : in VectorAddrWithinBlockArray; -- Memory Enable		
		-- out_dout : out VectorURAM       -- Data Output
        -- );
-- end component;







--------------------------------------------------------
---------- stage 1a: Event Fetch pipeline --------------
--------------------------------------------------------
----- Signal definition for FIFO registers
signal FIFO_data_out : std_logic_vector((EventWidth - 1) downto 0); -- FIFO data output
--	signal empty : std_logic; -- is FIFO empty?
--	signal full : std_logic;-- is FIFO full?

component STD_FIFO is
	Generic(
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
	Port ( 
		CLK		: in  STD_LOGIC;
		RST		: in  STD_LOGIC;
		WriteEn	: in  STD_LOGIC;
		DataIn	: in  STD_LOGIC_VECTOR ((EventWidth-1) downto 0);
		ReadEn	: in  STD_LOGIC;
		DataOut	: out STD_LOGIC_VECTOR ((EventWidth-1) downto 0);
		Empty	: out STD_LOGIC;
		Full	: out STD_LOGIC
	);
end component;


--------------------------------------------------------
------ stage 1b: Neighborhood address generator  -------
----------- ---------------------------------------------
signal EF_NAG_in, EF_NAG_out : std_logic_vector((EF_NAG_length - 1) downto 0); -- Input_output to pipeline registers
signal EF_NAG_WE : std_logic;
signal EF_NAG_addr_of_block_search_in : Addr4BlockSearch2d;
signal EF_NAG_addr_within_block_search_in : AddrWithinBlockSearch2d;
signal EF_NAG_border_in, EF_NAG_border_out : SearchElement; -- border search region
--
---- Neighborhood Address Generator A ---- 
signal NAG_in_addr :std_logic_vector(((2*AXIS_LENGTH)-1) downto 0);   -- type: 19, yaddr: 18:10, xaddr: 9:0 
signal NAG_out_addr_of_block_search : Addr4BlockSearch2d; -- address of each block
signal NAG_out_border : SearchElement; -- 7*7 border definition
signal NAG_out_addr_within_block_search : AddrWithinBlockSearch2d; -- address of each element within a block


component nregister_sync is
generic(N: natural:= DATA_WIDTH);
 port(
  clr, ce, clk : in  std_logic;
  d_in         : in  std_logic_vector((N-1) downto 0);
  dout         : out std_logic_vector((N-1) downto 0)
 );
end component nregister_sync;


-- NeighborhoodAddressGenerator_URAMAddressMapper pipeline
component NeighborhoodAddressGenerator_URAMAddressMapper is
generic(EventWidth: natural:= EventWidth);
 port(
  clr, ce, clk : in  std_logic;
  NAGUM_ts_in         : in std_logic_vector((EventWidth-1) downto 0);
  NAGUM_border_in         : in  SearchElement;
  NAGUM_addr_of_block_search_in         : in Addr4BlockSearch2d;
  NAGUM_addr_within_block_search_in         : in AddrWithinBlockSearch2d;
  NAGUM_ts_out         : out  std_logic_vector((EventWidth-1) downto 0);
  NAGUM_border_out         : out  SearchElement;
  NAGUM_addr_of_block_search_out         : out Addr4BlockSearch2d;
  NAGUM_addr_within_block_search_out         : out AddrWithinBlockSearch2d);
end component;



component NeighborhoodAddressGenerator  is
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
		Polarity : in std_logic;
		NAG_in_addr_x :in std_logic_vector((AXIS_LENGTH-1) downto 0);   -- event ts from DAVIS sensor
		NAG_in_addr_y :in std_logic_vector((AXIS_LENGTH-2) downto 0);   -- event ts from DAVIS sensor
		NAG_out_border : out SearchElement; -- 7*7 border definition
		NAG_out_addr_of_block_search : out Addr4BlockSearch2d;		-- addr of each block on search region dimension 7*7
		NAG_out_addr_within_block_search : out AddrWithinBlockSearch2d		-- addr of each element inside block on search region dimension 7*7
		);
end component;




------------------------------------------------------
------ stage 1c: URAM address mapping  ---------------
------------------------------------------------------
-- NeighborhoodAddressGenerator_URAMAddressMapper pipeline
signal NAGUM_ts_in, NAGUM_ts_out : std_logic_vector((TS_WIDTH-1) downto 0);
signal NAGUM_border_in, NAGUM_border_out : SearchElement;
signal NAGUM_addr_of_block_search_in, NAGUM_addr_of_block_search_out : Addr4BlockSearch2d;
signal NAGUM_addr_within_block_search_in, NAGUM_addr_within_block_search_out : AddrWithinBlockSearch2d;

signal NAG_URAMAM_addr_of_block_search_in, NAG_URAMAM_addr_of_block_search_out : Addr4BlockSearch2d; -- addr of block search region
signal NAG_URAMAM_addr_within_block_search_in, NAG_URAMAM_addr_within_block_search_out : AddrWithinBlockSearch2d; -- addr within block search region
signal NAG_URAMAM_out : std_logic_vector((NAG_URAMAM_length -1) downto 0);
signal NAG_URAMAM_in : std_logic_vector((NAG_URAMAM_length -1) downto 0);
signal URAMAM_addr_within_block_vec : std_vec_array1d;
signal URAMAM_ReadEnable_vec : std_logic_vector((RAM2DBLOCK-1) downto 0);

signal URAMAM_URAMDA_addr_within_block_vec_in, URAMAM_URAMDA_addr_within_block_vec_out : std_vec_array1d;
signal URAMAM_URAMDA_ReadEnable_vec_out, URAMAM_URAMDA_ReadEnable_vec_in : std_logic_vector((RAM2DBLOCK-1) downto 0);
signal URAMAM_URAMDA_ts_out : std_logic_vector((TS_WIDTH-1) downto 0);
signal URAMAM_URAMDA_border_out : SearchElement;
signal URAMAM_URAMDA_addr_of_block_search_out : Addr4BlockSearch2d;
signal URAMAM_URAMDA_addr_within_block_search_out : AddrWithinBlockSearch2d;


----- URAM address mapper
signal URAM_AM_in_border : SearchElement; -- 7*7 border definition
signal URAM_AM_in_addr_of_block_search : Addr4BlockSearch2d;		-- addr of each block on search region dimension 7*7
signal URAM_AM_in_addr_within_block_search : AddrWithinBlockSearch2d;		-- addr of each element inside block on search region dimension 7*7		
signal URAM_AM_out_we : std_logic_vector((RAM2DBLOCK-1) downto 0); -- Write Enable
signal URAM_AM_out_regce : std_logic_vector((RAM2DBLOCK-1) downto 0); -- Output Register Enable
signal URAM_AM_out_mem_en : std_logic_vector((RAM2DBLOCK-1) downto 0); -- Output Memory Enable
signal URAM_AM_out_vectorized_addr : VectorAddrWithinBlockArray; -- vector addr according to the blocks 63:0	

-- pipeline register --
component URAMAddressMapper_URAMDataAccess is
generic(EventWidth: natural:= EventWidth);
 port(
  clr, ce, clk : in  std_logic;
  URAMAM_URAMDA_ts_in : in std_logic_vector((TS_WIDTH-1) downto 0);
  URAMAM_URAMDA_border_in : in  SearchElement;
  URAMAM_URAMDA_ReadEnable_vec_in : in std_logic_vector((RAM2DBLOCK-1) downto 0);
  URAMAM_URAMDA_addr_within_block_vec_in : in std_vec_array1d;
  URAMAM_URAMDA_addr_of_block_search_in         : in Addr4BlockSearch2d;
  URAMAM_URAMDA_addr_within_block_search_in         : in AddrWithinBlockSearch2d;
  URAMAM_URAMDA_ts_out : out  std_logic_vector((TS_WIDTH-1) downto 0);
  URAMAM_URAMDA_border_out : out  SearchElement;
  URAMAM_URAMDA_ReadEnable_vec_out : out std_logic_vector((RAM2DBLOCK-1) downto 0);
  URAMAM_URAMDA_addr_within_block_vec_out : out std_vec_array1d;
  URAMAM_URAMDA_addr_of_block_search_out : out Addr4BlockSearch2d;
  URAMAM_URAMDA_addr_within_block_search_out : out AddrWithinBlockSearch2d);
end component;

component URAMAddressMapper  is
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
		URAM_AM_in_addr_of_block_search : in Addr4BlockSearch2d;		-- addr of each block on search region dimension 7*7
		URAM_AM_in_addr_within_block_search : in AddrWithinBlockSearch2d;		-- addr of each element inside block on search region dimension 7*7
		-- URAM_AM_in_border : in SearchElement; -- 7*7 border definition
		URAM_AM_out_addr_within_block_vec : out std_vec_array1d;		-- addr of each element inside block on search region dimension 7*7
		URAM_AM_ReadEnable_vec : out std_logic_vector((RAM2DBLOCK-1) downto 0)
		);
end component;


------------------------------------------------------
-------- stage 1d: URAM data access  -----------------
------------------------------------------------------
signal URAMAM_URAMDA_re : std_logic_vector((RAM2DBLOCK-1) downto 0); -- read enable
signal URAMAM_URAMDA_border : SearchElement; -- border search region
signal URAMAM_addr_of_block_search : Addr4BlockSearch2d; -- addr of block search region
signal URAMAM_URAMDA_addr_within_block_search_in : std_vec_array1d; -- addr within block search region
signal URAMAM_URAMDA_in : std_logic_vector((URAMAM_URAMDA_length-1) downto 0);
signal URAMAM_URAMDA_out : std_logic_vector((URAMAM_URAMDA_length-1) downto 0);
signal URAMAM_URAMDA_doutb: data_std_array1d;

--- URAM array ports
-- Port a
signal rsta : std_logic; -- Reset
signal URAM_wea : std_logic_vector((RAM2DBLOCK-1) downto 0);  -- Write Enable
signal URAM_regcea : std_logic_vector((RAM2DBLOCK-1) downto 0); -- Output Register Enablea
signal URAM_mem_ena : std_logic_vector((RAM2DBLOCK-1) downto 0); -- Memory Enable
signal URAM_dina : VectorURAM;      -- Data Input  
signal URAM_addra : VectorAddrWithinBlockArray;     -- Address Input
signal URAM_douta : VectorURAM;      -- Data Output
-- Port b 
signal rstb : std_logic;                                  -- Reset
signal URAM_web : std_logic_vector((RAM2DBLOCK-1) downto 0); -- Write Enable
signal URAM_regceb : std_logic_vector((RAM2DBLOCK-1) downto 0); -- Output Register Enableb
signal URAM_mem_enb : std_logic_vector((RAM2DBLOCK-1) downto 0); -- Memory Enable
signal URAM_dinb : VectorURAM;      -- Data Input  
signal URAM_addrb : VectorAddrWithinBlockArray;     -- Address Input
signal URAM_doutb : VectorURAM;      -- Data Output
signal URAMArray_out_dout : VectorURAM;
signal in_din : VectorURAM;

signal URAMDA_NDE_ts_out : std_logic_vector((TS_WIDTH-1) downto 0);
signal URAMDA_NDE_border_out : SearchElement;
signal URAMDA_NDE_ReadEnable_vec_out : std_logic_vector((RAM2DBLOCK-1) downto 0);
signal URAMDA_NDE_addr_within_block_vec_out : std_vec_array1d;
signal URAMDA_NDE_addr_of_block_search_out : Addr4BlockSearch2d;
signal URAMDA_NDE_addr_within_block_search_out : AddrWithinBlockSearch2d;
signal URAMDA_NDE_doutb_out: data_std_array1d;

component URAMDataAccess_NeighborhoodDataExtraction is
generic(EventWidth: natural:= EventWidth);
 port(
  clr, ce, clk : in  std_logic;
  URAMDA_NDE_ts_in : in std_logic_vector((TS_WIDTH-1) downto 0);
  URAMDA_NDE_border_in : in  SearchElement;
  URAMDA_NDE_ReadEnable_vec_in : in std_logic_vector((RAM2DBLOCK-1) downto 0);
  URAMDA_NDE_addr_within_block_vec_in : in std_vec_array1d;
  URAMDA_NDE_addr_of_block_search_in         : in Addr4BlockSearch2d;
  URAMDA_NDE_addr_within_block_search_in         : in AddrWithinBlockSearch2d;
  URAMDA_NDE_doutb_in: in data_std_array1d;
  URAMDA_NDE_ts_out : out  std_logic_vector((TS_WIDTH-1) downto 0);
  URAMDA_NDE_border_out : out  SearchElement;
  URAMDA_NDE_ReadEnable_vec_out : out std_logic_vector((RAM2DBLOCK-1) downto 0);
  URAMDA_NDE_addr_within_block_vec_out : out std_vec_array1d;
  URAMDA_NDE_addr_of_block_search_out : out Addr4BlockSearch2d;
  URAMDA_NDE_addr_within_block_search_out : out AddrWithinBlockSearch2d;
  URAMDA_NDE_doutb_out: out data_std_array1d);
end component;


component xilinx_ultraram_true_dual_port is
generic (
         Address_Width : integer := 12;  -- Address Width for 4096 locations
         DWIDTH : integer := 72;  -- Data Width
         NBPIPE : integer := 3    -- Number of pipeline Registers
        );
port    (
clk :  in std_logic;                                  -- Clock 
-- Port A
rsta :  in std_logic;                                  -- Reset
wea :  in std_logic;                                   -- Write Enable
regcea :  in std_logic;                                -- Output Register Enablea
mem_ena :  in std_logic;                               -- Memory Enable
dina :  in std_logic_vector(DWIDTH-1 downto 0);      -- Data Input  
addra :  in std_logic_vector(Address_Width-1 downto 0);     -- Address Input
douta : out std_logic_vector(DWIDTH-1 downto 0);      -- Data Output
-- Port b 
rstb :  in std_logic;                                  -- Reset
web :  in std_logic;                                   -- Write Enable
regceb :  in std_logic;                                -- Output Register Enableb
mem_enb :  in std_logic;                               -- Memory Enable
dinb :  in std_logic_vector(DWIDTH-1 downto 0);      -- Data Input  
addrb :  in std_logic_vector(Address_Width-1 downto 0);     -- Address Input
doutb : out std_logic_vector(DWIDTH-1 downto 0));      -- Data Output
end component;




------------------------------------------------------
-------- stage 1e: Neighborhood data extraction  -----
------------------------------------------------------
signal URAMDA_NDE_addr_of_block_search_in : Addr4BlockSearch2d;
signal URAMDA_NDE_doutb : data_std_array1d;
signal URAMDA_NDE_out_data : RAMArraySearchRegion;
signal URAMDA_NDE_in : std_logic_vector((URAMDA_NDE_length - 1) downto 0);
signal URAMDA_NDE_out : std_logic_vector((URAMDA_NDE_length - 1) downto 0);

--- Neighborhood data extraction
signal NDE_in_search_addr : Addr4BlockSearch2d; -- address of each block on search region dimension
signal NDE_in_border : SearchElement; -- 64 border data input
signal NDE_in_data : VectorURAM; -- 64 URAM block data input
signal NDE_out_data : RAMArraySearchRegion; -- 7*7 * 72*Precision data output	

signal NDE_NR_ts_out : std_logic_vector((TS_WIDTH-1) downto 0);
signal NDE_NR_border_out : SearchElement;
signal NDE_NR_ReadEnable_vec_out : std_logic_vector((RAM2DBLOCK-1) downto 0);
signal NDE_NR_addr_within_block_vec_out : std_vec_array1d;
signal NDE_NR_addr_of_block_search_out : Addr4BlockSearch2d;
signal NDE_NR_addr_within_block_search_out : AddrWithinBlockSearch2d;
signal NDE_NR_doutb_out: data_std_array1d;
signal NDE_NR_out_data_out: RAMArraySearchRegion;

component NeighborhoodDataExtraction_NoiseRemoval is
generic(EventWidth: natural:= EventWidth);
 port(
  clr, ce, clk : in  std_logic;
  NDE_NR_ts_in : in std_logic_vector((TS_WIDTH-1) downto 0);
  NDE_NR_border_in : in  SearchElement;
  NDE_NR_ReadEnable_vec_in : in std_logic_vector((RAM2DBLOCK-1) downto 0);
  NDE_NR_addr_within_block_vec_in : in std_vec_array1d;
  NDE_NR_addr_of_block_search_in         : in Addr4BlockSearch2d;
  NDE_NR_addr_within_block_search_in         : in AddrWithinBlockSearch2d;
  NDE_NR_doutb_in: in data_std_array1d;
  NDE_NR_out_data_in: in RAMArraySearchRegion;
  NDE_NR_ts_out : out  std_logic_vector((TS_WIDTH-1) downto 0);
  NDE_NR_border_out : out  SearchElement;
  NDE_NR_ReadEnable_vec_out : out std_logic_vector((RAM2DBLOCK-1) downto 0);
  NDE_NR_addr_within_block_vec_out : out std_vec_array1d;
  NDE_NR_addr_of_block_search_out : out Addr4BlockSearch2d;
  NDE_NR_addr_within_block_search_out : out AddrWithinBlockSearch2d;
  NDE_NR_doutb_out: out data_std_array1d;
  NDE_NR_out_data_out: out RAMArraySearchRegion);
end component;

component NeighborhoodDataExtraction  is
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
		NDE_in_data : in data_std_array1d; -- 64 URAM block data input
		NDE_out_data : out RAMArraySearchRegion -- 7*7 * 72*Precision data output	
		);
end component;


------------------------------------------------------
------------- stage 2: Noise Removal -----------------
------------------------------------------------------
signal NDE_NR_in, NDE_NR_out : std_logic_vector(NDE_NR_length -1 downto 0);
signal NDE_NR_border : SearchElement;
signal NDE_NR_data : RAMArraySearchRegion;
--signal NDE_NR_valid : std_logic;


--- Neighborhood definition
signal Neighbor_out : std_logic_vector((((EventSearchDiameter)*(EventSearchDiameter)*Size_Width)-1) downto 0); -- output array for gradient calculation

---- Memory Address Generator A ----
signal MAG_out_data : RAMArraySearchRegion; -- 7*7 * 72*Precision data output		
---- Event Fetch Section ----
--	signal EF_NR_Neighboring_Events : 

---- Noise Removal Section ----
signal NR_in_data : RAMArraySearchRegion; -- 64 URAM block data input
signal NR_valid : std_logic;

component NoiseRemoval  is
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
end component;
------------------------------------------------------
------------- stage 3: Prefix Adder ------------------
------------------------------------------------------
signal NR_PA_in, NR_PA_out : std_logic_vector((NR_PA_length-1) downto 0);
signal NR_PA_data : RAMArraySearchRegion;
signal NR_PA_prefixadder_out : array_deltat2d;

---- Prefix Adder -----
signal prefixadder_out : array_deltat2d;
signal NR_PA_ts_out : std_logic_vector((TS_WIDTH-1) downto 0);
signal NR_PA_border_out : SearchElement;
signal NR_PA_ReadEnable_vec_out : std_logic_vector((RAM2DBLOCK-1) downto 0);
signal NR_PA_addr_within_block_vec_out : std_vec_array1d;
signal NR_PA_addr_of_block_search_out : Addr4BlockSearch2d;
signal NR_PA_addr_within_block_search_out : AddrWithinBlockSearch2d;
signal NR_PA_doutb_out: data_std_array1d;
signal NR_PA_out_data_out: RAMArraySearchRegion;
signal NR_PA_valid_out: std_logic;

component NoiseRemoval_PrefixAdder is
generic(EventWidth: natural:= EventWidth);
 port(
  clr, ce, clk : in  std_logic;
  NR_PA_ts_in : in std_logic_vector((TS_WIDTH-1) downto 0);
  NR_PA_border_in : in  SearchElement;
  NR_PA_ReadEnable_vec_in : in std_logic_vector((RAM2DBLOCK-1) downto 0);
  NR_PA_addr_within_block_vec_in : in std_vec_array1d;
  NR_PA_addr_of_block_search_in         : in Addr4BlockSearch2d;
  NR_PA_addr_within_block_search_in         : in AddrWithinBlockSearch2d;
  NR_PA_doutb_in: in data_std_array1d;
  NR_PA_out_data_in: in RAMArraySearchRegion;
  NR_PA_valid_in: in std_logic;
  NR_PA_ts_out : out  std_logic_vector((TS_WIDTH-1) downto 0);
  NR_PA_border_out : out  SearchElement;
  NR_PA_ReadEnable_vec_out : out std_logic_vector((RAM2DBLOCK-1) downto 0);
  NR_PA_addr_within_block_vec_out : out std_vec_array1d;
  NR_PA_addr_of_block_search_out : out Addr4BlockSearch2d;
  NR_PA_addr_within_block_search_out : out AddrWithinBlockSearch2d;
  NR_PA_doutb_out: out data_std_array1d;
  NR_PA_out_data_out: out RAMArraySearchRegion;
  NR_PA_valid_out: out std_logic);
end component;

component PrefixAdder is
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
end component;


------------------------------------------------------
------------- stage 4: Decompression -----------------
------------------------------------------------------
signal PA_DE_in, PA_DE_out : std_logic_vector((PA_DE_length-1) downto 0);
signal PA_DE_data : RAMArraySearchRegion;
signal PA_DE_Limitted_TS : std_logic_vector((TS_WIDTH-1) downto 0);
signal PA_DE_decompressed_out : RingBuffer2d;
---- Decompression ----
signal Limitted_TS : std_logic_vector((TS_WIDTH-1) downto 0);
signal decompressed_out : RingBuffer2d;

signal PA_De_ts_out : std_logic_vector((TS_WIDTH-1) downto 0);
signal PA_De_border_out : SearchElement;
signal PA_De_ReadEnable_vec_out : std_logic_vector((RAM2DBLOCK-1) downto 0);
signal PA_De_addr_within_block_vec_out : std_vec_array1d;
signal PA_De_addr_of_block_search_out : Addr4BlockSearch2d;
signal PA_De_addr_within_block_search_out : AddrWithinBlockSearch2d;
signal PA_De_doutb_out: data_std_array1d;
signal PA_De_out_data_out: RAMArraySearchRegion;
signal PA_De_valid_out: std_logic;
signal PA_De_prefixadder_out: array_deltat2d;

component PrefixAdder_Decompression is
generic(EventWidth: natural:= EventWidth);
 port(
  clr, ce, clk : in  std_logic;
  PA_De_ts_in : in std_logic_vector((TS_WIDTH-1) downto 0);
  PA_De_border_in : in  SearchElement;
  PA_De_ReadEnable_vec_in : in std_logic_vector((RAM2DBLOCK-1) downto 0);
  PA_De_addr_within_block_vec_in : in std_vec_array1d;
  PA_De_addr_of_block_search_in : in Addr4BlockSearch2d;
  PA_De_addr_within_block_search_in : in AddrWithinBlockSearch2d;
  PA_De_doutb_in: in data_std_array1d;
  PA_De_out_data_in: in RAMArraySearchRegion;
  PA_De_valid_in: in std_logic;
  PA_De_prefixadder_in: in array_deltat2d;
  PA_De_ts_out : out  std_logic_vector((TS_WIDTH-1) downto 0);
  PA_De_border_out : out  SearchElement;
  PA_De_ReadEnable_vec_out : out std_logic_vector((RAM2DBLOCK-1) downto 0);
  PA_De_addr_within_block_vec_out : out std_vec_array1d;
  PA_De_addr_of_block_search_out : out Addr4BlockSearch2d;
  PA_De_addr_within_block_search_out : out AddrWithinBlockSearch2d;
  PA_De_doutb_out: out data_std_array1d;
  PA_De_out_data_out: out RAMArraySearchRegion;
  PA_De_valid_out: out std_logic;
  PA_De_prefixadder_out: out array_deltat2d);
  end component;

component decompression_unit is
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
		Data_In : in array_deltat;	 -- input uncompressed data
		Previous_TS : in std_logic_vector((TS_WIDTH - 1) downto 0);
		Current_TS : in std_logic_vector((TS_WIDTH - 1) downto 0);
		Limitted_TS : out std_logic_vector((TS_WIDTH - 1) downto 0);
		Data_Out : out RingBuffer
	);
end component;

------------------------------------------------------
------------- stage 5: Comparator and Shifter --------
------------------------------------------------------
signal De_CP_in_addr_of_block_search : Addr4BlockSearch2d;		-- addr of each block on search region dimension 7*7
signal De_CP_in_border : SearchElement; -- 7*7 border definition
signal De_CP_in_data_within_block_search : RAMArraySearchRegion;		-- data of each element inside block on search region dimension 7*7
signal De_CP_out_data_within_block_vec : data_std_array1d;
signal De_CP_in, De_CP_out: std_logic_vector((De_CP_length-1) downto 0);
signal De_CP_Limitted_TS: ts_array2d;
signal De_CP_data_in, De_CP_data_out: RAMArraySearchRegion;

--- comparison unit ---
signal comp_data_out : RAMArraySearchRegion; 
signal Size_out : size_array2d;

signal De_CP_ts_out : std_logic_vector((TS_WIDTH-1) downto 0);
signal De_CP_limited_ts_out : std_logic_vector((TS_WIDTH-1) downto 0);
signal De_CP_border_out : SearchElement;
signal De_CP_ReadEnable_vec_out : std_logic_vector((RAM2DBLOCK-1) downto 0);
signal De_CP_addr_within_block_vec_out : std_vec_array1d;
signal De_CP_addr_of_block_search_out : Addr4BlockSearch2d;
signal De_CP_addr_within_block_search_out : AddrWithinBlockSearch2d;
signal De_CP_doutb_out: data_std_array1d;
signal De_CP_out_data_out: RAMArraySearchRegion;
signal De_CP_valid_out: std_logic;
signal De_CP_prefixadder_out: array_deltat2d;
signal De_CP_decompressed_out : RingBuffer2d;
  
component Decompression_Comparison is
generic(EventWidth: natural:= EventWidth);
 port(
  clr, ce, clk : in  std_logic;
  De_CP_ts_in : in std_logic_vector((TS_WIDTH-1) downto 0);
  De_CP_limited_ts_in : in std_logic_vector((TS_WIDTH-1) downto 0);
  De_CP_border_in : in  SearchElement;
  De_CP_ReadEnable_vec_in : in std_logic_vector((RAM2DBLOCK-1) downto 0);
  De_CP_addr_within_block_vec_in : in std_vec_array1d;
  De_CP_addr_of_block_search_in : in Addr4BlockSearch2d;
  De_CP_addr_within_block_search_in : in AddrWithinBlockSearch2d;
  De_CP_doutb_in: in data_std_array1d;
  De_CP_out_data_in: in RAMArraySearchRegion;
  De_CP_valid_in: in std_logic;
  De_CP_prefixadder_in: in array_deltat2d;
  De_CP_decompressed_in : in RingBuffer2d;
  De_CP_ts_out : out  std_logic_vector((TS_WIDTH-1) downto 0);
  De_CP_limited_ts_out : out  std_logic_vector((TS_WIDTH-1) downto 0);
  De_CP_border_out : out  SearchElement;
  De_CP_ReadEnable_vec_out : out std_logic_vector((RAM2DBLOCK-1) downto 0);
  De_CP_addr_within_block_vec_out : out std_vec_array1d;
  De_CP_addr_of_block_search_out : out Addr4BlockSearch2d;
  De_CP_addr_within_block_search_out : out AddrWithinBlockSearch2d;
  De_CP_doutb_out: out data_std_array1d;
  De_CP_out_data_out: out RAMArraySearchRegion;
  De_CP_valid_out: out std_logic;
  De_CP_prefixadder_out: out array_deltat2d;
  De_CP_decompressed_out : out RingBuffer2d);
  end component;

component ComparisonUnit is
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
		data_in : in std_logic_vector((DATA_WIDTH - 1) downto 0);		  -- input data from input ring buffer
		DecompressedData : in RingBuffer;	 -- decompressed data by prefix adder
		Current_ts : in std_logic_vector((TS_WIDTH - 1) downto 0);  -- Current TS
		LimitedTS : in std_logic_vector((TS_WIDTH - 1) downto 0);  -- TS - Threshold value
		data_out : out std_logic_vector((DATA_WIDTH - 1) downto 0));	   -- output to shifter size unit
end component;

------------------------------------------------------
------------- stage 6: URAM Data Mapping -------------
------------------------------------------------------
signal COM_URAMDM_addr_of_block_search : Addr4BlockSearch2d;		-- addr of each block on search region dimension 7*7
signal COM_URAMDM_border : SearchElement; -- 7*7 border definition
signal COM_URAMDM_data_within_block_search : RAMArraySearchRegion;		-- data of each element inside block on search region dimension 7*7
signal COM_URAMDM_data_within_block_vec : data_std_array1d;
signal COM_URAMDM_in, COM_URAMDM_out : std_logic_vector((COM_URAMDM_length-1) downto 0);
 --- URAM address mapping 2 ---
signal URAM_AM_out_vectorized_data : VectorURAM;

signal type_in : std_logic; -- polarity clarification 1 bit
signal ts_in : std_logic_vector((TS_WIDTH-1) downto 0); -- 32 bits
signal x_addr_in : std_logic_vector((AXIS_LENGTH -1) downto 0); -- 10 bits
signal y_addr_in : std_logic_vector((AXIS_LENGTH -2) downto 0); -- 9 bits
signal APS_in : std_logic_vector(1 downto 0); -- 2
signal ADC_in : std_logic_vector((AXIS_LENGTH-1) downto 0); -- 10
signal Data_In_uncompressed : array_deltat;	  -- input uncompressed data
signal Previous_ts : std_logic_vector((TS_WIDTH - 1) downto 0); -- previous timestamp
signal Data_Out_ring : RingBuffer;
signal DecompressedData : RingBuffer;	 -- decompressed data by prefix adder
signal Current_ts : std_logic_vector((TS_WIDTH - 1) downto 0);  -- Current TS
signal LimitedTS : std_logic_vector((TS_WIDTH - 1) downto 0);  -- TS - Threshold value
signal data_out_shift : std_logic_vector((DATA_WIDTH - 1) downto 0);	   -- output to shifter size unit
signal data_in_ring : std_logic_vector((DATA_WIDTH - 1) downto 0);
signal data_out_delta : array_deltat;
signal data8_in : std_logic_vector(7 downto 0);		   
signal size8_out : std_logic_vector(2 downto 0);
signal data12_in : std_logic_vector(11 downto 0);		   
signal size12_out : std_logic_vector(3 downto 0);
signal data16_in : std_logic_vector(15 downto 0);
signal size16_out : std_logic_vector(3 downto 0);

signal CP_URAMDM_ts_out : std_logic_vector((TS_WIDTH-1) downto 0);
signal CP_URAMDM_limited_ts_out : std_logic_vector((TS_WIDTH-1) downto 0);
signal CP_URAMDM_border_out : SearchElement;
signal CP_URAMDM_ReadEnable_vec_out : std_logic_vector((RAM2DBLOCK-1) downto 0);
signal CP_URAMDM_addr_within_block_vec_out : std_vec_array1d;
signal CP_URAMDM_addr_of_block_search_out : Addr4BlockSearch2d;
signal CP_URAMDM_addr_within_block_search_out : AddrWithinBlockSearch2d;
signal CP_URAMDM_doutb_out: data_std_array1d;
signal CP_URAMDM_out_data_out: RAMArraySearchRegion;
signal CP_URAMDM_valid_out: std_logic;
signal CP_URAMDM_prefixadder_out: array_deltat2d;
signal CP_URAMDM_decompressed_out : RingBuffer2d;
signal CP_URAMDM_compared_data_out: RAMArraySearchRegion;

component URAMDataMapper  is
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
		URAM_DM_in_addr_of_block_search : in Addr4BlockSearch2d;		-- addr of each block on search region dimension 7*7
		URAM_DM_in_data_within_block_search : in RAMArraySearchRegion;		-- data of each element inside block on search region dimension 7*7
		URAM_DM_out_data_within_block_vec : out data_std_array1d
		);
end component;

component Comparison_URAMDataMapper is
generic(EventWidth: natural:= EventWidth);
 port(
  clr, ce, clk : in  std_logic;
  CP_URAMDM_ts_in : in std_logic_vector((TS_WIDTH-1) downto 0);
  CP_URAMDM_limited_ts_in : in std_logic_vector((TS_WIDTH-1) downto 0);
  CP_URAMDM_border_in : in  SearchElement;
  CP_URAMDM_ReadEnable_vec_in : in std_logic_vector((RAM2DBLOCK-1) downto 0);
  CP_URAMDM_addr_within_block_vec_in : in std_vec_array1d;
  CP_URAMDM_addr_of_block_search_in : in Addr4BlockSearch2d;
  CP_URAMDM_addr_within_block_search_in : in AddrWithinBlockSearch2d;
  CP_URAMDM_doutb_in: in data_std_array1d;
  CP_URAMDM_out_data_in: in RAMArraySearchRegion;
  CP_URAMDM_valid_in: in std_logic;
  CP_URAMDM_prefixadder_in: in array_deltat2d;
  CP_URAMDM_decompressed_in : in RingBuffer2d;
  CP_URAMDM_compared_data_in: in RAMArraySearchRegion;
  CP_URAMDM_ts_out : out  std_logic_vector((TS_WIDTH-1) downto 0);
  CP_URAMDM_limited_ts_out : out std_logic_vector((TS_WIDTH-1) downto 0);
  CP_URAMDM_border_out : out  SearchElement;
  CP_URAMDM_ReadEnable_vec_out : out std_logic_vector((RAM2DBLOCK-1) downto 0):=(others=>'0');
  CP_URAMDM_addr_within_block_vec_out : out std_vec_array1d;
  CP_URAMDM_addr_of_block_search_out : out Addr4BlockSearch2d;
  CP_URAMDM_addr_within_block_search_out : out AddrWithinBlockSearch2d;
  CP_URAMDM_doutb_out: out data_std_array1d;
  CP_URAMDM_out_data_out: out RAMArraySearchRegion;
  CP_URAMDM_valid_out: out std_logic;
  CP_URAMDM_prefixadder_out: out array_deltat2d;
  CP_URAMDM_decompressed_out : out RingBuffer2d;
  CP_URAMDM_compared_data_out: out RAMArraySearchRegion);
end component;

------------------------------------------------------
------------- stage 7: URAM Write back ---------------
------------------------------------------------------
signal URAMDM_WB_in, URAMDM_WB_out: std_logic_vector((URAMDM_WriteBack_length-1) downto 0);
signal URAMDM_WB_we : std_logic_vector((RAM2DBLOCK-1) downto 0);
signal URAMDM_WB_addr_within_block : std_vec_array1d;
signal URAMDM_WB_data_within_block : data_std_array1d;

signal URAMDM_WB_ts_out : std_logic_vector((TS_WIDTH-1) downto 0);
signal URAMDM_WB_limited_ts_out : std_logic_vector((TS_WIDTH-1) downto 0);
signal URAMDM_WB_border_out : SearchElement;
signal URAMDM_WB_ReadEnable_vec_out : std_logic_vector((RAM2DBLOCK-1) downto 0):=(others=>'0');
signal URAMDM_WB_addr_within_block_vec_out : std_vec_array1d;
signal URAMDM_WB_addr_of_block_search_out : Addr4BlockSearch2d;
signal URAMDM_WB_addr_within_block_search_out : AddrWithinBlockSearch2d;
signal URAMDM_WB_doutb_out: data_std_array1d;
signal URAMDM_WB_out_data_out: RAMArraySearchRegion;
signal URAMDM_WB_valid_out: std_logic;
signal URAMDM_WB_prefixadder_out: array_deltat2d;
signal URAMDM_WB_decompressed_out : RingBuffer2d;
signal URAMDM_WB_compared_data_out: RAMArraySearchRegion;
signal URAMDM_WB_dina_out: data_std_array1d;
  
component URAMDataMapper_WriteBack is
generic(EventWidth: natural:= EventWidth);
 port(
  clr, ce, clk : in  std_logic;
  URAMDM_WB_ts_in : in std_logic_vector((TS_WIDTH-1) downto 0);
  URAMDM_WB_limited_ts_in : in std_logic_vector((TS_WIDTH-1) downto 0);
  URAMDM_WB_border_in : in  SearchElement;
  URAMDM_WB_ReadEnable_vec_in : in std_logic_vector((RAM2DBLOCK-1) downto 0);
  URAMDM_WB_addr_within_block_vec_in : in std_vec_array1d;
  URAMDM_WB_addr_of_block_search_in : in Addr4BlockSearch2d;
  URAMDM_WB_addr_within_block_search_in : in AddrWithinBlockSearch2d;
  URAMDM_WB_doutb_in: in data_std_array1d;
  URAMDM_WB_out_data_in: in RAMArraySearchRegion;
  URAMDM_WB_valid_in: in std_logic;
  URAMDM_WB_prefixadder_in: in array_deltat2d;
  URAMDM_WB_decompressed_in : in RingBuffer2d;
  URAMDM_WB_compared_data_in: in RAMArraySearchRegion;
  URAMDM_WB_dina_in: in data_std_array1d;
  URAMDM_WB_ts_out : out  std_logic_vector((TS_WIDTH-1) downto 0);
  URAMDM_WB_limited_ts_out : out std_logic_vector((TS_WIDTH-1) downto 0);
  URAMDM_WB_border_out : out  SearchElement;
  URAMDM_WB_ReadEnable_vec_out : out std_logic_vector((RAM2DBLOCK-1) downto 0);
  URAMDM_WB_addr_within_block_vec_out : out std_vec_array1d;
  URAMDM_WB_addr_of_block_search_out : out Addr4BlockSearch2d;
  URAMDM_WB_addr_within_block_search_out : out AddrWithinBlockSearch2d;
  URAMDM_WB_doutb_out: out data_std_array1d;
  URAMDM_WB_out_data_out: out RAMArraySearchRegion;
  URAMDM_WB_valid_out: out std_logic;
  URAMDM_WB_prefixadder_out: out array_deltat2d;
  URAMDM_WB_decompressed_out : out RingBuffer2d;
  URAMDM_WB_compared_data_out: out RAMArraySearchRegion;
  URAMDM_WB_dina_out: out data_std_array1d);
end component;


begin
--------------------------------------------------------
---------- stage 1a: Event Fetch FIFO -------------------
--------------------------------------------------------
InputFIFO: STD_FIFO Generic map(PRECISION,	EventWidth, EventSearchRadius, Address_Width, DWIDTH, NBPIPE, RAMBLOCKADDR, RAM2DBLOCK, TS_WIDTH, AXIS_LENGTH, DELTA_T_WIDTH, Hist_Size, Size_Width, DATA_WIDTH, FIFO_DEPTH)
	Port map( 
		CLK	 => clk,
		RST => rst,
		WriteEn	=> FIFO_Write_En,
		DataIn	=> input_data,
		ReadEn	=> FIFO_Read_En,
		DataOut	=> FIFO_data_out,
		Empty => empty,
		Full => full);

-- send event through the pipeline
EF_NAG_in((EF_NAG_length-1) downto 0) <= FIFO_data_out;

--------------------------------------------------------
------ stage 1b: Neighborhood address generator  -------
--------------------------------------------------------
EventFetch_NeighborhoodAddressGenerator1: nregister_sync generic map(N => EF_NAG_length)
  port map(clk => clk,     -- Clock input
	   clr => rst,     -- Reset input
	   ce => '1',     -- Write enable input
	   d_in => EF_NAG_in,     -- Data value input
	   dout => EF_NAG_out);   -- Data value output


NeighborhoodAddressGenerator1: NeighborhoodAddressGenerator Generic map(PRECISION, EventWidth, EventSearchRadius, Address_Width, DWIDTH, NBPIPE, RAMBLOCKADDR, RAM2DBLOCK, TS_WIDTH, AXIS_LENGTH, DELTA_T_WIDTH, Hist_Size, Size_Width, DATA_WIDTH, FIFO_DEPTH)
		port map (Polarity => EF_NAG_out(EventWidth-1),
		NAG_in_addr_x => EF_NAG_out((EventWidth-2) downto (EventWidth-11)),   -- event x address from DAVIS sensor
		NAG_in_addr_y => EF_NAG_out((EventWidth-12) downto (EventWidth-20)),   -- event y address from DAVIS sensor
		NAG_out_border => NAGUM_border_in, --  7*7 border definition
		NAG_out_addr_of_block_search => NAGUM_addr_of_block_search_in, -- 7*7 address according to the blocks		
		NAG_out_addr_within_block_search => NAGUM_addr_within_block_search_in);	-- 7*7 address for each memory location within blocks

checktypelength1: if (TS_WIDTH >= (EventWidth/2)) generate
NAGUM_ts_in(((EventWidth/2) - 1) downto 0) <= EF_NAG_out(((EventWidth/2)-1) downto 0); -- current timestamp
NAGUM_ts_in((TS_WIDTH - 1) downto (EventWidth/2)) <= (others => '0'); -- current timestamp
end generate;
checktypelength2: if (TS_WIDTH < (EventWidth/2)) generate
NAGUM_ts_in((EventSearch2D + TS_WIDTH - 1) downto EventSearch2D) <= (others =>'1') when (EF_NAG_out(((EventWidth/2)-1) downto ((EventWidth/2)-TS_WIDTH)) /= 0) else EF_NAG_out((TS_WIDTH-1) downto 0); -- current timestamp
end generate;

-- --------------------------------------------------------
-- -------- stage 1c: URAM address mapping  ---------------
-- --------------------------------------------------------

NeighborhoodAddressGenerator_URAMAddressMapper1: NeighborhoodAddressGenerator_URAMAddressMapper 
generic map(EventWidth => EventWidth)
 port map(
  clr => rst, 
  ce => '1', 
  clk => clk,
  NAGUM_ts_in => NAGUM_ts_in,
  NAGUM_border_in => NAGUM_border_in,
  NAGUM_addr_of_block_search_in => NAGUM_addr_of_block_search_in,
  NAGUM_addr_within_block_search_in => NAGUM_addr_within_block_search_in,
  NAGUM_ts_out => NAGUM_ts_out,
  NAGUM_border_out => NAGUM_border_out,
  NAGUM_addr_of_block_search_out => NAGUM_addr_of_block_search_out,
  NAGUM_addr_within_block_search_out => NAGUM_addr_within_block_search_out);


URAMAddressMapper1: URAMAddressMapper Generic map(PRECISION, EventWidth, EventSearchRadius, Address_Width, DWIDTH, NBPIPE, RAMBLOCKADDR, RAM2DBLOCK, TS_WIDTH, AXIS_LENGTH, DELTA_T_WIDTH, Hist_Size, Size_Width, DATA_WIDTH, FIFO_DEPTH)
		port map (URAM_AM_in_addr_of_block_search => NAGUM_addr_of_block_search_out, -- 7*7 addr of each block on search region dimension
		URAM_AM_in_addr_within_block_search => NAGUM_addr_within_block_search_out, -- 7*7 addr of each element inside block on search region dimension 
		URAM_AM_out_addr_within_block_vec => URAMAM_URAMDA_addr_within_block_vec_in, -- vector addr according to the blocks 63:0
		URAM_AM_ReadEnable_vec => URAMAM_URAMDA_ReadEnable_vec_in);	-- vector read_enable according to the blocks 63:0


--------------------------------------------------------
---------- stage 1d: URAM data access  -----------------
--------------------------------------------------------
URAMAddressMapper_URAMDataAccess1: URAMAddressMapper_URAMDataAccess
generic map(EventWidth => EventWidth)
 port map(clr => rst,     -- Reset input
	   ce => '1',     -- Write enable input
	   clk => clk,     -- Clock input
	   URAMAM_URAMDA_ts_in => NAGUM_ts_out,     -- Data value input
	   URAMAM_URAMDA_border_in => NAGUM_border_out,
	   URAMAM_URAMDA_ReadEnable_vec_in => URAMAM_URAMDA_ReadEnable_vec_in,
	   URAMAM_URAMDA_addr_within_block_vec_in => URAMAM_URAMDA_addr_within_block_vec_in, -- vector based addr of block
	   URAMAM_URAMDA_addr_of_block_search_in => NAGUM_addr_of_block_search_out, -- matrix based address of block
	   URAMAM_URAMDA_addr_within_block_search_in => NAGUM_addr_within_block_search_out,
	   URAMAM_URAMDA_ts_out => URAMAM_URAMDA_ts_out,
	   URAMAM_URAMDA_border_out => URAMAM_URAMDA_border_out,
	   URAMAM_URAMDA_ReadEnable_vec_out => URAMAM_URAMDA_ReadEnable_vec_out,
	   URAMAM_URAMDA_addr_within_block_vec_out => URAMAM_URAMDA_addr_within_block_vec_out,
	   URAMAM_URAMDA_addr_of_block_search_out => URAMAM_URAMDA_addr_of_block_search_out,
	   URAMAM_URAMDA_addr_within_block_search_out => URAMAM_URAMDA_addr_within_block_search_out);   -- Data value output


-- use port A for writing and port B for read
SelectPrecision: for j in 0 to (PRECISION-1) generate
	GenLoopInst: for i in 0 to (RAM2DBLOCK-1) generate
	filtering_RAM_Inst : xilinx_ultraram_true_dual_port generic map(Address_Width => Address_Width, DWIDTH=> DWIDTH, NBPIPE => NBPIPE)
	PORT MAP (
	clk => clk, -- Clock 
	-- Port A
	rsta => rst, -- Reset
	wea => URAMDM_WB_ReadEnable_vec_out(i) and (not URAMAM_URAMDA_ReadEnable_vec_out(i)), -- Write Enable
	regcea => URAMDM_WB_ReadEnable_vec_out(i) and (not URAMAM_URAMDA_ReadEnable_vec_out(i)), -- Output Register Enablea
	mem_ena => URAMDM_WB_ReadEnable_vec_out(i) and (not URAMAM_URAMDA_ReadEnable_vec_out(i)), -- Memory Enable
	dina => URAMDM_WB_dina_out(i)((((j+1)*DWIDTH)-1) downto (j*DWIDTH)),      -- Data Input  
	addra => URAMDM_WB_addr_within_block_vec_out(i),     -- Address Input
	douta => open,      -- Data Output
	-- Port B 
	rstb => rst, -- Reset
	web => '0', -- Write Enable
	regceb => URAMAM_URAMDA_ReadEnable_vec_out(i), -- Output Register Enableb
	mem_enb => URAMAM_URAMDA_ReadEnable_vec_out(i), -- Memory Enable
	dinb => (others => '0'), -- Data Input  
	addrb => URAMAM_URAMDA_addr_within_block_vec_out(i), -- Address Input
	doutb => URAMAM_URAMDA_doutb(i)((((j+1)*DWIDTH)-1) downto (j*DWIDTH))); -- Data Output
end generate;
end generate;

--------------------------------------------------------
---------- stage 1e: Neighborhood data extraction  -----
--------------------------------------------------------

URAMDataAccess_NeighborhoodDataExtraction1: URAMDataAccess_NeighborhoodDataExtraction
generic map(EventWidth => EventWidth)
 port map(clr => rst,     -- Reset input
	   ce => '1',     -- Write enable input
	   clk => clk,     -- Clock input
	   URAMDA_NDE_ts_in => URAMAM_URAMDA_ts_out,     -- Data value input
	   URAMDA_NDE_border_in => URAMAM_URAMDA_border_out,
	   URAMDA_NDE_ReadEnable_vec_in => URAMAM_URAMDA_ReadEnable_vec_out,
	   URAMDA_NDE_addr_within_block_vec_in => URAMAM_URAMDA_addr_within_block_vec_out,
	   URAMDA_NDE_addr_of_block_search_in => URAMAM_URAMDA_addr_of_block_search_out,
	   URAMDA_NDE_addr_within_block_search_in => URAMAM_URAMDA_addr_within_block_search_out,
	   URAMDA_NDE_doutb_in => URAMAM_URAMDA_doutb,
	   URAMDA_NDE_ts_out => URAMDA_NDE_ts_out,
	   URAMDA_NDE_border_out => URAMDA_NDE_border_out,
	   URAMDA_NDE_ReadEnable_vec_out => URAMDA_NDE_ReadEnable_vec_out,
	   URAMDA_NDE_addr_within_block_vec_out => URAMDA_NDE_addr_within_block_vec_out,
	   URAMDA_NDE_addr_of_block_search_out => URAMDA_NDE_addr_of_block_search_out,
	   URAMDA_NDE_addr_within_block_search_out => URAMDA_NDE_addr_within_block_search_out,
	   URAMDA_NDE_doutb_out => URAMDA_NDE_doutb_out);   -- Data value output

NeighborhoodDataExtraction1: NeighborhoodDataExtraction Generic map(PRECISION, EventWidth, EventSearchRadius, Address_Width, DWIDTH, NBPIPE, RAMBLOCKADDR, RAM2DBLOCK, TS_WIDTH, AXIS_LENGTH, DELTA_T_WIDTH, Hist_Size, Size_Width, DATA_WIDTH, FIFO_DEPTH)
		port map (NDE_in_search_addr =>  URAMDA_NDE_addr_of_block_search_out, -- address of each block on search region dimension
		NDE_in_data => URAMDA_NDE_doutb_out, -- 64 URAM block data input
		NDE_out_data =>  URAMDA_NDE_out_data);-- 7*7 data output		


------------------------------------------------------
------------- stage 2: Noise Removal  ----------------
------------------------------------------------------
NeighborhoodDataExtraction_NoiseRemoval1: NeighborhoodDataExtraction_NoiseRemoval
generic map(EventWidth => EventWidth)
 port map(clr => rst,     -- Reset input
	   ce => '1',     -- Write enable input
	   clk => clk,     -- Clock input
	   NDE_NR_ts_in => URAMDA_NDE_ts_out,     -- Data value input
	   NDE_NR_border_in => URAMDA_NDE_border_out,
	   NDE_NR_ReadEnable_vec_in => URAMDA_NDE_ReadEnable_vec_out,
	   NDE_NR_addr_within_block_vec_in => URAMDA_NDE_addr_within_block_vec_out,
	   NDE_NR_addr_of_block_search_in => URAMDA_NDE_addr_of_block_search_out,
	   NDE_NR_addr_within_block_search_in => URAMDA_NDE_addr_within_block_search_out,
	   NDE_NR_doutb_in => URAMDA_NDE_doutb_out,
	   NDE_NR_out_data_in => URAMDA_NDE_out_data,
	   NDE_NR_ts_out => NDE_NR_ts_out,
	   NDE_NR_border_out => NDE_NR_border_out,
	   NDE_NR_ReadEnable_vec_out => NDE_NR_ReadEnable_vec_out,
	   NDE_NR_addr_within_block_vec_out => NDE_NR_addr_within_block_vec_out,
	   NDE_NR_addr_of_block_search_out => NDE_NR_addr_of_block_search_out,
	   NDE_NR_addr_within_block_search_out => NDE_NR_addr_within_block_search_out,  
	   NDE_NR_doutb_out => NDE_NR_doutb_out, -- Vector-based Data
	   NDE_NR_out_data_out => NDE_NR_out_data_out);   -- Region-based Data


NoiseRemoval1: NoiseRemoval  
Generic map(PRECISION, EventWidth, EventSearchRadius, Address_Width, DWIDTH, NBPIPE, RAMBLOCKADDR, RAM2DBLOCK, TS_WIDTH, AXIS_LENGTH, DELTA_T_WIDTH, Hist_Size, Size_Width, DATA_WIDTH, FIFO_DEPTH)
port map (
		 NR_ts => NDE_NR_ts_out, -- current timestamp
		 NR_border_in => NDE_NR_border_out, -- 7*7 border data input
		 NR_in_data => NDE_NR_out_data_out, -- 7*7 URAM block data input
		 NR_valid => NDE_NR_valid); -- output to hazard detection unit

------------------------------------------------------
------------- stage 3: Prefix adder  -----------------
------------------------------------------------------
NoiseRemoval_PrefixAdder1: NoiseRemoval_PrefixAdder
generic map(EventWidth => EventWidth)
 port map(clr => rst,     -- Reset input
	   ce => '1',     -- Write enable input
	   clk => clk,     -- Clock input
	   NR_PA_ts_in => NDE_NR_ts_out,     -- Data value input
	   NR_PA_border_in => NDE_NR_border_out,
	   NR_PA_ReadEnable_vec_in => NDE_NR_ReadEnable_vec_out,
	   NR_PA_addr_within_block_vec_in => NDE_NR_addr_within_block_vec_out,
	   NR_PA_addr_of_block_search_in => NDE_NR_addr_of_block_search_out,
	   NR_PA_addr_within_block_search_in => NDE_NR_addr_within_block_search_out,
	   NR_PA_doutb_in => NDE_NR_doutb_out,
	   NR_PA_out_data_in => NDE_NR_out_data_out,
	   NR_PA_valid_in => NDE_NR_valid,
	   NR_PA_ts_out => NR_PA_ts_out,
	   NR_PA_border_out => NR_PA_border_out,
	   NR_PA_ReadEnable_vec_out => NR_PA_ReadEnable_vec_out,
	   NR_PA_addr_within_block_vec_out => NR_PA_addr_within_block_vec_out,
	   NR_PA_addr_of_block_search_out => NR_PA_addr_of_block_search_out,
	   NR_PA_addr_within_block_search_out => NR_PA_addr_within_block_search_out,  
	   NR_PA_doutb_out => NR_PA_doutb_out, -- vector-based Data
	   NR_PA_out_data_out => NR_PA_out_data_out, -- matrix-based data
	   NR_PA_valid_out => NR_PA_valid_out);   -- Valid or not valid for noise removal

Prefixadder_row: for i in -EventSearchRadius to EventSearchRadius generate
Prefixadder_col:	for j in -EventSearchRadius to EventSearchRadius generate
Prefixadder_ij: Prefixadder  
                generic map(PRECISION, EventWidth, EventSearchRadius, Address_Width, DWIDTH, NBPIPE, RAMBLOCKADDR, RAM2DBLOCK, TS_WIDTH, AXIS_LENGTH, DELTA_T_WIDTH, Hist_Size, Size_Width, DATA_WIDTH, FIFO_DEPTH)
                port map (
                        data_in => NR_PA_out_data_out(i)(j),
                        data_out => NR_PA_prefixadder_out(i)(j));
                end generate;
            end generate;

------------------------------------------------------
------------- stage 4: Decompression  ----------------
------------------------------------------------------
PrefixAdder_Decompression1: PrefixAdder_Decompression
generic map(EventWidth => EventWidth)
 port map(clr => rst,     -- Reset input
	   ce => '1',     -- Write enable input
	   clk => clk,     -- Clock input
	   PA_De_ts_in => NR_PA_ts_out,     -- Data value input
	   PA_De_border_in => NR_PA_border_out,
	   PA_De_ReadEnable_vec_in => NR_PA_ReadEnable_vec_out,
	   PA_De_addr_within_block_vec_in => NR_PA_addr_within_block_vec_out,
	   PA_De_addr_of_block_search_in => NR_PA_addr_of_block_search_out,
	   PA_De_addr_within_block_search_in => NR_PA_addr_within_block_search_out,
	   PA_De_doutb_in => NR_PA_doutb_out,
	   PA_De_out_data_in => NR_PA_out_data_out,
	   PA_De_valid_in => NR_PA_valid_out,
	   PA_De_prefixadder_in => NR_PA_prefixadder_out,
	   PA_De_ts_out => PA_De_ts_out,
	   PA_De_border_out => PA_De_border_out,
	   PA_De_ReadEnable_vec_out => PA_De_ReadEnable_vec_out,
	   PA_De_addr_within_block_vec_out => PA_De_addr_within_block_vec_out,
	   PA_De_addr_of_block_search_out => PA_De_addr_of_block_search_out,
	   PA_De_addr_within_block_search_out => PA_De_addr_within_block_search_out,  
	   PA_De_doutb_out => PA_De_doutb_out, -- vector-based Data
	   PA_De_out_data_out => PA_De_out_data_out, -- matrix-based data
	   PA_De_valid_out => PA_De_valid_out,  -- Valid or not valid for noise removal
	   PA_De_prefixadder_out => PA_De_prefixadder_out);  -- decompressed array by prefix adder


Decompression_row: for i in -EventSearchRadius to EventSearchRadius generate
Decompression_col:	for j in -EventSearchRadius to EventSearchRadius generate
    decompressionij: decompression_unit
    generic map(PRECISION, EventWidth, EventSearchRadius, Address_Width, DWIDTH, NBPIPE, RAMBLOCKADDR, RAM2DBLOCK, TS_WIDTH, AXIS_LENGTH, DELTA_T_WIDTH, Hist_Size, Size_Width, DATA_WIDTH, FIFO_DEPTH)
		port map(
			Data_In => PA_DE_prefixadder_out(i)(j), -- prefix adder output
			Previous_TS => PA_De_out_data_out(i)(j)((DATA_WIDTH - Size_Width - 1) downto (DATA_WIDTH - Size_Width - TS_WIDTH)), -- previous timestamp
			Current_TS => PA_De_ts_out, --- current timestamp
			Limitted_TS => PA_De_Limitted_TS,
			Data_Out => PA_De_decompressed_out(i)(j));
		end generate;
	end generate;

-- ------------------------------------------------------
------------- stage 5: comparison  -------------------
------------------------------------------------------
Decompression_Comparison1: Decompression_Comparison
generic map(EventWidth => EventWidth)
 port map(clr => rst,     -- Reset input
	   ce => '1',     -- Write enable input
	   clk => clk,     -- Clock input
	   De_CP_ts_in => PA_De_ts_out,     -- Data value input
	   De_CP_limited_ts_in => PA_De_Limitted_TS,
	   De_CP_border_in => PA_De_border_out,
	   De_CP_ReadEnable_vec_in => PA_De_ReadEnable_vec_out,
	   De_CP_addr_within_block_vec_in => PA_De_addr_within_block_vec_out,
	   De_CP_addr_of_block_search_in => PA_De_addr_of_block_search_out,
	   De_CP_addr_within_block_search_in => PA_De_addr_within_block_search_out,
	   De_CP_doutb_in => PA_De_doutb_out,
	   De_CP_out_data_in => PA_De_out_data_out,
	   De_CP_valid_in => PA_De_valid_out,
	   De_CP_prefixadder_in => PA_De_prefixadder_out,
	   De_CP_decompressed_in => PA_De_decompressed_out,
	   De_CP_ts_out => De_CP_ts_out,
	   De_CP_limited_ts_out => De_CP_limited_ts_out,
	   De_CP_border_out => De_CP_border_out, -- border signal
	   De_CP_ReadEnable_vec_out => De_CP_ReadEnable_vec_out, -- ram read and write enable
	   De_CP_addr_within_block_vec_out => De_CP_addr_within_block_vec_out, 
	   De_CP_addr_of_block_search_out => De_CP_addr_of_block_search_out,
	   De_CP_addr_within_block_search_out => De_CP_addr_within_block_search_out,  
	   De_CP_doutb_out => De_CP_doutb_out, -- vector-based Data
	   De_CP_out_data_out => De_CP_out_data_out, -- matrix-based data
	   De_CP_valid_out => De_CP_valid_out,  -- Valid or not valid for noise removal
	   De_CP_prefixadder_out => De_CP_prefixadder_out,
	   De_CP_decompressed_out => De_CP_decompressed_out);  -- decompressed array by prefix adder

 
ComparisonUnit_row: for i in -EventSearchRadius to EventSearchRadius generate
	 ComparisonUnit_col:	for j in -EventSearchRadius to EventSearchRadius generate
		 ComparisonUnit_ij: ComparisonUnit 
		 generic map(PRECISION, EventWidth, EventSearchRadius, Address_Width, DWIDTH, NBPIPE, RAMBLOCKADDR, RAM2DBLOCK, TS_WIDTH, AXIS_LENGTH, DELTA_T_WIDTH, Hist_Size, Size_Width, DATA_WIDTH, FIFO_DEPTH)
		 port map(
			 data_in => De_CP_out_data_out(i)(j),		  -- input data from input ring buffer
			 DecompressedData => De_CP_decompressed_out(i)(j),	 -- decompressed data by prefix adder
			 Current_ts => De_CP_ts_out,  -- Current TS
			 LimitedTS => De_CP_limited_ts_out,  -- TS - Threshold value
			 data_out => De_CP_data_out(i)(j));	   -- output to shifter size unit
	 end generate;
end generate;


----------------------------------------------------
----------- stage 6: Data Mapping  -----------------
----------------------------------------------------
Comparison_URAMDataMapper1: Comparison_URAMDataMapper
generic map(EventWidth => EventWidth)
 port map(clr => rst,     -- Reset input
	   ce => '1',     -- Write enable input
	   clk => clk,     -- Clock input
	   CP_URAMDM_ts_in => De_CP_ts_out,     -- Data value input
	   CP_URAMDM_limited_ts_in => De_CP_limited_ts_out,
	   CP_URAMDM_border_in => De_CP_border_out,
	   CP_URAMDM_ReadEnable_vec_in => De_CP_ReadEnable_vec_out,
	   CP_URAMDM_addr_within_block_vec_in => De_CP_addr_within_block_vec_out,
	   CP_URAMDM_addr_of_block_search_in => De_CP_addr_of_block_search_out,
	   CP_URAMDM_addr_within_block_search_in => De_CP_addr_within_block_search_out,
	   CP_URAMDM_doutb_in => De_CP_doutb_out,
	   CP_URAMDM_out_data_in => De_CP_out_data_out,
	   CP_URAMDM_valid_in => De_CP_valid_out,
	   CP_URAMDM_prefixadder_in => De_CP_prefixadder_out,
	   CP_URAMDM_decompressed_in => De_CP_decompressed_out,
	   CP_URAMDM_compared_data_in => De_CP_data_out,
	   CP_URAMDM_ts_out => CP_URAMDM_ts_out,
	   CP_URAMDM_limited_ts_out => CP_URAMDM_limited_ts_out,
	   CP_URAMDM_border_out => CP_URAMDM_border_out, -- border signal
	   CP_URAMDM_ReadEnable_vec_out => CP_URAMDM_ReadEnable_vec_out, -- ram read and write enable
	   CP_URAMDM_addr_within_block_vec_out => CP_URAMDM_addr_within_block_vec_out, 
	   CP_URAMDM_addr_of_block_search_out => CP_URAMDM_addr_of_block_search_out,
	   CP_URAMDM_addr_within_block_search_out => CP_URAMDM_addr_within_block_search_out,  
	   CP_URAMDM_doutb_out => CP_URAMDM_doutb_out, -- vector-based Data
	   CP_URAMDM_out_data_out => CP_URAMDM_out_data_out, -- matrix-based data
	   CP_URAMDM_valid_out => CP_URAMDM_valid_out,  -- Valid or not valid for noise removal
	   CP_URAMDM_prefixadder_out => CP_URAMDM_prefixadder_out,
	   CP_URAMDM_decompressed_out => CP_URAMDM_decompressed_out,
	   CP_URAMDM_compared_data_out => CP_URAMDM_compared_data_out);  -- decompressed array by prefix adder

-- URAM data mapping 1
URAMDataMapper1: URAMdataMapper Generic map(PRECISION, EventWidth, EventSearchRadius, Address_Width, DWIDTH, NBPIPE, RAMBLOCKADDR, RAM2DBLOCK, TS_WIDTH, AXIS_LENGTH, DELTA_T_WIDTH, Hist_Size, Size_Width, DATA_WIDTH, FIFO_DEPTH)
	 port map (URAM_DM_in_addr_of_block_search => CP_URAMDM_addr_of_block_search_out,    -- 7*7 border definition
	 URAM_DM_in_data_within_block_search => CP_URAMDM_compared_data_out, -- 7*7 addr of each element inside block on search region dimension 
	 URAM_DM_out_data_within_block_vec => COM_URAMDM_data_within_block_vec);	-- vector data according to the blocks 63:0

----------------------------------------------------
----------- stage 7: Write back  -------------------
----------------------------------------------------
URAMDataMapper_WriteBack1: URAMDataMapper_WriteBack
generic map(EventWidth => EventWidth)
 port map(clr => rst,     -- Reset input
   ce => '1',     -- Write enable input
   clk => clk,     -- Clock input
   URAMDM_WB_ts_in => De_CP_ts_out,     -- Data value input
   URAMDM_WB_limited_ts_in => De_CP_limited_ts_out,
   URAMDM_WB_border_in => De_CP_border_out,
   URAMDM_WB_ReadEnable_vec_in => De_CP_ReadEnable_vec_out,
   URAMDM_WB_addr_within_block_vec_in => De_CP_addr_within_block_vec_out,
   URAMDM_WB_addr_of_block_search_in => De_CP_addr_of_block_search_out,
   URAMDM_WB_addr_within_block_search_in => De_CP_addr_within_block_search_out,
   URAMDM_WB_doutb_in => De_CP_doutb_out,
   URAMDM_WB_out_data_in => De_CP_out_data_out,
   URAMDM_WB_valid_in => De_CP_valid_out,
   URAMDM_WB_prefixadder_in => De_CP_prefixadder_out,
   URAMDM_WB_decompressed_in => De_CP_decompressed_out,
   URAMDM_WB_compared_data_in => De_CP_data_out,
   URAMDM_WB_dina_in => COM_URAMDM_data_within_block_vec,
   URAMDM_WB_ts_out => URAMDM_WB_ts_out,
   URAMDM_WB_limited_ts_out => URAMDM_WB_limited_ts_out,
   URAMDM_WB_border_out => URAMDM_WB_border_out, -- border signal
   URAMDM_WB_ReadEnable_vec_out => URAMDM_WB_ReadEnable_vec_out, -- ram read and write enable
   URAMDM_WB_addr_within_block_vec_out => URAMDM_WB_addr_within_block_vec_out, 
   URAMDM_WB_addr_of_block_search_out => URAMDM_WB_addr_of_block_search_out,
   URAMDM_WB_addr_within_block_search_out => URAMDM_WB_addr_within_block_search_out,  
   URAMDM_WB_doutb_out => URAMDM_WB_doutb_out, -- vector-based Data
   URAMDM_WB_out_data_out => URAMDM_WB_out_data_out, -- matrix-based data
   URAMDM_WB_valid_out => URAMDM_WB_valid_out,  -- Valid or not valid for noise removal
   URAMDM_WB_prefixadder_out => URAMDM_WB_prefixadder_out,
   URAMDM_WB_decompressed_out => URAMDM_WB_decompressed_out,
   URAMDM_WB_compared_data_out => URAMDM_WB_compared_data_out,
   URAMDM_WB_dina_out => URAMDM_WB_dina_out);  -- decompressed array by prefix adder

		 
end behavioral;