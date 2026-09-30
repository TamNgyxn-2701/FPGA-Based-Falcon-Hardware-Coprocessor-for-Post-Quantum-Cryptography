rtl/ip/04_core_ip/
│
├── fft/
│   ├── FFT.v
│   ├── RADIX2.v
│   ├── BUTTERFLY.v
│   ├── DELAY_BUFFER.v
│   └── FPC.v
│
├── ifft/
│   ├── IFFT.v
│   ├── RADIX2.v
│   ├── BUTTERFLY.v
│   ├── DELAY_BUFFER.v
│   └── FPC.v
│
├── fpc_core/
│   ├── FPC.sv
│   └── FPC_TOP.sv
│
├── bfu_core/
│   └── BFU.sv
│
├── shake256/
│   ├── shake256.v
│   ├── keccak_f1600.v
│   └── shake256_ctrl.v
│
├── hash_to_point/
│   ├── hash_to_point.v
│   ├── rejection_modq.v
│   └── c_ram_writer.v
│
├── samplerz/
│   ├── samplerz.v
│   ├── basesampler.v
│   ├── berexp.v
│   └── approxexp.v
│
├── norm_check/
│   ├── norm_check.v
│   └── POLY_SMALL_SQNORM.v
│
└── compress/
    ├── compress.v
    ├── coeff_encoder.v
    └── bitstream_packer.v
