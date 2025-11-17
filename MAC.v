module MAC_unit(vecA, vecB, int4_gate, int8_gate, VSQ_gate, partial_sum_in, result); // Fig 7
//(1) initialization of parameters
input  [255:0] vecA; // int8 : wide32 * 8 = 256 bits // int4 : wide64 * 4 = 256 bits
input  [255:0] vecB;
// 目前的理解是 partial sum in 是collector中的值，collector[lane_id(0~15)][ad_idx(0~15)]同時代表了當前計算要加上的值
input int4_gate; // int4 mode select
input int8_gate; // int8 mode select
input VSQ_gate; // VSQ mode select
input  [23:0] partial_sum_in; // partial sum in : 24 bits
output reg [23:0] result; // partial sum out : 24 bits

//(2) other regs and wires
/*reg signed [3:0] int4_VecA [0:63]; // int4
reg signed [3:0] int4_VecB [0:63];
reg signed [7:0] int8_VecA [0:31]; // int8
reg signed [7:0] int8_VecB [0:31]; */
reg signed [13:0] int4_dotout;
reg signed [20:0] int8_dotout;
integer m,n;

//(3) int4 no VSQ
always @(*) begin
    int4_dotout = 14'd0;
    if (int4_gate && !VSQ_gate) begin
        for (m=0; m<64; m=m+1) begin
            int4_dotout = int4_dotout + ({{10{vecA[m*4+3]}}, vecA[m*4 +: 4]} * {{10{vecB[m*4+3]}}, vecB[m*4 +: 4]});
        end
    end
end

//(4) int8 no VSQ
always @(*) begin
    int8_dotout = 21'd0;
    if (int8_gate && !VSQ_gate) begin
        for (n=0; n<32; n=n+1) begin
            int8_dotout = int8_dotout + ({{8{vecA[n*8+7]}}, vecA[n*8 +: 8]} * {{8{vecB[n*8+7]}}, vecB[n*8 +: 8]});
        end
    end
end

// assign result
always @(*) begin
    if (int4_gate && !VSQ_gate) begin
        result = partial_sum_in + {{10{int4_dotout[13]}}, int4_dotout};
    end
    else if (int8_gate && !VSQ_gate) begin
        result = partial_sum_in + {{3{int8_dotout[20]}}, int8_dotout};
    end
    else if (int4_gate && !int8_gate && VSQ_gate) begin
        result = 24'd0; // VSQ mode not implemented yet
    end
    else begin
        result = 24'd0;
    end
end
endmodule

module MAC16(vecA, vecB, int4_gate, int8_gate, VSQ_gate, partial_sum_in, result); // Fig 6 
// totally, (VL=16 * VS) partialA matrix * (VS*1) vecB = (VL=16 * 1) result vector
input  [255:0] vecA [0:15],   // 16 vector lanes 
input  [255:0] vecB,            
input          int4_gate,
input          int8_gate,
input          VSQ_gate,
input  [23:0]  partial_sum_in [0:15],
output [23:0]  result [0:15]
    
genvar i;
generate
    for(i = 0; i < 16; i = i + 1) begin : MAC_LANE
        MAC_unit MAC_inst (
            .vecA(vecA[i]),
            .vecB(vecB),
            .int4_gate(int4_gate),
            .int8_gate(int8_gate),
            .VSQ_gate(VSQ_gate),
            .partial_sum_in(partial_sum_in[i]),
            .result(result[i])
        );
    end
endgenerate
endmodule

