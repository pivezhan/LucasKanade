-------------------------------------------------------------------------
-- Mohammad Pivezhandi
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------
-- Flip-Flop with
-- Rising-edge Clock
-- Active-high Asynchronous Clear
-- Active-high Clock Enable
-- File: registers_1.vhd

library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.LK_Package.all;
use work.all;

entity PrefixAdder_Decompression is
generic(EventWidth: natural:= EventWidth);
 port(
  clr, ce, clk : in  std_logic;
  PA_De_ts_in : in std_logic_vector((TS_WIDTH-1) downto 0);
  PA_De_border_in : in  SearchElement;
  PA_De_ReadEnable_vec_in : in std_logic_vector((RAM2DBLOCK-1) downto 0);
  PA_De_addr_within_block_vec_in : in std_vec_array1d;
  PA_De_addr_of_block_search_in : in Addr4BlockSearch2d;
  PA_De_addr_within_block_search_in : in AddrWithinBlockSearch2d;
  PA_De_doutb_in: in data_std_array1d;
  PA_De_out_data_in: in RAMArraySearchRegion;
  PA_De_valid_in: in std_logic;
  PA_De_prefixadder_in: in array_deltat2d;
  PA_De_ts_out : out  std_logic_vector((TS_WIDTH-1) downto 0);
  PA_De_border_out : out  SearchElement;
  PA_De_ReadEnable_vec_out : out std_logic_vector((RAM2DBLOCK-1) downto 0);
  PA_De_addr_within_block_vec_out : out std_vec_array1d;
  PA_De_addr_of_block_search_out : out Addr4BlockSearch2d;
  PA_De_addr_within_block_search_out : out AddrWithinBlockSearch2d;
  PA_De_doutb_out: out data_std_array1d;
  PA_De_out_data_out: out RAMArraySearchRegion;
  PA_De_valid_out: out std_logic;
  PA_De_prefixadder_out: out array_deltat2d);
  end entity PrefixAdder_Decompression;

architecture rtl of PrefixAdder_Decompression is

component array_deltat2d_Reg is
generic(N: natural:= DATA_WIDTH);
 port(
  clr, ce, clk : in  std_logic;
  d_in         : in  array_deltat2d;
  dout         : out array_deltat2d
 );
end component;

component gdff is
  port(i_CLK        : in std_logic;     -- Clock input
       i_RST        : in std_logic;     -- Reset input
       i_WE         : in std_logic;     -- Write enable input
       i_D          : in std_logic;     -- Data value input
       o_Q          : out std_logic);   -- Data value output
end component;

component nregister_sync is
generic(N: natural:= DATA_WIDTH);
 port(
  clr, ce, clk : in  std_logic;
  d_in         : in  std_logic_vector((N-1) downto 0);
  dout         : out std_logic_vector((N-1) downto 0)
 );
end component;

component RAMArraySearchRegion_Reg is
generic(N: natural:= DATA_WIDTH);
 port(
  clr, ce, clk : in  std_logic;
  d_in         : in  RAMArraySearchRegion;
  dout         : out RAMArraySearchRegion
 );
end component;

component data_std_array1d_Reg is
generic(N: natural:= DATA_WIDTH);
 port(
  clr, ce, clk : in  std_logic;
  d_in         : in  data_std_array1d;
  dout         : out data_std_array1d
 );
end component;

component std_vec_array1d_Reg is
generic(N: natural:= DATA_WIDTH);
 port(
  clr, ce, clk : in  std_logic;
  d_in         : in  std_vec_array1d;
  dout         : out std_vec_array1d
 );
end component;

component SearchElement_Reg is
generic(N: natural:= DATA_WIDTH);
 port(
  clr, ce, clk : in  std_logic;
  d_in         : in  SearchElement;
  dout         : out SearchElement
 );
end component;

component Addr4BlockSearch2dSyncReg is
generic(N: natural:= DATA_WIDTH);
 port(
  clr, ce, clk : in  std_logic;
  d_in         : in  Addr4BlockSearch2d;
  dout         : out Addr4BlockSearch2d
 );
end component;

component Addr_within_block_search_Reg is
generic(N: natural:= DATA_WIDTH);
 port(
  clr, ce, clk : in  std_logic;
  d_in         : in  AddrWithinBlockSearch2d;
  dout         : out AddrWithinBlockSearch2d
 );
end component;

begin

array_deltat2d_Reg1: array_deltat2d_Reg Generic map(N => TS_WIDTH)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => PA_De_prefixadder_in, 
dout => PA_De_prefixadder_out);

Dff1: gdff port map(i_CLK => clk,     -- Clock input
       i_RST => clr,     -- Reset input
       i_WE => ce,     -- Write enable input
       i_D => PA_De_valid_in,     -- Data value input
       o_Q => PA_De_valid_out);   -- Data value output

nregister_sync1: nregister_sync Generic map(N => TS_WIDTH)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => PA_De_ts_in, 
dout => PA_De_ts_out);	

nregister_sync2: nregister_sync Generic map(N => RAM2DBLOCK)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => PA_De_ReadEnable_vec_in, 
dout => PA_De_ReadEnable_vec_out);	

RAMArraySearchRegion_Reg1: RAMArraySearchRegion_Reg Generic map(N => RAM2DBLOCK)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => PA_De_out_data_in, 
dout => PA_De_out_data_out);

data_std_array1d_Reg1: data_std_array1d_Reg Generic map(N => EventWidth)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => PA_De_doutb_in, 
dout => PA_De_doutb_out);	

SearchElement_Reg1: SearchElement_Reg Generic map(N => EventWidth)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => PA_De_border_in, 
dout => PA_De_border_out);	

std_vec_array1d_Reg1: std_vec_array1d_Reg Generic map(N => EventWidth)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => PA_De_addr_within_block_vec_in, 
dout => PA_De_addr_within_block_vec_out);	

Addr4BlockSearch2dSyncReg1: Addr4BlockSearch2dSyncReg Generic map(N => EventWidth)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => PA_De_addr_of_block_search_in, 
dout => PA_De_addr_of_block_search_out);	

Addr_within_block_search_Reg1: Addr_within_block_search_Reg Generic map(N => EventWidth)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => PA_De_addr_within_block_search_in, 
dout => PA_De_addr_within_block_search_out);	

end architecture rtl;
