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
#include <HostBuffersManager.cuh>
#include <Logger.h>
#include <MakeSubBanks.cuh>
#include <MakeSelRep.cuh>
#include <HltDecReport.cuh>
#include <regex>

HostBuffersManager::HostBuffersManager(
  size_t nBuffers,
  size_t host_memory_size,
  const ConfigurationReader::Params& configuration)
{
  m_host_memory_size = host_memory_size;
  m_persistent_stores.reserve(nBuffers);
  for (size_t i = 0; i < nBuffers; ++i) {
    m_persistent_stores.push_back(new Allen::Store::PersistentStore(host_memory_size, 64));
    buffer_statuses.push_back(BufferStatus::Empty);
    empty_buffers.push(i);
  }

  // load configuration relevant to the large-event passthrough
  if (configuration.find("dec_reporter") != configuration.end()) {
    auto decrep_config = configuration.find("dec_reporter")->second;
    for (auto& [key, m] : {std::tuple {"tck", std::ref(m_tck)}, std::tuple {"task_id", std::ref(m_task_id)}}) {
      if (decrep_config.find(key) != decrep_config.end()) {
        m.get() = decrep_config[key].template get<unsigned>();
      }
    }
  }

  if (configuration.find("host_routingbits_writer") != configuration.end()) {
    auto rb_config = configuration.find("host_routingbits_writer")->second;
    if (rb_config.find("routingbit_map") != rb_config.end()) {
      for (auto [expr, bit] : rb_config["routingbit_map"].template get<std::map<std::string, unsigned>>()) {
        std::smatch result;
        if (std::regex_match(m_passthrough_line, result, std::regex {expr})) {
          m_passthrough_rbs |= 1u << bit;
        }
      }
    }
  }
}

size_t HostBuffersManager::assignBufferToFill()
{
  if (empty_buffers.empty()) {
    warning_cout << "No empty buffers available" << std::endl;
    warning_cout << "Adding new buffers" << std::endl;
    m_persistent_stores.push_back(new Allen::Store::PersistentStore(m_host_memory_size, 64));
    buffer_statuses.push_back(BufferStatus::Filling);
    return m_persistent_stores.size() - 1;
  }

  auto b = empty_buffers.front();
  empty_buffers.pop();

  buffer_statuses[b] = BufferStatus::Filling;
  return b;
}

void HostBuffersManager::returnBufferFilled(size_t b)
{
  buffer_statuses[b] = BufferStatus::Filled;
  filled_buffers.push(b);
}

void HostBuffersManager::returnBufferUnfilled(size_t b)
{
  buffer_statuses[b] = BufferStatus::Empty;
  empty_buffers.push(b);

#ifndef ALLEN_STANDALONE
  if (m_nsplit) ++(*m_nsplit);
#endif
}

void HostBuffersManager::returnBufferWritten(size_t b)
{
  buffer_statuses[b] = BufferStatus::Empty;
  empty_buffers.push(b);
}

void HostBuffersManager::writeSingleEventPassthrough(const size_t b)
{
  if (b >= m_persistent_stores.size()) {
    error_cout << "Buffer index " << b
               << " is larger than the number of available buffers: " << m_persistent_stores.size() << std::endl;
    return;
  }
  auto store = m_persistent_stores[b];

  store->inject("host_init_number_of_events__host_number_of_events_t", std::vector<unsigned> {1});
  store->inject("global_decision__host_global_decision_t", std::vector<bool> {true});
  std::vector<unsigned> dr_data(HltDecReports<false>::size(1u), 0u);
  HltDecReports<false> decrep({dr_data.data(), dr_data.size()}, 0u, 1u);
  decrep.set_number_of_lines(1u);
  decrep.set_key(m_passthrough_key);
  decrep.set_tck(m_tck);
  decrep.set_task_id(m_task_id);
  decrep.set_dec_report(
    0u,
    HltDecReport {true,
                  std::byte {0},                    // error
                  std::byte {1},                    // number of candidates
                  std::byte {1},                    // execution stage
                  static_cast<unsigned short>(1)}); // decision ID
  store->inject("dec_reporter__host_dec_reports_t", dr_data);
  store->inject("host_routingbits_writer__host_routingbits_t", std::vector<unsigned> {m_passthrough_rbs, 0, 0});

  // Make the substructure bank.
  // Substructure bank size. First word for bank size info and the second for
  // the substructure information.
  const unsigned substr_bank_size = 2;
  unsigned rb_substr[2] = {0, 0};
  // Selection list. There is one selection with ID 0.
  unsigned sel_list[1] = {0};
  // Line object offsets. Can be anything, but it needs to exist.
  unsigned line_object_offsets[1] = {0};
  // Multi-event containers. Need a container of nullptrs.
  Allen::IMultiEventContainer* mecs[1] = {nullptr};
  make_subbanks::make_rb_substr_bank(
    rb_substr,
    substr_bank_size,
    0,
    1, // Number of selections.
    0,
    0,
    0,
    1, // Size of selections in the substructure bank.
    0,
    0,
    mecs, // Need to be able to access the first pointer.
    nullptr,
    nullptr,
    nullptr,
    line_object_offsets,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
    sel_list,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
    nullptr);

  // Make the ObjTyp bank.
  // The ObjTyp bank size is 2. One word giving the bank size and one word for
  // each object type. We only save a selection here, so there is 1 object type.
  const unsigned n_objtyps = 1;
  const unsigned objtyp_bank_size = 1 + n_objtyps;
  unsigned rb_objtyp[2] = {0, 0};
  make_subbanks::make_rb_objtyp_bank(
    rb_objtyp,
    n_objtyps,
    1, // One selection, no other objects.
    0,
    0,
    0);

  // Make the StdInfo bank.
  // The StdInfo bank contains 1 word giving the structure of the bank, 8 bits
  // plus padding giving the number of values saved for the persisted object,
  // and 1 word for the selection.
  const unsigned stdinfo_bank_size = 3;
  unsigned rb_stdinfo[3] = {0, 0, 0};
  make_subbanks::make_rb_stdinfo_bank(
    rb_stdinfo,
    stdinfo_bank_size,
    1, // One selection, no other objects.
    0,
    0,
    0,
    sel_list,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
    nullptr,
    nullptr);

  // Make the hits bank. No hits are stored, so this is one word containing 0.
  const unsigned hits_bank_size = 1;
  unsigned rb_hits[1] = {0};

  // Extra info bank. This bank is empty, but it needs to exist. It is organized
  // similarly to the StdInfo bank, but there is no saved information. The size
  // is 2.
  const unsigned einfo_size = 2;

  // Make the selreport bank.
  const unsigned header_size = 10;
  const unsigned selrep_bank_size =
    header_size + substr_bank_size + stdinfo_bank_size + objtyp_bank_size + hits_bank_size + einfo_size;
  std::vector<unsigned> sr_data(selrep_bank_size, 0);
  make_selrep::make_selrep_bank(
    sr_data.data(),
    rb_objtyp,
    rb_hits,
    rb_substr,
    rb_stdinfo,
    selrep_bank_size,
    objtyp_bank_size,
    hits_bank_size,
    substr_bank_size,
    stdinfo_bank_size);

  store->inject("make_selreps__host_selrep_offsets_t", std::vector<unsigned> {0, selrep_bank_size});
  store->inject("make_selreps__host_sel_reports_t", sr_data);

  returnBufferFilled(b);

#ifndef ALLEN_STANDALONE
  if (m_npassthrough) ++(*m_npassthrough);
#endif
}

void HostBuffersManager::printStatus() const
{
  info_cout << m_persistent_stores.size() << " stores; " << empty_buffers.size() << " empty; " << filled_buffers.size()
            << " filled." << std::endl;
}

#ifndef ALLEN_STANDALONE
void HostBuffersManager::activateMonitoring(Service* svc)
{
  if (svc != nullptr) {
    m_nsplit = std::make_unique<Gaudi::Accumulators::Counter<>>(svc, "NSplit");
    m_npassthrough = std::make_unique<Gaudi::Accumulators::Counter<>>(svc, "NPassthrough");
  }
}
#endif
