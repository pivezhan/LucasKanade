library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.LK_Package.all;

entity ComparisonUnit is
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
end entity;

-- architecture behavioral of ComparisonUnit is
	-- signal temp_slt, temp_slt_halt : std_logic_vector((TS_WIDTH - 1) downto 0);
	-- signal temp_data_out : std_logic_vector((DATA_WIDTH - 1) downto 0):=(others => '0');
	-- signal temp_delta_prev_ts : std_logic_vector((TS_WIDTH - 1) downto 0);
	-- signal temp_prev_ts : std_logic_vector((TS_WIDTH - 1) downto 0);
	-- signal count : std_logic_vector((TS_SIZE-1) downto 0) := (others => '0');
	-- constant countmax : std_logic_vector((TS_SIZE-1) downto 0) := (others => '1');
-- begin

	-- temp_slt <= ts_in - threshold - decompressed_data(DELTA_T_NUM-to_integer(unsigned(count))-1);
	-- temp_prev_ts <= data_in((DATA_WIDTH - TS_SIZE - 1) downto (DATA_WIDTH - TS_SIZE - TS_WIDTH));
	-- temp_slt_halt <= ts_in - threshold - temp_prev_ts;
	-- temp_delta_prev_ts <= ts_in - temp_prev_ts;
	
	-- process(clk, rst, ts_in, data_in, decompressed_data, threshold)
	-- begin
	-- if clk'event and clk='1' then
	-- if (temp_slt_halt(TS_WIDTH - 1)='0') then
			-- data_out((DATA_WIDTH - TS_SIZE -1) downto (DATA_WIDTH - TS_SIZE - TS_WIDTH)) <= ts_in; -- replace the previous timestamp with the current timestamp
			-- data_out((DATA_WIDTH - TS_SIZE - TS_WIDTH - 1) downto 0) <= std_logic_vector(to_unsigned(0,(DATA_WIDTH - TS_SIZE - TS_WIDTH)));
			-- else
		-- if ((in_valid_comp = '1')  and (count /= countmax) and (temp_slt(TS_WIDTH - 1) = '0')) then
		-- count <= count + 1;
		-- out_valid_comp <= '0';
		-- elsif ((in_valid_comp = '1') and (temp_slt(TS_WIDTH-1) = '1')) then
		-- data_out((DATA_WIDTH -1) downto (DATA_WIDTH - TS_SIZE)) <= data_in((DATA_WIDTH -1) downto (DATA_WIDTH - TS_SIZE)) - count; -- resize the ring buffer
		-- data_out((DATA_WIDTH - TS_SIZE -1) downto (DATA_WIDTH - TS_SIZE - TS_WIDTH)) <= ts_in; -- replace the previous timestamp with the current timestamp
		-- data_out((DATA_WIDTH - TS_SIZE - TS_WIDTH - DELTA_T_WIDTH -1) downto (DATA_WIDTH - TS_SIZE - TS_WIDTH - (2*DELTA_T_WIDTH))) 
		-- <= std_logic_vector(to_unsigned(to_integer(unsigned(temp_delta_prev_ts)), DELTA_T_WIDTH));
		-- data_out((DATA_WIDTH - TS_SIZE - TS_WIDTH - 2*DELTA_T_WIDTH -1) downto 0) 
		-- <= data_in((DATA_WIDTH - TS_SIZE - TS_WIDTH - DELTA_T_WIDTH -1) downto (DATA_WIDTH - TS_SIZE - TS_WIDTH - ((DELTA_T_NUM-1)*DELTA_T_WIDTH))); -- move data in ring buffer
		-- data_out((DATA_WIDTH - TS_SIZE - TS_WIDTH - ((DELTA_T_NUM-to_integer(unsigned(count)))*DELTA_T_WIDTH)-1) downto 0) 
		-- <=  (others => '0'); -- get rid of data that passes the threshold value
		-- out_valid_comp <= '1';
		-- elsif ((in_valid_comp = '1') and (count = countmax) and (temp_slt(TS_WIDTH-1) = '0')) then
		-- data_out((DATA_WIDTH -1) downto (DATA_WIDTH - TS_SIZE)) <= data_in((DATA_WIDTH -1) downto (DATA_WIDTH - TS_SIZE)) - count; -- resize the ring buffer
		-- data_out((DATA_WIDTH - TS_SIZE -1) downto (DATA_WIDTH - TS_SIZE - TS_WIDTH)) <= ts_in; -- replace the previous timestamp with the current timestamp
		-- data_out((DATA_WIDTH - TS_SIZE - TS_WIDTH - DELTA_T_WIDTH -1) downto (DATA_WIDTH - TS_SIZE - TS_WIDTH - (2*DELTA_T_WIDTH))) 
		-- <= std_logic_vector(to_unsigned(to_integer(unsigned(temp_delta_prev_ts)),DELTA_T_WIDTH));
		-- data_out((DATA_WIDTH - TS_SIZE - TS_WIDTH - 2*DELTA_T_WIDTH -1) downto 0) 
		-- <= data_in((DATA_WIDTH - TS_SIZE - TS_WIDTH - DELTA_T_WIDTH -1) downto (DATA_WIDTH - TS_SIZE - TS_WIDTH - ((DELTA_T_NUM-1)*DELTA_T_WIDTH))); -- move data in ring buffer
		-- data_out((DATA_WIDTH - TS_SIZE - TS_WIDTH - ((DELTA_T_NUM-to_integer(unsigned(count)))*DELTA_T_WIDTH)-1) downto 0) 
		-- <=  (others => '0');--std_logic_vector(to_unsigned(0, (DATA_WIDTH - TS_SIZE - TS_WIDTH - ((DELTA_T_NUM - to_integer(unsigned(count)))*DELTA_T_WIDTH)))); -- get rid of data that passes the threshold value
		-- out_valid_comp <= '1';
		-- else null;		
		-- end if;
	-- end if;
	-- end if;
	 -- end process;

-- end behavioral;

architecture structural of ComparisonUnit is
signal tempring : RingBuffer;
constant zerodelta : std_logic_vector((DELTA_T_WIDTH-1) downto 0) := (others => '0');
begin

Comparison:		for i in 0 to (DELTA_T_NUM-1) generate
				tempring(i) <= LimitedTS - DecompressedData(i);
				end generate;
				

OmissionAndShifter:		for i in 0 to (DELTA_T_NUM-2) generate
				-- data_out() <= data_in when tempring(i)(TS_SIZE - 1) = '1' else (others => '0');
				data_out((DATA_WIDTH - TS_SIZE - TS_WIDTH - ((i+1)*DELTA_T_WIDTH) - 1) downto (DATA_WIDTH - TS_SIZE - TS_WIDTH - ((i+2)*DELTA_T_WIDTH)))
				<= data_in((DATA_WIDTH - TS_SIZE - TS_WIDTH - (i*DELTA_T_WIDTH) - 1) downto (DATA_WIDTH - TS_SIZE - TS_WIDTH - ((i+1)*DELTA_T_WIDTH))) 
				when tempring(i)(TS_SIZE - 1) = '1' else zerodelta; 
				-- move data in ring buffer
				end generate;
data_out((DATA_WIDTH - TS_SIZE - TS_WIDTH - 1) downto (DATA_WIDTH - TS_SIZE - TS_WIDTH - DELTA_T_WIDTH)) <= Current_ts - Previous_ts;
data_out((DATA_WIDTH - TS_SIZE - 1) downto (DATA_WIDTH - TS_SIZE - TS_WIDTH)) <= Current_ts;

SizeDefinition: for i in 0 to (DELTA_T_NUM-1) generate
				Size_out(i) <= '1' when tempring(i)(TS_SIZE - 1) = '1' else '0'; 
				-- move data in ring buffer
				end generate;
end structural;