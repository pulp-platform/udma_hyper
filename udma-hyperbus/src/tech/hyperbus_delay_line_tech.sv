// Copyright (C) 2017-2018 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

/// A single to double data rate converter.
`timescale 1 ps/1 ps

module hyperbus_delay_line (
    input        in,
    output       out,
    input [31:0] delay
);


    `ifndef SYNTHESIS

        assign #(1.5ns) out = in; 

    `else
    

        logic l1_left;
        logic l1_right;

        logic l2_0;
        logic l2_1;
        logic l2_2;// Copyright (C) 2017-2018 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

/// A single to double data rate converter.
`ifndef SYNTHESIS
    `timescale 1 ps/1 ps
`endif

module tc_delay (
    input        in,
    output       out,
    input [31:0] delay
);


    `ifndef SYNTHESIS

        assign #(1.5ns) out = in; 

    `else
    

        logic l1_left;
        logic l1_right;

        logic l2_0;
        logic l2_1;
        logic l2_2;
        logic l2_3;

    // Level 0
        //CKMUX2M2R i_clk_mux_top 
        //hyperbus_mux_generic i_clk_mux_top 
        tc_clk_mux2 i_clk_mux_top
        (
            .clk0_i ( l1_left  ),
            .clk1_i ( l1_right ),
            .clk_sel_i ( delay[2] ),
            .clk_o ( out      )
        );

    // Level 1
        //CKMUX2M2R i_clk_mux_l1_left 
        //hyperbus_mux_generic i_clk_mux_l1_left 
        tc_clk_mux2 i_clk_mux_l1_left
        (
            .clk0_i ( l2_0     ),
            .clk1_i ( l2_1     ),
            .clk_sel_i ( delay[1] ),
            .clk_o ( l1_left  )
        );

        //CKMUX2M2R i_clk_mux_l1_right 
        //hyperbus_mux_generic i_clk_mux_l1_right 
        tc_clk_mux2 i_clk_mux_l1_right
        (
            .clk0_i ( l2_2     ),
            .clk1_i ( l2_3     ),
            .clk_sel_i ( delay[1] ),
            .clk_o ( l1_right )
        );

    //Level 2
        //CKMUX2M2R i_clk_mux_l2_0
        //hyperbus_mux_generic i_clk_mux_l2_0
        tc_clk_mux2 i_clk_mux_l2_0
        (
            .clk0_i ( in       ),
            .clk1_i ( in       ),
            .clk_sel_i ( delay[0] ),
            .clk_o ( l2_0     )
        );

        //CKMUX2M2R i_clk_mux_l2_1
        //hyperbus_mux_generic i_clk_mux_l2_1
        tc_clk_mux2 i_clk_mux_l2_1
        (
            .clk0_i ( in       ),
            .clk1_i ( in       ),
            .clk_sel_i ( delay[0] ),
            .clk_o ( l2_1     )
        );

        //CKMUX2M2R i_clk_mux_l2_2
        //hyperbus_mux_generic i_clk_mux_l2_2
        tc_clk_mux2 i_clk_mux_l2_2
        (
            .clk0_i ( in       ),
            .clk1_i ( in       ),
            .clk_sel_i ( delay[0] ),
            .clk_o ( l2_2     )
        );

        //CKMUX2M2R i_clk_mux_l2_3
        //hyperbus_mux_generic i_clk_mux_l2_3
        tc_clk_mux2 i_clk_mux_l2_3
        (
            .clk0_i ( in       ),
            .clk1_i ( in       ),
            .clk_sel_i ( delay[0] ),
            .clk_o ( l2_3     )
        );

    `endif

endmodule

        logic l2_3;

    // Level 0
        //CKMUX2M2R i_clk_mux_top 
        //hyperbus_mux_generic i_clk_mux_top 
        SC8T_MUX2X1_A_CSC28L i_clk_mux_top
        (
            .D0 ( l1_left  ),
            .D1 ( l1_right ),
            .S ( delay[2] ),
            .Z ( out      )
        );

    // Level 1
        //CKMUX2M2R i_clk_mux_l1_left 
        //hyperbus_mux_generic i_clk_mux_l1_left 
        SC8T_MUX2X1_A_CSC28L i_clk_mux_l1_left
        (
            .D0 ( l2_0     ),
            .D1 ( l2_1     ),
            .S ( delay[1] ),
            .Z ( l1_left  )
        );

        //CKMUX2M2R i_clk_mux_l1_right 
        //hyperbus_mux_generic i_clk_mux_l1_right 
        SC8T_MUX2X1_A_CSC28L i_clk_mux_l1_right
        (
            .D0 ( l2_2     ),
            .D1 ( l2_3     ),
            .S ( delay[1] ),
            .Z ( l1_right )
        );

    //Level 2
        //CKMUX2M2R i_clk_mux_l2_0
        //hyperbus_mux_generic i_clk_mux_l2_0
        SC8T_MUX2X1_A_CSC28L i_clk_mux_l2_0
        (
            .D0 ( in       ),
            .D1 ( in       ),
            .S ( delay[0] ),
            .Z ( l2_0     )
        );

        //CKMUX2M2R i_clk_mux_l2_1
        //hyperbus_mux_generic i_clk_mux_l2_1
        SC8T_MUX2X1_A_CSC28L i_clk_mux_l2_1
        (
            .D0 ( in       ),
            .D1 ( in       ),
            .S ( delay[0] ),
            .Z ( l2_1     )
        );

        //CKMUX2M2R i_clk_mux_l2_2
        //hyperbus_mux_generic i_clk_mux_l2_2
        SC8T_MUX2X1_A_CSC28L i_clk_mux_l2_2
        (
            .D0 ( in       ),
            .D1 ( in       ),
            .S ( delay[0] ),
            .Z ( l2_2     )
        );

        //CKMUX2M2R i_clk_mux_l2_3
        //hyperbus_mux_generic i_clk_mux_l2_3
        SC8T_MUX2X1_A_CSC28L i_clk_mux_l2_3
        (
            .D0 ( in       ),
            .D1 ( in       ),
            .S ( delay[0] ),
            .Z ( l2_3     )
        );

    `endif

endmodule
