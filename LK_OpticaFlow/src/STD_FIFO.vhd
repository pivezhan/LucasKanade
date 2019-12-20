library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
 
entity STD_FIFO is
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
end STD_FIFO;
 
architecture Behavioral of STD_FIFO is
	type memarray is array (0 to 5) of std_logic_vector (0 to 7);
	signal fifo1 : memarray := (others => (others => '0'));
 	signal read_ptr,write_ptr : std_logic_vector (2 downto 0);
begin

	-- Memory Pointer Process
	mem_pointer_proc : process (CLK)
		begin
		if (rising_edge(CLK)) then
		if (RST='1') then 
		write_ptr <= "000";
		read_ptr <= "000";
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
		for i in 0 to 5 loop
		fifo1(i)<="00000000";
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
		DataOut <= "00000000";
		elsif (ReadEn = '1') then 
		DataOut <= fifo1(to_integer(unsigned(read_ptr(1 downto 0))));
		end if;
		end if;
		end process;
	end architecture Behavioral;
