library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.pkg.all;

entity top_mac_with_weight_sram_tb is
end entity top_mac_with_weight_sram_tb;

architecture tb of top_mac_with_weight_sram_tb is

  --------------------------------------------------------------------------
  -- DUT signals
  --------------------------------------------------------------------------
  signal clk       : std_logic := '0';
  signal rst       : std_logic := '1';

  signal mem_we    : std_logic := '0';
  signal mem_addr  : unsigned(0 downto 0) := (others => '0');
  signal mem_din   : std_logic_vector(N*X_W_WIDTH-1 downto 0) := (others => '0');

  signal valid_in  : std_logic := '0';
  signal valid_out : std_logic;
  signal x         : x_w_array(0 to N-1);
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
  dut : entity work.top_mac_with_weight_sram
    port map (
      clk       => clk,
      rst       => rst,
      mem_we    => mem_we,
      mem_addr  => mem_addr,
      mem_din   => mem_din,
      valid_in  => valid_in,
      x         => x,
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
    variable w_word : std_logic_vector(N*X_W_WIDTH-1 downto 0);
  begin
    report "TB sees TRUNC_BITS = " & integer'image(TRUNC_BITS);

    for i in 0 to N-1 loop
      x(i) <= (others => '0');
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

    -- Read weights from first line and pack into SRAM write word
    w_word := (others => '0');
    for i in 0 to N-1 loop
      read(L_in, wi);
      w_word((i+1)*X_W_WIDTH-1 downto i*X_W_WIDTH) :=
        std_logic_vector(to_signed(wi, X_W_WIDTH));
    end loop;

    -- First expected output
    read(L_out, exp_i);
    exp_q(wptr) <= to_signed(exp_i, Y_WIDTH_TRUNC);
    wptr <= (wptr + 1) mod QDEPTH;
    sent_count <= 1;

    --------------------------------------------------------------------
    -- 2) Start measurement at weight memory programming
    --------------------------------------------------------------------
    t_start <= now;
    measurement_started <= '1';

    wait until rising_edge(clk);
    mem_addr <= (others => '0');
    mem_din  <= w_word;
    mem_we   <= '1';

    wait until rising_edge(clk);
    mem_we   <= '0';
    mem_din  <= (others => '0');

    --------------------------------------------------------------------
    -- 3) Release reset and wait for weight memory path to become ready
    --------------------------------------------------------------------
    wait for 2 ns;
    rst <= '0';

    wait until rising_edge(clk);
    wait until rising_edge(clk);

    --------------------------------------------------------------------
    -- 4) Start streaming
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
    -- 5) Wait for final output to be detected
    --------------------------------------------------------------------
    wait until measurement_finished = '1';

    report "Sent vectors     = " & integer'image(sent_count);
    report "Received outputs = " & integer'image(recv_count);

    assert false report "TB DONE" severity failure;
  end process;

end architecture;