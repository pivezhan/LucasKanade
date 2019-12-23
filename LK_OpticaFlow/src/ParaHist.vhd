library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.LK_Package.all;

entity ParaHist is
	generic(
	TS_WIDTH : integer:=TS_WIDTH; --  this is the width of each timestamp
	AXIS_LENGTH : integer := AXIS_LENGTH; -- the width of x, y addresses in frame 
	ADDR_WIDTH : integer := ADDR_WIDTH; -- the address width for Ring buffer based block ram  
	DELTA_T_WIDTH : integer := DELTA_T_WIDTH; -- The width of delta_t timestamps
	DELTA_T_NUM : integer := DELTA_T_NUM; -- the capacity of number of events inside the rb array
	TS_SIZE : integer := TS_SIZE; -- the length of section inside the ring buffer that stores the number of events 
	DATA_WIDTH : integer := DATA_WIDTH -- data_width = TS_SIZE + TS_WIDTH + DELTA_T_WIDTH*DELTA_T_NUM
	);
	port(
	data_in : in std_logic_vector((DATA_WIDTH - 1) downto 0);
	type_in : in std_logic; -- polarity clarification 1 bit
	ts_in : in std_logic_vector((TS_WIDTH-1) downto 0); -- 32 bits
	x_addr_in : in std_logic_vector((AXIS_LENGTH -1) downto 0); -- 10 bits
	y_addr_in : in std_logic_vector((AXIS_LENGTH -2) downto 0); -- 9 bits
	APS_in : in std_logic(1 downto 0); -- 2
	ADC_in : in std_logic((AXIS_LENGTH-1) downto 0); -- 10
	valid_out : out std_logic; -- valid when finishing
	Neighbor_out : out std_logic((7*7*DELTA_T_WIDTH)-1 downto 0); -- output array for gradient calculation
	 data_out : out array_deltat
	);
end entity;

architecture behavioral of ParaHist

	signal Data_In : array_deltat;	  -- input uncompressed data
	signal Previous_TS : std_logic_vector((TS_SIZE - 1) downto 0); -- previous timestamp
	signal Current_TS : std_logic_vector((TS_SIZE - 1) downto 0); -- current timestamp
	signal Data_Out : RingBuffer;
	signal data_in : std_logic_vector((DATA_WIDTH - 1) downto 0);		  -- input data from input ring buffer
	signal DecompressedData : RingBuffer;	 -- decompressed data by prefix adder
	signal Previous_ts : std_logic_vector((TS_SIZE - 1) downto 0);  -- Previous TS
	signal Current_ts : std_logic_vector((TS_SIZE - 1) downto 0);  -- Current TS
	signal LimitedTS : std_logic_vector((TS_SIZE - 1) downto 0);  -- TS - Threshold value
	signal data_out : std_logic_vector((DATA_WIDTH - 1) downto 0);	   -- output to shifter size unit
	signal Size_out : std_logic_vector((DELTA_T_NUM - 1) downto 0);	 -- output to size unit 
	signal data_in : std_logic_vector((DATA_WIDTH - 1) downto 0);
	signal data_out : array_deltat;
	signal data8_in : std_logic_vector(7 downto 0);
	signal size8_out : std_logic_vector(2 downto 0);
	signal data16_in : std_logic_vector(15 downto 0);
	signal size16_out : std_logic_vector(3 downto 0);
component PrefixAdder is
	generic(
	TS_WIDTH : integer:=TS_WIDTH; --  this is the width of each timestamp
	AXIS_LENGTH : integer := AXIS_LENGTH; -- the width of x, y addresses in frame 
	ADDR_WIDTH : integer := ADDR_WIDTH; -- the address width for Ring buffer based block ram  
	DELTA_T_WIDTH : integer := DELTA_T_WIDTH; -- The width of delta_t timestamps
	DELTA_T_NUM : integer := DELTA_T_NUM; -- the capacity of number of events inside the rb array
	TS_SIZE : integer := TS_SIZE; -- the length of section inside the ring buffer that stores the number of events 
	DATA_WIDTH : integer := DATA_WIDTH -- data_width = TS_SIZE + TS_WIDTH + DELTA_T_WIDTH*DELTA_T_NUM
	);
	port(
	data_in : in std_logic_vector((DATA_WIDTH - 1) downto 0);
	data_out : out array_deltat
	);
end component;

component decompression_unit is
	generic(
	TS_WIDTH : integer:=TS_WIDTH; --  this is the width of each timestamp
	AXIS_LENGTH : integer := AXIS_LENGTH; -- the width of x, y addresses in frame 
	ADDR_WIDTH : integer := ADDR_WIDTH; -- the address width for Ring buffer based block ram  
	DELTA_T_WIDTH : integer := DELTA_T_WIDTH; -- The width of delta_t timestamps
	DELTA_T_NUM : integer := DELTA_T_NUM; -- the capacity of number of events inside the rb array
	TS_SIZE : integer := TS_SIZE; -- the length of section inside the ring buffer that stores the number of events 
	DATA_WIDTH : integer := DATA_WIDTH -- data_width = TS_SIZE + TS_WIDTH + DELTA_T_WIDTH*DELTA_T_NUM
	);
	port(
		Data_In : in array_deltat;	 -- input uncompressed data
		Previous_TS : in std_logic_vector((TS_SIZE - 1) downto 0);
		Current_TS : in std_logic_vector((TS_SIZE - 1) downto 0);
		Limitted_TS : out std_logic_vector((TS_SIZE - 1) downto 0);
		Data_Out : out RingBuffer
	);
end component;

component ComparisonUnit is
	generic(
	TS_WIDTH : integer:=TS_WIDTH; --  this is the width of each timestamp
	AXIS_LENGTH : integer := AXIS_LENGTH; -- the width of x, y addresses in frame 
	ADDR_WIDTH : integer := ADDR_WIDTH; -- the address width for Ring buffer based block ram  
	DELTA_T_WIDTH : integer := DELTA_T_WIDTH; -- The width of delta_t timestamps
	DELTA_T_NUM : integer := DELTA_T_NUM; -- the capacity of number of events inside the rb array
	TS_SIZE : integer := TS_SIZE; -- the length of section inside the ring buffer that stores the number of events 
	DATA_WIDTH : integer := DATA_WIDTH -- data_width = TS_SIZE + TS_WIDTH + DELTA_T_WIDTH*DELTA_T_NUM
	);
	port(
		data_in : in std_logic_vector((DATA_WIDTH - 1) downto 0);		  -- input data from input ring buffer
		DecompressedData : in RingBuffer;	 -- decompressed data by prefix adder
		Previous_ts : in std_logic_vector((TS_SIZE - 1) downto 0);  -- Previous TS
		Current_ts : in std_logic_vector((TS_SIZE - 1) downto 0);  -- Current TS
		LimitedTS : in std_logic_vector((TS_SIZE - 1) downto 0);  -- TS - Threshold value
		data_out : out std_logic_vector((DATA_WIDTH - 1) downto 0);	   -- output to shifter size unit
		Size_out : out std_logic_vector((DELTA_T_NUM - 1) downto 0)	 -- output to size unit 
	);
end component;

component setbitcounter is
	generic(
	TS_WIDTH : integer:=TS_WIDTH; --  this is the width of each timestamp
	AXIS_LENGTH : integer := AXIS_LENGTH; -- the width of x, y addresses in frame 
	ADDR_WIDTH : integer := ADDR_WIDTH; -- the address width for Ring buffer based block ram  
	DELTA_T_WIDTH : integer := DELTA_T_WIDTH; -- The width of delta_t timestamps
	DELTA_T_NUM : integer := DELTA_T_NUM; -- the capacity of number of events inside the rb array
	TS_SIZE : integer := TS_SIZE; -- the length of section inside the ring buffer that stores the number of events 
	DATA_WIDTH : integer := DATA_WIDTH -- data_width = TS_SIZE + TS_WIDTH + DELTA_T_WIDTH*DELTA_T_NUM
	);
	port(
	data8_in : in std_logic_vector(7 downto 0);
	size8_out : out std_logic_vector(2 downto 0);
	data16_in : in std_logic_vector(15 downto 0);
	size16_out : out std_logic_vector(3 downto 0)
	);
end component;

component STD_FIFO is
	Port ( 
		CLK		: in  STD_LOGIC;
		RST		: in  STD_LOGIC;
		WriteEn	: in  STD_LOGIC;
		DataIn	: in  STD_LOGIC_VECTOR (7 downto 0);
		ReadEn	: in  STD_LOGIC;
		DataOut	: out STD_LOGIC_VECTOR (7 downto 0);
		Empty	: out STD_LOGIC;
		Full	: out STD_LOGIC
	);
end component;


 
begin
end behavioral;