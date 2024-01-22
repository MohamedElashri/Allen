/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <gsl/span>
#include <memory>

#include "Common.h"
#include "AlgorithmTypes.cuh"
#include "InputProvider.h"
#include "Event/RawBank.h"
#include <MEPTools.h>

#ifndef ALLEN_STANDALONE
#include <GaudiKernel/ParsersFactory.h>
#include <GaudiKernel/ToStream.h>
#include <Gaudi/Parsers/CommonParsers.h>
#include <GaudiKernel/StatusCode.h>
#include <Kernel/STLExtensions.h>
#include <GaudiMonitoring.h>
#endif

namespace error_bank_filter {
  struct bank_types_t {
    using key_type = std::string;
    using mapped_type = std::vector<std::string>;

    void insert(std::pair<key_type, mapped_type> v)
    {
      if (v.first == "data_types") {
        data_types = std::move(v.second);
      }
      else if (v.first == "other_types") {
        other_types = std::move(v.second);
      }
      else if (v.first == "error_types") {
        error_types = std::move(v.second);
      }
    }

    std::vector<std::string> data_types;
    std::vector<std::string> other_types;
    std::vector<std::string> error_types;
  };

  // Conversion functions from and to json
  void from_json(const nlohmann::json& j, bank_types_t& sd_bank_types);

  void to_json(nlohmann::json& j, bank_types_t const& sd_bank_types);

  struct Parameters {
    HOST_INPUT(host_event_list_t, unsigned) host_event_list;
    HOST_INPUT(mep_layout_t, unsigned) mep_layout;
    MASK_OUTPUT(dev_output_event_list_t) dev_output_event_list;
    HOST_OUTPUT(host_output_event_list_t, unsigned) host_output_event_list;
    HOST_OUTPUT(host_number_of_selected_events_t, unsigned) host_number_of_selected_events;
    PROPERTY(
      sd_bank_types_t,
      "sd_bank_types",
      "subdetector data, other and error bank types",
      std::map<std::string, error_bank_filter::bank_types_t>)
    sd_bank_types;
    PROPERTY(daq_error_types_t, "daq_error_types", "DAQ error types", std::vector<std::string>) daq_error_types;
  };

  // Algorithm
  struct error_bank_filter_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const Allen::Context& context) const;

    void init();

    void error_bank_filter(
      Parameters parameters,
      IInputProvider const* input_provider,
      unsigned const slice_index,
      unsigned const number_of_events,
      unsigned const event_start) const;

  private:
    using bin_mapping_t = std::array<unsigned, LHCb::RawBank::BankType::LastType>;

#ifndef ALLEN_STANDALONE
    mutable std::unique_ptr<gaudi_histo_t<1, float>> m_data_banks;
    mutable bin_mapping_t m_data_bin_mapping;
    mutable std::unique_ptr<gaudi_histo_t<1, float>> m_other_banks;
    mutable bin_mapping_t m_other_bin_mapping;
    mutable std::unique_ptr<gaudi_histo_t<1, float>> m_error_banks;
    mutable bin_mapping_t m_error_bin_mapping;
#endif

    struct sd_info_t {
      sd_info_t() = default;

      BankTypes sd = BankTypes::Unknown;
      std::unordered_set<unsigned char> data_bank_types;
      std::unordered_set<unsigned char> other_bank_types;
      std::unordered_set<unsigned char> error_bank_types;
#ifndef ALLEN_STANDALONE
      bin_mapping_t mapping;
      std::unique_ptr<gaudi_histo_t<1, float>> banks;
      std::unique_ptr<Gaudi::Accumulators::Counter<>> error;
      std::unique_ptr<Gaudi::Accumulators::Counter<>> invalid_type;
#endif
    };

    mutable std::unordered_map<std::string, sd_info_t> m_sd_info;

    Property<sd_bank_types_t> m_sd_bank_types {this, {}};
    Property<daq_error_types_t> m_daq_error_types {this,
                                                   {"DaqErrorFragmentThrottled",
                                                    "DaqErrorBXIDCorrupted",
                                                    "DaqErrorSyncBXIDCorrupted",
                                                    "DaqErrorFragmentMissing",
                                                    "DaqErrorFragmentTruncated",
                                                    "DaqErrorIdleBXIDCorrupted",
                                                    "DaqErrorFragmentMalformed",
                                                    "DaqErrorEVIDJumped"}};
  };

} // namespace error_bank_filter

#ifndef ALLEN_STANDALONE
namespace Gaudi::Utils {
  inline std::string toString(error_bank_filter::bank_types_t bt)
  {
    std::map<std::string, std::vector<std::string>> tmp = {{"data_types", std::move(bt.data_types)},
                                                           {"other_types", std::move(bt.other_types)},
                                                           {"error_types", std::move(bt.error_types)}};
    return toString(std::move(tmp));
  }

  std::ostream& toStream(error_bank_filter::bank_types_t bt, std::ostream& os)
  {
    return os << std::quoted(toString(std::move(bt)), '\'');
  }
} // namespace Gaudi::Utils

namespace error_bank_filter {
  std::ostream& operator<<(std::ostream& s, bank_types_t bt) { return Gaudi::Utils::toStream(std::move(bt), s); }
} // namespace error_bank_filter

namespace Gaudi {
  namespace Parsers {

    template<typename Iterator, typename Skipper>
    struct Grammar_<Iterator, error_bank_filter::bank_types_t, Skipper> {
      typedef MapGrammar<Iterator, error_bank_filter::bank_types_t, Skipper> Grammar;
    };

    StatusCode parse(error_bank_filter::bank_types_t& bt, const std::string& in);
  } // namespace Parsers
} // namespace Gaudi
#endif
