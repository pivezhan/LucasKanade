library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
library work;
use work.LK_Package.all;
use ieee.math_real.all;
use work.all;

entity NeighborhoodAddressGenerator  is
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
		Polarity : in std_logic;
		NAG_in_addr_x :in std_logic_vector((AXIS_LENGTH-1) downto 0);   -- event ts from DAVIS sensor
		NAG_in_addr_y :in std_logic_vector((AXIS_LENGTH-2) downto 0);   -- event ts from DAVIS sensor
		NAG_out_border : out SearchElement; -- 7*7 border definition
		NAG_out_addr_of_block_search : out Addr4BlockSearch2d;		-- addr of each block on search region dimension 7*7
		NAG_out_addr_within_block_search : out AddrWithinBlockSearch2d		-- addr of each element inside block on search region dimension 7*7
		);
end NeighborhoodAddressGenerator;

architecture behavioral of NeighborhoodAddressGenerator is

-- signal AddrWithinBlock : std_logic_vector((Address_Width -1) downto 0); -- The address of the location within block
-- signal BlockIndex : std_logic_vector(((2*RAMBLOCKADDR)-1) downto 0);
-- signal DecodedIndex : std_logic_vector((RAM2DBLOCK-1) downto 0);
signal temp_addr_Y : SearchRegionY;
signal temp_addr_X : SearchRegionX; -- temp_addr_Y: 8 bits of radius*radius, temp_addr_X: 9 bits of radius*radius,
signal IndexBoundaryArrayY : std_logic_vector((AXIS_LENGTH-2) downto 0); -- subaddr for block index
signal IndexBoundaryArrayX : std_logic_vector((AXIS_LENGTH-1) downto 0); -- subaddr for block index
signal borderX, borderY : SearchElement; -- Defines whether or nt we are in border region
signal xindex, yindex : integer;
--signal borderY : SearchElement;
-- signal MC_out_addr_YX : VectorSearchRegion; -- Address Output : type: 19, yaddr: 18:10, xaddr: 9:0
--signal border : std_logic_vector(((((2*EventSearchRadius)+1)*((2*EventSearchRadius)+1))-1) downto 0);--border signal 
type integer_array1d is array (EventSearchRadius downto -EventSearchRadius) of integer;
type integer_array2d is array (EventSearchRadius downto -EventSearchRadius) of integer_array1d;

-- signal we : std_array3d; 
-- signal withinblockaddr : std_vec_array3d; 

-- signal index :integer_array2d:=((others => (others=>0)));

begin				

xindex <= to_integer(unsigned(NAG_in_addr_x));
yindex <= to_integer(unsigned(NAG_in_addr_y));

-- AddrWithinBlock <= NAG_in_addr(19) & NAG_in_addr(17 downto 13) & NAG_in_addr(8 downto 3); -- this should add up to 12 bits of UltraRAM address
IndexBoundaryArrayY <= NAG_in_addr_y; -- temporary for boundary extraction
IndexBoundaryArrayX <= NAG_in_addr_x; -- temporary for boundary extraction

-- BlockIndex <= NAG_in_addr(12 downto 10) & NAG_in_addr(2 downto 0); -- block index should be (5 downto 0)
--MC_out_we <= DecodedIndex when (MC_in_we='1' and MC_in_WB='0') else (others => '0');
--MC_out_regce <= DecodedIndex when (MC_in_regce='1' and MC_in_WB='0') else (others => '0');
--MC_out_mem_en <= DecodedIndex when (MC_in_mem_en='1' and MC_in_WB='0') else (others => '0');

----- WB section for storing modified values-----
row:	for i in -EventSearchRadius to EventSearchRadius generate -- Y_addr
col: 		for j in -EventSearchRadius to EventSearchRadius generate -- X_addr
			check_right_boundary: if (j>=0) generate
			-- temp_addr_X(i)(j) <= (std_logic_vector(to_signed(j,IndexBoundaryArrayX'length)) + IndexBoundaryArrayX) when (IndexBoundaryArrayX /= "0011110000") else IndexBoundaryArrayX;
			-- borderX(i)(j) <= '0' when (to_integer(unsigned(IndexBoundaryArrayX)) > "0011110000") else '1';
			temp_addr_X(i)(j) <= std_logic_vector(to_unsigned(xindex,AXIS_LENGTH)) when ((j + xindex) > 239) else std_logic_vector(to_signed((j + xindex),AXIS_LENGTH));
			borderX(i)(j) <= '1' when ((j + xindex) > 239) else '0';
			end generate;	   
			check_left_boundary: if (j<0) generate
			-- temp_addr_X(i)(j) <= (std_logic_vector(to_signed(j,IndexBoundaryArrayX'length)) + IndexBoundaryArrayX) when (IndexBoundaryArrayX /= "0000000000") else IndexBoundaryArrayX;
			-- borderX(i)(j) <= '0' when (IndexBoundaryArrayX /= "0000000000") else '1';
			temp_addr_X(i)(j) <=  std_logic_vector(to_unsigned(xindex,AXIS_LENGTH)) when ((j + xindex) < 0) else std_logic_vector(to_signed((j + xindex),AXIS_LENGTH));
			borderX(i)(j) <= '1' when ((j + xindex) < 0) else '0';
			end generate;
			check_top_boundary: if (i>=0) generate
			-- temp_addr_Y(i)(j) <= (std_logic_vector(to_signed(i,IndexBoundaryArrayY'length)) + IndexBoundaryArrayY) when (IndexBoundaryArrayY /= "010110100") else IndexBoundaryArrayY;
			-- borderY(i)(j) <= '1' when (to_integer(unsigned(IndexBoundaryArrayY)) > 179) else '0';
			temp_addr_Y(i)(j) <=  std_logic_vector(to_unsigned(yindex,AXIS_LENGTH-1)) when ((i + yindex) > 179) else std_logic_vector(to_unsigned((i + yindex), AXIS_LENGTH-1));
			borderY(i)(j) <= '1' when ((i + yindex) > 179) else '0';
			end generate;	   
			check_bottom_boundary: if (i<0) generate
			-- temp_addr_Y(i)(j) <= (std_logic_vector(to_signed(i,IndexBoundaryArrayY'length)) + IndexBoundaryArrayY) when (IndexBoundaryArrayY /= "000000000") else IndexBoundaryArrayY;
			-- borderY(i)(j) <= '1' when (to_integer(unsigned(IndexBoundaryArrayY)) < 0) else '0';
			temp_addr_Y(i)(j) <= std_logic_vector(to_unsigned(yindex,AXIS_LENGTH-1)) when ((i + yindex) < 0) else std_logic_vector(to_unsigned((i + yindex), AXIS_LENGTH-1));
			borderY(i)(j) <= '1' when ((i + yindex) < 0) else '0';
			end generate;
			NAG_out_border(i)(j) <= borderY(i)(j) or borderX(i)(j);
			NAG_out_addr_of_block_search(i)(j) <= (temp_addr_X(i)(j)(2 downto 0) & temp_addr_Y(i)(j)(2 downto 0));
			NAG_out_addr_within_block_search(i)(j) <= (Polarity & temp_addr_X(i)(j)(8 downto 3) & temp_addr_Y(i)(j)(7 downto 3));
				-- MC_out_we()(integer(to_unsigned(MC_out_addr_X(i)(j)((AXIS_LENGTH-5) downto 0)))) <= '1';
			end generate;
		end generate; 

-- tot: for k in 0 to (RAM2DBLOCK-1) generate
-- row2:	for i in -EventSearchRadius to EventSearchRadius generate -- Y_addr
-- col2: 		for j in -EventSearchRadius to EventSearchRadius generate -- X_addr
				-- we(i)(j)(k) <= '1' when (index(i)(j)=k) else '0';
				-- withinblockaddr(i)(j)(k) <= NAG_out_addr_within_block_search(i)(j) when (index(i)(j)=k) else (others => '0');
			-- end generate;
		-- end generate;
	-- end generate;


-- g1 : if EventSearchRadius = 2 generate
	-- finalwe1: for k in 0 to (RAM2DBLOCK-1) generate
		-- WriteEnable(k) <= we(1)(1)(k) or we(1)(0)(k) or 
		-- we(1)(-1)(k) or we(0)(1)(k) or we(0)(0)(k) or 
		-- we(0)(-1)(k) or we(-1)(1)(k) or we(-1)(0)(k) or
		-- we(-1)(-1)(k);
	-- end generate;
	-- end generate;

--gg1: if EventSearchRadius = 2 generate
--	finalwe2: for k in 0 to (RAM2DBLOCK-1) generate
--		WriteEnable(k) <= we(2)(2)(k) or we(2)(1)(k) or we(2)(0)(k) or 
--		we(2)(-1)(k) or we(2)(-2)(k) or we(1)(2)(k) or 
--		we(1)(1)(k) or we(1)(0)(k) or we(1)(-1)(k) or 
--		we(1)(-2)(k) or we(0)(2)(k) or we(0)(1)(k) or 
--		we(0)(0)(k) or we(-1)(2)(k) or we(-1)(1)(k) or 
--		we(-1)(0)(k) or we(-1)(-1)(k) or we(-1)(-2)(k) or 
--		we(-2)(2)(k) or we(-2)(1)(k) or we(-2)(0)(k) or 
--		we(-2)(-1)(k) or we(-2)(-2)(k);
--	end generate;  
--end generate;

--ggg1: if EventSearchRadius = 3 generate
--	finalwe3: for k in 0 to (RAM2DBLOCK-1) generate
--		WriteEnable(k) <= we(3)(3)(k) or we(3)(2)(k) or 
--		we(3)(1)(k) or we(3)(0)(k) or we(3)(-1)(k) or 
--		we(3)(-2)(k) or we(3)(-3)(k) or we(2)(3)(k) or 
--		we(2)(2)(k) or we(2)(1)(k) or we(2)(0)(k) or 
--		we(2)(-1)(k) or we(2)(-2)(k) or we(2)(-3)(k) or 
--		we(1)(3)(k) or we(1)(2)(k) or we(1)(1)(k) or
--		we(1)(0)(k) or we(1)(-1)(k) or we(1)(-2)(k) or
--		we(1)(-3)(k) or we(0)(3)(k) or we(0)(2)(k) or
--		we(0)(1)(k) or we(0)(0)(k) or we(-1)(3)(k) or
--		we(-1)(2)(k) or we(-1)(1)(k) or we(-1)(0)(k) or
--		we(-1)(-1)(k) or we(-1)(-2)(k) or we(-1)(-3)(k) or
--		we(-2)(3)(k) or we(-2)(2)(k) or we(-2)(1)(k) or
--		we(-2)(0)(k) or we(-2)(-1)(k) or we(-2)(-2)(k) or
--		we(-2)(-3)(k) or we(-3)(3)(k) or we(-3)(2)(k) or
--		we(-3)(1)(k) or we(-3)(0)(k) or we(-3)(-1)(k) or
--		we(-3)(-2)(k) or we(-3)(-2)(k);
--	end generate;
--end generate;

-- g2 : if EventSearchRadius = 1 generate
	-- finaladdr: for k in 0 to (RAM2DBLOCK-1) generate
		-- NAG_out_addr_within_block_vec(k) <= withinblockaddr(1)(1)(k) or withinblockaddr(1)(0)(k) or 
		-- withinblockaddr(1)(-1)(k) or withinblockaddr(0)(1)(k) or withinblockaddr(0)(0)(k) or 
		-- withinblockaddr(0)(-1)(k) or withinblockaddr(-1)(1)(k) or withinblockaddr(-1)(0)(k) or
		-- withinblockaddr(-1)(-1)(k);
	-- end generate;
-- end generate;

--gg2: if EventSearchRadius = 2 generate
--	finalwe2: for k in 0 to (RAM2DBLOCK-1) generate
--		NAG_out_addr_within_block_vec(k) <= withinblockaddr(2)(2)(k) or withinblockaddr(2)(1)(k) 
--		or withinblockaddr(2)(0)(k) or withinblockaddr(2)(-1)(k) or 
--		withinblockaddr(2)(-2)(k) or withinblockaddr(1)(2)(k) or 
--		withinblockaddr(1)(1)(k) or withinblockaddr(1)(0)(k) or 
--		withinblockaddr(1)(-1)(k) or withinblockaddr(1)(-2)(k) or 
--		withinblockaddr(0)(2)(k) or withinblockaddr(0)(1)(k) or 
--		withinblockaddr(0)(0)(k) or withinblockaddr(-1)(2)(k) or 
--		withinblockaddr(-1)(1)(k) or withinblockaddr(-1)(0)(k) or 
--		withinblockaddr(-1)(-1)(k) or withinblockaddr(-1)(-2)(k) or 
--		withinblockaddr(-2)(2)(k) or withinblockaddr(-2)(1)(k) or 
--		withinblockaddr(-2)(0)(k) or withinblockaddr(-2)(-1)(k) or withinblockaddr(-2)(-2)(k);
--	end generate;  
--end generate;
--
--ggg2: if EventSearchRadius = 3 generate
--	finalwe3: for k in 0 to (RAM2DBLOCK-1) generate
--		NAG_out_addr_within_block_vec(k) <= we(3)(3)(k) or we(3)(2)(k) or 
--		we(3)(1)(k) or we(3)(0)(k) or we(3)(-1)(k) or 
--		we(3)(-2)(k) or we(3)(-3)(k) or we(2)(3)(k) or 
--		we(2)(2)(k) or we(2)(1)(k) or we(2)(0)(k) or 
--		we(2)(-1)(k) or we(2)(-2)(k) or we(2)(-3)(k) or 
--		we(1)(3)(k) or we(1)(2)(k) or we(1)(1)(k) or
--		we(1)(0)(k) or we(1)(-1)(k) or we(1)(-2)(k) or
--		we(1)(-3)(k) or we(0)(3)(k) or we(0)(2)(k) or
--		we(0)(1)(k) or we(0)(0)(k) or we(-1)(3)(k) or
--		we(-1)(2)(k) or we(-1)(1)(k) or we(-1)(0)(k) or
--		we(-1)(-1)(k) or we(-1)(-2)(k) or we(-1)(-3)(k) or
--		we(-2)(3)(k) or we(-2)(2)(k) or we(-2)(1)(k) or
--		we(-2)(0)(k) or we(-2)(-1)(k) or we(-2)(-2)(k) or
--		we(-2)(-3)(k) or we(-3)(3)(k) or we(-3)(2)(k) or
--		we(-3)(1)(k) or we(-3)(0)(k) or we(-3)(-1)(k) or
--		we(-3)(-2)(k) or we(-3)(-2)(k);
--	end generate;
--end generate;
--
--
-- border_out <= border;
--output_7 <= to_integer(unsigned("001",3));
-- MC_out_we(1)(to_integer(unsigned(MC_out_addr_X(1)(1)((AXIS_LENGTH-5) downto 0)))) <= '1';
-- 				y <= to_integer(unsigned("111"));
--				x <= to_integer(unsigned("001"));

----- decode section for ts write ----------
-- ramblocks: 	for k in 0 to (RAM2DBLOCK-1) generate
-- row2:			for i in -EventSearchRadius to EventSearchRadius generate -- Y_addr
-- col2: 				for j in -EventSearchRadius to EventSearchRadius generate -- X_addr
					-- MC_out_we(k) <= '1' when ((to_integer(unsigned(temp_addr_Y(i)(j)(2 downto 0) & temp_addr_X(i)(j)(2 downto 0))) = k) and (border(i)(j)='0')) else '0';
					-- MC_out_regce(k) <= '1' when ((to_integer(unsigned(temp_addr_Y(i)(j)(2 downto 0) & temp_addr_X(i)(j)(2 downto 0))) = k) and (border(i)(j)='0')) else '0';
					-- MC_out_mem_en(k) <= '1' when ((to_integer(unsigned(temp_addr_Y(i)(j)(2 downto 0) & temp_addr_X(i)(j)(2 downto 0))) = k) and (border(i)(j)='0')) else '0';
					-- MC_out_addr(k) <= (MC_in_addr(19) & temp_addr_Y(i)(j)(7 downto 3) & temp_addr_X(i)(j)(8 downto 3))
					-- when ((to_integer(unsigned(temp_addr_Y(i)(j)(2 downto 0) &  temp_addr_X(i)(j)(2 downto 0))) = k) and (border(i)(j)='0')) else (others => '0');
					-- end generate;
				-- end generate;
			-- end generate;

--with BlockIndex(6 downto 1) select DecodedIndex <=
--    "0000000000000000000000000000000000000000000000000000000000000001" when "000000",
--    "0000000000000000000000000000000000000000000000000000000000000010" when "000001",
--    "0000000000000000000000000000000000000000000000000000000000000100" when "000010",
--    "0000000000000000000000000000000000000000000000000000000000001000" when "000011",
--    "0000000000000000000000000000000000000000000000000000000000010000" when "000100",
--    "0000000000000000000000000000000000000000000000000000000000100000" when "000101",
--    "0000000000000000000000000000000000000000000000000000000001000000" when "000110",
--    "0000000000000000000000000000000000000000000000000000000010000000" when "000111",
--    "0000000000000000000000000000000000000000000000000000000100000000" when "001000",
--    "0000000000000000000000000000000000000000000000000000001000000000" when "001001",
--    "0000000000000000000000000000000000000000000000000000010000000000" when "001010",
--    "0000000000000000000000000000000000000000000000000000100000000000" when "001011",
--    "0000000000000000000000000000000000000000000000000001000000000000" when "001100",
--    "0000000000000000000000000000000000000000000000000010000000000000" when "001101",
--    "0000000000000000000000000000000000000000000000000100000000000000" when "001110",
--    "0000000000000000000000000000000000000000000000001000000000000000" when "001111",
--    "0000000000000000000000000000000000000000000000010000000000000000" when "010000",
--    "0000000000000000000000000000000000000000000000100000000000000000" when "010001",
--    "0000000000000000000000000000000000000000000001000000000000000000" when "010010",
--    "0000000000000000000000000000000000000000000010000000000000000000" when "010011",
--    "0000000000000000000000000000000000000000000100000000000000000000" when "010100",
--    "0000000000000000000000000000000000000000001000000000000000000000" when "010101",
--    "0000000000000000000000000000000000000000010000000000000000000000" when "010110",
--    "0000000000000000000000000000000000000000100000000000000000000000" when "010111",
--    "0000000000000000000000000000000000000001000000000000000000000000" when "011000",
--    "0000000000000000000000000000000000000010000000000000000000000000" when "011001",
--    "0000000000000000000000000000000000000100000000000000000000000000" when "011010",
--    "0000000000000000000000000000000000001000000000000000000000000000" when "011011",
--    "0000000000000000000000000000000000010000000000000000000000000000" when "011100",
--    "0000000000000000000000000000000000100000000000000000000000000000" when "011101",
--    "0000000000000000000000000000000001000000000000000000000000000000" when "011110",
--    "0000000000000000000000000000000010000000000000000000000000000000" when "011111",
--    "0000000000000000000000000000000100000000000000000000000000000000" when "100000",
--    "0000000000000000000000000000001000000000000000000000000000000000" when "100001",
--    "0000000000000000000000000000010000000000000000000000000000000000" when "100010",
--    "0000000000000000000000000000100000000000000000000000000000000000" when "100011",
--    "0000000000000000000000000001000000000000000000000000000000000000" when "100100",
--    "0000000000000000000000000010000000000000000000000000000000000000" when "100101",
--    "0000000000000000000000000100000000000000000000000000000000000000" when "100110",
--    "0000000000000000000000001000000000000000000000000000000000000000" when "100111",
--    "0000000000000000000000010000000000000000000000000000000000000000" when "101000",
--    "0000000000000000000000100000000000000000000000000000000000000000" when "101001",
--    "0000000000000000000001000000000000000000000000000000000000000000" when "101010",
--    "0000000000000000000010000000000000000000000000000000000000000000" when "101011",
--    "0000000000000000000100000000000000000000000000000000000000000000" when "101100",
--    "0000000000000000001000000000000000000000000000000000000000000000" when "101101",
--    "0000000000000000010000000000000000000000000000000000000000000000" when "101110",
--    "0000000000000000100000000000000000000000000000000000000000000000" when "101111",
--    "0000000000000001000000000000000000000000000000000000000000000000" when "110000",
--    "0000000000000010000000000000000000000000000000000000000000000000" when "110001",
--    "0000000000000100000000000000000000000000000000000000000000000000" when "110010",
--    "0000000000001000000000000000000000000000000000000000000000000000" when "110011",
--    "0000000000010000000000000000000000000000000000000000000000000000" when "110100",
--    "0000000000100000000000000000000000000000000000000000000000000000" when "110101",
--    "0000000001000000000000000000000000000000000000000000000000000000" when "110110",
--    "0000000010000000000000000000000000000000000000000000000000000000" when "110111",
--    "0000000100000000000000000000000000000000000000000000000000000000" when "111000",
--    "0000001000000000000000000000000000000000000000000000000000000000" when "111001",
--    "0000010000000000000000000000000000000000000000000000000000000000" when "111010",
--    "0000100000000000000000000000000000000000000000000000000000000000" when "111011",
--    "0001000000000000000000000000000000000000000000000000000000000000" when "111100",
--    "0010000000000000000000000000000000000000000000000000000000000000" when "111101",
--    "0100000000000000000000000000000000000000000000000000000000000000" when "111110",
--    "1000000000000000000000000000000000000000000000000000000000000000" when "111111",
--    "0000000000000000000000000000000000000000000000000000000000000000" when others;


end behavioral;