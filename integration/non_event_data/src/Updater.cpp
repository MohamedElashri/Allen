#include <string>
#include <optional>
#include <memory>
#include <map>
#include <array>

#include <Dumpers/Identifiers.h>
#include <Common.h>
#include <InputReader.h>
#include <Updater.h>

namespace {
  using std::string;
  using std::map;
  using std::vector;
  using std::array;
  using std::optional;
  using std::tuple;
  using std::unique_ptr;
}

namespace Test {
struct UTBoards {
  uint32_t number_of_boards;
  uint32_t number_of_channels;
  uint32_t* stripsPerHybrids;
  uint32_t* stations;
  uint32_t* layers;
  uint32_t* detRegions;
  uint32_t* sectors;
  uint32_t* chanIDs;

  UTBoards(const char* ut_boards) {
    uint32_t* p = (uint32_t*) ut_boards;
    number_of_boards = *p;
    p += 1;
    number_of_channels = 6 * number_of_boards;
    stripsPerHybrids = p;
    p += number_of_boards;
    stations = p;
    p += number_of_channels;
    layers = p;
    p += number_of_channels;
    detRegions = p;
    p += number_of_channels;
    sectors = p;
    p += number_of_channels;
    chanIDs = p;
    p += number_of_channels;
  }
};
}

namespace Allen {
namespace NonEventData {

  std::optional<vector<char>> beamline_producer() {
    vector<char> data(2 * sizeof(float));
    const array<float, 2> host_beamline{0.0f, 0.0f};
    memcpy(data.data(), host_beamline.data(), data.size());
    return {data};
  }

  std::optional<vector<char>> magnetic_field_producer() {
    vector<char> data(sizeof(float));
    const float host_magnet_polarity = -1.f;
    memcpy(data.data(), &host_magnet_polarity, data.size());
    return {data};
  }

  Updater::Updater(map<string, string> const& options) {

    auto get_option = [&options] (const std::string& f) {
                        auto it = options.find(f);
                        if (it == options.end()) {
                          StrException{string{"Unknown option flag: "} + f};
                        } else {
                          return it->second;
                        }
                      };

    auto folder_detector_configuration = get_option("g");
    GeometryReader reader{folder_detector_configuration};

    auto geometry_producer = [reader] (const std::string& file) {
                               return [reader, file] () -> optional<vector<char>> {
                                 return reader.read_geometry(file);
                               };
                             };


    auto ut_boards = [reader] () -> optional<vector<char>> {
                         auto v = reader.read_geometry("ut_boards.bin");
                         Test::UTBoards boards{v.data()};
                         info_cout << boards.number_of_boards << std::endl;
                         for (int i = 0; i < boards.number_of_boards; ++i) {
                           info_cout << "sph " << std::setw(3) << i << " " << boards.stripsPerHybrids[i] << std::endl;
                         }
                         for (int i = 0; i < 6 * boards.number_of_boards; ++i) {
                           info_cout << "stations " << std::setw(3) << i << " " << boards.stations[i] << std::endl;
                         }
                         return v;
    };

    registerProducer(NonEventData::UTBoards::id, ut_boards);

    tuple producers{tuple{NonEventData::VeloGeometry{},  "velo_geometry.bin"},
                    tuple{NonEventData::UTGeometry{}, "ut_geometry.bin"},
                    tuple{NonEventData::UTLookupTables{}, "ut_tables.bin"},
                    tuple{NonEventData::SciFiGeometry{}, "scifi_geometry.bin"}};

    for_each(producers, [this, &geometry_producer] (const auto& p) {
                          using id_t = typename std::remove_reference_t<decltype(std::get<0>(p))>;
                          registerProducer(id_t::id, geometry_producer(std::get<1>(p)));
                        });

    // registerProducer(NonEventData::UTLookupTables::id, [folder_detector_configuration] {
    //                                                      UTMagnetToolReader reader{folder_detector_configuration};
    //                                                      return reader.read_UT_magnet_tool();
    //                                                    });

    registerProducer(NonEventData::Beamline::id, beamline_producer);
    registerProducer(NonEventData::MagneticField::id, magnetic_field_producer);


  }

  void Updater::registerConsumer(string const&id, unique_ptr<Consumer> c) {
    auto it = m_pairs.find(id);
    if (it == m_pairs.end()) {
      vector<unique_ptr<Consumer>> consumers(1);
      consumers[0] = std::move(c);
      auto entry = tuple{Producer{}, std::move(consumers)};
      m_pairs.emplace(id, std::move(entry));
    } else {
      std::get<1>(it->second).emplace_back(std::move(c));
    }
  }

  void Updater::registerProducer(string const& id, Producer p) {
    auto it = m_pairs.find(id);
    if (it == m_pairs.end()) {
      auto entry = tuple{std::move(p), std::vector<std::unique_ptr<Consumer>>{}};
      m_pairs.emplace(id, std::move(entry));
    } else if (!std::get<0>(it->second)) {
      std::get<0>(it->second) = std::move(p);
    } else {
      throw StrException{string{"Producer for "} + it->first + " already registered."};
    }
  }

  void Updater::update(unsigned long) {
    for (auto const& entry : m_pairs) {
      auto const& name = std::get<0>(entry);
      auto const& p = std::get<1>(entry);

      if(!std::get<0>(p)) {
        throw StrException{string{"No producer for "} + name};
      } else if (std::get<1>(p).empty()) {
        debug_cout << "No consumers for " << std::get<0>(entry) << "\n";
      }
    }
    for (auto const& entry : m_pairs) {
      auto const& name = std::get<0>(entry);
      debug_cout << "Updating " << name << "\n";
      auto const& pairs = std::get<1>(entry);
      if (std::get<1>(pairs).empty()) continue;

      // Produce update
      auto update = std::get<0>(pairs)();
      if (update) {
        try {
          auto& consumers = std::get<1>(pairs);
          for (auto& consumer : consumers) {
            consumer->consume(*update);
          }
        } catch (const StrException& e) {
          error_cout << name << " update failed: "  << e.what() << std::endl;
          throw e;
        }
      }
    }
  }
}
}

Allen::NonEventData::IUpdater* make_updater(std::map<std::string, std::string>& options) {
  return new Allen::NonEventData::Updater{options};
}
