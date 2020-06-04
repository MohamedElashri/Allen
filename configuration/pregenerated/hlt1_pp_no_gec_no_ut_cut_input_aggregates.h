#pragma once

#include <tuple>
#include "../../device/selections/lines/include/TrackMVALine.cuh"
#include "../../device/selections/lines/include/TwoTrackMVALine.cuh"
#include "../../device/selections/lines/include/BeamCrossingLine.cuh"

struct track_mva_line__dev_decisions_t : track_mva_line::Parameters::dev_decisions_t {
  using type = track_mva_line::Parameters::dev_decisions_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "track_mva_line__dev_decisions_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }

private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct two_track_mva_line__dev_decisions_t : two_track_mva_line::Parameters::dev_decisions_t {
  using type = two_track_mva_line::Parameters::dev_decisions_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "two_track_mva_line__dev_decisions_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }

private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct no_beam_line__dev_decisions_t : beam_crossing_line::Parameters::dev_decisions_t {
  using type = beam_crossing_line::Parameters::dev_decisions_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "no_beam_line__dev_decisions_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }

private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct beam_one_line__dev_decisions_t : beam_crossing_line::Parameters::dev_decisions_t {
  using type = beam_crossing_line::Parameters::dev_decisions_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "beam_one_line__dev_decisions_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }

private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct beam_two_line__dev_decisions_t : beam_crossing_line::Parameters::dev_decisions_t {
  using type = beam_crossing_line::Parameters::dev_decisions_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "beam_two_line__dev_decisions_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }

private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct track_mva_line__dev_decisions_offsets_t : track_mva_line::Parameters::dev_decisions_offsets_t {
  using type = track_mva_line::Parameters::dev_decisions_offsets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "track_mva_line__dev_decisions_offsets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }

private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct two_track_mva_line__dev_decisions_offsets_t : two_track_mva_line::Parameters::dev_decisions_offsets_t {
  using type = two_track_mva_line::Parameters::dev_decisions_offsets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "two_track_mva_line__dev_decisions_offsets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }

private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct no_beam_line__dev_decisions_offsets_t : beam_crossing_line::Parameters::dev_decisions_offsets_t {
  using type = beam_crossing_line::Parameters::dev_decisions_offsets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "no_beam_line__dev_decisions_offsets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }

private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct beam_one_line__dev_decisions_offsets_t : beam_crossing_line::Parameters::dev_decisions_offsets_t {
  using type = beam_crossing_line::Parameters::dev_decisions_offsets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "beam_one_line__dev_decisions_offsets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }

private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};
struct beam_two_line__dev_decisions_offsets_t : beam_crossing_line::Parameters::dev_decisions_offsets_t {
  using type = beam_crossing_line::Parameters::dev_decisions_offsets_t::type;
  void set_size(size_t size) override { m_size = size; }
  size_t size() const override { return m_size; }
  std::string name() const override { return "beam_two_line__dev_decisions_offsets_t"; }
  void set_offset(char* offset) override { m_offset = offset; }
  char* offset() const override { return m_offset; }

private:
  size_t m_size = 0;
  char* m_offset = nullptr;
};

namespace gather_selections {
  namespace dev_input_selections_t {
    using tuple_t = std::tuple<
      track_mva_line__dev_decisions_t,
      two_track_mva_line__dev_decisions_t,
      no_beam_line__dev_decisions_t,
      beam_one_line__dev_decisions_t,
      beam_two_line__dev_decisions_t>;
  }
} // namespace gather_selections
namespace gather_selections {
  namespace dev_input_selections_offsets_t {
    using tuple_t = std::tuple<
      track_mva_line__dev_decisions_offsets_t,
      two_track_mva_line__dev_decisions_offsets_t,
      no_beam_line__dev_decisions_offsets_t,
      beam_one_line__dev_decisions_offsets_t,
      beam_two_line__dev_decisions_offsets_t>;
  }
} // namespace gather_selections
