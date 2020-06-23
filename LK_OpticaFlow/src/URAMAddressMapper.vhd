library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.LK_Package.all;
use ieee.math_real.all;
use work.all;

entity URAMAddressMapper  is
generic (
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
port    (
		URAM_AM_in_addr_of_block_search : in Addr4BlockSearch2d;		-- addr of each block on search region dimension 7*7
		URAM_AM_in_addr_within_block_search : in AddrWithinBlockSearch2d;		-- addr of each element inside block on search region dimension 7*7
		-- URAM_AM_in_border : in SearchElement; -- 7*7 border definition
		URAM_AM_out_addr_within_block_vec : out std_vec_array1d;		-- addr of each element inside block on search region dimension 7*7
		URAM_AM_ReadEnable_vec : out std_logic_vector((RAM2DBLOCK-1) downto 0)
		);
end URAMAddressMapper;

architecture behavioral of URAMAddressMapper is

--type integer_array1d is array (EventSearchRadius downto -EventSearchRadius) of integer;
--type integer_array2d is array (EventSearchRadius downto -EventSearchRadius) of integer_array1d;
--signal index :integer_array2d:=((others => (others=>0)));

signal withinblockaddr : std_vec_array3d; 
signal re : std_array3d; 

begin				

tot: for k in 0 to (RAM2DBLOCK-1) generate
row1:	for i in -EventSearchRadius to EventSearchRadius generate -- Y_addr
col1: 		for j in -EventSearchRadius to EventSearchRadius generate -- X_addr
				re(i)(j)(k) <= '1' when (unsigned(URAM_AM_in_addr_of_block_search(i)(j))=k) else '0';
				withinblockaddr(i)(j)(k) <= URAM_AM_in_addr_within_block_search(i)(j) when (unsigned(URAM_AM_in_addr_of_block_search(i)(j))=k) else (others => '0');
--			cond1: if (k=0) generate
--			URAM_AM_ReadEnable_vec(k) <=  re(i)(j)(k);
--			end generate;
        end generate;
        end generate;
    end generate;

--r1: if EventSearchRadius = 1 generate
--	finalwe1: for k in 0 to (RAM2DBLOCK-1) generate
--		URAM_AM_ReadEnable_vec(k) <= re(1)(1)(k) or re(1)(0)(k) or 
--		re(1)(-1)(k) or re(0)(1)(k) or re(0)(0)(k) or 
--		re(0)(-1)(k) or re(-1)(1)(k) or re(-1)(0)(k) or
--		re(-1)(-1)(k);
--		URAM_AM_out_addr_within_block_vec(k) <= withinblockaddr(1)(1)(k) or withinblockaddr(1)(0)(k) or 
--		withinblockaddr(1)(-1)(k) or withinblockaddr(0)(1)(k) or withinblockaddr(0)(0)(k) or 
--		withinblockaddr(0)(-1)(k) or withinblockaddr(-1)(1)(k) or withinblockaddr(-1)(0)(k) or
--		withinblockaddr(-1)(-1)(k);
--	end generate;
--end generate;

-- r2: if EventSearchRadius = 2 generate
--	 finalwe2: for k in 0 to (RAM2DBLOCK-1) generate
--		 URAM_AM_ReadEnable_vec(k) <= re(2)(2)(k) or re(2)(1)(k) or re(2)(0)(k) or 
--		 re(2)(-1)(k) or re(2)(-2)(k) or re(1)(2)(k) or 
--		 re(1)(1)(k) or re(1)(0)(k) or re(1)(-1)(k) or 
--		 re(1)(-2)(k) or re(0)(2)(k) or re(0)(1)(k) or 
--		 re(0)(0)(k) or re(-1)(2)(k) or re(-1)(1)(k) or 
--		 re(-1)(0)(k) or re(-1)(-1)(k) or re(-1)(-2)(k) or 
--		 re(-2)(2)(k) or re(-2)(1)(k) or re(-2)(0)(k) or 
--		 re(-2)(-1)(k) or re(-2)(-2)(k);
--		 URAM_AM_out_addr_within_block_vec(k) <= withinblockaddr(2)(2)(k) or withinblockaddr(2)(1)(k) 
--		 or withinblockaddr(2)(0)(k) or withinblockaddr(2)(-1)(k) or 
--		 withinblockaddr(2)(-2)(k) or withinblockaddr(1)(2)(k) or 
--		 withinblockaddr(1)(1)(k) or withinblockaddr(1)(0)(k) or 
--		 withinblockaddr(1)(-1)(k) or withinblockaddr(1)(-2)(k) or 
--		 withinblockaddr(0)(2)(k) or withinblockaddr(0)(1)(k) or 
--		 withinblockaddr(0)(0)(k) or withinblockaddr(-1)(2)(k) or 
--		 withinblockaddr(-1)(1)(k) or withinblockaddr(-1)(0)(k) or 
--		 withinblockaddr(-1)(-1)(k) or withinblockaddr(-1)(-2)(k) or 
--		 withinblockaddr(-2)(2)(k) or withinblockaddr(-2)(1)(k) or 
--		 withinblockaddr(-2)(0)(k) or withinblockaddr(-2)(-1)(k) or withinblockaddr(-2)(-2)(k);
--	 end generate;  
-- end generate;

-- --
 r3: if EventSearchRadius = 3 generate
	 finalwe3: for k in 0 to (RAM2DBLOCK-1) generate
		 URAM_AM_ReadEnable_vec(k) <= re(3)(3)(k) or re(3)(2)(k) or 
		 re(3)(1)(k) or re(3)(0)(k) or re(3)(-1)(k) or 
		 re(3)(-2)(k) or re(3)(-3)(k) or re(2)(3)(k) or 
		 re(2)(2)(k) or re(2)(1)(k) or re(2)(0)(k) or 
		 re(2)(-1)(k) or re(2)(-2)(k) or re(2)(-3)(k) or 
		 re(1)(3)(k) or re(1)(2)(k) or re(1)(1)(k) or
		 re(1)(0)(k) or re(1)(-1)(k) or re(1)(-2)(k) or
		 re(1)(-3)(k) or re(0)(3)(k) or re(0)(2)(k) or
		 re(0)(1)(k) or re(0)(0)(k) or re(-1)(3)(k) or
		 re(-1)(2)(k) or re(-1)(1)(k) or re(-1)(0)(k) or
		 re(-1)(-1)(k) or re(-1)(-2)(k) or re(-1)(-3)(k) or
		 re(-2)(3)(k) or re(-2)(2)(k) or re(-2)(1)(k) or
		 re(-2)(0)(k) or re(-2)(-1)(k) or re(-2)(-2)(k) or
		 re(-2)(-3)(k) or re(-3)(3)(k) or re(-3)(2)(k) or
		 re(-3)(1)(k) or re(-3)(0)(k) or re(-3)(-1)(k) or
		 re(-3)(-2)(k) or re(-3)(-2)(k);
		 URAM_AM_out_addr_within_block_vec(k) <= withinblockaddr(3)(3)(k) or withinblockaddr(3)(2)(k) or 
		 withinblockaddr(3)(1)(k) or withinblockaddr(3)(0)(k) or withinblockaddr(3)(-1)(k) or 
		 withinblockaddr(3)(-2)(k) or withinblockaddr(3)(-3)(k) or withinblockaddr(2)(3)(k) or 
		 withinblockaddr(2)(2)(k) or withinblockaddr(2)(1)(k) or withinblockaddr(2)(0)(k) or 
		 withinblockaddr(2)(-1)(k) or withinblockaddr(2)(-2)(k) or withinblockaddr(2)(-3)(k) or 
		 withinblockaddr(1)(3)(k) or withinblockaddr(1)(2)(k) or withinblockaddr(1)(1)(k) or
		 withinblockaddr(1)(0)(k) or withinblockaddr(1)(-1)(k) or withinblockaddr(1)(-2)(k) or
		 withinblockaddr(1)(-3)(k) or withinblockaddr(0)(3)(k) or withinblockaddr(0)(2)(k) or
		 withinblockaddr(0)(1)(k) or withinblockaddr(0)(0)(k) or withinblockaddr(-1)(3)(k) or
		 withinblockaddr(-1)(2)(k) or withinblockaddr(-1)(1)(k) or withinblockaddr(-1)(0)(k) or
		 withinblockaddr(-1)(-1)(k) or withinblockaddr(-1)(-2)(k) or withinblockaddr(-1)(-3)(k) or
		 withinblockaddr(-2)(3)(k) or withinblockaddr(-2)(2)(k) or withinblockaddr(-2)(1)(k) or
		 withinblockaddr(-2)(0)(k) or withinblockaddr(-2)(-1)(k) or withinblockaddr(-2)(-2)(k) or
		 withinblockaddr(-2)(-3)(k) or withinblockaddr(-3)(3)(k) or withinblockaddr(-3)(2)(k) or
		 withinblockaddr(-3)(1)(k) or withinblockaddr(-3)(0)(k) or withinblockaddr(-3)(-1)(k) or
		 withinblockaddr(-3)(-2)(k) or withinblockaddr(-3)(-2)(k);
	 end generate;
 end generate;


end behavioral;