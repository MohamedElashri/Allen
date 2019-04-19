#pragma once

#include <string>
#include <memory>

#include "IUpdater.h"

namespace Allen {
namespace NonEventData {

class Updater final : public IUpdater {
public:

  Updater() = delete;
  Updater(std::map<std::string, std::string> const& options);
  virtual ~Updater() = default;

  void update(unsigned int run) override;

protected:

  void registerConsumer(std::string const& id, std::unique_ptr<NonEventData::Consumer> c) override;

  void registerProducer(std::string const& id, NonEventData::Producer p) override;

private:

  std::map<std::string, std::tuple<NonEventData::Producer, std::unique_ptr<NonEventData::Consumer>>> m_pairs;

};
}
}
