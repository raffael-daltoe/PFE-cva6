.text
    .globl layer0
    .type layer0, @function
layer0:
    li t1, 128
    li t2, 8
    li a2, 11
layer0_oy_loop_begin:
    beqz a2, layer0_oy_loop_end
    li a3, 11
layer0_oy0_ox_loop_begin:
    beqz a3, layer0_oy0_ox_loop_end
    la t0, weight
    xadac.vbias 18, t1, 4
    xadac.vload 19, t0, 16
    xadac.vload 20, a1, 4
    addi t0, t0, 16
    addi a1, a1, 24
    xadac.vload 21, t0, 16
    xadac.vload 22, a1, 4
    addi t0, t0, 16
    addi a1, a1, 24
    xadac.vload 23, t0, 16
    xadac.vload 24, a1, 4
    addi t0, t0, 16
    addi a1, a1, 24
    xadac.vload 25, t0, 16
    xadac.vload 26, a1, 4
    addi t0, t0, 16
    addi a1, a1, 24
    xadac.vmacc 18, 19, 20, 4
    xadac.vmacc 18, 21, 22, 4
    xadac.vmacc 18, 23, 24, 4
    xadac.vmacc 18, 25, 26, 4
    addi a1, a1, -96
    xadac.vactv 18, a0, t2, 4
    addi a0, a0, 4
    xadac.vbias 18, t1, 4
    xadac.vload 19, t0, 16
    xadac.vload 20, a1, 4
    addi t0, t0, 16
    addi a1, a1, 24
    xadac.vload 21, t0, 16
    xadac.vload 22, a1, 4
    addi t0, t0, 16
    addi a1, a1, 24
    xadac.vload 23, t0, 16
    xadac.vload 24, a1, 4
    addi t0, t0, 16
    addi a1, a1, 24
    xadac.vload 25, t0, 16
    xadac.vload 26, a1, 4
    addi t0, t0, 16
    addi a1, a1, 24
    xadac.vmacc 18, 19, 20, 4
    xadac.vmacc 18, 21, 22, 4
    xadac.vmacc 18, 23, 24, 4
    xadac.vmacc 18, 25, 26, 4
    addi a1, a1, -96
    xadac.vactv 18, a0, t2, 4
    addi a0, a0, 4
    xadac.vbias 18, t1, 4
    xadac.vload 19, t0, 16
    xadac.vload 20, a1, 4
    addi t0, t0, 16
    addi a1, a1, 24
    xadac.vload 21, t0, 16
    xadac.vload 22, a1, 4
    addi t0, t0, 16
    addi a1, a1, 24
    xadac.vload 23, t0, 16
    xadac.vload 24, a1, 4
    addi t0, t0, 16
    addi a1, a1, 24
    xadac.vload 25, t0, 16
    xadac.vload 26, a1, 4
    addi t0, t0, 16
    addi a1, a1, 24
    xadac.vmacc 18, 19, 20, 4
    xadac.vmacc 18, 21, 22, 4
    xadac.vmacc 18, 23, 24, 4
    xadac.vmacc 18, 25, 26, 4
    addi a1, a1, -96
    xadac.vactv 18, a0, t2, 4
    addi a0, a0, 4
    xadac.vbias 18, t1, 4
    xadac.vload 19, t0, 16
    xadac.vload 20, a1, 4
    addi t0, t0, 16
    addi a1, a1, 24
    xadac.vload 21, t0, 16
    xadac.vload 22, a1, 4
    addi t0, t0, 16
    addi a1, a1, 24
    xadac.vload 23, t0, 16
    xadac.vload 24, a1, 4
    addi t0, t0, 16
    addi a1, a1, 24
    xadac.vload 25, t0, 16
    xadac.vload 26, a1, 4
    addi t0, t0, 16
    xadac.vmacc 18, 19, 20, 4
    xadac.vmacc 18, 21, 22, 4
    xadac.vmacc 18, 23, 24, 4
    xadac.vmacc 18, 25, 26, 4
    xadac.vactv 18, a0, t2, 4
    addi a0, a0, 4
    addi a3, a3, -1
addi a1, a1, -70
    j layer0_oy0_ox_loop_begin
layer0_oy0_ox_loop_end:
    addi a1, a1, 26
    addi a2, a2, -1
    j layer0_oy_loop_begin
layer0_oy_loop_end:
    ret

    .data
weight:
    .word 0xfdfa080d, 0xebf9f606, 0xd2c3c6d3, 0x2506f1df
    .word 0x0501f6f6, 0xd8d8dae0, 0xf7fafff9, 0x2c0defdf
    .word 0x07fb01fc, 0x0209f1d6, 0x242f2823, 0x1c1df1e1
    .word 0xf2fafefe, 0x33252a11, 0x0b110a10, 0x1a05f2e2
    .word 0x0b0a00f3, 0x201601fb, 0x19eae1f7, 0xfeff1725
    .word 0x1518ebe4, 0x02f3fe00, 0x24f9e8f1, 0xfbfff0fc
    .word 0x0c1702e5, 0xe3daee01, 0x2b06e4e8, 0x13f5fdeb
    .word 0xfd0df900, 0x00190e03, 0x200aefee, 0x1d0cfef1
    .word 0xd5fc2410, 0x1b1b03c8, 0x1c231401, 0x1cf5e408
    .word 0xf8231434, 0x151b19e4, 0x1b16f0ed, 0x04d2f41a
    .word 0xfb0e1d2c, 0xf5271c17, 0xfbe5d6df, 0x01f40619
    .word 0x06200a14, 0xc5e71016, 0xf3f7f201, 0xfa0114fd
    .word 0x36251111, 0xebebfbfc, 0x34351d08, 0xf0f4efff
    .word 0x21111a1d, 0xbfe0ff19, 0x32f3d3de, 0x03fef710
    .word 0x03f2f4f9, 0xda050d13, 0xfdcce2e2, 0xfff90c0c
    .word 0xdfcdd0d0, 0x0f313616, 0xe4e6f5fc, 0xf3f6fc15
