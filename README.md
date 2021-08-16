# HyperBus Module

This is the pulp_io interface to communicate with hyperflash and hyperram. 
More thorough documentation can be found in the docs folder. This module has been designed by Hayate Okuhara <hayate.okuhara@unibo.it> . 
Its drivers can be found in the [regression_tests](https://github.com/pulp-platform/regression_tests/blob/master/peripherals/hyperbus/hyperbus_test.h) and in the [sdk](https://github.com/pulp-platform/pulp-sdk/blob/sup_fpga/rtos/pulpos/pulp/drivers/hyperbus/hyperbus-v3.c).

If the module is implemented as a hard macro, the `-t hyper_macro` bender target can be used to omit all the RTL sources during script generation. In this case only the utility pakage `hyper_pkg.sv` file will be part of the script generation.



