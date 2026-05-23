library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.pkg.all;

entity top_with_activation_buffer_tb is
end entity top_with_activation_buffer_tb;

architecture tb of top_with_activation_buffer_tb is

  signal clk       : std_logic := '0';
  signal rst       : std_logic := '1';

  signal mem_we    : std_logic := '0';
  signal mem_addr  : unsigned(0 downto 0) := (others => '0');
  signal mem_din   : std_logic_vector(N*X_W_WIDTH-1 downto 0) := (others => '0');

  signal valid_in  : std_logic := '0';
  signal load_full : std_logic := '0';
  signal shift_horiz   : std_logic := '0';
  signal shift_vertical : std_logic := '0';

  signal x_full : x_w_array(0 to N-1);
  signal x_col0 : signed(X_W_WIDTH-1 downto 0) := (others => '0');
  signal x_col1 : signed(X_W_WIDTH-1 downto 0) := (others => '0');
  signal x_col2 : signed(X_W_WIDTH-1 downto 0) := (others => '0');
  signal x_row0, x_row1, x_row2 : signed(X_W_WIDTH-1 downto 0) := (others => '0');

  signal valid_out : std_logic;
  signal y         : signed(Y_WIDTH_TRUNC-1 downto 0);

  signal exp_q : exp_q_t := (others => (others => '0'));
  signal wptr  : integer := 0;
  signal rptr  : integer := 0;

  signal sent_count   : integer := 0;
  signal recv_count   : integer := 0;
  signal sending_done : std_logic := '0';

  file fweights : text open read_mode is "weights.txt";
  file fin      : text open read_mode is "input_windows.txt";
  file fout     : text open read_mode is "expected_out.txt";

begin

  dut : entity work.top_with_activation_buffer
    port map (
      clk       => clk,
      rst       => rst,
      mem_we    => mem_we,
      mem_addr  => mem_addr,
      mem_din   => mem_din,
      valid_in  => valid_in,
      load_full => load_full,
      shift_horiz   => shift_horiz,
      shift_vertical => shift_vertical,
      x_full    => x_full,
      x_col0    => x_col0,
      x_col1    => x_col1,
      x_col2    => x_col2,
      x_row0    => x_row0,
      x_row1    => x_row1,
      x_row2    => x_row2,
      valid_out => valid_out,
      y         => y
    );

  clk <= not clk after 0.5 ns;

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
      end if;
    end if;
  end process;

  stim : process
    variable Lw   : line;
    variable Lin  : line;
    variable Lout : line;

    variable vi   : integer;
    variable expi : integer;
    variable w_word : std_logic_vector(N*X_W_WIDTH-1 downto 0);

    variable mode : integer;
  begin
    for i in 0 to N-1 loop
      x_full(i) <= (others => '0');
    end loop;

    wait for 2 ns;

    -- read weights
    if endfile(fweights) then
      report "weights.txt is empty" severity failure;
    end if;

    readline(fweights, Lw);
    w_word := (others => '0');
    for i in 0 to N-1 loop
      read(Lw, vi);
      w_word((i+1)*X_W_WIDTH-1 downto i*X_W_WIDTH) :=
        std_logic_vector(to_signed(vi, X_W_WIDTH));
    end loop;

    -- program SRAM
    wait until rising_edge(clk);
    mem_addr <= (others => '0');
    mem_din  <= w_word;
    mem_we   <= '1';

    wait until rising_edge(clk);
    mem_we   <= '0';
    mem_din  <= (others => '0');

    wait for 2 ns;
    rst <= '0';

    wait until rising_edge(clk);
    wait until rising_edge(clk);

    valid_in <= '1';

    while not endfile(fin) loop
      readline(fin, Lin);
      readline(fout, Lout);

      -- mode: 0 = full 9-value load, 1 = shift with 3 new values
      read(Lin, mode);

      load_full <= '0';
      shift_horiz   <= '0';

      if mode = 0 then
        for i in 0 to N-1 loop
          read(Lin, vi);
          x_full(i) <= to_signed(vi, X_W_WIDTH);
        end loop;

        x_col0 <= (others => '0');
        x_col1 <= (others => '0');
        x_col2 <= (others => '0');
        load_full <= '1';

      else
        read(Lin, vi);
        x_col0 <= to_signed(vi, X_W_WIDTH);
        read(Lin, vi);
        x_col1 <= to_signed(vi, X_W_WIDTH);
        read(Lin, vi);
        x_col2 <= to_signed(vi, X_W_WIDTH);
        shift_horiz
 <= '1';
      end if;

      read(Lout, expi);
      exp_q(wptr) <= to_signed(expi, Y_WIDTH_TRUNC);
      wptr <= (wptr + 1) mod QDEPTH;
      sent_count <= sent_count + 1;

      wait until rising_edge(clk);

      load_full <= '0';
      shift_horiz   <= '0';
    end loop;

    valid_in <= '0';
    sending_done <= '1';

    wait for 20 ns;

    report "Sent vectors     = " & integer'image(sent_count);
    report "Received outputs = " & integer'image(recv_count);

    assert false report "TB DONE" severity failure;
  end process;

end architecture;