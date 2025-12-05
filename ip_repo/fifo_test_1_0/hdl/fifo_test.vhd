library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_test is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4;

		-- Parameters of Axi Slave Bus Interface S_AXIS
		C_S_AXIS_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S_AXIS
		s_axis_aclk	: in std_logic;
		s_axis_aresetn	: in std_logic;
		--s_axis_tready	: out std_logic;
		s_axis_tdata	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		--s_axis_tstrb	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		--s_axis_tlast	: in std_logic;
		s_axis_tvalid	: in std_logic
		
	);
end fifo_test;

architecture arch_imp of fifo_test is
    -- FIFO parameters
    constant FIFO_DEPTH : integer := 1024;
    
    signal counter : unsigned(31 downto 0);

    -- FIFO interface signals
    signal fifo_din   : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
    signal fifo_dout  : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
    signal fifo_wr_en : std_logic;
    signal fifo_rd_en : std_logic;
    signal fifo_full  : std_logic;
    signal fifo_empty : std_logic;
    signal fifo_count : unsigned(15 downto 0);  -- number of words in FIFO
    
    type fifo_mem_t is array (0 to FIFO_DEPTH-1) of std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
    signal fifo_mem : fifo_mem_t;
    signal wr_ptr   : unsigned(15 downto 0);
    signal rd_ptr   : unsigned(15 downto 0);
    signal cnt      : unsigned(15 downto 0);
	-- component declaration
	component fifo_test_slave_lite_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic;
		
		fifo_dout   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        fifo_count  : in  std_logic_vector(15 downto 0);
        fifo_rd_en  : out std_logic;
        counter : in std_logic_vector(31 downto 0)
		);
	end component fifo_test_slave_lite_v1_0_S00_AXI;

	component fifo_test_slave_stream_v1_0_S_AXIS is
		generic (
		C_S_AXIS_TDATA_WIDTH	: integer	:= 32
		);
		port (
		S_AXIS_ACLK	: in std_logic;
		S_AXIS_ARESETN	: in std_logic;
		--S_AXIS_TREADY	: out std_logic;
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		--S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		--S_AXIS_TLAST	: in std_logic;
		S_AXIS_TVALID	: in std_logic;
		
		fifo_din   : out std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
        fifo_wr_en : out std_logic;
        fifo_full  : in  std_logic
		);
	end component fifo_test_slave_stream_v1_0_S_AXIS;

begin

-- Instantiation of Axi Bus Interface S00_AXI
fifo_test_slave_lite_v1_0_S00_AXI_inst : fifo_test_slave_lite_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready,
		
		fifo_dout  => fifo_dout,
        fifo_count => std_logic_vector(fifo_count),
        fifo_rd_en => fifo_rd_en,
        counter => std_logic_vector(counter)
	);

-- Instantiation of Axi Bus Interface S_AXIS
fifo_test_slave_stream_v1_0_S_AXIS_inst : fifo_test_slave_stream_v1_0_S_AXIS
	generic map (
		C_S_AXIS_TDATA_WIDTH	=> C_S_AXIS_TDATA_WIDTH
	)
	port map (
		S_AXIS_ACLK	=> s_axis_aclk,
		S_AXIS_ARESETN	=> s_axis_aresetn,
		--S_AXIS_TREADY	=> s_axis_tready,
		S_AXIS_TDATA	=> s_axis_tdata,
		--S_AXIS_TSTRB	=> s_axis_tstrb,
		--S_AXIS_TLAST	=> s_axis_tlast,
		S_AXIS_TVALID	=> s_axis_tvalid,
		
		fifo_din   => fifo_din,
        fifo_wr_en => fifo_wr_en,
        fifo_full  => fifo_full
	);

	-- Add user logic here
    fifo_proc : process(s_axis_aclk)
    begin
        if rising_edge(s_axis_aclk) then
            if s_axis_aresetn = '0' then
                wr_ptr   <= (others => '0');
                rd_ptr   <= (others => '0');
                cnt      <= (others => '0');
                fifo_dout <= (others => '0');
            else
                --cnt debug lines...
                --if s_axis_aresetn = '1' then
                --    cnt    <= cnt + 1;
                --end if;
                -- write side (AXI-Stream)
                if fifo_wr_en = '1' then
                    counter <= counter + 1;
                end if;
                if fifo_wr_en = '1' and fifo_full = '0' then
                    fifo_mem(to_integer(wr_ptr)) <= fifo_din;
                    wr_ptr <= wr_ptr + 1;
                    cnt    <= cnt + 1;
                end if;
    
                -- read side (AXI-Lite)
                if fifo_rd_en = '1' and fifo_empty = '0' then
                    fifo_dout <= fifo_mem(to_integer(rd_ptr));
                    rd_ptr    <= rd_ptr + 1;
                    cnt       <= cnt - 1;
                end if;
    
                
            end if;
        end if;
    end process;
    fifo_empty <= '1' when cnt = 0 else '0';
    fifo_full  <= '1' when cnt = FIFO_DEPTH else '0';
    fifo_count <= cnt;
	-- User logic ends

end arch_imp;
