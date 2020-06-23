
--  Xilinx UltraRAM True Dual Port Mode.  This code implements 
--  a parameterizable UltraRAM block with write/read on both ports in 
--  No change behavior on both the ports . The behavior of this RAM is 
--  when data is written, the output of RAM is unchanged w.r.t each port. 
--  Only when write is inactive data corresponding to the address is 
--  presented on the output port.

-- Following libraries have to be used
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity xilinx_ultraram_true_dual_port is
generic (
         Address_Width : integer := 12;  -- Address Width for 4096 locations
         DWIDTH : integer := 72;  -- Data Width
         NBPIPE : integer := 3    -- Number of pipeline Registers
        );
port    (
clk :  in std_logic;                                  -- Clock 
-- Port A
rsta :  in std_logic;                                  -- Reset
wea :  in std_logic;                                   -- Write Enable
regcea :  in std_logic;                                -- Output Register Enablea
mem_ena :  in std_logic;                               -- Memory Enable
dina :  in std_logic_vector(DWIDTH-1 downto 0);      -- Data Input  
addra :  in std_logic_vector(Address_Width-1 downto 0);     -- Address Input
douta : out std_logic_vector(DWIDTH-1 downto 0);      -- Data Output
-- Port b 
rstb :  in std_logic;                                  -- Reset
web :  in std_logic;                                   -- Write Enable
regceb :  in std_logic;                                -- Output Register Enableb
mem_enb :  in std_logic;                               -- Memory Enable
dinb :  in std_logic_vector(DWIDTH-1 downto 0);      -- Data Input  
addrb :  in std_logic_vector(Address_Width-1 downto 0);     -- Address Input
doutb : out std_logic_vector(DWIDTH-1 downto 0)      -- Data Output
        );
end xilinx_ultraram_true_dual_port;

architecture behavioral of xilinx_ultraram_true_dual_port is
-- Internal Signals
--Insert the following in the architecture before the begin keyword
constant C_Address_Width : integer := Address_Width;
constant C_DWIDTH : integer := DWIDTH;
constant C_NBPIPE : integer := NBPIPE;

type mem_t is array(natural range<>) of std_logic_vector(C_DWIDTH-1 downto 0);
type pipe_data_t is array(natural range<>) of std_logic_vector(C_DWIDTH-1 downto 0);
type pipe_en_t is array(natural range<>) of std_logic;

signal mem : mem_t(2**C_Address_Width-1 downto 0);                -- Memory Declaration

signal memrega : std_logic_vector(C_DWIDTH-1 downto 0);              
signal mem_pipe_rega : pipe_data_t(C_NBPIPE-1 downto 0);    -- Pipelines for Memory
signal mem_en_pipe_rega : pipe_en_t(C_NBPIPE downto 0);     -- Pipelines for Memory enable  

signal memregb : std_logic_vector(C_DWIDTH-1 downto 0);              
signal mem_pipe_regb : pipe_data_t(C_NBPIPE-1 downto 0);    -- Pipelines for Memory
signal mem_en_pipe_regb : pipe_en_t(C_NBPIPE downto 0);     -- Pipelines for Memory enable  
attribute ram_style : string;

attribute ram_style of mem : signal is "ultra";
-- Insert the following after the begin keyword
begin
-- RAM : Read has one latency, Write has one latency as well.
process(clk)
begin
  if(clk'event and clk='1')then
    if(mem_ena = '1') then
      if(wea = '1') then
        mem(to_integer(unsigned(addra))) <= dina;
      else
        memrega <= mem(to_integer(unsigned(addra)));
      end if;
    end if;
  end if;
end process;

-- The enable of the RAM goes through a pipeline to produce a
-- series of pipelined enable signals required to control the data
-- pipeline.
process(clk)
begin
  if(clk'event and clk = '1') then
    mem_en_pipe_rega(0) <= mem_ena;
    for i in 0 to C_NBPIPE-1 loop
      mem_en_pipe_rega(i+1) <= mem_en_pipe_rega(i);
    end loop;
  end if;
end process;

-- RAM output data goes through a pipeline.
process(clk)
begin
  if(clk'event and clk = '1') then
    if(mem_en_pipe_rega(0) = '1') then
      mem_pipe_rega(0) <= memrega;
    end if;
    for i in 0 to C_NBPIPE-2 loop
      if(mem_en_pipe_rega(i+1) = '1') then
        mem_pipe_rega(i+1) <= mem_pipe_rega(i);
      end if;
    end loop;
  end if;
end process;

-- Final output register gives user the option to add a reset and
-- an additional enable signal just for the data ouptut

process(clk)
begin
  if(clk'event and clk = '1') then
    if(rsta = '1') then
      douta <= (others => '0');
    elsif(mem_en_pipe_rega(C_NBPIPE) = '1' and regcea = '1' ) then
      douta <= mem_pipe_rega(C_NBPIPE-1);
    end if;
  end if;    
end process;


process(clk)
begin
  if(clk'event and clk='1')then
    if(mem_enb = '1') then
      if(web = '1') then
        mem(to_integer(unsigned(addrb))) <= dinb;
      else
        memregb <= mem(to_integer(unsigned(addrb)));
      end if;
    end if;
  end if;
end process;

-- The enable of the RAM goes through a pipeline to produce a
-- series of pipelined enable signals required to control the data
-- pipeline.
process(clk)
begin
  if(clk'event and clk = '1') then
    mem_en_pipe_regb(0) <= mem_enb;
    for i in 0 to C_NBPIPE-1 loop
      mem_en_pipe_regb(i+1) <= mem_en_pipe_regb(i);
    end loop;
  end if;
end process;

-- RAM output data goes through a pipeline.
process(clk)
begin
  if(clk'event and clk = '1') then
    if(mem_en_pipe_regb(0) = '1') then
      mem_pipe_regb(0) <= memregb;
    end if;
    for i in 0 to C_NBPIPE-2 loop
      if(mem_en_pipe_regb(i+1) = '1') then
        mem_pipe_regb(i+1) <= mem_pipe_regb(i);
      end if;
    end loop;
  end if;
end process;

-- Final output register gives user the option to add a reset and
-- an additional enable signal just for the data ouptut

process(clk)
begin
  if(clk'event and clk = '1') then
    if(rstb = '1') then
      doutb <= (others => '0');
    elsif(mem_en_pipe_regb(C_NBPIPE) = '1' and regceb = '1' ) then
      doutb <= mem_pipe_regb(C_NBPIPE-1);
    end if;
  end if;    
end process;
end behavioral;
					