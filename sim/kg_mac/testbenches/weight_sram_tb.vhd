library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.pkg.all;

entity weight_sram_tb is
end entity weight_sram_tb;

architecture tb of weight_sram_tb is

  signal clk  : std_logic := '0';
  signal we   : std_logic := '0';
  signal addr : unsigned(0 downto 0) := (others => '0');
  signal din  : std_logic_vector(N*X_W_WIDTH-1 downto 0) := (others => '0');
  signal dout : std_logic_vector(N*X_W_WIDTH-1 downto 0);

  signal t_start : time := 0 ns;
  signal t_end   : time := 0 ns;

  file fweights : text open read_mode is "weights.txt";

begin

  U_MEM : entity work.weight_sram
    generic map (
      DEPTH => 1,
      ADDR_WIDTH => 1
    )
    port map (
      clk  => clk,
      we   => we,
      addr => addr,
      din  => din,
      dout => dout
    );

  clk <= not clk after 0.5 ns;

  stim : process
    variable Lw     : line;
    variable wi     : integer;
    variable w_word : std_logic_vector(N*X_W_WIDTH-1 downto 0);
  begin

    report "Starting weight memory load test";

    wait for 2 ns;

    if endfile(fweights) then
      report "weights.txt is empty" severity failure;
    end if;

    readline(fweights, Lw);

    w_word := (others => '0');

    for i in 0 to N-1 loop
      read(Lw, wi);

      w_word((i+1)*X_W_WIDTH-1 downto i*X_W_WIDTH) :=
        std_logic_vector(to_signed(wi, X_W_WIDTH));
    end loop;

    --------------------------------------------------------------------
    -- Start measuring memory loading energy
    --------------------------------------------------------------------
    t_start <= now;

    wait until rising_edge(clk);

    addr <= (others => '0');
    din  <= w_word;
    we   <= '1';

    wait until rising_edge(clk);

    we <= '0';

    --------------------------------------------------------------------
    -- Stop measuring after write cycle
    --------------------------------------------------------------------
    t_end <= now;

    report "Weight memory load time = " & time'image(now - t_start);

    wait for 1 ns;

    assert false report "WEIGHT MEMORY LOAD TB DONE" severity failure;

  end process;

end architecture;