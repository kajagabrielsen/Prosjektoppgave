--activation window buffer latch based row wise 24 input instead of 3 times 8

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg.all;

entity activation_window_buffer is
  port (
    clk  : in std_logic;
    rst  : in std_logic;

    load_full : in std_logic;
    shift_horiz   : in std_logic;

    x_full : in x_w_array(0 to N-1);

    x_col : in x_w_array(0 to 2);

    x_out : out x_w_array(0 to N-1)
  );
end entity;

architecture rtl of activation_window_buffer is
  signal win : x_w_array(0 to N-1);
begin

  process(clk, rst, load_full, shift_horiz, x_full, x_col, win)
  begin
    if rst = '1' then
      for i in 0 to N-1 loop
        win(i) <= (others => '0');
      end loop;

    elsif clk = '1' then  -- latch is transparent while clk is high
      if load_full = '1' then
        win <= x_full;

      elsif shift_horiz = '1' then
        win(0) <= win(1);
        win(1) <= win(2);
        win(2) <= x_col(0);

        win(3) <= win(4);
        win(4) <= win(5);
        win(5) <= x_col(1);

        win(6) <= win(7);
        win(7) <= win(8);
        win(8) <= x_col(2);
      end if;
    end if;
  end process;

  x_out <= win;

end architecture;