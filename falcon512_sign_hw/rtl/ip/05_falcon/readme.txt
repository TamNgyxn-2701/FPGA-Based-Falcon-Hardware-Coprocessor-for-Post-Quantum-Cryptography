rtl/ip/05_falcon/
│
├── key_loader/
│   ├── key_loader_ip.v
│   └── h_loader_ip.v
│
├── message_loader/
│   └── message_loader_ip.v
│
├── hash_to_point_system/
│   ├── salt_gen.v
│   ├── hash_to_point_system.v
│   └── c_ram_writer.v
│
├── bhat_builder/
│   ├── bhat_builder_ip.v
│   └── bhat_ram_writer.v
│
├── gram_builder/
│   ├── gram_matrix_builder_ip.v
│   └── gram_ram_writer.v
│
├── ldl_tree_builder/
│   ├── ldl_tree_builder_ip.v
│   ├── tree_normalize.v
│   └── tree_ram_writer.v
│
├── target_compute/
│   ├── target_compute_ip.v
│   └── target_ram_writer.v
│
├── ffsampling/
│   ├── ffsampling_ip.v
│   ├── recursive_scheduler.v
│   ├── tree_reader.v
│   └── sample_ram_writer.v
│
├── signature_compute/
│   ├── signature_compute_ip.v
│   ├── matrix_vector_mul_fft.v
│   └── sig_ram_writer.v
│
├── norm_retry/
│   ├── norm_retry_ip.v
│   └── retry_ctrl.v
│
└── signature_output/
    ├── signature_output_ip.v
    ├── signature_packer.v
    └── out_ram_writer.v
