/*
 * Copyright 2018-2019 NWO-I
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#pragma once

// STD & STL
#include <iostream>
#include <string>
#include <type_traits>
#include <algorithm>

// boost
#include <boost/iostreams/concepts.hpp>

// free function to give to zmq::message_t "move" constructor
template<class BYTE>
auto deleteBuffer(void* data, void * /* hint */) -> void
{
  delete[] static_cast<BYTE*>(data);
}

template<typename BYTE = char>
class CustomSink : public boost::iostreams::sink {
public:
  using byte = BYTE;

  BYTE* data() { return _begin; }
  const BYTE* data() const { return _begin; }

  BYTE* begin() { return _begin; }
  const BYTE* begin() const { return _begin; }
  const BYTE* cbegin() const { return _begin; }

  BYTE* end() { return _end; }
  const BYTE* end() const { return _end; }
  const BYTE* cend() const { return _end; }

  std::size_t size() const { return _end - _begin; }

  std::size_t capacity() const { return _endc - _begin; }

  void reserve(std::size_t s)
  {
    if (capacity() >= s) return;
    std::size_t newcapa = capacity();
    if (newcapa < 64) newcapa = 64;
    while (newcapa < s)
      newcapa *= 1.5;
    CustomSink tmp;
    tmp._begin = new BYTE[newcapa];
    tmp._end = tmp._begin + size();
    tmp._endc = tmp._begin + newcapa;
    std::copy(begin(), end(), tmp.begin());
    std::swap(_begin, tmp._begin);
    std::swap(_end, tmp._end);
    std::swap(_endc, tmp._endc);
  }

  void resize(std::size_t s)
  {
    reserve(s);
    _end = _begin + s;
  }

  CustomSink() : _begin(nullptr), _end(nullptr), _endc(nullptr) {}

  CustomSink(std::size_t s) : CustomSink() { resize(s); }

  CustomSink(const CustomSink& o) : CustomSink()
  {
    resize(o.size());
    std::copy(o.begin(), o.end(), begin());
  }

  CustomSink(CustomSink&& o) : CustomSink()
  {
    std::swap(_begin, o._begin);
    std::swap(_end, o._end);
    std::swap(_endc, o._endc);
  }

  CustomSink& operator=(const CustomSink& o)
  {
    resize(o.size());
    std::copy(o.begin(), o.end(), begin());
  }

  CustomSink& operator=(CustomSink&& o)
  {
    std::swap(_begin, o._begin);
    std::swap(_end, o._end);
    std::swap(_endc, o._endc);
  }

  ~CustomSink() { delete[] _begin; }

  BYTE& operator[](std::size_t i) { return data()[i]; }
  BYTE operator[](std::size_t i) const { return data()[i]; }

  std::size_t write(const BYTE* p, std::size_t n)
  {
    std::size_t newsize = size() + n;
    reserve(newsize);
    BYTE* beg = end();
    resize(newsize);
    std::copy_n(p, n, beg);
    return n;
  }

  BYTE* release()
  {
    BYTE* p = _begin;
    _begin = _end = _endc = nullptr;
    return p;
  }

private:
  BYTE *_begin, *_end, *_endc;
};
