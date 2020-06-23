-- This unit updates the whole blocks in memory instead of just the target pixel (needs fix)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.LK_Package.all;
use work.all;

entity ComparisonUnit is
	generic(
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
	port(
		data_in : in std_logic_vector((DATA_WIDTH - 1) downto 0);		  -- input data from input ring buffer
		DecompressedData : in RingBuffer;	 -- decompressed data by prefix adder
		Current_ts : in std_logic_vector((TS_WIDTH - 1) downto 0);  -- Current TS
		LimitedTS : in std_logic_vector((TS_WIDTH - 1) downto 0);  -- TS - Threshold value
		data_out : out std_logic_vector((DATA_WIDTH - 1) downto 0)	   -- output to set counter unit
	);
end entity;


architecture structural of ComparisonUnit is
signal tempring : RingBuffer;
signal Previous_ts : std_logic_vector((TS_WIDTH-1) downto 0);
signal Size_out : std_logic_vector(7 downto 0);	 -- output to size unit 
constant Allzeros : std_logic_vector((TS_WIDTH-1) downto 0):=(others => '0');
constant zerodelta : std_logic_vector((DELTA_T_WIDTH-1) downto 0) := (others => '0');
begin
Previous_ts <= data_in((DATA_WIDTH - Size_Width - 1) downto (DATA_WIDTH - Size_Width - TS_WIDTH));

Comparison: for i in 0 to (Hist_Size) generate
	tempring(i) <= LimitedTS - DecompressedData(i);
end generate;

OmissionAndShifter: for i in 0 to (Hist_Size-2) generate
				-- data_out() <= data_in when tempring(i)(Size_Width - 1) = '1' else (others => '0');
				data_out((DATA_WIDTH - Size_Width - TS_WIDTH - ((i+1)*DELTA_T_WIDTH) - 1) downto (DATA_WIDTH - Size_Width - TS_WIDTH - ((i+2)*DELTA_T_WIDTH)))
				<= data_in((DATA_WIDTH - Size_Width - TS_WIDTH - (i*DELTA_T_WIDTH) - 1) downto (DATA_WIDTH - Size_Width - TS_WIDTH - ((i+1)*DELTA_T_WIDTH))) 
				when tempring(i)(TS_WIDTH - 1) = '1' else zerodelta; -- move data in ring buffer
				end generate;
data_out((DATA_WIDTH - Size_Width - TS_WIDTH - 1) downto (DATA_WIDTH - Size_Width - TS_WIDTH - DELTA_T_WIDTH)) <= std_logic_vector(to_unsigned(to_integer(unsigned(Current_ts - Previous_ts)), DELTA_T_WIDTH)) when (Previous_ts/=Allzeros) else (others => '0');
				
data_out((DATA_WIDTH - Size_Width - 1) downto (DATA_WIDTH - Size_Width - TS_WIDTH)) <= Current_ts;

SizeDefinition: for i in 0 to (Hist_Size-1) generate
	Size_out(i) <= tempring(i)(TS_WIDTH - 1) when (DecompressedData(i) /= Allzeros) else '0'; -- move data in ring buffer
end generate; 
--  selectsignal <= Size_out;
-- 8 delta sections
DUT1: if  Hist_Size=8 generate
with Size_out select data_out((DATA_WIDTH - 1) downto (DATA_WIDTH - Size_Width)) <=
	"000" when "00000000",
	"001" when "10000000",
	"010" when "11000000",
	"011" when "11100000",
	"100" when "11110000",
	"101" when "11111000",
	"110" when "11111100",
	"111" when others;
end generate;

------ 12 delta sections
--DUT2: if  Hist_Size=12 generate
--	with Size_out select data_out((DATA_WIDTH - 1) downto (DATA_WIDTH - Size_Width)) <=
--	"0000" when "000000000000",
--	"0001" when "100000000000",
--	"0010" when "110000000000",
--	"0011" when "111000000000",
--	"0100" when "111100000000",
--	"0101" when "111110000000",
--	"0110" when "111111000000",
--	"0111" when "111111100000",
--	"1000" when "111111110000",
--	"1001" when "111111111000",
--	"1010" when "111111111100",
--	"1011" when others;
--end generate;

-- ------ 16 delta sections
-- DUT3: if  Hist_Size=16 generate 
	-- with Size_out select data_out((DATA_WIDTH - 1) downto (DATA_WIDTH - Size_Width)) <=
	-- "0000" when "0000000000000000",
	-- "0001" when "1000000000000000",
	-- "0010" when "1100000000000000",
	-- "0011" when "1110000000000000",
	-- "0100" when "1111000000000000",
	-- "0101" when "1111100000000000",
	-- "0110" when "1111110000000000",
	-- "0111" when "1111111000000000",
	-- "1000" when "1111111100000000",
	-- "1001" when "1111111110000000",
	-- "1010" when "1111111111000000",
	-- "1011" when "1111111111100000",
	-- "1100" when "1111111111110000",
	-- "1101" when "1111111111111000",
	-- "1110" when "1111111111111100",
	-- "1111" when others;
-- end generate;
	
end structural;