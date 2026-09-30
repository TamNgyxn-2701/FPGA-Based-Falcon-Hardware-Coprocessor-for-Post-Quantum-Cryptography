rtl/ip/01_primitive/
│
├── fpc/
│   ├── fxp_mul.v
│   ├── fpr_add.v
│   ├── fpr_sub.v
│   └── fpr_mul.v
│
├── fpr_inv/
│   └── fpr_inv.v
│
├── buffer/
│   ├── DELAY_BUFFER.v
│   └── valid_delay.v
│
├── integer/
│   ├── int_add.v
│   ├── int_sub.v
│   ├── abs.v
│   ├── square.v
│   ├── accumulator.v
│   └── comparator.v
│
├── modq/
│   ├── montymul_core.v
│   ├── mq_montymul_wrapper.v
│   ├── mq_add.v
│   ├── mq_sub.v
│   └── reduce_mod_q.v
│
├── rng_primitive/
│   ├── uniform_bits.v
│   └── random_byte.v
│   └── rng_wrapper.v
│
└── encoding_primitive/
    ├── sign_bit.v
    ├── low7_encoder.v
    ├── unary_encoder.v
    ├── bit_packer.v
    └── encoding_wrapper.v


=============
ORDER_TESTBECH
=============
integer/
buffer/
modq/
rng_primitive/
encoding_primitive/
fpc/
fpr_inv/
