#pragma once

#include <dirent.h>
#include <cstdint>
#include <cassert>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>
#include <string>
#include <numeric>
#include <algorithm>
#include <map>
#include <cmath>
#include "Logger.h"
#include "Common.h"

EventID name_to_number(const std::string& arg);

bool exists_test(const std::string& name);

bool naturalOrder(const std::string& s1, const std::string& s2);

void readFileIntoVector(const std::string& filename, std::vector<char>& events);

void appendFileToVector(const std::string& filename, std::vector<char>& events, std::vector<unsigned int>& event_sizes);

std::vector<std::string> list_folder(const std::string& foldername, const std::string& extension = "bin");

uint get_number_of_events_requested(uint number_of_events_requested, const std::string& foldername);

void read_files(
  std::vector<std::string>::const_iterator file_start,
  std::vector<std::string>::const_iterator file_end,
  std::vector<char>& events,
  std::vector<uint>& event_offsets);

void read_folder(
  const std::string& foldername,
  const std::vector<std::tuple<unsigned int, unsigned long>>& requested_events,
  std::vector<bool> const& event_mask,
  std::vector<char>& events,
  std::vector<unsigned int>& event_offsets,
  bool quiet = false);

std::vector<std::tuple<unsigned int, unsigned long>> read_folder(
  const std::string& foldername,
  uint number_of_events_requested,
  std::vector<char>& events,
  std::vector<unsigned int>& event_offsets,
  const uint start_event_offset);

void read_geometry(const std::string& foldername, std::vector<char>& geometry);

void read_muon_field_of_interest(std::vector<float>& foi_params, const std::string& filename);

std::vector<std::string> split_input(std::string const& input);
