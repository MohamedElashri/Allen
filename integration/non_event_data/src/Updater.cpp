#include <string>
#include <optional>
#include <memory>
#include <map>

#include <Common.h>
#include <InputReader.h>
#include <Updater.h>
#include <Identifiers.h>

namespace {
  using std::string;
  using std::map;
  using std::vector;
  using std::optional;
  using std::tuple;
  using std::unique_ptr;
}

namespace Allen {
namespace NonEventData {

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

    tuple producers{tuple{NonEventData::VeloGeometry{},  "velo_geometry.bin"},
                    tuple{NonEventData::UTGeometry{}, "ut_geometry.bin"},
                    tuple{NonEventData::UTBoards{}, "ut_boards.bin"},
                    tuple{NonEventData::SciFiGeometry{}, "scifi_geometry.bin"}};

    for_each(producers, [this, &geometry_producer] (const auto& p) {
                          using id_t = typename std::remove_reference_t<decltype(std::get<0>(p))>;
                          registerProducer(id_t::id, geometry_producer(std::get<1>(p)));
                        });

    registerProducer(NonEventData::UTLookupTables::id, [folder_detector_configuration] {
                                                         UTMagnetToolReader reader{folder_detector_configuration};
                                                         return reader.read_UT_magnet_tool();
                                                       });
  }

  void Updater::registerConsumer(string const&id, unique_ptr<Consumer> c) {
    auto it = m_pairs.find(id);
    if (it == m_pairs.end()) {
      m_pairs.emplace(id, tuple{Producer{}, std::move(c)});
    } else if (!std::get<1>(it->second)) {
      std::get<1>(it->second) = std::move(c);
    } else {
      throw StrException{string{"Consumer for "} + it->first + " already registered."};
    }
  }

  void Updater::registerProducer(string const& id, Producer p) {
    auto it = m_pairs.find(id);
    if (it == m_pairs.end()) {
      m_pairs.emplace(id, tuple{std::move(p), std::unique_ptr<Consumer>{}});
    } else if (!std::get<0>(it->second)) {
      std::get<0>(it->second) = std::move(p);
    } else {
      throw StrException{string{"Producer for "} + it->first + " already registered."};
    }
  }

  void Updater::update(unsigned int) {
    for (auto const& entry : m_pairs) {
      auto const& name = std::get<0>(entry);
      auto const& p = std::get<1>(entry);

      if(!std::get<0>(p)) {
        throw StrException{string{"No producer for "} + name};
      } else if (!std::get<1>(p)) {
        std::cout << "No producer for " << std::get<0>(entry) << "\n";
      }
    }
    for (auto const& entry : m_pairs) {
      auto const& name = std::get<0>(entry);
      debug_cout << "Updating " << name << "\n";
      auto const& p = std::get<1>(entry);
      if (!std::get<1>(p)) continue;
      auto update = std::get<0>(p)();
      if (update) {
        try {
          std::get<1>(p)->consume(std::move(*update));
        } catch (const StrException& e) {
          error_cout << name << " update failed: "  << e.what() << std::endl;
          throw e;
        }
      }
    }
  }
}
}
