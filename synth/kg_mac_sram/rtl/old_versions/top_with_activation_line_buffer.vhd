--top_with_activation_line_buffer

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg.all;

entity top_with_activation_buffer is
  port (
    clk : in std_logic;
    rst : in std_logic;

    -- SRAM programming interface for weights
    mem_we   : in std_logic;
    mem_addr : in unsigned(0 downto 0);
    mem_din  : in std_logic_vector(N*X_W_WIDTH-1 downto 0);

    -- pixel stream input
    valid_in : in std_logic;
    pixel_in : in signed(X_W_WIDTH-1 downto 0);

    -- output
    valid_out : out std_logic;
    y         : out signed(Y_WIDTH_TRUNC-1 downto 0)
  );
end entity top_with_activation_buffer;

architecture rtl of top_with_activation_buffer is

  signal mem_word    : std_logic_vector(N*X_W_WIDTH-1 downto 0);
  signal w_from_sram : x_w_array(0 to N-1);

  signal x_to_mac    : x_w_array(0 to N-1);
  signal x_valid_buf : std_logic;

begin

  U_SRAM : entity work.weight_sram
    generic map (
      DEPTH      => 1,
      ADDR_WIDTH => 1
    )
    port map (
      clk  => clk,
      we   => mem_we,
      addr => mem_addr,
      din  => mem_din,
      dout => mem_word
    );

  gen_unpack : for i in 0 to N-1 generate
  begin
    w_from_sram(i) <= signed(mem_word((i+1)*X_W_WIDTH-1 downto i*X_W_WIDTH));
  end generate;

  U_LINE_BUF : entity work.activation_window_buffer
    generic map (
      IMG_W => 28,
      IMG_H => 28
    )
    port map (
      clk      => clk,
      rst      => rst,
      valid_in => valid_in,
      pixel_in => pixel_in,
      x_out    => x_to_mac,
      x_valid  => x_valid_buf
    );

  U_MAC : entity work.mac_csa
    port map (
      clk       => clk,
      rst       => rst,
      valid_in  => x_valid_buf,
      x         => x_to_mac,
      w         => w_from_sram,
      valid_out => valid_out,
      y         => y
    );

end architecture;