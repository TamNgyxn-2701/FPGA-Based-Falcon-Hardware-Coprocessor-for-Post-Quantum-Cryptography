rtl/ip/
│
├── 01_primitive/
│   ├── fpc/
│   ├── fpr_inv/
│   ├── buffer/
│   ├── integer/
│   ├── modq/
│   ├── rng_primitive/
│   └── encoding_primitive/
│
├── 02_cell/
│   ├── butterfly_fft/
│   ├── butterfly_ifft/
│   ├── complex_ops/
│   ├── sampler_cell/
│   └── compress_cell/
│
├── 03_stage/
│   ├── radix2_fft/
│   ├── radix2_ifft/
│   ├── bfu/
│   └── samplerz_block/
│
├── 04_core/
│   ├── fft/
│   ├── ifft/
│   ├── bfu/
│   ├── fpc/
│   ├── shake256/
│   ├── hashtopoint/
│   ├── samplerz/
│   ├── norm_check/
│   └── compress/
│
├── 05_falcon/
│   ├── bhat_builder/
│   ├── gram_builder/
│   ├── ldl_tree_builder/
│   ├── target_compute/
│   ├── ffsampling/
│   ├── signature_compute/
│   ├── norm_retry/
│   └── signature_output/
│
└── 06_phase/
    ├── phase_load_key/
    ├── phase_hash_to_point/
    ├── phase_build_basis/
    ├── phase_gram_tree/
    ├── phase_target/
    ├── phase_ffsampling/
    ├── phase_sign/
    ├── phase_norm/
    └── phase_compress/
