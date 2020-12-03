#pragma once

#include "Common.h"
#include "Contract.h"
#include "ArgumentOps.cuh"

namespace Allen {
  namespace contract {
    namespace ops {
      template<typename T, int N>
      struct limit_high {
        constexpr static auto limit = static_cast<T>(N);
        constexpr bool operator()(const T& v) const { return v < limit; }
      };

      template<typename T, int N>
      struct limit_low {
        constexpr static auto limit = static_cast<T>(N);
        constexpr bool operator()(const T& v) const { return v >= limit; }
      };
    } // namespace ops

    /**
     * @brief Checks that all elements of container T fulfill the condition
     */
    template<typename T, typename Parameters, typename ContractType, typename UnOp>
    struct all_elements_condition : public ContractType {
      using ContractType::require;
      void operator()(
        const ArgumentReferences<Parameters>& arguments,
        const RuntimeOptions&,
        const Constants&,
        const Allen::Context&) const
      {
        const UnOp unop {};
        const auto container = make_vector<T>(arguments);
        const auto container_name = name<T>(arguments);

        bool condition = true;
        for (size_t i = 0; i < container.size() && condition; ++i) {
          condition &= unop(container[i]);
        }

        require(condition, "Require condition " + demangle<UnOp>() + " on all elements of " + container_name);
      }
    };

    /**
     * @brief Checks that container T fulfills conditions element by element
     */
    template<typename T, typename Parameters, typename ContractType, typename BinOp>
    struct consecutive_condition : public ContractType {
      using ContractType::require;
      void operator()(
        const ArgumentReferences<Parameters>& arguments,
        const RuntimeOptions&,
        const Constants&,
        const Allen::Context&) const
      {
        const BinOp binop {};
        const auto container = make_vector<T>(arguments);
        const auto container_name = name<T>(arguments);

        bool condition = true;
        if (container.size() > 0) {
          auto previous = std::begin(container);
          auto next = std::begin(container);
          while (++next != std::end(container) && condition) {
            condition &= binop(*next, *previous);
            previous = next;
          }
        }

        require(condition, "Require condition " + demangle<BinOp>() + " on consecutive elements of " + container_name);
      }
    };

    template<typename A, typename B, typename Parameters, typename ContractType>
    struct are_equal : public ContractType {
      using ContractType::require;
      void operator()(
        const ArgumentReferences<Parameters>& arguments,
        const RuntimeOptions&,
        const Constants&,
        const Allen::Context&) const
      {
        const auto container_a = make_vector<A>(arguments);
        const auto container_b = make_vector<B>(arguments);
        const auto container_a_name = name<A>(arguments);
        const auto container_b_name = name<B>(arguments);

        bool condition = container_a.size() == container_b.size();
        if (condition) {
          for (size_t i = 0; i < container_a.size() && condition; ++i) {
            condition &= container_a[i] == container_b[i];
          }
        }

        require(condition, "Require that containers " + container_a_name + " and " + container_b_name + " be equal");
      }
    };

    template<int N, typename T, typename Parameters, typename ContractType>
    using limit_high = all_elements_condition<T, Parameters, ContractType, ops::limit_high<typename T::type, N>>;

    template<int N, typename T, typename Parameters, typename ContractType>
    using limit_low = all_elements_condition<T, Parameters, ContractType, ops::limit_low<typename T::type, N>>;

    template<typename T, typename Parameters, typename ContractType>
    using is_monotonically_increasing =
      consecutive_condition<T, Parameters, ContractType, std::greater_equal<typename T::type>>;
  } // namespace contract
} // namespace Allen
