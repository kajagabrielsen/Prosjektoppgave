library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
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
  signal y         : signed(Y_WIDTH_TRUNC-1 downto 0);

  --------------------------------------------------------------------------
  -- Reference queue
  --------------------------------------------------------------------------
  signal exp_q : exp_q_t := (others => (others => '0'));
  signal wptr  : integer := 0;
  signal rptr  : integer := 0;

  --------------------------------------------------------------------------
  -- Timing / counting
  --------------------------------------------------------------------------
  signal sent_count    : integer := 0;
  signal recv_count    : integer := 0;
  signal sending_done  : std_logic := '0';

  signal t_start       : time := 0 ns;
  signal t_end         : time := 0 ns;
  signal measurement_started  : std_logic := '0';
  signal measurement_finished : std_logic := '0';

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
  -- Clock
  --------------------------------------------------------------------------
  clk <= not clk after 0.5 ns;

  --------------------------------------------------------------------------
  -- Compare outputs and detect final output time
  --------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        rptr <= 0;
        recv_count <= 0;
      elsif valid_out = '1' then
        if y /= exp_q(rptr) then
          report "MISMATCH: got " &
            integer'image(to_integer(y)) &
            " expected " &
            integer'image(to_integer(exp_q(rptr)))
            severity error;
        end if;

        rptr <= (rptr + 1) mod QDEPTH;
        recv_count <= recv_count + 1;

        if sending_done = '1' and (recv_count + 1 = sent_count) and measurement_finished = '0' then
          t_end <= now;
          measurement_finished <= '1';
          report "Measured hardware time = " & time'image(now - t_start);
        end if;
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

    for i in 0 to N-1 loop
      x(i) <= (others => '0');
      w(i) <= (others => '0');
    end loop;

    --------------------------------------------------------------------
    -- 1) Read first line and first expected while rst='1'
    --------------------------------------------------------------------
    wait for 2 ns;

    if endfile(fin) then
      report "input.txt is empty" severity failure;
    end if;

    readline(fin,  L_in);
    readline(fout, L_out);

    -- Read first x vector
    for i in 0 to N-1 loop
      read(L_in, xi);
      x(i) <= to_signed(xi, X_W_WIDTH);
    end loop;

    -- Read weights from first line and apply directly to MAC
    for i in 0 to N-1 loop
      read(L_in, wi);
      w(i) <= to_signed(wi, X_W_WIDTH);
    end loop;

    -- First expected output
    read(L_out, exp_i);
    exp_q(wptr) <= to_signed(exp_i, Y_WIDTH_TRUNC);
    wptr <= (wptr + 1) mod QDEPTH;
    sent_count <= 1;

    --------------------------------------------------------------------
    -- 2) Start measurement at first direct weight/data application
    --------------------------------------------------------------------
    t_start <= now;
    measurement_started <= '1';

    wait until rising_edge(clk);
    rst <= '0';

    --------------------------------------------------------------------
    -- 3) Start streaming
    --------------------------------------------------------------------
    valid_in <= '1';

    -- First vector already loaded
    wait until rising_edge(clk);

    while not endfile(fin) loop
      readline(fin,  L_in);
      readline(fout, L_out);

      for i in 0 to N-1 loop
        read(L_in, xi);
        x(i) <= to_signed(xi, X_W_WIDTH);
      end loop;

      -- Ignore repeated weight fields
      for i in 0 to N-1 loop
        read(L_in, wi);
      end loop;

      read(L_out, exp_i);
      exp_q(wptr) <= to_signed(exp_i, Y_WIDTH_TRUNC);
      wptr <= (wptr + 1) mod QDEPTH;
      sent_count <= sent_count + 1;

      wait until rising_edge(clk);
    end loop;

    valid_in <= '0';
    sending_done <= '1';

    --------------------------------------------------------------------
    -- 4) Wait for final output
    --------------------------------------------------------------------
    wait until measurement_finished = '1';

    report "Sent vectors     = " & integer'image(sent_count);
    report "Received outputs = " & integer'image(recv_count);

    assert false report "TB DONE" severity failure;
  end process;

end architecture;