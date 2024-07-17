/*****************************************************************************\
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

#pragma once

#include <cstdint>

#ifndef TARGET_DEVICE_CPU

template<typename T1, typename T2>
__device__ inline void cond_swap_regs(bool condition, T1& a, T1& b, T2& c, T2& d)
{
  if (condition) {
    T1 tmp1 = a;
    a = b;
    b = tmp1;
    T2 tmp2 = c;
    c = d;
    d = tmp2;
  }
}

template<typename T1>
__device__ inline void cond_swap_regs(bool condition, T1& a, T1& b)
{
  if (condition) {
    T1 tmp1 = a;
    a = b;
    b = tmp1;
  }
}

// Exchange intersection for 1 key-index pair(s)
template<typename K>
__device__ inline void exch_inter(K& k0, unsigned& v0, unsigned mask, const bool bit)
{
  K ex_k0, ex_k1;
  unsigned ex_v0, ex_v1;
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k0, mask);
  ex_v0 = v0;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v0, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k0 = ex_k0;
  v0 = ex_v0;
}

// Exchange intersection for 1 key(s)
template<typename K>
__device__ inline void exch_inter_keys(K& k0, unsigned mask, const bool bit)
{
  K ex_k0, ex_k1;
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k0, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k0 = ex_k0;
}

// Exchange intersection for 2 key-index pair(s)
template<typename K>
__device__ inline void exch_inter(K& k0, unsigned& v0, K& k1, unsigned& v1, unsigned mask, const bool bit)
{
  K ex_k0, ex_k1;
  unsigned ex_v0, ex_v1;
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k1, mask);
  ex_v0 = v0;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v1, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k0 = ex_k0;
  k1 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v0 = ex_v0;
  v1 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
}

// Exchange intersection for 2 key(s)
template<typename K>
__device__ inline void exch_inter_keys(K& k0, K& k1, unsigned mask, const bool bit)
{
  K ex_k0, ex_k1;
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k1, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k0 = ex_k0;
  k1 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
}

// Exchange intersection for 4 key-index pair(s)
template<typename K>
__device__ inline void exch_inter(
  K& k0,
  unsigned& v0,
  K& k1,
  unsigned& v1,
  K& k2,
  unsigned& v2,
  K& k3,
  unsigned& v3,
  unsigned mask,
  const bool bit)
{
  K ex_k0, ex_k1;
  unsigned ex_v0, ex_v1;
  cond_swap_regs(bit, k0, k2, v0, v2);
  cond_swap_regs(bit, k1, k3, v1, v3);
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k1, mask);
  ex_v0 = v0;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v1, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k0 = ex_k0;
  k1 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v0 = ex_v0;
  v1 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k2;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k3, mask);
  ex_v0 = v2;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v3, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k2 = ex_k0;
  k3 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v2 = ex_v0;
  v3 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  cond_swap_regs(bit, k0, k2, v0, v2);
  cond_swap_regs(bit, k1, k3, v1, v3);
}

// Exchange intersection for 4 key(s)
template<typename K>
__device__ inline void exch_inter_keys(K& k0, K& k1, K& k2, K& k3, unsigned mask, const bool bit)
{
  K ex_k0, ex_k1;
  cond_swap_regs(bit, k0, k2);
  cond_swap_regs(bit, k1, k3);
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k1, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k0 = ex_k0;
  k1 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k2;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k3, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k2 = ex_k0;
  k3 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  cond_swap_regs(bit, k0, k2);
  cond_swap_regs(bit, k1, k3);
}

// Exchange intersection for 8 key-index pair(s)
template<typename K>
__device__ inline void exch_inter(
  K& k0,
  unsigned& v0,
  K& k1,
  unsigned& v1,
  K& k2,
  unsigned& v2,
  K& k3,
  unsigned& v3,
  K& k4,
  unsigned& v4,
  K& k5,
  unsigned& v5,
  K& k6,
  unsigned& v6,
  K& k7,
  unsigned& v7,
  unsigned mask,
  const bool bit)
{
  K ex_k0, ex_k1;
  unsigned ex_v0, ex_v1;
  cond_swap_regs(bit, k0, k6, v0, v6);
  cond_swap_regs(bit, k1, k7, v1, v7);
  cond_swap_regs(bit, k2, k4, v2, v4);
  cond_swap_regs(bit, k3, k5, v3, v5);
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k1, mask);
  ex_v0 = v0;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v1, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k0 = ex_k0;
  k1 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v0 = ex_v0;
  v1 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k2;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k3, mask);
  ex_v0 = v2;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v3, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k2 = ex_k0;
  k3 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v2 = ex_v0;
  v3 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k4;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k5, mask);
  ex_v0 = v4;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v5, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k4 = ex_k0;
  k5 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v4 = ex_v0;
  v5 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k6;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k7, mask);
  ex_v0 = v6;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v7, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k6 = ex_k0;
  k7 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v6 = ex_v0;
  v7 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  cond_swap_regs(bit, k0, k6, v0, v6);
  cond_swap_regs(bit, k1, k7, v1, v7);
  cond_swap_regs(bit, k2, k4, v2, v4);
  cond_swap_regs(bit, k3, k5, v3, v5);
}

// Exchange intersection for 8 key(s)
template<typename K>
__device__ inline void
exch_inter_keys(K& k0, K& k1, K& k2, K& k3, K& k4, K& k5, K& k6, K& k7, unsigned mask, const bool bit)
{
  K ex_k0, ex_k1;
  cond_swap_regs(bit, k0, k6);
  cond_swap_regs(bit, k1, k7);
  cond_swap_regs(bit, k2, k4);
  cond_swap_regs(bit, k3, k5);
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k1, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k0 = ex_k0;
  k1 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k2;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k3, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k2 = ex_k0;
  k3 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k4;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k5, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k4 = ex_k0;
  k5 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k6;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k7, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k6 = ex_k0;
  k7 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  cond_swap_regs(bit, k0, k6);
  cond_swap_regs(bit, k1, k7);
  cond_swap_regs(bit, k2, k4);
  cond_swap_regs(bit, k3, k5);
}

// Exchange intersection for 16 key-index pair(s)
template<typename K>
__device__ inline void exch_inter(
  K& k0,
  unsigned& v0,
  K& k1,
  unsigned& v1,
  K& k2,
  unsigned& v2,
  K& k3,
  unsigned& v3,
  K& k4,
  unsigned& v4,
  K& k5,
  unsigned& v5,
  K& k6,
  unsigned& v6,
  K& k7,
  unsigned& v7,
  K& k8,
  unsigned& v8,
  K& k9,
  unsigned& v9,
  K& k10,
  unsigned& v10,
  K& k11,
  unsigned& v11,
  K& k12,
  unsigned& v12,
  K& k13,
  unsigned& v13,
  K& k14,
  unsigned& v14,
  K& k15,
  unsigned& v15,
  unsigned mask,
  const bool bit)
{
  K ex_k0, ex_k1;
  unsigned ex_v0, ex_v1;
  cond_swap_regs(bit, k0, k14, v0, v14);
  cond_swap_regs(bit, k1, k15, v1, v15);
  cond_swap_regs(bit, k2, k12, v2, v12);
  cond_swap_regs(bit, k3, k13, v3, v13);
  cond_swap_regs(bit, k4, k10, v4, v10);
  cond_swap_regs(bit, k5, k11, v5, v11);
  cond_swap_regs(bit, k6, k8, v6, v8);
  cond_swap_regs(bit, k7, k9, v7, v9);
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k1, mask);
  ex_v0 = v0;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v1, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k0 = ex_k0;
  k1 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v0 = ex_v0;
  v1 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k2;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k3, mask);
  ex_v0 = v2;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v3, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k2 = ex_k0;
  k3 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v2 = ex_v0;
  v3 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k4;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k5, mask);
  ex_v0 = v4;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v5, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k4 = ex_k0;
  k5 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v4 = ex_v0;
  v5 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k6;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k7, mask);
  ex_v0 = v6;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v7, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k6 = ex_k0;
  k7 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v6 = ex_v0;
  v7 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k8;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k9, mask);
  ex_v0 = v8;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v9, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k8 = ex_k0;
  k9 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v8 = ex_v0;
  v9 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k10;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k11, mask);
  ex_v0 = v10;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v11, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k10 = ex_k0;
  k11 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v10 = ex_v0;
  v11 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k12;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k13, mask);
  ex_v0 = v12;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v13, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k12 = ex_k0;
  k13 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v12 = ex_v0;
  v13 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k14;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k15, mask);
  ex_v0 = v14;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v15, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k14 = ex_k0;
  k15 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v14 = ex_v0;
  v15 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  cond_swap_regs(bit, k0, k14, v0, v14);
  cond_swap_regs(bit, k1, k15, v1, v15);
  cond_swap_regs(bit, k2, k12, v2, v12);
  cond_swap_regs(bit, k3, k13, v3, v13);
  cond_swap_regs(bit, k4, k10, v4, v10);
  cond_swap_regs(bit, k5, k11, v5, v11);
  cond_swap_regs(bit, k6, k8, v6, v8);
  cond_swap_regs(bit, k7, k9, v7, v9);
}

// Exchange intersection for 16 key(s)
template<typename K>
__device__ inline void exch_inter_keys(
  K& k0,
  K& k1,
  K& k2,
  K& k3,
  K& k4,
  K& k5,
  K& k6,
  K& k7,
  K& k8,
  K& k9,
  K& k10,
  K& k11,
  K& k12,
  K& k13,
  K& k14,
  K& k15,
  unsigned mask,
  const bool bit)
{
  K ex_k0, ex_k1;
  cond_swap_regs(bit, k0, k14);
  cond_swap_regs(bit, k1, k15);
  cond_swap_regs(bit, k2, k12);
  cond_swap_regs(bit, k3, k13);
  cond_swap_regs(bit, k4, k10);
  cond_swap_regs(bit, k5, k11);
  cond_swap_regs(bit, k6, k8);
  cond_swap_regs(bit, k7, k9);
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k1, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k0 = ex_k0;
  k1 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k2;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k3, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k2 = ex_k0;
  k3 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k4;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k5, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k4 = ex_k0;
  k5 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k6;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k7, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k6 = ex_k0;
  k7 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k8;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k9, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k8 = ex_k0;
  k9 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k10;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k11, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k10 = ex_k0;
  k11 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k12;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k13, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k12 = ex_k0;
  k13 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k14;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k15, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k14 = ex_k0;
  k15 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  cond_swap_regs(bit, k0, k14);
  cond_swap_regs(bit, k1, k15);
  cond_swap_regs(bit, k2, k12);
  cond_swap_regs(bit, k3, k13);
  cond_swap_regs(bit, k4, k10);
  cond_swap_regs(bit, k5, k11);
  cond_swap_regs(bit, k6, k8);
  cond_swap_regs(bit, k7, k9);
}

// Exchange parallel for 2 key-index pair(s)
template<typename K>
__device__ inline void exch_paral(K& k0, unsigned& v0, K& k1, unsigned& v1, unsigned mask, const bool bit)
{
  K ex_k0, ex_k1;
  unsigned ex_v0, ex_v1;
  cond_swap_regs(bit, k0, k1, v0, v1);
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k1, mask);
  ex_v0 = v0;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v1, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k0 = ex_k0;
  k1 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v0 = ex_v0;
  v1 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  cond_swap_regs(bit, k0, k1, v0, v1);
}

// Exchange parallel for 2 key(s)
template<typename K>
__device__ inline void exch_paral_keys(K& k0, K& k1, unsigned mask, const bool bit)
{
  K ex_k0, ex_k1;
  cond_swap_regs(bit, k0, k1);
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k1, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k0 = ex_k0;
  k1 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  cond_swap_regs(bit, k0, k1);
}

// Exchange parallel for 4 key-index pair(s)
template<typename K>
__device__ inline void exch_paral(
  K& k0,
  unsigned& v0,
  K& k1,
  unsigned& v1,
  K& k2,
  unsigned& v2,
  K& k3,
  unsigned& v3,
  unsigned mask,
  const bool bit)
{
  K ex_k0, ex_k1;
  unsigned ex_v0, ex_v1;
  cond_swap_regs(bit, k0, k1, v0, v1);
  cond_swap_regs(bit, k2, k3, v2, v3);
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k1, mask);
  ex_v0 = v0;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v1, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k0 = ex_k0;
  k1 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v0 = ex_v0;
  v1 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k2;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k3, mask);
  ex_v0 = v2;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v3, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k2 = ex_k0;
  k3 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v2 = ex_v0;
  v3 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  cond_swap_regs(bit, k0, k1, v0, v1);
  cond_swap_regs(bit, k2, k3, v2, v3);
}

// Exchange parallel for 4 key(s)
template<typename K>
__device__ inline void exch_paral_keys(K& k0, K& k1, K& k2, K& k3, unsigned mask, const bool bit)
{
  K ex_k0, ex_k1;
  cond_swap_regs(bit, k0, k1);
  cond_swap_regs(bit, k2, k3);
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k1, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k0 = ex_k0;
  k1 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k2;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k3, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k2 = ex_k0;
  k3 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  cond_swap_regs(bit, k0, k1);
  cond_swap_regs(bit, k2, k3);
}

// Exchange parallel for 8 key-index pair(s)
template<typename K>
__device__ inline void exch_paral(
  K& k0,
  unsigned& v0,
  K& k1,
  unsigned& v1,
  K& k2,
  unsigned& v2,
  K& k3,
  unsigned& v3,
  K& k4,
  unsigned& v4,
  K& k5,
  unsigned& v5,
  K& k6,
  unsigned& v6,
  K& k7,
  unsigned& v7,
  unsigned mask,
  const bool bit)
{
  K ex_k0, ex_k1;
  unsigned ex_v0, ex_v1;
  cond_swap_regs(bit, k0, k1, v0, v1);
  cond_swap_regs(bit, k2, k3, v2, v3);
  cond_swap_regs(bit, k4, k5, v4, v5);
  cond_swap_regs(bit, k6, k7, v6, v7);
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k1, mask);
  ex_v0 = v0;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v1, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k0 = ex_k0;
  k1 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v0 = ex_v0;
  v1 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k2;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k3, mask);
  ex_v0 = v2;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v3, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k2 = ex_k0;
  k3 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v2 = ex_v0;
  v3 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k4;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k5, mask);
  ex_v0 = v4;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v5, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k4 = ex_k0;
  k5 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v4 = ex_v0;
  v5 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k6;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k7, mask);
  ex_v0 = v6;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v7, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k6 = ex_k0;
  k7 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v6 = ex_v0;
  v7 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  cond_swap_regs(bit, k0, k1, v0, v1);
  cond_swap_regs(bit, k2, k3, v2, v3);
  cond_swap_regs(bit, k4, k5, v4, v5);
  cond_swap_regs(bit, k6, k7, v6, v7);
}

// Exchange parallel for 8 key(s)
template<typename K>
__device__ inline void
exch_paral_keys(K& k0, K& k1, K& k2, K& k3, K& k4, K& k5, K& k6, K& k7, unsigned mask, const bool bit)
{
  K ex_k0, ex_k1;
  cond_swap_regs(bit, k0, k1);
  cond_swap_regs(bit, k2, k3);
  cond_swap_regs(bit, k4, k5);
  cond_swap_regs(bit, k6, k7);
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k1, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k0 = ex_k0;
  k1 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k2;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k3, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k2 = ex_k0;
  k3 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k4;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k5, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k4 = ex_k0;
  k5 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k6;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k7, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k6 = ex_k0;
  k7 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  cond_swap_regs(bit, k0, k1);
  cond_swap_regs(bit, k2, k3);
  cond_swap_regs(bit, k4, k5);
  cond_swap_regs(bit, k6, k7);
}

// Exchange parallel for 16 key-index pair(s)
template<typename K>
__device__ inline void exch_paral(
  K& k0,
  unsigned& v0,
  K& k1,
  unsigned& v1,
  K& k2,
  unsigned& v2,
  K& k3,
  unsigned& v3,
  K& k4,
  unsigned& v4,
  K& k5,
  unsigned& v5,
  K& k6,
  unsigned& v6,
  K& k7,
  unsigned& v7,
  K& k8,
  unsigned& v8,
  K& k9,
  unsigned& v9,
  K& k10,
  unsigned& v10,
  K& k11,
  unsigned& v11,
  K& k12,
  unsigned& v12,
  K& k13,
  unsigned& v13,
  K& k14,
  unsigned& v14,
  K& k15,
  unsigned& v15,
  unsigned mask,
  const bool bit)
{
  K ex_k0, ex_k1;
  unsigned ex_v0, ex_v1;
  cond_swap_regs(bit, k0, k1, v0, v1);
  cond_swap_regs(bit, k2, k3, v2, v3);
  cond_swap_regs(bit, k4, k5, v4, v5);
  cond_swap_regs(bit, k6, k7, v6, v7);
  cond_swap_regs(bit, k8, k9, v8, v9);
  cond_swap_regs(bit, k10, k11, v10, v11);
  cond_swap_regs(bit, k12, k13, v12, v13);
  cond_swap_regs(bit, k14, k15, v14, v15);
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k1, mask);
  ex_v0 = v0;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v1, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k0 = ex_k0;
  k1 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v0 = ex_v0;
  v1 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k2;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k3, mask);
  ex_v0 = v2;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v3, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k2 = ex_k0;
  k3 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v2 = ex_v0;
  v3 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k4;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k5, mask);
  ex_v0 = v4;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v5, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k4 = ex_k0;
  k5 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v4 = ex_v0;
  v5 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k6;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k7, mask);
  ex_v0 = v6;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v7, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k6 = ex_k0;
  k7 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v6 = ex_v0;
  v7 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k8;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k9, mask);
  ex_v0 = v8;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v9, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k8 = ex_k0;
  k9 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v8 = ex_v0;
  v9 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k10;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k11, mask);
  ex_v0 = v10;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v11, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k10 = ex_k0;
  k11 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v10 = ex_v0;
  v11 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k12;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k13, mask);
  ex_v0 = v12;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v13, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k12 = ex_k0;
  k13 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v12 = ex_v0;
  v13 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  ex_k0 = k14;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k15, mask);
  ex_v0 = v14;
  ex_v1 = __shfl_xor_sync(0xFFFFFFFF, v15, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1, ex_v0, ex_v1);
  k14 = ex_k0;
  k15 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  v14 = ex_v0;
  v15 = __shfl_xor_sync(0xFFFFFFFF, ex_v1, mask);
  cond_swap_regs(bit, k0, k1, v0, v1);
  cond_swap_regs(bit, k2, k3, v2, v3);
  cond_swap_regs(bit, k4, k5, v4, v5);
  cond_swap_regs(bit, k6, k7, v6, v7);
  cond_swap_regs(bit, k8, k9, v8, v9);
  cond_swap_regs(bit, k10, k11, v10, v11);
  cond_swap_regs(bit, k12, k13, v12, v13);
  cond_swap_regs(bit, k14, k15, v14, v15);
}

// Exchange parallel for 16 key(s)
template<typename K>
__device__ inline void exch_paral_keys(
  K& k0,
  K& k1,
  K& k2,
  K& k3,
  K& k4,
  K& k5,
  K& k6,
  K& k7,
  K& k8,
  K& k9,
  K& k10,
  K& k11,
  K& k12,
  K& k13,
  K& k14,
  K& k15,
  unsigned mask,
  const bool bit)
{
  K ex_k0, ex_k1;
  cond_swap_regs(bit, k0, k1);
  cond_swap_regs(bit, k2, k3);
  cond_swap_regs(bit, k4, k5);
  cond_swap_regs(bit, k6, k7);
  cond_swap_regs(bit, k8, k9);
  cond_swap_regs(bit, k10, k11);
  cond_swap_regs(bit, k12, k13);
  cond_swap_regs(bit, k14, k15);
  ex_k0 = k0;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k1, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k0 = ex_k0;
  k1 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k2;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k3, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k2 = ex_k0;
  k3 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k4;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k5, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k4 = ex_k0;
  k5 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k6;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k7, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k6 = ex_k0;
  k7 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k8;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k9, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k8 = ex_k0;
  k9 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k10;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k11, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k10 = ex_k0;
  k11 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k12;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k13, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k12 = ex_k0;
  k13 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  ex_k0 = k14;
  ex_k1 = __shfl_xor_sync(0xFFFFFFFF, k15, mask);
  cond_swap_regs((ex_k0 > ex_k1) ^ (bit && ex_k0 != ex_k1), ex_k0, ex_k1);
  k14 = ex_k0;
  k15 = __shfl_xor_sync(0xFFFFFFFF, ex_k1, mask);
  cond_swap_regs(bit, k0, k1);
  cond_swap_regs(bit, k2, k3);
  cond_swap_regs(bit, k4, k5);
  cond_swap_regs(bit, k6, k7);
  cond_swap_regs(bit, k8, k9);
  cond_swap_regs(bit, k10, k11);
  cond_swap_regs(bit, k12, k13);
  cond_swap_regs(bit, k14, k15);
}

#endif
