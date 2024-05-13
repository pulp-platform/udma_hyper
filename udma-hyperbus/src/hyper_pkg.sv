package hyper_pkg;
	// qspi structure
	typedef struct packed {
		logic hyper_cs0_no;
		logic hyper_cs1_no;
		logic hyper_ck_o;
		logic hyper_ck_no;
		logic hyper_rwds_o;
		logic hyper_rwds_oe;
		logic hyper_reset_no;
		logic hyper_dq0_o;
		logic hyper_dq1_o;
		logic hyper_dq2_o;
		logic hyper_dq3_o;
		logic hyper_dq4_o;
		logic hyper_dq5_o;
		logic hyper_dq6_o;
		logic hyper_dq7_o;
		logic hyper_dq_oe;
	} hyper_to_pad_t;

	typedef struct packed {
		logic hyper_rwds_i;
		logic hyper_dq0_i;
		logic hyper_dq1_i;
		logic hyper_dq2_i;
		logic hyper_dq3_i;
		logic hyper_dq4_i;
		logic hyper_dq5_i;
		logic hyper_dq6_i;
		logic hyper_dq7_i;
	} pad_to_hyper_t;
endpackage