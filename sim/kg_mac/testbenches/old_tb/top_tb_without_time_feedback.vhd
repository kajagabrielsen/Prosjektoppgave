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

    variable w_word : std_logic_vector(N*X_W_WIDTH-1 downto 0);
    variable got_weights : boolean := false;
  begin

    report "TB sees TRUNC_BITS = " & integer'image(TRUNC_BITS);
    
    -- init
    for i in 0 to N-1 loop
      x(i) <= (others => '0');
    end loop;

    --------------------------------------------------------------------
    -- 1) While rst='1': read FIRST line weights and program SRAM
    --------------------------------------------------------------------
    wait for 2 ns;  -- small time before first actions

    if endfile(fin) then
      report "input.txt is empty" severity failure;
    end if;

    -- Read first vectors (x and w) and first expected
    readline(fin,  L_in);
    readline(fout, L_out);

    -- Read activations from first line (applied AFTER reset)
    for i in 0 to N-1 loop
      read(L_in, xi);
      x(i) <= to_signed(xi, X_W_WIDTH);
    end loop;

    -- Read weights from first line and pack into SRAM word
    w_word := (others => '0');
    for i in 0 to N-1 loop
      read(L_in, wi);
      w_word((i+1)*X_W_WIDTH-1 downto i*X_W_WIDTH) :=
        std_logic_vector(to_signed(wi, X_W_WIDTH));
    end loop;

    -- Read expected output for first vector into queue
    read(L_out, exp_i);
    exp_q(wptr) <= to_signed(exp_i, Y_WIDTH_TRUNC);
    wptr <= (wptr + 1) mod QDEPTH;

    -- Program SRAM at addr 0 while reset is still asserted
    wait until rising_edge(clk);
    mem_addr <= (others => '0');
    mem_din  <= w_word;
    mem_we   <= '1';

    wait until rising_edge(clk);
    mem_we   <= '0';
    mem_din  <= (others => '0');

    --------------------------------------------------------------------
    -- 2) Release reset so top latches SRAM output on next clock
    --------------------------------------------------------------------
    wait for 2 ns;
    rst <= '0';

    -- Give SRAM output time to become valid and allow loaded='1'
    wait until rising_edge(clk);
    wait until rising_edge(clk);

    --------------------------------------------------------------------
    -- 3) Start streaming
    --------------------------------------------------------------------
    valid_in <= '1';

    -- First vector was already loaded into x() before; just advance one cycle
    wait until rising_edge(clk);

    -- Continue with remaining lines
    while not endfile(fin) loop
      readline(fin,  L_in);
      readline(fout, L_out);

      -- Read activations
      for i in 0 to N-1 loop
        read(L_in, xi);
        x(i) <= to_signed(xi, X_W_WIDTH);
      end loop;

      -- Read weights fields but ignore them (SRAM weights are fixed now)
      for i in 0 to N-1 loop
        read(L_in, wi);
        -- optional: you could check they match the first-line weights
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