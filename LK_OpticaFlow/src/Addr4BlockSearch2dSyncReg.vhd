-------------------------------------------------------------------------
-- Mohammad Pivezhandi
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------
-- Module: pipeline with Rising-edge Clock
-- Active-high Synchronous Clear
-- Active-high Clock Enable
-- File: Addr4BlockSearch2dSyncReg.vhd
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.LK_Package.all;
use work.all;

entity Addr4BlockSearch2dSyncReg is
generic(N: natural:= DATA_WIDTH);
 port(
  clr, ce, clk : in  std_logic;
  d_in         : in  Addr4BlockSearch2d;
  dout         : out Addr4BlockSearch2d
 );
end entity Addr4BlockSearch2dSyncReg;

architecture rtl of Addr4BlockSearch2dSyncReg is
begin
 process(clk) is
 begin
  if rising_edge(clk) then
     if clr = '1' then
     dout <= (others=> (others=> (others=>'0')));
     elsif ce = '1' then
    dout <= d_in;
   end if;
  end if;
 end process;
end architecture rtl;

