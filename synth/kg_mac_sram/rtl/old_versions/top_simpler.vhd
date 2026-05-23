library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg.all;

entity top_mac_with_weight_sram is
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
end entity top_mac_with_weight_sram;

architecture rtl of top_mac_with_weight_sram is
  signal mem_word : std_logic_vector(N*X_W_WIDTH-1 downto 0);

  -- unpacked weights directly from SRAM output
  signal w_from_sram : x_w_array(0 to N-1);

  -- control to wait until SRAM output is valid
  signal loaded : std_logic := '0';
  signal valid_in_gated : std_logic;
begin

  U_WEIGHT_SRAM : entity work.weight_sram
    port map (
        clk  => clk,
        we   => mem_we,
        din  => mem_din,
        dout => mem_word
    );

  -- Unpack SRAM output directly to weight array
  gen_unpack : for i in 0 to N-1 generate
  begin
    w_from_sram(i) <= signed(mem_word((i+1)*X_W_WIDTH-1 downto i*X_W_WIDTH));
  end generate;

  -- Wait long enough for SRAM read data to become valid
  process(clk)
begin
  if rising_edge(clk) then
    if rst = '1' then
      loaded <= '0';

    elsif mem_we = '1' then
      loaded <= '1';
    end if;
  end if;
end process;

  valid_in_gated <= valid_in and loaded;

  U_MAC : entity work.mac_csa
    port map (
      clk       => clk,
      rst       => rst,
      valid_in  => valid_in_gated,
      x         => x,
      w         => w_from_sram,
      valid_out => valid_out,
      y         => y
    );

end architecture rtl;