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

entity SecondOrderDerivative_Collector is
port(
	clr, ce, clk : in  std_logic;
	SOD_Clt_dt_ij_in : in std_logic_vector((Size_Width-1) downto 0); -- temporal derivation
	SOD_Clt_dx_ij_in : in std_logic_vector((Size_Width-1) downto 0); -- sptial derivation on x axis
	SOD_Clt_dy_ij_in : in std_logic_vector((Size_Width-1) downto 0);  -- sptial derivation on y axis
	SOD_Clt_dx2_in : in histsize2d_grad; -- sptial derivation second order
	SOD_Clt_dy2_in : in histsize2d_grad; -- sptial derivation second order
	SOD_Clt_dxdy_in : in histsize2d_grad;  -- sptial derivation second order
	SOD_Clt_dxdt_in : in histsize2d_grad; -- temporal and spatial derivation
	SOD_Clt_dydt_in : in histsize2d_grad; -- temporal and spatial derivation
	SOD_Clt_dt_ij_out : out std_logic_vector((Size_Width-1) downto 0); -- temporal derivation
	SOD_Clt_dx_ij_out : out std_logic_vector((Size_Width-1) downto 0);
	SOD_Clt_dy_ij_out : out std_logic_vector((Size_Width-1) downto 0); 
	SOD_Clt_dx2_out : out histsize2d_grad;
	SOD_Clt_dy2_out : out histsize2d_grad;
	SOD_Clt_dxdy_out : out histsize2d_grad;
	SOD_Clt_dxdt_out : out histsize2d_grad;
	SOD_Clt_dydt_out : out histsize2d_grad);
end entity SecondOrderDerivative_Collector;

architecture rtl of SecondOrderDerivative_Collector is

component histsize2d_grad_Reg is
 port(
  clr, ce, clk : in  std_logic;
  d_in         : in  histsize2d_grad;
  dout         : out histsize2d_grad
 );
end component histsize2d_grad_Reg;

component nregister_sync is
generic(N: natural:= DATA_WIDTH);
 port(
  clr, ce, clk : in  std_logic;
  d_in         : in  std_logic_vector((N-1) downto 0);
  dout         : out std_logic_vector((N-1) downto 0)
 );
end component;

begin


nregister_sync1: nregister_sync
generic map (N => Size_Width)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => SOD_Clt_dt_ij_in, 
dout => SOD_Clt_dt_ij_out);

nregister_sync2: nregister_sync
generic map (N =>Size_Width)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => SOD_Clt_dx_ij_in, 
dout => SOD_Clt_dx_ij_out);

nregister_sync3: nregister_sync
generic map (N =>Size_Width)
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => SOD_Clt_dy_ij_in, 
dout => SOD_Clt_dy_ij_out);

histsize2d_grad_Reg1: histsize2d_grad_Reg
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => SOD_Clt_dx2_in, 
dout => SOD_Clt_dx2_out);

histsize2d_grad_Reg2: histsize2d_grad_Reg
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => SOD_Clt_dy2_in, 
dout => SOD_Clt_dy2_out);

histsize2d_grad_Reg3: histsize2d_grad_Reg
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => SOD_Clt_dxdy_in, 
dout => SOD_Clt_dxdy_out);

histsize2d_grad_Reg4: histsize2d_grad_Reg
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => SOD_Clt_dxdt_in, 
dout => SOD_Clt_dxdt_out);

histsize2d_grad_Reg5: histsize2d_grad_Reg
port map (clr => clr,
ce => ce,   
clk => clk, 
d_in => SOD_Clt_dydt_in, 
dout => SOD_Clt_dydt_out);

end architecture rtl;

