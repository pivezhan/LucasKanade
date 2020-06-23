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

entity array_deltat2d_Reg is
generic(N: natural:= DATA_WIDTH);
 port(
  clr, ce, clk : in  std_logic;
  d_in         : in  array_deltat2d;
  dout         : out array_deltat2d
 );
end entity array_deltat2d_Reg;

architecture rtl of array_deltat2d_Reg is
begin
process(clk) is
 begin
  if rising_edge(clk) then
     if clr = '1' then
		dout <= (others=> (others => (others => (others => '0'))));
     elsif ce = '1' then
    dout <= d_in;
   end if;
  end if;
end process;
end architecture rtl;

