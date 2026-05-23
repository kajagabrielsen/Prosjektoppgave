--activation_line_buffer

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg.all;

entity activation_window_buffer is
  generic (
    IMG_W : natural := 28;
    IMG_H : natural := 28
  );
  port (
    clk      : in std_logic;
    rst      : in std_logic;

    valid_in : in std_logic;
    pixel_in : in signed(X_W_WIDTH-1 downto 0);

    x_out    : out x_w_array(0 to N-1);
    x_valid  : out std_logic
  );
end entity activation_window_buffer;

architecture rtl of activation_window_buffer is

  type line_t is array (0 to IMG_W-1) of signed(X_W_WIDTH-1 downto 0);

  signal line0 : line_t := (others => (others => '0'));
  signal line1 : line_t := (others => (others => '0'));

  signal win : x_w_array(0 to N-1) := (others => (others => '0'));

  signal row_cnt : integer range 0 to IMG_H-1 := 0;
  signal col_cnt : integer range 0 to IMG_W-1 := 0;

  signal valid_reg : std_logic := '0';

begin

  process(clk)
    variable top_pixel    : signed(X_W_WIDTH-1 downto 0);
    variable middle_pixel : signed(X_W_WIDTH-1 downto 0);
    variable bottom_pixel : signed(X_W_WIDTH-1 downto 0);
  begin
    if rising_edge(clk) then

      if rst = '1' then

        row_cnt   <= 0;
        col_cnt   <= 0;
        valid_reg <= '0';

        win <= (others => (others => '0'));

        line0 <= (others => (others => '0'));
        line1 <= (others => (others => '0'));

      elsif valid_in = '1' then

        ------------------------------------------------------------
        -- Read old line-buffer values before updating them
        ------------------------------------------------------------
        top_pixel    := line1(col_cnt);
        middle_pixel := line0(col_cnt);
        bottom_pixel := pixel_in;

        ------------------------------------------------------------
        -- Update line buffers
        --
        -- line0 stores previous row
        -- line1 stores row before previous row
        ------------------------------------------------------------
        line1(col_cnt) <= line0(col_cnt);
        line0(col_cnt) <= pixel_in;

        ------------------------------------------------------------
        -- Shift 3x3 window horizontally
        ------------------------------------------------------------
        -- top row
        win(0) <= win(1);
        win(1) <= win(2);
        win(2) <= top_pixel;

        -- middle row
        win(3) <= win(4);
        win(4) <= win(5);
        win(5) <= middle_pixel;

        -- bottom row
        win(6) <= win(7);
        win(7) <= win(8);
        win(8) <= bottom_pixel;

        ------------------------------------------------------------
        -- Window is valid after at least 3 rows and 3 columns
        ------------------------------------------------------------
        if row_cnt >= 2 and col_cnt >= 2 then
          valid_reg <= '1';
        else
          valid_reg <= '0';
        end if;

        ------------------------------------------------------------
        -- Row/column counters
        ------------------------------------------------------------
        if col_cnt = IMG_W-1 then
          col_cnt <= 0;

          if row_cnt = IMG_H-1 then
            row_cnt <= 0;
          else
            row_cnt <= row_cnt + 1;
          end if;

        else
          col_cnt <= col_cnt + 1;
        end if;

      else
        valid_reg <= '0';
      end if;

    end if;
  end process;

  x_out   <= win;
  x_valid <= valid_reg;

end architecture;