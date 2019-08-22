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

#include <type_traits>
#include <utility>

#if defined(__clang__) && (__clang_major__ > 3 || (__clang_major__ == 3 && __clang_minor__ >= 10))
#define HAVE_TRIVIALLY_COPYABLE 1
#elif defined(__GNUC__) && __GNUC__ >= 5
#define HAVE_TRIVIALLY_COPYABLE 1
#else
#undef HAVE_TRIVIALLY_COPYABLE
#endif

namespace Detail {

  template<typename... Ts>
  struct is_container_helper {
  };

#if defined(HAVE_TRIVIALLY_COPYABLE)
  template<class T>
  using simple_object = std::is_trivially_copyable<T>;
#else
  template<class T>
  using simple_object = std::is_pod<T>;
#endif

  // is trivial
  template<class T>
  struct is_trivial
    : std::conditional<simple_object<typename std::decay<T>::type>::value, std::true_type, std::false_type>::type {
  };

} // namespace Detail

// is_pair
template<class>
struct is_pair : std::false_type {
};

template<class F, class S>
struct is_pair<std::pair<F, S>> : public std::true_type {
};

// is_container
template<typename T, typename _ = void>
struct is_container : std::false_type {
};

template<typename T>
struct is_container<
  T,
  typename std::conditional<
    false,
    Detail::is_container_helper<
      typename T::value_type,
      typename T::size_type,
      typename T::allocator_type,
      typename T::iterator,
      typename T::const_iterator,
      decltype(std::declval<T>().size()),
      decltype(std::declval<T>().begin()),
      decltype(std::declval<T>().end()),
      decltype(std::declval<T>().cbegin()),
      decltype(std::declval<T>().cend())>,
    void>::type> : public std::true_type {
};
