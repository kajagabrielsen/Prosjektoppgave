--activation window buffer latch based row wise, 3 inputs of 8 bits
--_latch_based_row_wise_3x8


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg.all;

entity activation_window_buffer is
  port (
    clk  : in std_logic;
    rst  : in std_logic;

    load_full   : in std_logic;
    shift_horiz : in std_logic;

    x_full : in x_w_array(0 to N-1);

    x_col0 : in signed(X_W_WIDTH-1 downto 0);
    x_col1 : in signed(X_W_WIDTH-1 downto 0);
    x_col2 : in signed(X_W_WIDTH-1 downto 0);

    x_out : out x_w_array(0 to N-1)
  );
end entity;

architecture rtl of activation_window_buffer is
  signal master : x_w_array(0 to N-1);
  signal slave  : x_w_array(0 to N-1);
begin

  --------------------------------------------------------------------
  -- Master latch
  -- Transparent when clk = '0'
  -- Computes next window from stable slave values.
  --------------------------------------------------------------------
  process(clk, rst, load_full, shift_horiz, x_full,
          x_col0, x_col1, x_col2, slave)
  begin
    if rst = '1' then
      for i in 0 to N-1 loop
        master(i) <= (others => '0');
      end loop;

    elsif clk = '0' then
      if load_full = '1' then
        master <= x_full;

      elsif shift_horiz = '1' then
        master(0) <= slave(1);
        master(1) <= slave(2);
        master(2) <= x_col0;

        master(3) <= slave(4);
        master(4) <= slave(5);
        master(5) <= x_col1;

        master(6) <= slave(7);
        master(7) <= slave(8);
        master(8) <= x_col2;

      else
        master <= slave;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------
  -- Slave latch
  -- Transparent when clk = '1'
  --------------------------------------------------------------------
  process(clk, rst, master)
  begin
    if rst = '1' then
      for i in 0 to N-1 loop
        slave(i) <= (others => '0');
      end loop;

    elsif clk = '1' then
      slave <= master;
    end if;
  end process;

  x_out <= slave;

end architecture;