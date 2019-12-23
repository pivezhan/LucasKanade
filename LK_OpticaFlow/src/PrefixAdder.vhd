library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.LK_Package.all;

entity PrefixAdder is
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
--	prefixarray : out array_deltat2d:=(others=>(others=>(others => '0')))
	 data_out : out array_deltat
	-- out_valid : out std_logic
	);
end entity;

--architecture kogge_stone of PrefixAdder is
--	signal prefixarray : array_deltat2d:=(others=>(others=>(others => '0')));
--
--begin 
--initailize:	for i in 0 to (DELTA_T_NUM - 1) generate
--		prefixarray(0)(i)((DELTA_T_WIDTH - 1) downto 0) <= data_in((DATA_WIDTH-TS_WIDTH-TS_SIZE-((DELTA_T_NUM-i-1)*DELTA_T_WIDTH)-1) downto (DATA_WIDTH-TS_WIDTH-TS_SIZE-((DELTA_T_NUM-i)*DELTA_T_WIDTH)));
--	end generate;	
--
--Level_j:		for j in 0 to TS_SIZE generate
--Array_i:			for i in 0 to (DELTA_T_NUM - 1) generate
--Cond_add:					if (i >= 2**j) generate
--								prefixarray(j+1)(i) <= prefixarray(j)(i) + prefixarray(j)(i-2**j);
--							end generate;
--Cond_pass:					if (i < 2**j) generate
--								prefixarray(j+1)(i) <= prefixarray(j)(i);
--							end generate;
--					end generate;
--				end generate;
--	data_out <= prefixarray(TS_SIZE);
--
--
--end kogge_stone;									
--
architecture radix4_sklanski of PrefixAdder is
	signal prefixarray : array_deltat2d:=(others=>(others=>(others => '0')));

begin 
initailize:	for i in 0 to (DELTA_T_NUM - 1) generate
		prefixarray(0)(i)((DELTA_T_WIDTH - 1) downto 0) <= data_in((DATA_WIDTH-TS_WIDTH-TS_SIZE-((DELTA_T_NUM-i-1)*DELTA_T_WIDTH)-1) downto (DATA_WIDTH-TS_WIDTH-TS_SIZE-((DELTA_T_NUM-i)*DELTA_T_WIDTH)));
end generate;	
-- combinational
Level_j:		for j in 0 to TS_SIZE generate
Array_i:			for i in 0 to (DELTA_T_NUM - 1) generate
Radix4_Reduce:			if (j < 2) generate	  -- Reduce stage of radix4_sklanski
Cond_Add1:					if ((i mod 4) >= 2**j) generate
								prefixarray(j+1)(i) <= prefixarray(j)(i) + prefixarray(j)(i-(2**j));
							end generate;
Cond_Pass1:					if ((i mod 4) < 2**j) generate
								prefixarray(j+1)(i) <= prefixarray(j)(i);
							end generate;
						end generate;
Radix4_Propagate:			if (j >= 2) generate		-- propagate stage of radix4_sklanski
Cond_Add2:					if ((i mod 2**(j+1)) >= (2**j)) generate
								prefixarray(j+1)(i) <= prefixarray(j)(i) + prefixarray(j)(i-(i mod 2**(j+1))+(2**j)-1);
							end generate;
Cond_Pass2:					if ((i mod 2**(j+1)) < (2**j)) generate
								prefixarray(j+1)(i) <= prefixarray(j)(i);
							end generate;
					   	end generate;
					end generate;
end generate;	

data_out <= prefixarray(TS_SIZE); -- write the result into the output array
--data_out(i) <= data_in((DATA_WIDTH-TS_SIZE-1) downto (DATA_WIDTH-TS_SIZE-TS_WIDTH)) - prefixarray(j)(i);
-- data_out(i) <= data_in((DATA_WIDTH-TS_SIZE-1) downto (DATA_WIDTH-TS_SIZE-TS_WIDTH)) - prefixarray(j)(i);

	-- out_valid <= '1' when (in_valid = '1') else '0';
end radix4_sklanski;			
					  