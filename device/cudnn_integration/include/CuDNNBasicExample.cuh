/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "VeloConsolidated.cuh"
#include "AlgorithmTypes.cuh"

#ifdef CUDNN_AVAILABLE 
#include <cudnn.h>
#endif

namespace cudnn_integration {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_velo_track_hit_number;
    DEVICE_OUTPUT(dev_cudnn_output_t, float) dev_cudnn_output;
  };

  struct cudnn_basic_convolution_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters>, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<int> m_input_channels {this, "input_channels", 1, "number of input channels"};
    Allen::Property<int> m_output_channels {this, "output_channels", 32, "number of output channels"};
    Allen::Property<int> m_kernel_size {this, "kernel_size", 3, "convolution kernel size"};
    Allen::Property<int> m_input_width {this, "input_width", 64, "input tensor width"};
    Allen::Property<int> m_input_height {this, "input_height", 64, "input tensor height"};
    Allen::Property<dim3> m_block_dim {this, "block_dim", {32, 1, 1}, "block dimensions"};
  };

#ifdef CUDNN_AVAILABLE
  // CuDNN helper functions
  void check_cudnn_error(cudnnStatus_t status, const char* file, int line);
  void setup_cudnn_convolution(
    cudnnHandle_t& cudnn,
    cudnnTensorDescriptor_t& input_desc,
    cudnnTensorDescriptor_t& output_desc,
    cudnnFilterDescriptor_t& filter_desc,
    cudnnConvolutionDescriptor_t& conv_desc,
    cudnnConvolutionFwdAlgo_t& conv_algo,
    int batch_size,
    int input_channels,
    int output_channels,
    int input_height,
    int input_width,
    int kernel_size
  );
  void cleanup_cudnn_resources(
    cudnnHandle_t& cudnn,
    cudnnTensorDescriptor_t& input_desc,
    cudnnTensorDescriptor_t& output_desc,
    cudnnFilterDescriptor_t& filter_desc,
    cudnnConvolutionDescriptor_t& conv_desc
  );
#endif

  // CUDA kernels for data preparation and post-processing
  __global__ void init_filter_kernel(float* filter, int size);
  
  __global__ void prepare_convolution_input(
    const unsigned* track_hit_number,
    const unsigned* track_offsets,
    float* conv_input,
    const unsigned number_of_events,
    const int input_channels,
    const int input_height,
    const int input_width
  );

  __global__ void process_convolution_output(
    const float* conv_output,
    float* final_output,
    const unsigned number_of_events,
    const int output_channels,
    const int output_height,
    const int output_width
  );

} // namespace cudnn_integration
