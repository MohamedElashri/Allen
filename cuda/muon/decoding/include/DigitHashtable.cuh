#pragma once

namespace Muon {
  struct DigitHashtable {
    static constexpr size_t M = 1601; //prime number greater than Constants::max_numhits_per_event / Constants::n_stations
    short currentFreeNext = M;
    unsigned long long xys[M] = {0};
    short next[2 * M];
    short last[M];
    size_t values[M];

    __device__ DigitHashtable() {
      for (short i = 0; i < M; i++) {
        last[i] = i;
      }
      memset(next, -1, sizeof(next));
      memset(xys, 0, sizeof(xys));
    }

    __device__ unsigned long long concatenate(unsigned int a, unsigned int b) {
      return (((unsigned long long) a) << 32) + b;
    }

    __device__ void add(unsigned int x, unsigned int y, size_t value) {
      unsigned long long xy = concatenate(x, y);
      short index = findIndex(xy);
      xys[index] = xy;
      next[last[index]] = currentFreeNext;
      last[index] = currentFreeNext;
      values[currentFreeNext - M] = value;
      currentFreeNext++;
    }

    __device__ short findIndex(unsigned long long xy) {
      auto index = (short)(xy % M);
      while (xys[index] != 0 && xys[index] != xy) {
        index++;
        if (index == M) {
          index = 0;
        }
      }
      return index;
    }

    __device__ short find(unsigned int x, unsigned int y) {
      unsigned long long xy = concatenate(x, y);
      short foundIndex = findIndex(xy);
      if (xys[foundIndex] == 0) {
        return -1;
      } else {
        return next[foundIndex];
      }
    }

    __device__ bool iterateOverValues(short& index, size_t& value) {
      if (index == -1) {
        return false;
      }
      value = values[index - M];
      index = next[index];
      return true;
    }
  };
};
