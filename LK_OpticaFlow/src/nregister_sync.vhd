-------------------------------------------------------------------------
-- Mohammad Pivezhandi
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- nregister_sync.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of Synchronous rst n bit
-- register
--
--
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.ALUpackage.all;

entity nregister_sync is
generic(N: natural:= Nwidth);
  port(i_CLK        : in std_logic;     -- Clock input
       i_RST        : in std_logic;     -- Reset input
       i_WE         : in std_logic;     -- Write enable input
       in_reg          : in std_logic_vector(N-1 downto 0);     -- Data value input
       o_reg          : out std_logic_vector(N-1 downto 0));   -- Data value output
end nregister_sync;

architecture mixed of nregister_sync is
  signal s_D    : std_logic_vector(N-1 downto 0);    -- Multiplexed input to the FF
  signal s_Q    : std_logic_vector(N-1 downto 0);    -- Output of the FF

begin

  -- The output of the FF is fixed to s_Q
  o_reg <= s_Q;
  
  -- Create a multiplexed input to the FF based on i_WE
  with i_WE select
    s_D <= in_reg when '1',
           s_Q when others;
  
  -- This process handles the asyncrhonous reset and
  -- synchronous write. We want to be able to reset 
  -- our processor's registers so that we minimize
  -- glitchy behavior on startup.
  process (i_CLK, i_RST)
  begin
	if (rising_edge(i_CLK)) then
		if (i_RST = '1') then
		  s_Q <= (others => '0'); -- Use "(others => '0')" for N-bit values
		else
		  s_Q <= s_D;
		end if;
	end if;
  end process;
  
end mixed;
