from copy import copy
from math import ceil
import numpy as np

LAYERS = {
    "layer0": {
        "lon": 16,
        "loy": 11,
        "lox": 11,
        "lin": 1,
        "liy": 24,
        "lix": 24,
        "lwy": 4,
        "lwx": 4,
        "sy": 2,
        "sx": 2,
        "bias": 128,
        "shift": 8,
        "input_file": "resources/input.bin",
        "weight_file": "resources/l0_weight.bin",
        "expected_file": "resources/l0_expected.bin"
    },
    "layer1": {
        "lon": 24,
        "loy": 4,
        "lox": 4,
        "lin": 16,
        "liy": 11,
        "lix": 11,
        "lwy": 5,
        "lwx": 5,
        "sy": 2,
        "sx": 2,
        "bias": 128,
        "shift": 8,
        "input_file": "resources/l0_expected.bin",
        "weight_file": "resources/l1_weight.bin",
        "expected_file": "resources/l1_expected.bin"
    },
    "layer2": {
        "lon": 150,
        "loy": 1,
        "lox": 1,
        "lin": 384,
        "liy": 1,
        "lix": 1,
        "lwy": 1,
        "lwx": 1,
        "sy": 1,
        "sx": 1,
        "bias": 128,
        "shift": 8,
        "input_file": "resources/l1_expected.bin",
        "weight_file": "resources/l2_weight.bin",
        "expected_file": "resources/l2_expected.bin"
    },
    "layer3": {
        "lon": 10,
        "loy": 1,
        "lox": 1,
        "lin": 150,
        "liy": 1,
        "lix": 1,
        "lwy": 1,
        "lwx": 1,
        "sy": 1,
        "sx": 1,
        "bias": 1024,
        "shift": 11,
        "input_file": "resources/l2_expected.bin",
        "weight_file": "resources/l3_weight.bin",
        "expected_file": "resources/l3_expected.bin"
    }
}


class Xadac:

    VLEN = 128
    V8LEN = VLEN // 8
    V32LEN = VLEN // 32
    VNUM = 32

    def __init__(self) -> None:
        self.vrf = np.random.randint(
            low=0,
            high=256,
            size=(self.VNUM, self.V8LEN),
            dtype=np.uint8
        )

        self.vrf_i8 = self.vrf.view(np.int8)
        self.vrf_u8 = self.vrf.view(np.uint8)
        self.vrf_i32 = self.vrf.view(np.int32)

    def vload(self, vd, rs1, imm):
        assert imm <= self.V8LEN
        mem = np.frombuffer(rs1, dtype=np.uint8)
        for i in range(self.V8LEN):
            ptr = i % min(imm, len(mem))
            self.vrf_u8[vd][i] = mem[ptr]

    def vbias(self, vd, rs1, imm):
        assert imm <= self.V32LEN

        for i in range(self.V32LEN):
            self.vrf_i32[vd][i] = rs1 if i < imm else 0

    def vmacc(self, vd, vs1, vs2, imm):
        assert imm <= 4
        for i in range(self.V32LEN):
            for j in range(imm):
                self.vrf_i32[vd][i] += (
                    self.vrf_i8[vs1][i * imm + j] *
                    self.vrf_u8[vs2][i * imm + j]
                )

    def vactv(self, vs3, rs1, rs2, imm):
        assert imm <= self.V32LEN
        ptr = np.frombuffer(rs1, dtype=np.uint8)
        for i in range(imm):
            sum = self.vrf_i32[vs3][i]
            sum = (sum >> rs2 if sum > 0 else 0) & 0xFF
            ptr[i] = np.uint8(sum)


class Asm:

    def __init__(self, regs, vecs) -> None:
        self.asm = ""
        self.stack = []

        self.reg_idle = copy(regs)
        self.reg_busy = []

        self.vec_idle = copy(vecs)
        self.vec_busy = []

    def vbias(self, vd, rs1, imm):
        self.asm += f"    xadac.vbias {vd}, {rs1}, {imm}\n"

    def vload(self, vd, rs1, imm):
        self.asm += f"    xadac.vload {vd}, {rs1}, {imm}\n"

    def vmacc(self, vd, vs1, vs2, imm):
        self.asm += f"    xadac.vmacc {vd}, {vs1}, {vs2}, {imm}\n"

    def vactv(self, vs3, rs1, rs2, imm):
        self.asm += f"    xadac.vactv {vs3}, {rs1}, {rs2}, {imm}\n"

    def beqz(self, rs1, symbol):
        self.asm += f"    beqz {rs1}, {symbol}\n"

    def ret(self):
        self.asm += "    ret\n"

    def j(self, symbol):
        self.asm += f"    j {symbol}\n"

    def la(self, reg, symbol):
        self.asm += f"    la {reg}, {symbol}\n"

    def li(self, reg, value):
        self.asm += f"    li {reg}, {value}\n"

    def inc(self, reg, imm):
        self.asm += f"    addi {reg}, {reg}, {imm}\n"

    def label(self, label):
        self.asm += f"{label}:\n"

    def newline(self):
        self.asm += "\n"

    def array(self, name, data):

        data = np.frombuffer(data, dtype=np.uint8)

        if len(data) % 4 != 0:
            padding_length = 4 - (len(data) % 4)
            padding = np.zeros(padding_length, dtype=np.uint8)
            data = np.concatenate((data, padding))

        data_u32 = data.view(np.uint32)

        self.asm += "    .data\n"
        self.asm += f"{name}:\n"
        for i in range(0, len(data_u32), 4):
            words = data_u32[i:i+4]
            words_hex = ", ".join(f"0x{word:08x}" for word in words)
            self.asm += f"    .word {words_hex}\n"

    def func(self, name):
        def decorator(body):
            self.asm += "    .text\n"
            self.asm += f"    .globl {name}\n"
            self.asm += f"    .type {name}, @function\n"
            self.label(name)

            self.stack += [name]
            body()
            self.stack.pop()

            self.ret()
            self.newline()

            return None

        return decorator

    def loop(self, name, size, reg=None, unroll=1):
        if reg is None:
            unroll = size

        div = size // unroll
        rem = size % unroll

        if div == 1:
            div, rem = 0, div*unroll

        prefix = "_".join(self.stack + [name])

        def decorator(body):
            if div > 0:
                self.li(reg, div)
                self.label(f"{prefix}_loop_begin")
                self.beqz(reg, f"{prefix}_loop_end")

                for i in range(unroll):
                    self.stack += [f"{name}{i}"]
                    body(i)
                    self.stack.pop()

                self.inc(reg, -1)
                self.j(f"{prefix}_loop_begin")
                self.label(f"{prefix}_loop_end")

            for i in range(rem):
                self.stack += [f"{name}{i + div*unroll}"]
                body(i + div*unroll)
                self.stack.pop()

            return None

        return decorator

    def reg_alloc(self, reg=None):
        assert reg not in self.reg_busy
        reg = reg or self.reg_idle.pop()
        self.reg_busy.insert(0, reg)
        return reg

    def reg_free(self, reg):
        self.reg_busy.remove(reg)
        self.reg_idle.issert(0, reg)

    def vec_alloc(self, vec=None):
        assert vec not in self.vec_busy
        vec = vec or self.vec_idle.pop()
        self.vec_busy.insert(0, vec)
        return vec

    def vec_free(self, vec):
        self.vec_busy.remove(vec)
        self.vec_idle.insert(0, vec)


def load_data(layer: dict) -> None:
    load_data = {
        "input": ("liy", "lix", "lin"),
        "weight": ("lon", "lwy", "lwx", "lin"),
        "expected": ("loy", "lox", "lon")
    }

    for name, kshape in load_data.items():
        shape = tuple(layer[k] for k in kshape)
        data = np.fromfile(layer[f"{name}_file"], dtype=np.uint8)
        layer[name] = data[:np.prod(shape)].reshape(shape)

    layer["weight"] = layer["weight"].view(np.int8)


def hexdump(data):
    data_uint32 = data.reshape(-1).view(np.uint32)
    for i in range(0, len(data_uint32), 4):
        line = data_uint32[i:i+4]
        print(" ".join(f"{x:08x}" for x in line))


def gen_conv(
    lon: int,
    loy: int,
    lox: int,
    lin: int,
    liy: int,
    lix: int,
    lwy: int,
    lwx: int,
    sy: int,
    sx: int,
    bias: int,
    shift: int,
    **kwargs
) -> None:
    loa = 1
    lob = 1
    lia = 1
    lib = 1

    s_vec = "1"
    w_vec = "2"
    i_vec = "3"

    b_reg = "x1"
    s_reg = "x2"
    w_reg = "x3"
    i_reg = "x4"
    oy_reg = "x5"
    ox_reg = "x6"

    for oy in range(loy):
        for ox in range(lox):
            i_reg = sy*lix*lin*oy + sx*lin*ox
            for oa in range(loa):
                print(f"xadac.vbias {s_vec}, {b_reg}, {lob}")
                for wy in range(lwy):
                    for wx in range(lwx):
                        for ia in range(lia):
                            print(f"xadac.vload {w_vec}, {w_reg}, {lob*lib}")
                            print(f"xadac.vload {i_vec}, {i_reg}, {lib}")
                            print(f"xadac.vmacc {s_vec}, {w_vec}, {i_vec}, {lib}")
                            print(f"addi {w_reg}, {w_reg}, {lib}")
                            print(f"addi {i_reg}, {i_reg}, {lib}")
                print(f"xadac.vactv {s_vec}, {s_reg}, {shift}, {lob}")
            print(f"addi {ox_reg}, {ox_reg}, 1")
        print(f"addi {oy_reg}, {oy_reg}, 1")


def base_conv(
    lon: int,
    loy: int,
    lox: int,
    lin: int,
    lwy: int,
    lwx: int,
    sy: int,
    sx: int,
    bias: int,
    shift: int,
    input: np.ndarray,
    weight: np.ndarray,
    expected: np.ndarray,
    **kwargs
) -> None:

    output = np.zeros((loy, lox, lon), dtype=np.uint8)

    for oy in range(loy):
        for ox in range(lox):
            for on in range(lon):
                sum = bias
                for wy in range(lwy):
                    for wx in range(lwx):
                        for in_ in range(lin):
                            iy = sy*oy + wy
                            ix = sx*ox + wx
                            sum += input[iy][ix][in_] * weight[on][wy][wx][in_]

                output[oy][ox][on] = (sum >> shift if sum > 0 else 0) & 0xFF

    assert np.array_equal(output, expected)


def reform_weight(layer):
    lon = layer["lon"]
    lin = layer["lin"]
    lwx = layer["lwx"]
    lwy = layer["lwy"]
    weight = layer["weight"]

    loa = layer["loa"] = ceil(lon / Xadac.V32LEN)
    lob = layer["lob"] = Xadac.V32LEN

    lia = layer["lia"] = ceil(lin / 4)
    lib = layer["lib"] = min(4, lin)

    kshape = ("loa", "lwx", "lwy", "lia", "lob", "lib")
    shape = tuple(layer[k] for k in kshape)

    reformed = np.zeros(shape, dtype=np.int8)

    print(layer["weight_file"])

    for oa in range(loa):
        for wx in range(lwx):
            for wy in range(lwy):
                for ia in range(lia):
                    for ob in range(lob):
                        for ib in range(lib):
                            on = oa*lob + ob
                            in_ = ia*lib + ib

                            if on >= lon or in_ >= lin:
                                continue

                            reformed[oa][wx][wy][ia][ob][ib] = (
                                weight[on][wx][wy][in_]
                            )

    layer["reformed_weight"] = reformed


def reform_weight_layer0(layer):
    lon = layer["lon"]
    lwx = layer["lwx"]
    lwy = layer["lwy"]
    weight = layer["weight"]

    loa = layer["loa"] = ceil(lon / Xadac.V32LEN)
    lob = layer["lob"] = Xadac.V32LEN

    kshape = ("loa", "lwy", "lob", "lwx")
    shape = tuple(layer[k] for k in kshape)

    reformed = np.zeros(shape, dtype=np.int8)

    print(layer["weight_file"])

    for oa in range(loa):
        for wy in range(lwy):
            for wx in range(lwx):
                for ob in range(lob):
                    on = oa*lob + ob

                    if on >= lon:
                        continue

                    reformed[oa][wy][ob][wx] = (
                        weight[on][wy][wx][0]
                    )

    layer["reformed_weight"] = reformed


def xadac_conv(
    lon: int,
    loy: int,
    lox: int,
    lin: int,
    lix: int,
    lwy: int,
    lwx: int,
    sy: int,
    sx: int,
    bias: int,
    shift: int,
    input: np.ndarray,
    reformed_weight: np.ndarray,
    expected: np.ndarray,
    loa: int,
    lob: int,
    lia: int,
    lib: int,
    **kwargs
) -> str:

    xadac = Xadac()

    input = np.frombuffer(input, dtype=np.uint8)
    weight = np.frombuffer(reformed_weight, dtype=np.uint8)
    expected = np.frombuffer(expected, dtype=np.uint8)
    output = np.zeros((loy*lox*lon), dtype=np.uint8)

    i_ptr = 0
    o_ptr = 0
    for oy in range(loy):
        for ox in range(lox):
            w_ptr = 0
            for oa in range(loa):
                xadac.vbias(1, bias, lob)

                for wy in range(lwy):
                    for wx in range(lwx):
                        for ia in range(lia):
                            xadac.vload(2, weight[w_ptr:], lob*lib)
                            xadac.vload(3, input[i_ptr:], lib)
                            xadac.vmacc(1, 2, 3, lib)
                            w_ptr += lob*lib
                            i_ptr += lib

                    i_ptr += (lix - lwx)*lin

                i_ptr -= lib*lia*lwx*lwy + lwy*(lix - lwx)*lin

                imm = min(lob, lon - oa*lob)
                xadac.vactv(1, output[o_ptr:], shift, imm)
                o_ptr += imm

            i_ptr += sx*lin
        i_ptr += sy*lix*lin - lox*sx*lin

    assert np.array_equal(output, expected)


def xadac_conv_asm(
    name: str,
    lon: int,
    loy: int,
    lox: int,
    lin: int,
    lix: int,
    lwy: int,
    lwx: int,
    sy: int,
    sx: int,
    bias: int,
    shift: int,
    reformed_weight: np.ndarray,
    loa: int,
    lob: int,
    lia: int,
    lib: int,
    **kwargs
) -> str:

    asm = Asm(
        regs=[
            *[f"a{i}" for i in range(5)],
            *[f"t{i}" for i in range(5)]
        ],
        vecs=[f"{i}" for i in range(18, 28)]
    )

    @asm.func(name)
    def layer_body():

        o_reg = asm.reg_alloc("a0")
        i_reg = asm.reg_alloc("a1")

        w_reg = asm.reg_alloc()

        oy_reg = asm.reg_alloc()
        ox_reg = asm.reg_alloc()
        ia_reg = asm.reg_alloc()

        bias_reg = asm.reg_alloc()
        shift_reg = asm.reg_alloc()

        asm.li(bias_reg, bias)
        asm.li(shift_reg, shift)

        @asm.loop("oy", loy, oy_reg)
        def oy_body(oy):

            @asm.loop("ox", lox, ox_reg)
            def ox_body(ox):

                asm.la(w_reg, "weight")

                @asm.loop("oa", loa)
                def oa_body(oa):

                    s_vec = asm.vec_alloc()

                    asm.vbias(s_vec, bias_reg, lob)

                    @asm.loop("wy", lwy)
                    def wy_body(wy):

                        @asm.loop("wx", lwx)
                        def wx_body(wx):

                            @asm.loop("ia", lia, ia_reg, unroll=8)
                            def ia_body(ia):

                                w_vec = asm.vec_alloc()
                                i_vec = asm.vec_alloc()

                                asm.vload(w_vec, w_reg, lob*lib)
                                asm.vload(i_vec, i_reg, lib)
                                asm.vmacc(s_vec, w_vec, i_vec, lib)
                                asm.inc(w_reg, lob*lib)
                                asm.inc(i_reg, lib)

                                asm.vec_free(w_vec)
                                asm.vec_free(i_vec)

                        asm.inc(i_reg, (lix - lwx)*lin)

                    asm.inc(i_reg, - lib*lia*lwx*lwy - lwy*(lix - lwx)*lin)

                    imm = min(lob, lon - oa*lob)
                    asm.vactv(s_vec, o_reg, shift_reg, imm)
                    asm.inc(o_reg, imm)

                    asm.vec_free(s_vec)

                asm.inc(i_reg, sx*lin)

            asm.inc(i_reg, sy*lix*lin - lox*sx*lin)

    asm.array("weight", reformed_weight)

    return asm


def xadac_layer0(
    lon: int,
    loy: int,
    lox: int,
    lwy: int,
    lwx: int,
    sy: int,
    sx: int,
    bias: int,
    shift: int,
    input: np.ndarray,
    reformed_weight: np.ndarray,
    expected: np.ndarray,
    loa: int,
    lob: int,
    **kwargs
) -> None:

    weight = reformed_weight
    output = np.zeros((loy, lox, lon), dtype=np.uint8)

    for oy in range(loy):
        for ox in range(lox):
            for oa in range(loa):

                sum = np.zeros(lob, dtype=np.int32)

                for ob in range(lob):
                    sum[ob] = bias

                for wy in range(lwy):
                    for ob in range(lob):
                        for wx in range(lwx):

                            iy = sy*oy + wy
                            ix = sx*ox + wx

                            sum[ob] += (
                                input[iy][ix][0] *
                                weight[oa][wy][ob][wx]
                            )

                for ob in range(lob):
                    on = oa*lob + ob
                    if on >= lon:
                        continue
                    output[oy][ox][on] = (
                        (sum[ob] >> shift if sum[ob] > 0 else 0) & 0xFF
                    )

    assert np.array_equal(output, expected)


def xadac_layer0_asm(
    name: str,
    lon: int,
    loy: int,
    lox: int,
    lix: int,
    lwy: int,
    lwx: int,
    sy: int,
    sx: int,
    bias: int,
    shift: int,
    reformed_weight: np.ndarray,
    loa: int,
    lob: int,
    **kwargs
) -> str:

    asm = Asm(
        regs=[
            *[f"a{i}" for i in range(5)],
            *[f"t{i}" for i in range(5)]
        ],
        vecs=[f"{i}" for i in range(18, 28)]
    )

    @asm.func(name)
    def layer_body():

        o_reg = asm.reg_alloc("a0")
        i_reg = asm.reg_alloc("a1")

        w_reg = asm.reg_alloc()

        oy_reg = asm.reg_alloc()
        ox_reg = asm.reg_alloc()

        bias_reg = asm.reg_alloc()
        shift_reg = asm.reg_alloc()

        asm.li(bias_reg, bias)
        asm.li(shift_reg, shift)

        @asm.loop("oy", loy, oy_reg)
        def oy_body(oy):

            @asm.loop("ox", lox, ox_reg)
            def ox_body(ox):

                asm.la(w_reg, "weight")

                @asm.loop("oa", loa)
                def oa_body(oa):

                    s_vec = asm.vec_alloc()

                    asm.vbias(s_vec, bias_reg, lob)

                    @asm.loop("wy", lwy)
                    def wy_body(wy):

                        w_vec = asm.vec_alloc()
                        i_vec = asm.vec_alloc()

                        asm.vload(w_vec, w_reg, lob*lwx)
                        asm.vload(i_vec, i_reg, lwx)
                        asm.vmacc(s_vec, w_vec, i_vec, lwx)
                        asm.inc(w_reg, lob*lwx)
                        asm.inc(i_reg, lix)

                        asm.vec_free(w_vec)
                        asm.vec_free(i_vec)

                    asm.inc(i_reg, - lwx*lwy - lwy*(lix - lwx))

                    imm = min(lob, lon - oa*lob)
                    asm.vactv(s_vec, o_reg, shift_reg, imm)
                    asm.inc(o_reg, imm)

                    asm.vec_free(s_vec)

                asm.inc(i_reg, sx)

            asm.inc(i_reg, sy*lix - lox*sx)

    asm.array("weight", reformed_weight)

    return asm


if __name__ == "__main__":
    for name, params in LAYERS.items():
        load_data(params)
        base_conv(**params)

        if name == "layer0":
            reform_weight_layer0(params)
            xadac_layer0(**params)
            asm = xadac_layer0_asm(name, **params)
        else:
            reform_weight(params)
            xadac_conv(**params)
            asm = xadac_conv_asm(name, **params)

        with open(f"{name}.S", "w") as f:
            f.write(asm.asm)
