###############################################################################
# (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the Apache License          #
# version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################

import math


def gen_header(header=True):
    c = """/*****************************************************************************\\
* (c) Copyright 2018-2024 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

// *** Auto-generated file do not edit *** //

"""
    if header: c += "#pragma once\n\n"
    return c


def gen_exch_inter(N, with_val=True):
    if with_val:
        args = [f"K& k{i}, unsigned& v{i}" for i in range(N)]
        c = f"// Exchange intersection for {N} key-index pair(s)\n"
        c += "template<typename K>\n"
        c += f"__device__ inline void exch_inter({', '.join(args)}, unsigned mask, const bool bit) {{\n"
    else:
        args = [f"K& k{i}" for i in range(N)]
        c = f"// Exchange intersection for {N} key(s)\n"
        c += "template<typename K>\n"
        c += f"__device__ inline void exch_inter_keys({', '.join(args)}, unsigned mask, const bool bit) {{\n"
    c += "  K ex_k0, ex_k1;\n"
    if with_val: c += "  unsigned ex_v0, ex_v1;\n"
    var_names = ['k']
    if with_val: var_names = ['k', 'v']
    if N > 2:
        for i in range(N // 2):
            if with_val:
                c += f"  cond_swap_regs(bit, k{i}, k{N-1-(i^1)}, v{i}, v{N-1-(i^1)});\n"
            else:
                c += f"  cond_swap_regs(bit, k{i}, k{N-1-(i^1)});\n"
    if N == 1:
        for var in var_names:
            c += f"  ex_{var}0 = {var}0;\n"
            c += f"  ex_{var}1 = __shfl_xor_sync(0xFFFFFFFF, {var}0, mask);\n"
        if with_val:
            c += "  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);\n"
        else:
            c += "  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);\n"
        for var in var_names:
            c += f"  {var}0 = ex_{var}0;\n"
    else:
        for i in range(N // 2):
            for var in var_names:
                c += f"  ex_{var}0 = {var}{i*2};\n"
                c += f"  ex_{var}1 = __shfl_xor_sync(0xFFFFFFFF, {var}{i*2+1}, mask);\n"
            if with_val:
                c += "  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);\n"
            else:
                c += "  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);\n"
            for var in var_names:
                c += f"  {var}{i*2} = ex_{var}0;\n"
                c += f"  {var}{i*2+1} = __shfl_xor_sync(0xFFFFFFFF, ex_{var}1, mask);\n"
    if N > 2:
        for i in range(N // 2):
            if with_val:
                c += f"  cond_swap_regs(bit, k{i}, k{N-1-(i^1)}, v{i}, v{N-1-(i^1)});\n"
            else:
                c += f"  cond_swap_regs(bit, k{i}, k{N-1-(i^1)});\n"
    c += "}\n\n"
    return c


def gen_exch_paral(N, with_val=True):
    if with_val:
        args = [f"K& k{i}, unsigned& v{i}" for i in range(N)]
        c = f"// Exchange parallel for {N} key-index pair(s)\n"
        c += "template<typename K>\n"
        c += f"__device__ inline void exch_paral({', '.join(args)}, unsigned mask, const bool bit) {{\n"
    else:
        args = [f"K& k{i}" for i in range(N)]
        c = f"// Exchange parallel for {N} key(s)\n"
        c += "template<typename K>\n"
        c += f"__device__ inline void exch_paral_keys({', '.join(args)}, unsigned mask, const bool bit) {{\n"
    c += "  K ex_k0, ex_k1;\n"
    if with_val: c += "  unsigned ex_v0, ex_v1;\n"
    var_names = ['k']
    if with_val: var_names = ['k', 'v']
    for i in range(N // 2):
        if with_val:
            c += f"  cond_swap_regs(bit, k{i*2}, k{i*2+1}, v{i*2}, v{i*2+1});\n"
        else:
            c += f"  cond_swap_regs(bit, k{i*2}, k{i*2+1});\n"
    for i in range(N // 2):
        for var in var_names:
            c += f"  ex_{var}0 = {var}{i*2};\n"
            c += f"  ex_{var}1 = __shfl_xor_sync(0xFFFFFFFF, {var}{i*2+1}, mask);\n"
        if with_val:
            c += "  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);\n"
        else:
            c += "  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);\n"
        for var in var_names:
            c += f"  {var}{i*2} = ex_{var}0;\n"
            c += f"  {var}{i*2+1} = __shfl_xor_sync(0xFFFFFFFF, ex_{var}1, mask);\n"
    for i in range(N // 2):
        if with_val:
            c += f"  cond_swap_regs(bit, k{i*2}, k{i*2+1}, v{i*2}, v{i*2+1});\n"
        else:
            c += f"  cond_swap_regs(bit, k{i*2}, k{i*2+1});\n"
    c += "}\n\n"
    return c


def call_local_exch(ept, rmask, with_val=True):
    c = ""
    used = []
    for i in range(ept):
        if i in used: continue
        a = i
        b = i ^ rmask
        if with_val:
            c += f"    cond_swap_regs(rg_k{a} > rg_k{b}, rg_k{a}, rg_k{b}, rg_v{a}, rg_v{b});\n"
        else:
            c += f"    cond_swap_regs(rg_k{a} > rg_k{b}, rg_k{a}, rg_k{b});\n"
        used.append(a)
        used.append(b)
    return c


def call_inter_exch(ept, tmask, swbit, with_val=True):
    if with_val:
        kv = [f"rg_k{i}, rg_v{i}" for i in range(ept)]
        name = ""
    else:
        kv = [f"rg_k{i}" for i in range(ept)]
        name = "_keys"
    return f"    exch_inter{name}({', '.join(kv)}, {hex(tmask)}, bit{swbit});\n"


def call_paral_exch(ept, tmask, swbit, with_val=True):
    if with_val:
        kv = [f"rg_k{i}, rg_v{i}" for i in range(ept)]
        name = "inter" if (ept == 1) else "paral"
    else:
        kv = [f"rg_k{i}" for i in range(ept)]
        name = "inter_keys" if (ept == 1) else "paral_keys"
    return f"    exch_{name}({', '.join(kv)}, {hex(tmask)}, bit{swbit});\n"


def gen_regsort_kernel(threads, ept, with_perm=True):
    rg_k = [f"rg_k{i}" for i in range(ept)]
    rg_v = [f"rg_v{i}" for i in range(ept)]
    c = f"// {threads * ept} = {threads} threads x {ept} elements per thread\n"
    c += "template<typename KeyType>\n"
    if with_perm:
        c += f"__global__ void regsort_{threads*ept}_{threads}t_{ept}ept(const unsigned* bins, unsigned n_segments, const KeyType* keys, const unsigned* seg_offsets, unsigned* permutations) {{\n"
    else:
        c += f"__global__ void regsort_{threads*ept}_{threads}t_{ept}ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets) {{\n"
    c += f"  unsigned step = (gridDim.x * blockDim.x) / {threads};\n"
    c += f"  unsigned first_seg = (blockIdx.x * blockDim.x + threadIdx.x) / {threads};\n"
    c += f"  unsigned tid = threadIdx.x & {threads-1};\n"
    for i in range(int(math.log2(threads))):
        c += f"  const bool bit{i} = (tid >> {i}) & 1;\n"  # TODO: predicate packing ?
    c += f"  KeyType {', '.join(rg_k)};\n"
    c += f"  unsigned {', '.join(rg_v)};\n"
    c += "  for (unsigned s = first_seg; s < n_segments; s += step) {\n"
    c += "    unsigned seg = bins[s];\n"
    c += "    const unsigned start = seg_offsets[seg];\n"
    c += "    const unsigned size = seg_offsets[seg + 1] - seg_offsets[seg];\n\n"
    # LOAD
    for i in range(ept):
        c += f"    {rg_v[i]} = tid + {i*threads};\n"
    for i in range(ept):
        c += f"    {rg_k[i]} = ({rg_v[i]} < size) ? keys[start + {rg_v[i]}] : std::numeric_limits<KeyType>::max();\n"
    c += "\n"

    # SORT
    log_size = int(math.log2(threads * ept))
    log_threads = int(math.log2(threads))

    step = 1
    for l in range(log_size, 0, -1):
        step += 1
        n_groups = 2**(l - 1)
        n_thread_groups = 2**(min(log_threads, l - 1))
        elements_per_group = 2**(log_size - l + 1)
        threads_per_group = 2**(log_threads - min(log_threads, l - 1))
        if threads_per_group == 1:
            rmask = elements_per_group - 1
            c += call_local_exch(ept, rmask, with_val=with_perm)
        else:
            tmask = threads_per_group - 1
            swbit = int(math.log2(threads_per_group) - 1)
            c += call_inter_exch(ept, tmask, swbit, with_val=with_perm)
        for k in range(l + 1, log_size + 1):
            step += 1
            n_groups = 2**(k - 1)
            n_thread_groups = 2**(min(log_threads, k - 1))
            elements_per_group = 2**(log_size - k + 1)
            threads_per_group = 2**(log_threads - min(log_threads, k - 1))
            if threads_per_group == 1:
                rmask = elements_per_group - 1
                rmask = rmask - rmask // 2
                c += call_local_exch(ept, rmask, with_val=with_perm)
            else:
                tmask = threads_per_group - 1
                tmask = tmask - tmask // 2
                swbit = int(math.log2(threads_per_group) - 1)
                c += call_paral_exch(ept, tmask, swbit, with_val=with_perm)
    c += "\n"

    # STORE BACK
    if with_perm:
        for i in range(ept):
            #c += f"    if (tid * {ept} + {i} < size) permutations[start + {rg_v[i]}] = start + tid * {ept} + {i};\n"
            c += f"    if (tid * {ept} + {i} < size) permutations[start + tid * {ept} + {i}] = start + {rg_v[i]};\n"
    else:
        for i in range(ept):
            c += f"    if (tid * {ept} + {i} < size) keys[start + tid * {ept} + {i}] = {rg_k[i]};\n"
    c += "  }\n"
    c += "}\n\n"
    # instantiate:
    for t in ["uint32_t", "int64_t", "uint64_t"]:
        if with_perm:
            c += f"template __global__ void regsort_{threads*ept}_{threads}t_{ept}ept<{t}>(const unsigned* bins, unsigned n_segments, const {t}* keys, const unsigned* seg_offsets, unsigned* permutations);\n"
        else:
            c += f"template __global__ void regsort_{threads*ept}_{threads}t_{ept}ept<{t}>(const unsigned* bins, unsigned n_segments, {t}* keys, const unsigned* seg_offsets);\n"
    c += "\n"
    return c


def gen_exch_header(filename):
    c = gen_header()

    c += """#include <cstdint>

#ifndef TARGET_DEVICE_CPU

template<typename T1, typename T2>
__device__ inline void cond_swap_regs(bool condition, T1& a, T1& b, T2& c, T2& d) {
  if (condition) {
    T1 tmp1 = a; a = b; b = tmp1;
    T2 tmp2 = c; c = d; d = tmp2;
  }
}

template<typename T1>
__device__ inline void cond_swap_regs(bool condition, T1& a, T1& b) {
  if (condition) {
    T1 tmp1 = a; a = b; b = tmp1;
  }
}

"""
    for i in [1, 2, 4, 8, 16]:
        c += gen_exch_inter(i)
        c += gen_exch_inter(i, with_val=False)
    # for i == 1, paral and inter are identical, generate them once
    for i in [2, 4, 8, 16]:
        c += gen_exch_paral(i)
        c += gen_exch_paral(i, with_val=False)

    c += "#endif\n"

    with open(filename, "w") as f:
        f.write(c)


def gen_regsort_header(filename):
    c = gen_header()

    c += "#ifndef TARGET_DEVICE_CPU\n\n"

    for size in [2, 4, 8, 16, 32, 64, 128, 256, 512]:
        c += f"// Sorts for size <= {size}:\n\n"
        for threads in [2, 4, 8, 16, 32]:
            for ept in [1, 2, 4, 8, 16]:
                if ept * threads == size:
                    c += "template<typename KeyType>\n"
                    c += f"__global__ void regsort_{threads*ept}_{threads}t_{ept}ept(const unsigned* bins, unsigned n_segments, const KeyType* keys, const unsigned* seg_offsets, unsigned* permutations);\n"
                    c += "template<typename KeyType>\n"
                    c += f"__global__ void regsort_{threads*ept}_{threads}t_{ept}ept(const unsigned* bins, unsigned n_segments, KeyType* keys, const unsigned* seg_offsets);\n"
        c += "\n"

    c += "#endif\n"

    with open(filename, "w") as f:
        f.write(c)


def gen_regsort_kernels(filename):
    c = gen_header(header=False)
    c += "#include <regsort_exch.h>\n"
    c += "#include <regsort_kernels.h>\n\n"

    c += "#ifndef TARGET_DEVICE_CPU\n\n"

    for size in [2, 4, 8, 16, 32, 64, 128, 256, 512]:
        c += f"// Sorts for size <= {size}:\n\n"
        for threads in [2, 4, 8, 16, 32]:
            for ept in [1, 2, 4, 8, 16]:
                if ept * threads == size:
                    c += gen_regsort_kernel(threads, ept)
                    c += gen_regsort_kernel(threads, ept, with_perm=False)

    c += "#endif\n"

    with open(filename, "w") as f:
        f.write(c)


if __name__ == '__main__':
    gen_exch_header("../include/regsort_exch.h")
    gen_regsort_header("../include/regsort_kernels.h")
    gen_regsort_kernels("../src/regsort_kernels.cu")
