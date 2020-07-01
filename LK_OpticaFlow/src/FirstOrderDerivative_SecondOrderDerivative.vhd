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

entity FirstOrderDerivative_SecondOrderDerivative is
port(
	clr, ce, clk : in  std_logic;
	FOD_SOD_dt_in : in histsize2d_grad; -- temporal derivation
	FOD_SOD_dx_in : in histsize2d_grad; -- sptial derivation on x axis
	FOD_SOD_dy_in : in histsize2d_grad;  -- sptial derivation on y axis
	FOD_SOD_dt_out : out histsize2d_grad; -- temporal derivation
	FOD_SOD_dx_out : out histsize2d_grad; -- sptial derivation on x axis
	FOD_SOD_dy_out : out histsize2d_grad); -- sptial derivation on y axis
end entity FirstOrderDerivative_SecondOrderDerivative;

architecture rtl of FirstOrderDerivative_SecondOrderDerivative is

component histsize2d_grad_Reg is
 port(
  clr, ce, clk : in  std_logic;
  d_in         : in  histsize2d_grad;
  dout         : out histsize2d_grad
 );
end component histsize2d_grad_Reg;

begin

histsize2d_grad_Reg1: histsize2d_grad_Reg
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => FOD_SOD_dt_in, 
dout => FOD_SOD_dt_out);

histsize2d_grad_Reg2: histsize2d_grad_Reg
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => FOD_SOD_dx_in, 
dout => FOD_SOD_dx_out);

histsize2d_grad_Reg3: histsize2d_grad_Reg
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => FOD_SOD_dy_in, 
dout => FOD_SOD_dy_out);

end architecture rtl;

