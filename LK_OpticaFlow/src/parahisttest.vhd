library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.LK_Package.all;
use work.all;

entity parahisttest is
	generic(
	gCLK_HPER   : time := 10 ns;
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

end entity;

architecture behavioral of parahisttest is
constant EF_NAG_length : integer := DATA_WIDTH; -- event fetch and neighborhood address generator length
constant URAMDA_NDE_length : integer := (RAM2DBLOCK*DATA_WIDTH) + RAM2DBLOCK*13 + TS_WIDTH + 7*EventSearch2D; -- URAM data access to neighborhood data extraction pipeline
constant NDE_NR_length : integer := (EventSearch2D*DATA_WIDTH) + (RAM2DBLOCK*12) + RAM2DBLOCK + 7*EventSearch2D + TS_WIDTH; -- neighborhood data extraction to noise removal pipeline
constant NR_PA_length : integer := (EventSearch2D*DATA_WIDTH) + (RAM2DBLOCK*12) + RAM2DBLOCK + 7*EventSearch2D + TS_WIDTH; -- noise removal to prefix adder pipeline
constant PA_DE_length : integer := (EventSearch2D*Hist_Size*TS_WIDTH)  + (EventSearch2D*DATA_WIDTH) + (RAM2DBLOCK*12) + RAM2DBLOCK + (7*EventSearch2D) + TS_WIDTH; -- prefix adder to decompression unit pipeline
constant DE_COM_length : integer := EventSearch2D*(Hist_Size+1)*TS_WIDTH + (RAM2DBLOCK*12) + (EventSearch2D*TS_WIDTH) + (EventSearch2D*DATA_WIDTH) + RAM2DBLOCK + 7*EventSearch2D + TS_WIDTH; -- Decompression unit to comparison and shift pipeline
constant COM_URAMDM_length : integer := (EventSearch2D*DATA_WIDTH) + (RAM2DBLOCK*12) + RAM2DBLOCK + 7*EventSearch2D + TS_WIDTH; -- comparison and shift to URAM data mapping pipeline
constant URAMDM_WB_length : integer := DATA_WIDTH; -- comparison and shift to URAM data mapping pipeline
constant NAG_URAMAM_length : integer := (20*EventSearch2D)+TS_WIDTH; -- neighborhood address generator and URAM address mapping pipeline
constant URAMAM_URAMDA_length : integer := (RAM2DBLOCK*DATA_WIDTH) + (RAM2DBLOCK*12) + RAM2DBLOCK + TS_WIDTH + 7*EventSearch2D; -- URAM address mapping  to URAM data access pipeline
constant URAMDM_WriteBack_length : integer:= (RAM2DBLOCK*DATA_WIDTH) + (RAM2DBLOCK*12) +  RAM2DBLOCK;
constant timestamp_begining_point: integer:= 23;

component ParaHist is
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
		clk : in std_logic;
		rst : in std_logic;
		FIFO_Read_En : in std_logic; -- read enable for FIFO ram
		FIFO_Write_En : in std_logic; -- write enable for FIFO ram
		input_data : in std_logic_vector((EventWidth - 1) downto 0);
--		Packet_Event_En : out std_logic;
--		valid_out : out std_logic; -- valid when finishing
		empty : out std_logic; -- fifo is empty
		full : out std_logic; -- fifo is full
		NDE_NR_valid : out std_logic; -- valid means the ts is within the noise threshold value so no stall condition
		hist_size_out : out histsize2d; -- size of each elements in corresponding window
		hist_border : out SearchElement ---border of the histogram window
		-- URAMDA_NDE_out : out std_logic_vector((RAM2DBLOCK*DATA_WIDTH) + RAM2DBLOCK*13 + TS_WIDTH + 7*EventSearch2D -1  downto 0)
	);
end component;

signal CLK : std_logic;
signal rst : std_logic;
signal FIFO_Read_En : std_logic; -- read enable for FIFO ram
signal FIFO_Write_En : std_logic; -- write enable for FIFO ram
signal input_data : std_logic_vector((EventWidth - 1) downto 0);
signal empty : std_logic; -- fifo is empty
signal full : std_logic; -- fifo is full
signal NDE_NR_valid : std_logic; -- valid means the ts is within the noise threshold value so no stall condition
signal hist_size_out : histsize2d; -- size of each elements in corresponding window
signal hist_border : SearchElement; ---border of the histogram window
 begin
 -- TODO: Make an instance of the component to test and wire all signals to the corresponding
-- input or output.
  ParaHistdut: ParaHist
  generic map(PRECISION => PRECISION,
	EventWidth => EventWidth,
	EventSearchRadius => EventSearchRadius,
    Address_Width => Address_Width,
    DWIDTH => DWIDTH,
    NBPIPE => NBPIPE,
	RAMBLOCKADDR => RAMBLOCKADDR,
	RAM2DBLOCK => RAM2DBLOCK,
	TS_WIDTH => TS_WIDTH,
	AXIS_LENGTH => AXIS_LENGTH,
	DELTA_T_WIDTH => DELTA_T_WIDTH,
	Hist_Size => Hist_Size,
	Size_Width => Size_Width,
	DATA_WIDTH => DATA_WIDTH,
	FIFO_DEPTH =>FIFO_DEPTH)
  port map(
            CLK => CLK,
            rst => rst,
            FIFO_Read_En   => FIFO_Read_En,
            FIFO_Write_En => FIFO_Write_En,
            input_data  => input_data,
            empty   => empty,
			full => full,
			NDE_NR_valid => NDE_NR_valid,
			hist_size_out => hist_size_out,
			hist_border => hist_border);
			
 --This first process is to automate the clock for the test bench
  P_CLK: process
  begin
    CLK <= '1';
    wait for gCLK_HPER;
    CLK <= '0';
    wait for gCLK_HPER;
  end process;

    -- This process resets the processor.
  P_RST: process
  begin
  	rst <= '0';
    wait for gCLK_HPER/2;
	rst <= '1';
    wait for gCLK_HPER*2;
	rst <= '0';
	wait;
  end process;  
  	process
begin
FIFO_Read_En <= '1';
FIFO_Write_En <= '1';
input_data <= "0000000001000000001000000000000000000000000000000000000000001010";
-- input_data <= "0 0000000010 000000010 000000000000 00000000000000000000000000001010";

wait for 100 ns;
-- input_data <= "0 0000000110 000000010 000000000000 00000000000000000000000000001011";
input_data <= "0000000011000000001000000000000000000000000000000000000000001011";
end process;
end behavioral;