library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.LK_Package.all;

entity tb_decompression_unit is
	generic(
	TS_WIDTH : integer:=TS_WIDTH; --  this is the width of each timestamp
	AXIS_LENGTH : integer := AXIS_LENGTH; -- the width of x, y addresses in frame 
	ADDR_WIDTH : integer := ADDR_WIDTH; -- the address width for Ring buffer based block ram  
	DELTA_T_WIDTH : integer := DELTA_T_WIDTH; -- The width of delta_t timestamps
	DELTA_T_NUM : integer := DELTA_T_NUM; -- the capacity of number of events inside the rb array
	TS_SIZE : integer := TS_SIZE; -- the length of section inside the ring buffer that stores the number of events 
	DATA_WIDTH : integer := DATA_WIDTH -- data_width = TS_SIZE + TS_WIDTH + DELTA_T_WIDTH*DELTA_T_NUM
	);
end entity;

architecture behavioral of tb_decompression_unit is
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
	signal data_in : std_logic_vector((DATA_WIDTH - 1) downto 0);
	signal data_out : array_deltat;
	signal in_valid, out_valid : std_logic;
	

	begin 
	DUT: decompression_unit generic map(TS_WIDTH, AXIS_LENGTH, ADDR_WIDTH, DELTA_T_WIDTH, DELTA_T_NUM, TS_SIZE, DATA_WIDTH)
	port map (in_valid => in_valid,data_in => data_in,data_out => data_out, out_valid => out_valid);

	process
	begin
		data_in <= std_logic_vector(to_unsigned(8, TS_SIZE)) & std_logic_vector(to_unsigned(20, TS_WIDTH)) & std_logic_vector(to_unsigned(1, DELTA_T_WIDTH)) & std_logic_vector(to_unsigned(1, DELTA_T_WIDTH)) & std_logic_vector(to_unsigned(1, DELTA_T_WIDTH)) & std_logic_vector(to_unsigned(1, DELTA_T_WIDTH)) & std_logic_vector(to_unsigned(1, DELTA_T_WIDTH)) &  std_logic_vector(to_unsigned(1, DELTA_T_WIDTH)) & std_logic_vector(to_unsigned(1, DELTA_T_WIDTH)) & std_logic_vector(to_unsigned(1, DELTA_T_WIDTH));
		in_valid <= '1';
		wait for 100 ns;
	end process;

end behavioral;
