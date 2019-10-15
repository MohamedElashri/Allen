#include <string>
#include <optional>
#include <memory>
#include <map>
#include <array>

#include <Dumpers/Identifiers.h>
#include <Common.h>
#include <InputReader.h>
#include <Updater.h>
#include <tuple>
namespace {
  using std::array;
  using std::map;
  using std::optional;
  using std::string;
  using std::tuple;
  using std::unique_ptr;
  using std::vector;
} // namespace

namespace Allen {
  namespace NonEventData {

    Updater::Updater(map<string, string> const& options)
    {

      auto get_option = [&options](const std::string& f) -> std::string {
        auto it = options.find(f);
        if (it == options.end()) {
          StrException {string {"Unknown option flag: "} + f};
        }
        else {
          return it->second;
        }
        return "";
      };

      auto folder_detector_configuration = get_option("g");
      GeometryReader reader {folder_detector_configuration};

      auto geometry_producer = [reader](const std::string& file) {
        return [reader, file]() -> optional<vector<char>> { return reader.read_geometry(file); };
      };

      tuple producers {tuple {NonEventData::VeloGeometry {}, std::string("velo_geometry.bin")},
                       tuple {NonEventData::UTBoards {}, std::string("ut_boards.bin")},
                       tuple {NonEventData::Beamline {}, std::string("beamline.bin")},
                       tuple {NonEventData::MagneticField {}, std::string("polarity.bin")},
                       tuple {NonEventData::UTGeometry {}, std::string("ut_geometry.bin")},
                       tuple {NonEventData::UTLookupTables {}, std::string("ut_tables.bin")},
                       tuple {NonEventData::SciFiGeometry {}, std::string("scifi_geometry.bin")},
                       tuple {NonEventData::MuonGeometry {}, std::string("muon_geometry.bin")},
                       tuple {NonEventData::MuonLookupTables {}, std::string("muon_tables.bin")}};

      for_each(producers, [this, &geometry_producer](const auto& p) {
        using id_t = typename std::remove_reference_t<decltype(std::get<0>(p))>;
        registerProducer(id_t::id, geometry_producer(std::get<1>(p)));
      });
    }

    void Updater::registerConsumer(string const& id, unique_ptr<Consumer> c)
    {
      auto it = m_pairs.find(id);
      if (it == m_pairs.end()) {
        vector<unique_ptr<Consumer>> consumers(1);
        consumers[0] = std::move(c);
        auto entry = tuple {Producer {}, std::move(consumers)};
        m_pairs.emplace(id, std::move(entry));
      }
      else {
        std::get<1>(it->second).emplace_back(std::move(c));
      }
    }

    void Updater::registerProducer(string const& id, Producer p)
    {
      auto it = m_pairs.find(id);
      if (it == m_pairs.end()) {
        auto entry = tuple {std::move(p), std::vector<std::unique_ptr<Consumer>> {}};
        m_pairs.emplace(id, std::move(entry));
      }
      else if (!std::get<0>(it->second)) {
        std::get<0>(it->second) = std::move(p);
      }
      else {
        throw StrException {string {"Producer for "} + it->first + " already registered."};
      }
    }

    void Updater::update(unsigned long)
    {
      for (auto const& entry : m_pairs) {
        auto const& name = std::get<0>(entry);
        auto const& p = std::get<1>(entry);

        if (!std::get<0>(p)) {
          throw StrException {string {"No producer for "} + name};
        }
        else if (std::get<1>(p).empty()) {
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
            error_cout << name << " update failed: " << e.what() << std::endl;
            throw e;
          }
        }
      }
    }
  } // namespace NonEventData
} // namespace Allen

Allen::NonEventData::IUpdater* make_updater(std::map<std::string, std::string>& options)
{
  return new Allen::NonEventData::Updater {options};
}
