--top_with_activation_buffer_row_wise_3x8
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg.all;

entity top_with_activation_buffer is
  port (
    clk  : in std_logic;
    rst  : in std_logic;

    -- SRAM programming interface for weights
    mem_we   : in std_logic;
    mem_addr : in unsigned(0 downto 0);
    mem_din  : in std_logic_vector(N*X_W_WIDTH-1 downto 0);

    -- activation window control
    valid_in  : in std_logic;
    load_full : in std_logic;
    shift_horiz   : in std_logic;

    -- activations
    x_full : in x_w_array(0 to N-1);
    x_col0 : in signed(X_W_WIDTH-1 downto 0);
    x_col1 : in signed(X_W_WIDTH-1 downto 0);
    x_col2 : in signed(X_W_WIDTH-1 downto 0);

    -- output
    valid_out : out std_logic;
    y         : out signed(Y_WIDTH_TRUNC-1 downto 0)
  );
end entity top_with_activation_buffer;

architecture rtl of top_with_activation_buffer is
  signal mem_word     : std_logic_vector(N*X_W_WIDTH-1 downto 0);
  signal w_from_sram  : x_w_array(0 to N-1);
  signal x_to_mac     : x_w_array(0 to N-1);

  signal loaded         : std_logic := '0';
  signal win_update        : std_logic;
  signal win_update_d      : std_logic := '0';
  signal valid_in_gated : std_logic;

begin

  U_SRAM : entity work.weight_sram
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

  gen_unpack : for i in 0 to N-1 generate
  begin
    w_from_sram(i) <= signed(mem_word((i+1)*X_W_WIDTH-1 downto i*X_W_WIDTH));
  end generate;

  U_ACT_BUF : entity work.activation_window_buffer
    port map (
      clk       => clk,
      rst       => rst,
      load_full => load_full,
      shift_horiz   => shift_horiz,
      x_full    => x_full,
      x_col0    => x_col0,
      x_col1    => x_col1,
      x_col2    => x_col2,
      x_out     => x_to_mac
    );

  win_update <= valid_in and (load_full or shift_horiz);

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        loaded       <= '0';
        win_update_d <= '0';
      else
        if loaded = '0' then
          loaded <= '1';
        end if;

        win_update_d <= win_update;
      end if;
    end if;
  end process;

  valid_in_gated <= win_update_d and loaded;

  U_MAC : entity work.mac_csa
    port map (
      clk       => clk,
      rst       => rst,
      valid_in  => valid_in_gated,
      x         => x_to_mac,
      w         => w_from_sram,
      valid_out => valid_out,
      y         => y
    );

end architecture;