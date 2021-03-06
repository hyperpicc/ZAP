`default_nettype none
`include "zap_defines.vh"

//
// Top level testbench. Ties the CPU together with RAM and UART.
// UART address space starts from FFFFFFE0 to FFFFFFFF.
//

module zap_test; // +nctop+zap_test

// Bench related.

//`define STALL
//`define IRQ_EN
//`define MAX_CLOCK_CYCLES 100000

// CPU config.
parameter RAM_SIZE                      = 32768;
parameter START                         = 1992;
parameter COUNT                         = 120;
parameter DATA_SECTION_TLB_ENTRIES      = 4;
parameter DATA_LPAGE_TLB_ENTRIES        = 8;
parameter DATA_SPAGE_TLB_ENTRIES        = 16;
parameter DATA_CACHE_SIZE               = 1024;
parameter CODE_SECTION_TLB_ENTRIES      = 4;
parameter CODE_LPAGE_TLB_ENTRIES        = 8;
parameter CODE_SPAGE_TLB_ENTRIES        = 16;
parameter CODE_CACHE_SIZE               = 1024;
parameter FIFO_DEPTH                    = 4;
parameter BP_ENTRIES                    = 1024;
parameter STORE_BUFFER_DEPTH            = 32;

///////////////////////////////////////////////////////////////////////////////

reg             i_clk;
reg             i_reset;

reg             i_irq;
reg             i_fiq;

wire            data_wb_cyc; reg data_wb_cyc_ram, data_wb_cyc_uart;
wire            data_wb_stb; reg data_wb_stb_ram, data_wb_stb_uart;
wire [3:0]      data_wb_sel;
wire            data_wb_we;
reg [31:0]     data_wb_din; wire [31:0] data_wb_din_ram, data_wb_din_uart;
wire [31:0]     data_wb_dout;
wire [31:0]     data_wb_adr;
reg             data_wb_ack; wire data_wb_ack_ram, data_wb_ack_uart;
wire [2:0]      data_wb_cti; // Cycle Type Indicator.

// Wishbone selector.
always @*
begin
        data_wb_cyc_uart = 0;
        data_wb_stb_uart = 0;
        data_wb_cyc_ram  = 0;
        data_wb_stb_ram  = 0;

        if ( &data_wb_adr[31:5] ) // UART access
        begin
                data_wb_cyc_uart = data_wb_cyc;
                data_wb_stb_uart = data_wb_stb;
                data_wb_ack      = data_wb_ack_uart;
                data_wb_din      = data_wb_din_uart; 
        end
        else // RAM access
        begin
                data_wb_cyc_ram  = data_wb_cyc;
                data_wb_stb_ram  = data_wb_stb;
                data_wb_ack      = data_wb_ack_ram;
                data_wb_din      = data_wb_din_ram; 
        end
end

initial
begin
      
        $display("parameter RAM_SIZE              %d", RAM_SIZE           ); 
        $display("parameter START                 %d", START              ); 
        $display("parameter COUNT                 %d", COUNT              ); 
        $display("parameter FIFO_DEPTH            %d", u_zap_top.FIFO_DEPTH);
        
        `ifdef STALL
                $display("STALL defined!");
        `endif
        
        `ifdef IRQ_EN
                $display("IRQ_EN defined!");
        `endif
        
        `ifdef FIQ_EN
                $display("FIQ_EN defined!");
        `endif
        
        `ifdef MAX_CLOCK_CYCLES
                $display("MAX_CLOCK_CYCLES defined!");
        `endif
        
        `ifdef TLB_DEBUG
                $display("TLB_DEBUG defined!");
        `endif
        
        // CPU config.
        
        $display("parameter DATA_SECTION_TLB_ENTRIES      = %d", DATA_SECTION_TLB_ENTRIES    ) ;
        $display("parameter DATA_LPAGE_TLB_ENTRIES        = %d", DATA_LPAGE_TLB_ENTRIES      ) ;
        $display("parameter DATA_SPAGE_TLB_ENTRIES        = %d", DATA_SPAGE_TLB_ENTRIES      ) ;
        $display("parameter DATA_CACHE_SIZE               = %d", DATA_CACHE_SIZE             ) ;
        $display("parameter CODE_SECTION_TLB_ENTRIES      = %d", CODE_SECTION_TLB_ENTRIES    ) ;
        $display("parameter CODE_LPAGE_TLB_ENTRIES        = %d", CODE_LPAGE_TLB_ENTRIES      ) ;
        $display("parameter CODE_SPAGE_TLB_ENTRIES        = %d", CODE_SPAGE_TLB_ENTRIES      ) ;
        $display("parameter CODE_CACHE_SIZE               = %d", CODE_CACHE_SIZE             ) ;
        $display("parameter STORE_BUFFER_DEPTH            = %d", STORE_BUFFER_DEPTH          ) ;

end

// =========================
// Processor core.
// =========================
zap_top #(
        // Configure FIFO depth and BP entries.
        .FIFO_DEPTH(FIFO_DEPTH),
        .BP_ENTRIES(BP_ENTRIES),
        .STORE_BUFFER_DEPTH(STORE_BUFFER_DEPTH),

        // data config.
        .DATA_SECTION_TLB_ENTRIES(DATA_SECTION_TLB_ENTRIES),
        .DATA_LPAGE_TLB_ENTRIES(DATA_LPAGE_TLB_ENTRIES),
        .DATA_SPAGE_TLB_ENTRIES(DATA_SPAGE_TLB_ENTRIES),
        .DATA_CACHE_SIZE(DATA_CACHE_SIZE),

        // code config.
        .CODE_SECTION_TLB_ENTRIES(CODE_SECTION_TLB_ENTRIES),
        .CODE_LPAGE_TLB_ENTRIES(CODE_LPAGE_TLB_ENTRIES),
        .CODE_SPAGE_TLB_ENTRIES(CODE_SPAGE_TLB_ENTRIES),
        .CODE_CACHE_SIZE(CODE_CACHE_SIZE)
) 
u_zap_top 
(
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_irq(i_irq),
        .i_fiq(i_fiq),

        .o_wb_cyc(data_wb_cyc),
        .o_wb_stb(data_wb_stb),
        .o_wb_adr(data_wb_adr),
        .o_wb_we (data_wb_we),
        .o_wb_cti(data_wb_cti),
        .i_wb_dat(data_wb_din),
        .o_wb_dat(data_wb_dout),
        .i_wb_ack(data_wb_ack),
        .o_wb_sel(data_wb_sel)

);

// ===============================
// UART
// ===============================

wire uart_in = 1'd0;
wire uart_out;

uart_top u_uart_top (

        // WISHBONE interface
        .wb_clk_i(i_clk),
        .wb_rst_i(i_reset),
        .wb_adr_i(data_wb_adr),
        .wb_dat_i(data_wb_dout),
        .wb_dat_o(data_wb_din_uart),
        .wb_we_i (data_wb_we),
        .wb_stb_i(data_wb_stb_uart),
        .wb_cyc_i(data_wb_cyc_uart),
        .wb_sel_i(data_wb_sel),
        .wb_ack_o(data_wb_ack_uart),
        .int_o   (), // Interrupt.
        
        // UART signals.
        .srx_pad_i(uart_in),
        .stx_pad_o(uart_out),
        .rts_pad_o(),
        .cts_pad_i(1'd0),
        .dtr_pad_o(),
        .dsr_pad_i(1'd0),
        .ri_pad_i (1'd0),
        .dcd_pad_i(1'd0)
);

reg [3:0] clk_ctr = 4'd0;

// Logic to read from UART - Assumes no parity, 8 bits per character and
// 1 stop bit. TB logic.

localparam UART_WAIT_FOR_START = 0;
localparam UART_RX             = 1;
localparam UART_STOP_BIT       = 2;

integer uart_state = UART_WAIT_FOR_START;
reg uart_sof = 1'd0;
reg uart_eof = 1'd0;
integer uart_ctr = 0;
integer uart_bit_ctr = 1'dx;
reg [7:0] uart_sr = 0;
reg [7:0] UART_SR;
reg       UART_SR_DAV;

always @ (posedge i_clk)
begin
        UART_SR_DAV = 1'd0;
        uart_sof = 1'd0;
        uart_eof = 1'd0;

        case ( uart_state ) 
                UART_WAIT_FOR_START:
                begin
                        if ( !uart_out ) 
                        begin
                                uart_ctr = uart_ctr + 1;
                                uart_sof = 1'd1;
                        end

                        if ( !uart_out && uart_ctr == 16  ) 
                        begin
                                uart_sof     = 1'd0;
                                uart_state   = UART_RX;
                                uart_ctr     = 0;
                                uart_bit_ctr = 0;
                        end                        
                end

                UART_RX:
                begin
                        uart_ctr++;

                        if ( uart_ctr == 2 ) 
                                uart_sr = uart_sr >> 1 | uart_out << 7;                                

                        if ( uart_ctr == 16 ) 
                        begin
                                uart_bit_ctr++;
                                uart_ctr = 0;

                                if ( uart_bit_ctr == 8 ) 
                                begin
                                        uart_state  = UART_STOP_BIT;                               
                                        UART_SR     = uart_sr;
                                        UART_SR_DAV = 1'd1;
                                        uart_ctr    = 0;
                                        uart_bit_ctr = 0;
                                end
                        end                        
                end

                UART_STOP_BIT:
                begin
                        uart_ctr++;

                        if ( uart_out && uart_ctr == 16 ) // Stop bit.
                        begin
                                uart_state = UART_WAIT_FOR_START;                                
                                uart_bit_ctr = 0;
                                uart_ctr = 0;
                        end
                end
        endcase
end

// Write ASCII characters on UART TX to a file.

integer signed fh;

initial
begin
        fh = $fopen(`UART_FILE_PATH, "w");

        if ( fh == -1 ) 
        begin
                $display($time, " - Error: Failed to open UART output log.");
                $finish;
        end
        else    
        begin
                $display($time, " - File opened %s!", `UART_FILE_PATH);
        end
end

always @ (negedge i_clk)
begin
        if ( UART_SR_DAV )
        begin
                $display("UART Wrote %c", UART_SR);
                $fwrite(fh, "%c", UART_SR);
                $fflush(fh);
        end
end

// ===============================
// RAM
// ===============================
model_ram_dual
#(
        .SIZE_IN_BYTES  (RAM_SIZE)
)
U_MODEL_RAM_DATA
(
        .i_clk(i_clk),

        .i_wb_cyc(data_wb_cyc_ram),
        .i_wb_stb(data_wb_stb_ram),
        .i_wb_adr(data_wb_adr),
        .i_wb_we(data_wb_we),
        .o_wb_dat(data_wb_din_ram),
        .i_wb_dat(data_wb_dout),
        .o_wb_ack(data_wb_ack_ram),
        .i_wb_sel(data_wb_sel),

        // Port 2 is unused.
        .i_wb_cyc2(0),
        .i_wb_stb2(0),
        .i_wb_adr2(0),
        .i_wb_we2 (0),
        .o_wb_dat2(),
        .o_wb_ack2(),
        .i_wb_sel2(0),
        .i_wb_dat2(0)
);

// ===========================
// Variables.
// ===========================
integer i;

// ===========================
// Clocks.
// ===========================
initial         i_clk    = 0;
always #10      i_clk = !i_clk;

integer seed = `SEED;
integer seed_new = `SEED + 1;

// ===========================
// Interrupts
// ===========================

`ifdef IRQ_EN

always @ (negedge i_clk)
begin
        i_irq = $random(seed);
end

`endif

`ifdef FIQ_EN

always @ (negedge i_clk)
begin: blk1
        reg [1:0] x;
        x = $random(seed_new);

        i_fiq = (x == 0) ? 1'd1 : 1'd0 ; // 25 percent chance.
end

`endif

initial i_reset = 1'd0;

initial
begin
        i_irq = 0;
        i_fiq = 0;

        for(i=START;i<START+COUNT;i=i+4)
        begin
                $display("DATA INITIAL :: mem[%d] = %x", i, {U_MODEL_RAM_DATA.ram[(i/4)]});
        end

        $dumpfile(`VCD_FILE_PATH);
        $dumpvars;

        $display($time," - Applying reset...");

        @(posedge i_clk);
        i_reset <= 1;
        @(posedge i_clk);
        i_reset <= 0;

        $display($time, " - Running for %d clock cycles...", `MAX_CLOCK_CYCLES);

        repeat(`MAX_CLOCK_CYCLES) 
                @(negedge i_clk);

        $display($time, " - Clock cycles elapsed. Generating memory data.");

        $display(">>>>>>>>>>>>>>>>>>>>>>> MEMORY DUMP START <<<<<<<<<<<<<<<<<<<<<<<");

        for(i=START;i<START+COUNT;i=i+4)
        begin
                $display("DATA mem[%d] = %x", i, {U_MODEL_RAM_DATA.ram[(i/4)]});
        end

        $display("<<<<<<<<<<<<<<<<<<<<<<< MEMORY DUMP END >>>>>>>>>>>>>>>>>>>>>>>>>>");

        $fclose(fh);

        `include "zap_check.vh"                
end

endmodule

`default_nettype wire
