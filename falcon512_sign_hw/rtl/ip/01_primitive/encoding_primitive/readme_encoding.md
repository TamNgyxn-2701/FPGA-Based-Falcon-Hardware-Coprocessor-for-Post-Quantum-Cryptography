Quy tac ma hoa:
coeff -> sign | low7 | unary(high) -> byte_out

Trong do:
- coeff      : he so signed dau vao
- sign       : bit dau cua coeff
- low7       : 7 bit thap cua |coeff|
- high       : phan con lai cua |coeff| sau khi bo 7 bit thap
- unary(high): ma unary cua high
- byte_out   : byte ket qua sau khi pack bit

Chuc nang tung file:

| File                 | Chuc nang                                      |
|----------------------|-----------------------------------------------|
| sign_bit.v           | Lay bit dau va tri tuyet doi cua coeff        |
| low7_encoder.v       | Tach abs_value thanh low7 va high             |
| unary_encoder.v      | Ma hoa high thanh unary code                  |
| bit_packer.v         | Gom tung bit thanh byte 8-bit                 |
| encoding_wrapper.v   | Ket noi cac module tren de encode mot he so   |
