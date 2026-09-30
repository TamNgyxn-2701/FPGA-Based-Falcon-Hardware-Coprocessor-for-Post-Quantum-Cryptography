Muc dich:
fpc/ chua cac module tinh toan so phuc dang fixed-point.
Phien ban hien tai khong dung DesignWare, co the simulation va synthesis.

Dinh dang du lieu:
Q32.48 fixed-point
DATA_WIDTH = 80
FRAC_WIDTH = 48

Moi so phuc co dang:
a = a_re + j*a_im
b = b_re + j*b_im

Quy tac tinh toan:
FPC_ADD: d = a + b
d_re = a_re + b_re
d_im = a_im + b_im

FPC_SUB: d = a - b
d_re = a_re - b_re
d_im = a_im - b_im

FPC_MUL: d = a * b
d_re = a_re*b_re - a_im*b_im
d_im = a_re*b_im + a_im*b_re

Chuc nang tung file:

| File        | Chuc nang                                                   |
|-------------|-------------------------------------------------------------|
| fxp_mul.v   | Nhan hai so fixed-point signed                              |
| fpc_add.v   | Cong hai so phuc fixed-point                                |
| fpc_sub.v   | Tru hai so phuc fixed-point                                 |
| fpc_mul.v   | Nhan hai so phuc fixed-point                                |
| tb_fpc.v    | Testbench kiem tra chuc nang cac module FPC                 |
| list_fpc.f  | Danh sach file RTL dung de compile                          |
| run_fpc.sh  | Script chay simulation bang VCS                             |

Vi du Q32.48:
1.0  = 80'h0000_0001_0000_0000_0000
2.0  = 80'h0000_0002_0000_0000_0000
0.5  = 80'h0000_0000_8000_0000_0000
-1.0 = 80'hFFFF_FFFF_0000_0000_0000

Luu y:
- Day la fixed-point, khong phai IEEE-754 floating-point.
- Cac module khong dung DW_fp_add, DW_fp_sub, DW_fp_mult.
- Phep nhan fixed-point duoc tinh bang:
  z = (a * b) >>> FRAC_WIDTH

Trang thai test:
FPC_ADD : PASS
FPC_SUB : PASS
FPC_MUL : PASS
Format  : Q32.48 fixed-point
DW used : no
