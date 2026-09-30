Muc dich:
modq/ chua cac module tinh toan so nguyen theo modulo q.

Trong Falcon, modulus chinh la:
q = 12289

Cac module trong folder nay dung de thuc hien cac phep toan co ban tren mien modulo q, bao gom:
- Reduce modulo q
- Cong modulo q
- Tru modulo q
- Nhan Montgomery modulo q

Dinh dang du lieu:
Q_WIDTH = 14

Vi:
q = 12289 < 2^14 = 16384

Nen moi gia tri modulo q duoc bieu dien bang 14 bit.

Mien gia tri hop le:
0 <= a < q
0 <= b < q

Tuc la:
0 <= a, b <= 12288

Quy tac tinh toan:

reduce_mod_q:
d = a mod q

mq_add:
d = (a + b) mod q

mq_sub:
d = (a - b) mod q

mq_montymul_wrapper:
d = a * b * R^(-1) mod q

Voi:
q = 12289
R = 2^16
R^(-1) mod q = 2304

Chuc nang tung file:

| File                   | Chuc nang                                           |
|------------------------|-----------------------------------------------------|
| reduce_mod_q.v         | Giam gia tri 16-bit ve mien modulo q                |
| mq_add.v               | Cong hai so modulo q                                |
| mq_sub.v               | Tru hai so modulo q                                 |
| montymul_core.v        | Core nhan Montgomery modulo q                       |
| mq_montymul_wrapper.v  | Wrapper cho montymul_core                           |
| tb_modq.v              | Testbench kiem tra cac module trong modq/           |
| list_modq.f            | Danh sach file RTL dung de compile                  |
| run_modq.sh            | Script chay simulation bang VCS                     |
| readme_modq.md         | Mo ta chuc nang va cach hoat dong cua modq/         |

Tin hieu chinh cua reduce_mod_q:

| Tin hieu | Chuc nang                         |
|----------|-----------------------------------|
| a        | Gia tri dau vao 16-bit            |
| d        | Ket qua sau khi reduce modulo q   |

Tin hieu chinh cua mq_add va mq_sub:

| Tin hieu | Chuc nang                |
|----------|--------------------------|
| a        | Toan hang thu nhat       |
| b        | Toan hang thu hai        |
| d        | Ket qua modulo q         |

Tin hieu chinh cua mq_montymul_wrapper:

| Tin hieu   | Chuc nang                         |
|------------|-----------------------------------|
| clk        | Clock                             |
| rst_n      | Reset muc thap                    |
| in_valid   | Bao input a, b hop le             |
| a          | Toan hang thu nhat                |
| b          | Toan hang thu hai                 |
| out_valid  | Bao output d hop le               |
| d          | Ket qua nhan Montgomery modulo q  |

Cach hoat dong:

1. reduce_mod_q:
   - Nhan input a 16-bit.
   - Neu a >= q thi tru q mot hoac nhieu lan.
   - Tra ve d = a mod q.

2. mq_add:
   - Tinh sum = a + b.
   - Neu sum >= q thi tru q.
   - Tra ve d = (a + b) mod q.

3. mq_sub:
   - Tinh sub = a - b.
   - Neu a < b thi cong them q.
   - Tra ve d = (a - b) mod q.

4. mq_montymul_wrapper:
   - Goi montymul_core.
   - Tinh phep nhan Montgomery:
     d = a * b * R^(-1) mod q
   - out_valid = 1 khi ket qua d hop le.

Cac truong hop da test:

reduce_mod_q:
| Test case       | Ket qua mong muon |
|-----------------|-------------------|
| 0 mod q         | 0                 |
| 1 mod q         | 1                 |
| 12288 mod q     | 12288             |
| 12289 mod q     | 0                 |
| 12290 mod q     | 1                 |
| 65535 mod q     | 4090              |

mq_add:
| Test case              | Ket qua mong muon |
|------------------------|-------------------|
| 1 + 2                  | 3                 |
| 12288 + 1              | 0                 |
| 7000 + 6000            | 711               |
| 10000 + 3000           | 711               |

mq_sub:
| Test case              | Ket qua mong muon |
|------------------------|-------------------|
| 5 - 3                  | 2                 |
| 3 - 5                  | 12287             |
| 0 - 1                  | 12288             |
| 12288 - 12288          | 0                 |

mq_montymul_wrapper:
| Test case              | Ket qua tinh theo |
|------------------------|-------------------|
| 1 * 1                  | 1 * 1 * R^(-1) mod q |
| 2 * 3                  | 2 * 3 * R^(-1) mod q |
| 100 * 200              | 100 * 200 * R^(-1) mod q |
| 12288 * 12288          | 12288 * 12288 * R^(-1) mod q |

Ket qua test:
MODQ PRIMITIVE TEST PASS

Luu y:
- modq/ xu ly so nguyen modulo q, khong phai fixed-point.
- Khong dung DesignWare.
- Co the simulation va synthesis bang Verilog chuan.
- Montgomery multiplication khong phai phep nhan thong thuong a*b mod q.
- Ket qua cua mq_montymul_wrapper la:
  a * b * R^(-1) mod q

Vai tro trong Falcon-512:
modq/ la nhom primitive quan trong cho cac phep toan tren da thuc modulo q.

Cac module nay co the duoc dung trong:
- NTT / inverse NTT
- Polynomial arithmetic
- HashToPoint
- Verify
- Signature arithmetic
- Cac khoi xu ly he so modulo q

Trang thai:
reduce_mod_q        : PASS
mq_add              : PASS
mq_sub              : PASS
mq_montymul_wrapper : PASS
Format              : integer modulo q
q                   : 12289
DW used             : no
Status              : ready for higher-level integration
