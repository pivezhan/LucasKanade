library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.LK_Package.all;

entity counter is
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
clk: in std_logic; 
rst: in std_logic;  
Q: out std_logic_vector(TS_SIZE-1 downto 0));
end counter;
-- clock ,clr  are inputs and Q is output of 4 -bits (inout means can be read and written)
Architecture behavioral of counter is
signal count : std_logic_vector (TS_SIZE-1 downto 0):=(others => '0');

begin
Q <= count;
process(clk,rst,count)
begin
	if rising_edge(clk) then
		 if (rst = '1') then
		 count <= (others=> '0');
		 else
		 count <= count + 1; -- or you can use “0001”
		 end if;
	end if; 
end process;	
end behavioral;