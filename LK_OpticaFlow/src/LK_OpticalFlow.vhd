library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.LK_Package.all;

entity LK_OpticalFlow is 
	generic(
	TS_WIDTH: integer:=TS_WIDTH;
	AXIS_LENGTH : integer := AXIS_LENGTH;
	ADDR_WIDTH : integer := ADDR_WIDTH;
	DATA_WIDTH : integer := DATA_WIDTH;
	DELTA_T_WIDTH : integer := DELTA_T_WIDTH;
	DELTA_T_NUM : integer := DELTA_T_NUM;
	TS_SIZE : integer := TS_SIZE
	);
	port(
	clk: in std_logic;
	rst: in std_logic;
	timestamp_in: in std_logic_vector((TS_WIDTH - 1) downto 0);
	X_in: in std_logic_vector((AXIS_LENGTH-1) downto 0);
	Y_in: in std_logic_vector((AXIS_LENGTH-1) downto 0);
	refractory: in std_logic_vector((TS_WIDTH - 1) downto 0);
	threshold_in : in std_logic_vector((TS_WIDTH - 1) downto 0);
	X_out: out std_logic_vector((AXIS_LENGTH-1) downto 0);
	Y_out: out std_logic_vector((AXIS_LENGTH-1) downto 0);
	V_x : out std_logic_vector((TS_WIDTH - 1) downto 0);
	V_y : out std_logic_vector((TS_WIDTH - 1) downto 0)
	);
end entity;

architecture behavioral of LK_OpticalFlow is 

component mem is
	generic 
	(
		DATA_WIDTH : natural := 32;
		ADDR_WIDTH : natural := 10
	);
	port 
	(	
	clk		: in std_logic;
	addr	        : in std_logic_vector((ADDR_WIDTH-1) downto 0);
	data	        : in std_logic_vector((DATA_WIDTH-1) downto 0);
	we		: in std_logic := '1';
	q		: out std_logic_vector((DATA_WIDTH -1) downto 0));
end component;

signal addr	        : std_logic_vector((ADDR_WIDTH-1) downto 0);
signal data	        : std_logic_vector((DATA_WIDTH-1) downto 0);
signal we		: std_logic := '1';
signal q		: std_logic_vector((DATA_WIDTH -1) downto 0);

begin

Eventrb: mem generic map(DATA_WIDTH => DATA_WIDTH, ADDR_WIDTH => ADDR_WIDTH)
port map(clk => clk,
addr => addr,
data => data,
we => we,
q => q);



end behavioral;
