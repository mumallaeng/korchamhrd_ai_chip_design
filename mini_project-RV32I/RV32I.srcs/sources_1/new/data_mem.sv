`timescale 1ns / 1ps
`include "header/define.vh"

module data_mem (
    input  logic        clk,
    input  logic        dwe,
    input  logic [ 2:0] mem_mode,
    input  logic [31:0] daddr,
    input  logic [31:0] dwdata,
    output logic [31:0] drdata
);

    logic [31:0] data_ram[0:255];

    always_ff @(posedge clk) begin
        if (dwe) begin
            case (mem_mode)
                `SW: begin
                    data_ram[daddr[31:2]] <= dwdata;
                end
                `SH: begin
                    if (!(daddr[1])) begin
                        data_ram[daddr[31:2]][15:0] <= dwdata[15:0];
                    end else begin
                        data_ram[daddr[31:2]][31:16] <= dwdata[15:0];
                    end
                end
                `SB: begin
                    case (daddr[1:0])
                        2'b00: data_ram[daddr[31:2]][7:0] <= dwdata[7:0];
                        2'b01: data_ram[daddr[31:2]][15:8] <= dwdata[7:0];
                        2'b10: data_ram[daddr[31:2]][23:16] <= dwdata[7:0];
                        2'b11: data_ram[daddr[31:2]][31:24] <= dwdata[7:0];
                    endcase

                end
            endcase
        end
    end

    always_comb begin
        case (mem_mode)
            `LW: begin
                drdata = data_ram[daddr[31:2]];
            end
            `LH: begin
                if (!(daddr[1])) begin
                    drdata = {
                        {16{data_ram[daddr[31:2]][15]}},
                        data_ram[daddr[31:2]][15:0]
                    };
                end else begin
                    drdata = {
                        {16{data_ram[daddr[31:2]][31]}},
                        data_ram[daddr[31:2]][31:16]
                    };
                end
            end
            `LB: begin
                case (daddr[1:0])
                    2'b00:
                    drdata = {
                        {24{data_ram[daddr[31:2]][7]}},
                        data_ram[daddr[31:2]][7:0]
                    };
                    2'b01:
                    drdata = {
                        {24{data_ram[daddr[31:2]][15]}},
                        data_ram[daddr[31:2]][15:8]
                    };
                    2'b10:
                    drdata = {
                        {24{data_ram[daddr[31:2]][23]}},
                        data_ram[daddr[31:2]][23:16]
                    };
                    2'b11:
                    drdata = {
                        {24{data_ram[daddr[31:2]][31]}},
                        data_ram[daddr[31:2]][31:24]
                    };
                endcase

            end
            `LBU: begin
                case (daddr[1:0])
                    2'b00: drdata = data_ram[daddr[31:2]][7:0];
                    2'b01: drdata = data_ram[daddr[31:2]][15:8];
                    2'b10: drdata = data_ram[daddr[31:2]][23:16];
                    2'b11: drdata = data_ram[daddr[31:2]][31:24];
                endcase
            end
            `LHU: begin
                if (!(daddr[1])) begin
                    drdata = data_ram[daddr[31:2]][15:0];

                end else begin
                    drdata = data_ram[daddr[31:2]][31:16];
                end
            end
            default: drdata = 32'h0000_0000;
        endcase
    end
endmodule
