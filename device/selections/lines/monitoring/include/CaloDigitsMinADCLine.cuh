/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"
#include "Line.cuh"
#include "CaloGeometry.cuh"
#include "CaloDigit.cuh"

namespace calo_digits_minADC {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_ecal_number_of_digits_t, unsigned) host_ecal_number_of_digits;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_ecal_digits_t, CaloDigit) dev_ecal_digits;
    DEVICE_INPUT(dev_ecal_digits_offsets_t, unsigned) dev_ecal_digits_offsets;

    DEVICE_OUTPUT(host_decisions_size_t, unsigned) host_decisions_size;

    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;

    HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;

    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(minADC_t, "minADC", "minADC description", int16_t) minADC;
  };

  struct calo_digits_minADC_t : public SelectionAlgorithm, Parameters, Line<calo_digits_minADC_t, Parameters> {

    __device__ static bool select(const Parameters& ps, std::tuple<const CaloDigit> input);

    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_ecal_digits_offsets[event_number];
    }

    __device__ static unsigned input_size(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_ecal_digits_offsets[event_number + 1] - parameters.dev_ecal_digits_offsets[event_number];
    }

    __device__ static std::tuple<const CaloDigit>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i)
    {
      const CaloDigit event_ecal_digits =
        parameters.dev_ecal_digits[parameters.dev_ecal_digits_offsets[event_number] + i];
      return std::forward_as_tuple(event_ecal_digits);
    }

    static unsigned get_decisions_size(const ArgumentReferences<Parameters>& arguments)
    {
      return first<typename Parameters::host_ecal_number_of_digits_t>(arguments);
    }

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1.f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<minADC_t> m_minADC {this, 10}; // MeV
  };
} // namespace calo_digits_minADC
