library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg.all;

entity weight_latch_mem is
  generic (
    DEPTH : natural := 1;
    ADDR_WIDTH : natural := 1
  );
  port (
    clk  : in  std_logic; -- kept for interface compatibility
    we   : in  std_logic;
    addr : in  unsigned(ADDR_WIDTH-1 downto 0);
    din  : in  std_logic_vector(N*X_W_WIDTH-1 downto 0);
    dout : out std_logic_vector(N*X_W_WIDTH-1 downto 0)
  );
end entity weight_latch_mem;

architecture rtl of weight_latch_mem is

  type mem_t is array (0 to DEPTH-1) of std_logic_vector(N*X_W_WIDTH-1 downto 0);
  signal mem : mem_t := (others => (others => '0'));

  signal dout_r : std_logic_vector(N*X_W_WIDTH-1 downto 0) := (others => '0');

begin

  --------------------------------------------------------------------------
  -- Latch-based write (transparent when we = '1')
  --------------------------------------------------------------------------
  gen_mem : for i in 0 to DEPTH-1 generate
  begin
    process(we, din, addr)
    begin
      if we = '1' and to_integer(addr) = i then
        mem(i) <= din;
      end if;
    end process;
  end generate;

  --------------------------------------------------------------------------
  -- Latch-based read
  --------------------------------------------------------------------------
  process(we, mem, addr)
  begin
    -- when not writing, output follows stored value
    dout_r <= mem(to_integer(addr));
  end process;

  dout <= dout_r;

end architecture;