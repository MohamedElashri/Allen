#include <Event/ODIN.h>

namespace boost {
  namespace serialization {

    // Serialize RunInfo
    template<typename Archive>
    auto serialize(Archive& archive, LHCb::ODIN& t, const unsigned int /* version */) -> void
    {
      archive& t.data;
    }

  } // namespace serialization
} // namespace boost
