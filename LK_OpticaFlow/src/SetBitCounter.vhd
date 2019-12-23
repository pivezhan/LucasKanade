library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.LK_Package.all;

entity setbitcounter is
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
end entity;

architecture behavioral of setbitcounter is
begin
	with data8_in select size8_out <=
	"000" when "00000000",
	"001" when "10000000",
	"010" when "11000000",
	"011" when "11100000",
	"100" when "11110000",
	"101" when "11111000",
	"110" when "11111100",
	"111" when others;

	with data16_in select size16_out <=
	"0000" when "0000000000000000",
	"0001" when "1000000000000000",
	"0010" when "1100000000000000",
	"0011" when "1110000000000000",
	"0100" when "1111000000000000",
	"0101" when "1111100000000000",
	"0110" when "1111110000000000",
	"0111" when "1111111000000000",
	"1000" when "1111111100000000",
	"1001" when "1111111110000000",
	"1010" when "1111111111000000",
	"1011" when "1111111111100000",
	"1100" when "1111111111110000",
	"1101" when "1111111111111000",
	"1110" when "1111111111111100",
	"1111" when others;
end behavioral;