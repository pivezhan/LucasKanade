-------------------------------------------------------------------------
-- Mohammad Pivezhandi
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------
-- Flip-Flop with
-- Rising-edge Clock
-- Active-high Synchronous Clear
-- Active-high Clock Enable
-- File: registers_1.vhd

library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.LK_Package.all;
use work.all;

entity URAMAddressMapper_URAMDataAccess is
generic(EventWidth: natural:= EventWidth);
 port(
  clr, ce, clk : in  std_logic;
  URAMAM_URAMDA_ts_in : in std_logic_vector((TS_WIDTH-1) downto 0);
  URAMAM_URAMDA_border_in : in  SearchElement;
  URAMAM_URAMDA_ReadEnable_vec_in : in std_logic_vector((RAM2DBLOCK-1) downto 0);
  URAMAM_URAMDA_addr_within_block_vec_in : in std_vec_array1d;
  URAMAM_URAMDA_addr_of_block_search_in         : in Addr4BlockSearch2d;
  URAMAM_URAMDA_addr_within_block_search_in         : in AddrWithinBlockSearch2d;
  URAMAM_URAMDA_ts_out : out  std_logic_vector((TS_WIDTH-1) downto 0);
  URAMAM_URAMDA_border_out : out  SearchElement;
  URAMAM_URAMDA_ReadEnable_vec_out : out std_logic_vector((RAM2DBLOCK-1) downto 0);
  URAMAM_URAMDA_addr_within_block_vec_out : out std_vec_array1d;
  URAMAM_URAMDA_addr_of_block_search_out : out Addr4BlockSearch2d;
  URAMAM_URAMDA_addr_within_block_search_out : out AddrWithinBlockSearch2d);
end entity URAMAddressMapper_URAMDataAccess;

architecture rtl of URAMAddressMapper_URAMDataAccess is
component nregister_sync is
generic(N: natural:= DATA_WIDTH);
 port(
  clr, ce, clk : in  std_logic;
  d_in         : in  std_logic_vector((N-1) downto 0);
  dout         : out std_logic_vector((N-1) downto 0)
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
nregister_sync1: nregister_sync Generic map(N => TS_WIDTH)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => URAMAM_URAMDA_ts_in, 
dout => URAMAM_URAMDA_ts_out);	

nregister_sync2: nregister_sync Generic map(N => RAM2DBLOCK)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => URAMAM_URAMDA_ReadEnable_vec_in, 
dout => URAMAM_URAMDA_ReadEnable_vec_out);	

SearchElement_Reg1: SearchElement_Reg Generic map(N => EventWidth)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => URAMAM_URAMDA_border_in, 
dout => URAMAM_URAMDA_border_out);	

std_vec_array1d_Reg1: std_vec_array1d_Reg Generic map(N => EventWidth)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => URAMAM_URAMDA_addr_within_block_vec_in, 
dout => URAMAM_URAMDA_addr_within_block_vec_out);	

Addr4BlockSearch2dSyncReg1: Addr4BlockSearch2dSyncReg Generic map(N => EventWidth)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => URAMAM_URAMDA_addr_of_block_search_in, 
dout => URAMAM_URAMDA_addr_of_block_search_out);	

Addr_within_block_search_Reg1: Addr_within_block_search_Reg Generic map(N => EventWidth)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => URAMAM_URAMDA_addr_within_block_search_in, 
dout => URAMAM_URAMDA_addr_within_block_search_out);	

end architecture rtl;

