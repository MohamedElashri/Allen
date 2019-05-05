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
      //std::cerr << "add: x = " << x << ", y = " << y << ", value = " << value << ", xy = ";
      unsigned long long xy = concatenate(x, y);
      //std::cerr << xy << "\n";
      short index = findIndex(xy);
      xys[index] = xy;
      next[last[index]] = currentFreeNext;
      //std::cerr << "index = " << index << ", last[" << index << "] = " << last[index] << ", next[" << last[index] << "] = " << next[last[index]] << "\n";
      last[index] = currentFreeNext;
      //std::cerr << "currentFreeNext = " << currentFreeNext << ", value = " << value << "\n";
      values[currentFreeNext - M] = value;
      currentFreeNext++;
    }

    __device__ short findIndex(unsigned long long xy) {
      //std::cerr << "findIndex: xy = " << xy << ", ";
      auto index = (short)(xy % M);
      //std::cerr << "hash = " << index << ", ";
      while (xys[index] != 0 && xys[index] != xy) {
        index++;
        if (index == M) {
          index = 0;
        }
      }
      //std::cerr << "index = " << index << "\n";
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
      //std::cerr << "BEFORE: index = " << index << ", ";
      if (index == -1) {
        //std::cerr << "\n";
        return false;
      }
      value = values[index - M];
      index = next[index];
      //std::cerr << "value = " << value << ", AFTER: index = " << index << "\n";
      return true;
    }
  };
};