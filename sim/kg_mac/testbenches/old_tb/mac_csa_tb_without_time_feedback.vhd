
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

use work.pkg.all;

entity mac_csa_tb is
end entity mac_csa_tb;

architecture tb of mac_csa_tb is

  --------------------------------------------------------------------------
  -- DUT signals
  --------------------------------------------------------------------------
  signal clk       : std_logic := '0';
  signal rst       : std_logic := '1';
  signal valid_in  : std_logic := '0';
  signal valid_out : std_logic;
  signal x         : x_w_array(0 to N-1);
  signal w         : x_w_array(0 to N-1);
  signal y         : signed(Y_WIDTH_TRUNC-1 downto 0);  -- DUT output

  --------------------------------------------------------------------------
  -- Reference queue (to handle pipeline latency)
  --------------------------------------------------------------------------
  signal exp_q : exp_q_t := (others => (others => '0'));
  signal wptr  : integer := 0;
  signal rptr  : integer := 0;

  --------------------------------------------------------------------------
  -- Files
  --------------------------------------------------------------------------
  file fin  : text open read_mode is "input.txt";
  file fout : text open read_mode is "expected_out.txt";

begin

  --------------------------------------------------------------------------
  -- DUT
  --------------------------------------------------------------------------
  dut : entity work.mac_csa
    port map (
      clk       => clk,
      rst       => rst,
      valid_in  => valid_in,
      x         => x,
      w         => w,
      valid_out => valid_out,
      y         => y
    );

  --------------------------------------------------------------------------
  -- Clock (1 GHz)
  --------------------------------------------------------------------------
  clk <= not clk after 0.5 ns;

  --------------------------------------------------------------------------
  -- Compare outputs
  --------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        rptr <= 0;
      elsif valid_out = '1' then
        if y /= exp_q(rptr) then
          report "MISMATCH: got " &
            integer'image(to_integer(y)) &
            " expected " &
            integer'image(to_integer(exp_q(rptr)))
            severity error;
        end if;
        rptr <= (rptr + 1) mod QDEPTH;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Stimulus
  --------------------------------------------------------------------------
  stim : process
  variable xi, wi : integer;
  variable exp_i  : integer;
  variable L_in   : line;
  variable L_out  : line;
begin
  report "TB sees TRUNC_BITS = " & integer'image(TRUNC_BITS);

  -- init
  for i in 0 to N-1 loop
    x(i) <= (others => '0');
    w(i) <= (others => '0');
  end loop;

  --------------------------------------------------------------------
  -- 1) While rst='1': read FIRST line and set fixed weights
  --------------------------------------------------------------------
  wait for 2 ns;

  if endfile(fin) then
    report "input.txt is empty" severity failure;
  end if;

  readline(fin, L_in);
  readline(fout, L_out);

  -- Read activations from first line
  for i in 0 to N-1 loop
    read(L_in, xi);
    x(i) <= to_signed(xi, X_W_WIDTH);
  end loop;

  -- Read weights from first line ONCE
  for i in 0 to N-1 loop
    read(L_in, wi);
    w(i) <= to_signed(wi, X_W_WIDTH);
  end loop;

  -- First expected output
  read(L_out, exp_i);
  exp_q(wptr) <= to_signed(exp_i, Y_WIDTH_TRUNC);
  wptr <= (wptr + 1) mod QDEPTH;

  --------------------------------------------------------------------
  -- 2) Release reset
  --------------------------------------------------------------------
  wait until rising_edge(clk);
  rst <= '0';

  --------------------------------------------------------------------
  -- 3) Start streaming
  --------------------------------------------------------------------
  valid_in <= '1';

  -- First vector already loaded
  wait until rising_edge(clk);

  -- Continue with remaining lines
  while not endfile(fin) loop
    readline(fin, L_in);
    readline(fout, L_out);

    -- Read activations
    for i in 0 to N-1 loop
      read(L_in, xi);
      x(i) <= to_signed(xi, X_W_WIDTH);
    end loop;

    -- Read weights but IGNORE them
    for i in 0 to N-1 loop
      read(L_in, wi);
    end loop;

    -- Read expected output
    read(L_out, exp_i);
    exp_q(wptr) <= to_signed(exp_i, Y_WIDTH_TRUNC);
    wptr <= (wptr + 1) mod QDEPTH;

    wait until rising_edge(clk);
  end loop;

  valid_in <= '0';

  -- Drain pipeline
  for i in 0 to 50 loop
    wait until rising_edge(clk);
  end loop;

  assert false report "TB DONE" severity failure;
end process;

end architecture;
