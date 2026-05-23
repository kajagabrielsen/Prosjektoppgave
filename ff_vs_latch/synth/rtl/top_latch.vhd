library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg.all;

entity top_mac_with_latch_mem is
  port (
    clk  : in std_logic;
    rst  : in std_logic;

    -- SRAM programming interface
    mem_we   : in std_logic;
    mem_addr : in unsigned(0 downto 0);
    mem_din  : in std_logic_vector(N*X_W_WIDTH-1 downto 0);

    -- streaming activations
    valid_in : in std_logic;
    x        : in x_w_array(0 to N-1);

    -- output
    valid_out : out std_logic;
    y         : out signed(Y_WIDTH_TRUNC-1 downto 0)
  );
end entity top_mac_with_latch_mem;

architecture rtl of top_mac_with_latch_mem is
  signal mem_word : std_logic_vector(N*X_W_WIDTH-1 downto 0);

  -- unpacked weights directly from latch output
  signal w_from_latch : x_w_array(0 to N-1);

begin

  U_LATCH_MEM : entity work.weight_latch_mem
    generic map (
      DEPTH => 1,
      ADDR_WIDTH => 1
    )
    port map (
      clk  => clk,
      we   => mem_we,
      addr => mem_addr,
      din  => mem_din,
      dout => mem_word
    );

  -- Unpack latch output directly to weight array
  gen_unpack : for i in 0 to N-1 generate
  begin
    w_from_latch(i) <= signed(mem_word((i+1)*X_W_WIDTH-1 downto i*X_W_WIDTH));
  end generate;


  U_MAC : entity work.mac_csa
    port map (
      clk       => clk,
      rst       => rst,
      valid_in  => valid_in,
      x         => x,
      w         => w_from_latch,
      valid_out => valid_out,
      y         => y
    );

end architecture rtl;