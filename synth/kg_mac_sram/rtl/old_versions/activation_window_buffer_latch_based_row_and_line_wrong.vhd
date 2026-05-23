library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg.all;

-- Unified activation buffer: handles both horizontal (row-wise)
-- and vertical (line-wise) sliding for a 3x3 convolution window.

entity activation_window_buffer is
  port (
    clk  : in std_logic;
    rst  : in std_logic;

    -- control
    load_full    : in std_logic;  -- load initial 3×3 block
    shift_horiz  : in std_logic;  -- shift right (3 new pixels)
    shift_vertical : in std_logic; -- move one row down (vertical shift)

    -- input pixels
    x_full : in x_w_array(0 to N-1);  -- full 3×3 load (for start/reset)
    -- three new pixels for horizontal shift
    x_col0 : in signed(X_W_WIDTH-1 downto 0);
    x_col1 : in signed(X_W_WIDTH-1 downto 0);
    x_col2 : in signed(X_W_WIDTH-1 downto 0);
    -- three new pixels for next line (vertical shift)
    x_row0 : in signed(X_W_WIDTH-1 downto 0);
    x_row1 : in signed(X_W_WIDTH-1 downto 0);
    x_row2 : in signed(X_W_WIDTH-1 downto 0);

    -- output 3×3 patch to MAC
    x_out : out x_w_array(0 to N-1)
  );
end entity;

architecture rtl of activation_window_buffer is

  signal line0, line1, line2 : x_w_array(0 to 2) := (others => (others => '0'));
  signal win : x_w_array(0 to N-1);

begin

  process(clk, rst, load_full, shift_horiz, shift_vertical,
          x_full, x_col0, x_col1, x_col2, x_row0, x_row1, x_row2,
          line0, line1, line2)
  begin
    if rst = '1' then
      for i in 0 to 2 loop
        line0(i) <= (others => '0');
        line1(i) <= (others => '0');
        line2(i) <= (others => '0');
      end loop;

    elsif clk = '1' then
      if load_full = '1' then
        line2(0) <= x_full(0); line2(1) <= x_full(1); line2(2) <= x_full(2);
        line1(0) <= x_full(3); line1(1) <= x_full(4); line1(2) <= x_full(5);
        line0(0) <= x_full(6); line0(1) <= x_full(7); line0(2) <= x_full(8);

      elsif shift_horiz = '1' then
        line2(0) <= line2(1);
        line2(1) <= line2(2);
        line2(2) <= x_col0;

        line1(0) <= line1(1);
        line1(1) <= line1(2);
        line1(2) <= x_col1;

        line0(0) <= line0(1);
        line0(1) <= line0(2);
        line0(2) <= x_col2;

      elsif shift_vertical = '1' then
        line2 <= line1;
        line1 <= line0;
        line0(0) <= x_row0;
        line0(1) <= x_row1;
        line0(2) <= x_row2;
      end if;
    end if;
  end process;

  win(0) <= line2(0);  win(1) <= line2(1);  win(2) <= line2(2);
  win(3) <= line1(0);  win(4) <= line1(1);  win(5) <= line1(2);
  win(6) <= line0(0);  win(7) <= line0(1);  win(8) <= line0(2);

  x_out <= win;

end architecture;