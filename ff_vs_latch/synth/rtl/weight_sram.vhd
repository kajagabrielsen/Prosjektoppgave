library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg.all;

entity weight_sram is
  generic (
    DEPTH : natural := 1;
    ADDR_WIDTH : natural := 1  -- log2(DEPTH) (for DEPTH=1 is this a bit dummy)
  );
  port (
    clk  : in  std_logic;
    we   : in  std_logic; --write enable
    addr : in  unsigned(ADDR_WIDTH-1 downto 0);
    din  : in  std_logic_vector(N*X_W_WIDTH-1 downto 0);
    dout : out std_logic_vector(N*X_W_WIDTH-1 downto 0)
  );
end entity weight_sram;

architecture rtl of weight_sram is
  type mem_t is array (0 to DEPTH-1) of std_logic_vector(N*X_W_WIDTH-1 downto 0); --just one address line with 72 bits for the weights
  signal mem    : mem_t := (others => (others => '0'));
  signal dout_r : std_logic_vector(N*X_W_WIDTH-1 downto 0) := (others => '0');
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        mem(to_integer(addr)) <= din;
      end if;
      dout_r <= mem(to_integer(addr)); -- 1-cycle read latency
    end if;
  end process;

  dout <= dout_r;
end architecture;