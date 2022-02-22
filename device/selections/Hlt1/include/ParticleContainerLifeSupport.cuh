#pragma once

#include "AlgorithmTypes.cuh"
#include "ParticleTypes.cuh"

namespace particle_container_life_support {
  struct Parameters {
    DEVICE_INPUT(dev_particle_container_ptr_t, Allen::Views::Physics::IMultiEventParticleContainer*)
    dev_particle_container_ptr_t;
    DEVICE_INPUT(dev_particle_container_user_t, unsigned) dev_particle_container_user_t;
  };

  struct particle_container_life_support_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      const Allen::Context& context) const;
  };
} // namespace particle_container_life_support