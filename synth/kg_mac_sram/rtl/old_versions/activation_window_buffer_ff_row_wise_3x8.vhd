--activation_window_buffer_ff_based_row_wise_3x8 (correct version)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg.all;

entity activation_window_buffer is
  port (
    clk : in std_logic;
    rst : in std_logic;

    load_full   : in std_logic;
    shift_horiz : in std_logic;

    x_full : in x_w_array(0 to N-1);
    x_col0 : in signed(X_W_WIDTH-1 downto 0);
    x_col1 : in signed(X_W_WIDTH-1 downto 0);
    x_col2 : in signed(X_W_WIDTH-1 downto 0);

    x_out   : out x_w_array(0 to N-1);
    x_valid : out std_logic
  );
end entity;

architecture rtl of activation_window_buffer is
  signal win       : x_w_array(0 to N-1);
  signal valid_reg : std_logic := '0';
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        for i in 0 to N-1 loop
          win(i) <= (others => '0');
        end loop;
        valid_reg <= '0';

      elsif load_full = '1' then
        win <= x_full;
        valid_reg <= '1';

      elsif shift_horiz = '1' then
        -- top row
        win(0) <= win(1);
        win(1) <= win(2);
        win(2) <= x_col0;

        -- middle row
        win(3) <= win(4);
        win(4) <= win(5);
        win(5) <= x_col1;

        -- bottom row
        win(6) <= win(7);
        win(7) <= win(8);
        win(8) <= x_col2;

        valid_reg <= '1';

      else
        valid_reg <= '0';
      end if;
    end if;
  end process;

  x_out   <= win;
  x_valid <= valid_reg;

end architecture;