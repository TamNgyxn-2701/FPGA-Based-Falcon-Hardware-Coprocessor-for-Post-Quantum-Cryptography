falcon512_sign_hw/
│
├── rtl/
│   ├── common/
│   │   ├── falcon512_params.v
│   │   └── task_opcode.v
│   │
│   ├── ctrl/
│   │   ├── sign_main_ctrl.v
│   │   ├── basis_build_ctrl.v
│   │   ├── gram_build_ctrl.v
│   │   ├── target_build_ctrl.v
│   │   ├── ffsampling_ctrl.v
│   │   ├── signature_compute_ctrl.v
│   │   └── norm_check_ctrl.v
│   │
│   ├── mem/
│   │   ├── key_ram.v
│   │   ├── h_ram.v
│   │   ├── msg_ram.v
│   │   ├── c_ram.v
│   │   ├── bhat_ram.v
│   │   ├── tree_ram.v
│   │   ├── target_ram.v
│   │   ├── sample_ram.v
│   │   ├── sig_ram.v
│   │   └── out_ram.v
│   │
│   ├── bus/
│   │   ├── bus_slave.v
│   │   ├── reg_file.v
│   │   └── ram_bus_mux.v
│   │
│   ├── ip/
│   │   ├── level1_primitive/
│   │   ├── level2_cell/
│   │   ├── level3_stage/
│   │   ├── level4_core_ip/
│   │   ├── level5_falcon_ip/
│   │   └── level6_phase_ip/
│   │
│   ├── wrapper/
│   │   ├── fft_wrapper.v
│   │   ├── ifft_wrapper.v
│   │   ├── bfu_wrapper.v
│   │   ├── fpc_wrapper.v
│   │   ├── samplerz_wrapper.v
│   │   └── shake256_wrapper.v
│   │
│   └── top/
│       └── falcon512_sign_top.v
│
├── tb/
├── sim/
├── vectors/
└── software_tools/
