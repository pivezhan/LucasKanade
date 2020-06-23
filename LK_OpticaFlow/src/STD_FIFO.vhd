library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
library work;
use work.LK_Package.all;
use work.all;

entity STD_FIFO is
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
end STD_FIFO;
 
architecture Behavioral of STD_FIFO is
	type memarray is array (0 to (FIFO_DEPTH-1)) of std_logic_vector (0 to (EventWidth-1));
	signal fifo1 : memarray := (others => (others => '0'));
 	signal read_ptr,write_ptr : std_logic_vector (2 downto 0);
begin

	-- Memory Pointer Process
	mem_pointer_proc : process (CLK)
		begin
		if (rising_edge(CLK)) then
		if (RST='1') then 
		write_ptr <= (others => '0');
		read_ptr <= (others => '0');
		end if;
		if (RST='0') and (WriteEn='1') then
		write_ptr <= write_ptr + 1;
		end if;
		if (RST='0') and (ReadEn = '1') then
		read_ptr <= read_ptr + 1;
		end if;
		end if;
		end process;
	
	-- Full Process
		full_proc : process (CLK)
		begin 
		if (rising_edge(CLK)) then
		if (write_ptr(2)/=read_ptr(2)) and (write_ptr(1 downto 0)= read_ptr(1 downto 0)) then
		Full <= '1';
		else 
		Full <= '0';
		end if;
		end if;
		end process;
	
	--Empty Process
		empty_proc: process (CLK)
		begin
		if (rising_edge(CLK)) then
		if (write_ptr=read_ptr) then 
		Empty<='1';
		else
		Empty<='0';
		end if;
		end if;
		end process;
	
	--Data in process
		data_in : process (CLK)
		begin
		if (rising_edge(CLK)) then
		if (RST='1') then
		for i in 0 to (FIFO_DEPTH-1) loop
		fifo1(i)<=(others=>'0');
		end loop;
		elsif (WriteEn = '1') then 
		fifo1(to_integer(unsigned(write_ptr(1 downto 0))))<=DataIn;
		end if;
		end if;
		end process;
	
	--Data out process
		data_out : process(CLK)
		begin
		if (rising_edge(CLK)) then
		if (RST='1') then
		DataOut <= (others=>'0');
		elsif (ReadEn = '1') then 
		DataOut <= fifo1(to_integer(unsigned(read_ptr(1 downto 0))));
		end if;
		end if;
		end process;
	end architecture Behavioral;
