    .text
    .globl layer3
    .type layer3, @function
layer3:
    li t0, 1024
    li a4, 11
    la t4, weight
    xadac.vbias 27, t0, 4
    li t1, 4
layer3_oy0_ox0_oa0_wy0_wx0_ia_loop_begin:
    beqz t1, layer3_oy0_ox0_oa0_wy0_wx0_ia_loop_end
    xadac.vload 26, t4, 16
    xadac.vload 25, a1, 4
    xadac.vmacc 27, 26, 25, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 24, t4, 16
    xadac.vload 23, a1, 4
    xadac.vmacc 27, 24, 23, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 22, t4, 16
    xadac.vload 21, a1, 4
    xadac.vmacc 27, 22, 21, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 20, t4, 16
    xadac.vload 19, a1, 4
    xadac.vmacc 27, 20, 19, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 18, t4, 16
    xadac.vload 26, a1, 4
    xadac.vmacc 27, 18, 26, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 25, t4, 16
    xadac.vload 24, a1, 4
    xadac.vmacc 27, 25, 24, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 23, t4, 16
    xadac.vload 22, a1, 4
    xadac.vmacc 27, 23, 22, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 21, t4, 16
    xadac.vload 20, a1, 4
    xadac.vmacc 27, 21, 20, 4
    addi t4, t4, 16
    addi a1, a1, 4
    addi t1, t1, -1
    j layer3_oy0_ox0_oa0_wy0_wx0_ia_loop_begin
layer3_oy0_ox0_oa0_wy0_wx0_ia_loop_end:
    xadac.vload 19, t4, 16
    xadac.vload 18, a1, 4
    xadac.vmacc 27, 19, 18, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 26, t4, 16
    xadac.vload 25, a1, 4
    xadac.vmacc 27, 26, 25, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 24, t4, 16
    xadac.vload 23, a1, 4
    xadac.vmacc 27, 24, 23, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 22, t4, 16
    xadac.vload 21, a1, 4
    xadac.vmacc 27, 22, 21, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 20, t4, 16
    xadac.vload 19, a1, 4
    xadac.vmacc 27, 20, 19, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 18, t4, 16
    xadac.vload 26, a1, 4
    xadac.vmacc 27, 18, 26, 4
    addi t4, t4, 16
    addi a1, a1, 4
    addi a1, a1, 0
    addi a1, a1, -152
    xadac.vactv 27, a0, a4, 4
    addi a0, a0, 4
    xadac.vbias 25, t0, 4
    li t1, 4
layer3_oy0_ox0_oa1_wy0_wx0_ia_loop_begin:
    beqz t1, layer3_oy0_ox0_oa1_wy0_wx0_ia_loop_end
    xadac.vload 24, t4, 16
    xadac.vload 23, a1, 4
    xadac.vmacc 25, 24, 23, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 22, t4, 16
    xadac.vload 21, a1, 4
    xadac.vmacc 25, 22, 21, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 20, t4, 16
    xadac.vload 19, a1, 4
    xadac.vmacc 25, 20, 19, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 18, t4, 16
    xadac.vload 26, a1, 4
    xadac.vmacc 25, 18, 26, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 27, t4, 16
    xadac.vload 24, a1, 4
    xadac.vmacc 25, 27, 24, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 23, t4, 16
    xadac.vload 22, a1, 4
    xadac.vmacc 25, 23, 22, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 21, t4, 16
    xadac.vload 20, a1, 4
    xadac.vmacc 25, 21, 20, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 19, t4, 16
    xadac.vload 18, a1, 4
    xadac.vmacc 25, 19, 18, 4
    addi t4, t4, 16
    addi a1, a1, 4
    addi t1, t1, -1
    j layer3_oy0_ox0_oa1_wy0_wx0_ia_loop_begin
layer3_oy0_ox0_oa1_wy0_wx0_ia_loop_end:
    xadac.vload 26, t4, 16
    xadac.vload 27, a1, 4
    xadac.vmacc 25, 26, 27, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 24, t4, 16
    xadac.vload 23, a1, 4
    xadac.vmacc 25, 24, 23, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 22, t4, 16
    xadac.vload 21, a1, 4
    xadac.vmacc 25, 22, 21, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 20, t4, 16
    xadac.vload 19, a1, 4
    xadac.vmacc 25, 20, 19, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 18, t4, 16
    xadac.vload 26, a1, 4
    xadac.vmacc 25, 18, 26, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 27, t4, 16
    xadac.vload 24, a1, 4
    xadac.vmacc 25, 27, 24, 4
    addi t4, t4, 16
    addi a1, a1, 4
    addi a1, a1, 0
    addi a1, a1, -152
    xadac.vactv 25, a0, a4, 4
    addi a0, a0, 4
    xadac.vbias 23, t0, 4
    li t1, 4
layer3_oy0_ox0_oa2_wy0_wx0_ia_loop_begin:
    beqz t1, layer3_oy0_ox0_oa2_wy0_wx0_ia_loop_end
    xadac.vload 22, t4, 16
    xadac.vload 21, a1, 4
    xadac.vmacc 23, 22, 21, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 20, t4, 16
    xadac.vload 19, a1, 4
    xadac.vmacc 23, 20, 19, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 18, t4, 16
    xadac.vload 26, a1, 4
    xadac.vmacc 23, 18, 26, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 27, t4, 16
    xadac.vload 24, a1, 4
    xadac.vmacc 23, 27, 24, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 25, t4, 16
    xadac.vload 22, a1, 4
    xadac.vmacc 23, 25, 22, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 21, t4, 16
    xadac.vload 20, a1, 4
    xadac.vmacc 23, 21, 20, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 19, t4, 16
    xadac.vload 18, a1, 4
    xadac.vmacc 23, 19, 18, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 26, t4, 16
    xadac.vload 27, a1, 4
    xadac.vmacc 23, 26, 27, 4
    addi t4, t4, 16
    addi a1, a1, 4
    addi t1, t1, -1
    j layer3_oy0_ox0_oa2_wy0_wx0_ia_loop_begin
layer3_oy0_ox0_oa2_wy0_wx0_ia_loop_end:
    xadac.vload 24, t4, 16
    xadac.vload 25, a1, 4
    xadac.vmacc 23, 24, 25, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 22, t4, 16
    xadac.vload 21, a1, 4
    xadac.vmacc 23, 22, 21, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 20, t4, 16
    xadac.vload 19, a1, 4
    xadac.vmacc 23, 20, 19, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 18, t4, 16
    xadac.vload 26, a1, 4
    xadac.vmacc 23, 18, 26, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 27, t4, 16
    xadac.vload 24, a1, 4
    xadac.vmacc 23, 27, 24, 4
    addi t4, t4, 16
    addi a1, a1, 4
    xadac.vload 25, t4, 16
    xadac.vload 22, a1, 4
    xadac.vmacc 23, 25, 22, 4
    addi t4, t4, 16
    addi a1, a1, 4
    addi a1, a1, 0
    addi a1, a1, -152
    xadac.vactv 23, a0, a4, 2
    addi a0, a0, 2
    addi a1, a1, 150
    addi a1, a1, 0
    ret

    .data
weight:
    .word 0xe4fafbc9, 0x04e2340e, 0x323027e7, 0xfd1de8f9
    .word 0xe31edae6, 0xf0ddddeb, 0x2700dbdf, 0xf2320dd9
    .word 0x2ce7e4fb, 0x24e1ee28, 0x1603efd5, 0xe93ae4e1
    .word 0xe9f9edf8, 0xfa2df927, 0xe5e4fe2c, 0xf8e2032f
    .word 0x1cf61df2, 0xed02fb20, 0x2708f430, 0x2214f82e
    .word 0xd9da211e, 0x2329e6e5, 0xcdcc1d1b, 0x2c361dd8
    .word 0xedf210dc, 0xda22e73a, 0xe8de1e39, 0xd9e2e3d4
    .word 0x3afdf4e7, 0xeff6ec06, 0x07070207, 0xe3e5f8f8
    .word 0x29d5fb06, 0x1ffa0430, 0x132dfde5, 0xce37efed
    .word 0x2ce9fc1b, 0xdd04f8e1, 0xf3212014, 0xe22837e6
    .word 0x03fedf1c, 0xfbea3134, 0xf5eef32c, 0x0623e7e6
    .word 0x2ef9e928, 0xf8f1e1ed, 0xe4f72fe9, 0xf3e4f8ec
    .word 0xd8edeb26, 0xdb25ebd3, 0xc1cecf07, 0x2f282fd4
    .word 0xf3ebeff7, 0xd0e62a01, 0x14f032ff, 0xece7f7f0
    .word 0xd6fcf922, 0xe4ebf5ef, 0xf20201f7, 0xddfb39d6
    .word 0xe2f6242f, 0x1613eef0, 0xd50ae438, 0x22fef0e4
    .word 0xe21ce6eb, 0x18073509, 0x2de5fd04, 0xe91ceb01
    .word 0x3c140132, 0xe5f3d71d, 0x1637d619, 0xdbfdcbf7
    .word 0xfbf62a2c, 0xede7eef1, 0xecdf21d7, 0x33390bfb
    .word 0xf8f8fc1e, 0x1cdaf2ef, 0xe6d4f520, 0xe32e0010
    .word 0xec28ddfa, 0xe52135fa, 0xe2d43128, 0xe3eee6dd
    .word 0xe012e9ec, 0xd12216db, 0xe4142f28, 0xfd0bee14
    .word 0x2cf8ed0c, 0xdbf4f80b, 0xe0311df4, 0x06ebfaff
    .word 0x27df12e8, 0xe025ec2e, 0xf3d130d1, 0xe6dbf6e5
    .word 0xd91be925, 0x26e815e3, 0x2be4c7d0, 0x29d61bde
    .word 0xe20e1f02, 0x36e81a32, 0x2af911fb, 0xeb2b0feb
    .word 0xe7d0de31, 0xcaf2e4ed, 0xdf1bd827, 0xd92732e8
    .word 0xf026fdec, 0xefe5f318, 0xeae5f4ed, 0x39eefde5
    .word 0xfb00e327, 0x16f3e501, 0xff2ae717, 0x312430dd
    .word 0x1406e507, 0xd9eb1f29, 0x31fa11e8, 0x2ef3cfef
    .word 0xfdf6f327, 0xec0d2b2a, 0xff2401e9, 0x272032ed
    .word 0xdff8d7db, 0x2fe519eb, 0xf0da1ff8, 0x39dc1ddb
    .word 0xf9fcfdf8, 0xe7f0daf1, 0x36e8e6fc, 0x2bfb2eeb
    .word 0xe70a2102, 0xebfc37fe, 0x2225edd9, 0x1efbe117
    .word 0xdcf5f32e, 0xf113ecf5, 0x2dff1bcc, 0x22ed150b
    .word 0xffe4f3e3, 0xef353629, 0x23d9e423, 0xefecf9e5
    .word 0xedf5f605, 0xf9fa322a, 0xfc08ed05, 0xf2faeee4
    .word 0x0000e6dd, 0x000035ee, 0x0000e40c, 0x0000dfec
    .word 0xf6e4f12e, 0xfefaf525, 0xe9d7fad7, 0x36271b27
    .word 0xe7f02fed, 0x1c28e723, 0x1514e638, 0xe2de31ed
    .word 0xf6e333fc, 0x05e2fd04, 0x0ce3fae5, 0xdcde2a10
    .word 0x1b19e4ce, 0x13e7f2f2, 0xeee7efe3, 0x44f22022
    .word 0xdef8fbdb, 0xd401eec8, 0xe5ed18ef, 0xe7eff635
    .word 0xfde0f6ef, 0x1d2ecc20, 0xe518dfd8, 0xe0e00025
    .word 0x001d2efe, 0x3bd3f8d8, 0x2efce3e7, 0xceebf500
    .word 0xd1fffeea, 0x243519f3, 0xf101e4f4, 0x0d043931
    .word 0xf0e1f625, 0xd31537e9, 0x272219ea, 0xddd8f303
    .word 0xe0cfc916, 0x1fd10eed, 0x28ec152a, 0xd929d815
    .word 0x07e72d0f, 0x0d03f4f4, 0xfdf039d9, 0x06eed4ed
    .word 0xeb37f240, 0x0e01fae8, 0xf9e921ee, 0x1fea01f5
    .word 0x23dce9dd, 0x2ae02821, 0xd8e10a1e, 0xf421dbea
    .word 0x2c31fcfe, 0x1bffecf5, 0x37ecec05, 0xf10729f8
    .word 0x3430e5e2, 0x15f42a27, 0xde00f806, 0x22e2dd2b
    .word 0x2127edf8, 0xe5e425f7, 0xe7ea2ef2, 0x2535221e
    .word 0xe5cd36f3, 0x0e0cf6ed, 0x23ec01f7, 0xf6fdfb2f
    .word 0xe1fd2a09, 0xf60018db, 0x38edef2f, 0xceef2ed9
    .word 0xe5f0d51b, 0x1d2dcdd6, 0xf4f0da2f, 0x1cf410fb
    .word 0xf6dbfc39, 0xfe2ffed0, 0x1329f0d7, 0xfaeaf8e1
    .word 0xe7e4fb34, 0x3314eee1, 0x3b0b2fd1, 0xe3ecedd8
    .word 0x29fa091c, 0xe009d41d, 0xe001eef2, 0x11e51ff6
    .word 0x2330fe06, 0xd600fbf9, 0x2cf2000b, 0xd2f0310d
    .word 0x261cef03, 0xf422f124, 0xd226f117, 0x29d1fcee
    .word 0xdaf7deee, 0xda172221, 0xdff2e621, 0x2ee10d0c
    .word 0xfde2f01d, 0xea26e4fe, 0x23cff4e6, 0xf31b093d
    .word 0x26cf04ea, 0x34292eed, 0x22d9e8f0, 0xcf1fe518
    .word 0x24cbf8f1, 0xe62efd14, 0xec274b2d, 0x31e0fceb
    .word 0xf7db06ea, 0xea22eaeb, 0xf0f5f118, 0x31f2f821
    .word 0xe4371feb, 0xe3ed1021, 0xe53218f8, 0xe3ebd928
    .word 0xf0112dd6, 0x25dfe306, 0xe5fceb0d, 0xe613fd26
    .word 0xe729dd27, 0x36fb19e2, 0xe906dee0, 0xf4e9dc23
    .word 0xe332fa0b, 0xd5f50604, 0xe13aedf8, 0x20ffe2fc
    .word 0xce1a361b, 0xcf14e216, 0xd6efe530, 0x26ecd9f3
    .word 0xd4fd2224, 0xe205d4d4, 0xd1ffcf36, 0x22eb25e7
    .word 0x2f25f021, 0x01e03bf4, 0xede3e625, 0xde33f5e6
    .word 0xf3fb2efc, 0x1005f3e5, 0xdbfc03e8, 0x2cffedf2
    .word 0x0000291d, 0x0000dbdf, 0x0000e7f6, 0x00002c34
    .word 0xec28e0c7, 0xe0d1ee27, 0x00000000, 0x00000000
    .word 0x32e81232, 0xdfd01c03, 0x00000000, 0x00000000
    .word 0xe5292f21, 0xe62af21f, 0x00000000, 0x00000000
    .word 0x000417d6, 0xd52531fc, 0x00000000, 0x00000000
    .word 0x321000da, 0xfb1209ea, 0x00000000, 0x00000000
    .word 0x01f71cd1, 0x1800fa1c, 0x00000000, 0x00000000
    .word 0x261ef712, 0x321d1326, 0x00000000, 0x00000000
    .word 0x1af7fef1, 0xfdf10124, 0x00000000, 0x00000000
    .word 0x2a19edee, 0xddcbfa22, 0x00000000, 0x00000000
    .word 0x14242fe7, 0x22cfcecf, 0x00000000, 0x00000000
    .word 0x0035ffd1, 0x0625cf0f, 0x00000000, 0x00000000
    .word 0xfad91ced, 0xf737e328, 0x00000000, 0x00000000
    .word 0x280f1821, 0x2b1a210a, 0x00000000, 0x00000000
    .word 0xdff8de27, 0xdc2eebef, 0x00000000, 0x00000000
    .word 0x1ce2fcd6, 0x1429000f, 0x00000000, 0x00000000
    .word 0xd2e3d80e, 0x2ceaf4c3, 0x00000000, 0x00000000
    .word 0x040d06eb, 0xf40edc06, 0x00000000, 0x00000000
    .word 0x30df32dd, 0xccfcf0f1, 0x00000000, 0x00000000
    .word 0xf8ee0fe5, 0xf11b2614, 0x00000000, 0x00000000
    .word 0x1727f3f9, 0x0be13c22, 0x00000000, 0x00000000
    .word 0x2b14eb10, 0x00f7ef33, 0x00000000, 0x00000000
    .word 0x20c00cf2, 0x38f7d3ed, 0x00000000, 0x00000000
    .word 0x0df4f002, 0x22dbeb09, 0x00000000, 0x00000000
    .word 0xd2e0292d, 0x2f25e5e5, 0x00000000, 0x00000000
    .word 0x232a1816, 0xcb2b0f10, 0x00000000, 0x00000000
    .word 0xe3dcd7ec, 0xfa19fcc8, 0x00000000, 0x00000000
    .word 0x1a1d051c, 0x28ed38dd, 0x00000000, 0x00000000
    .word 0xf625fa2b, 0xd90bfae2, 0x00000000, 0x00000000
    .word 0xe21123e0, 0xeeda1de4, 0x00000000, 0x00000000
    .word 0x15041bf9, 0x0ddce0ed, 0x00000000, 0x00000000
    .word 0xe7e9ec05, 0x31c4ccc9, 0x00000000, 0x00000000
    .word 0xdf3e2528, 0xf3331824, 0x00000000, 0x00000000
    .word 0x32f13d46, 0xe7e022f2, 0x00000000, 0x00000000
    .word 0x260b15e9, 0x25d4d3c5, 0x00000000, 0x00000000
    .word 0x2510f0d4, 0x14101b25, 0x00000000, 0x00000000
    .word 0xded5ecea, 0x1a2703d4, 0x00000000, 0x00000000
    .word 0xd606ec35, 0x330509f6, 0x00000000, 0x00000000
    .word 0x0000eb0a, 0x0000202b, 0x00000000, 0x00000000
