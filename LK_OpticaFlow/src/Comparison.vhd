library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.LK_Package.all;

entity Comparison is
	generic(
	gCLK_HPER   : time := 50 ns;
	TS_WIDTH : integer:=TS_WIDTH; --  this is the width of each timestamp
	AXIS_LENGTH : integer := AXIS_LENGTH; -- the width of x, y addresses in frame 
	ADDR_WIDTH : integer := ADDR_WIDTH; -- the address width for Ring buffer based block ram  
	DELTA_T_WIDTH : integer := DELTA_T_WIDTH; -- The width of delta_t timestamps
	DELTA_T_NUM : integer := DELTA_T_NUM; -- the capacity of number of events inside the rb array
	TS_SIZE : integer := TS_SIZE; -- the length of section inside the ring buffer that stores the number of events 
	DATA_WIDTH : integer := DATA_WIDTH -- data_width = TS_SIZE + TS_WIDTH + DELTA_T_WIDTH*DELTA_T_NUM
	);
	port(	
	clk : in std_logic;
	rst : in std_logic;
	ts_in : in std_logic_vector((TS_WIDTH - 1) downto 0);
	data_in : in std_logic_vector((DATA_WIDTH - 1) downto 0);	
	threshold : in std_logic_vector((TS_WIDTH - 1) downto 0);
	in_valid : in std_logic;
	data_out : out std_logic_vector((DATA_WIDTH - 1) downto 0);
	out_valid_comp : out std_logic
	);
end entity;

architecture behavioral of Comparison is

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
		in_valid_comp : in std_logic;
		clk : in std_logic;
		rst : in std_logic;
		ts_in : in std_logic_vector((TS_WIDTH - 1) downto 0);
		data_in : in std_logic_vector((DATA_WIDTH - 1) downto 0);
		decompressed_data : in array_deltat;
		threshold : in std_logic_vector((TS_WIDTH - 1) downto 0);
		data_out : out std_logic_vector((DATA_WIDTH - 1) downto 0);
		out_valid_comp : out std_logic
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
	in_valid : in std_logic;
	data_in : in std_logic_vector((DATA_WIDTH - 1) downto 0);
	data_out : out array_deltat;
	out_valid : out std_logic
	);
	end component;
	
	
	signal in_valid_comp : std_logic;
	signal decompressed_data : array_deltat;
	signal out_valid : std_logic;



	
begin 
	decompression: decompression_unit generic map(TS_WIDTH => TS_WIDTH, AXIS_LENGTH => AXIS_LENGTH, 
	ADDR_WIDTH =>ADDR_WIDTH, DELTA_T_WIDTH => DELTA_T_WIDTH, DELTA_T_NUM => DELTA_T_NUM,
	TS_SIZE => TS_SIZE, DATA_WIDTH => DATA_WIDTH) 
	port map(in_valid => in_valid, data_in => data_in,
	data_out => decompressed_data, out_valid => out_valid);
	
	comparison: ComparisonUnit generic map(TS_WIDTH => TS_WIDTH, AXIS_LENGTH => AXIS_LENGTH, 
	ADDR_WIDTH => ADDR_WIDTH, DELTA_T_WIDTH => DELTA_T_WIDTH, DELTA_T_NUM => DELTA_T_NUM,
	TS_SIZE => TS_SIZE, DATA_WIDTH => DATA_WIDTH) 
	port map(in_valid_comp => in_valid_comp, clk => clk, rst => rst,
	ts_in => ts_in, data_in => data_in, decompressed_data => decompressed_data,
	threshold => threshold, data_out => data_out, out_valid_comp => out_valid_comp);
	
	in_valid_comp <= out_valid;

end behavioral;
