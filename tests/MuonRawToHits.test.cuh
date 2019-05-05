#pragma once

#include <vector>
#include <fstream>
#include <iostream>
#include <string>
#include "MuonRawToHitsDecoding.h"
#include "MuonDefinitions.cuh"
#include "MuonTables.cuh"
#include "MuonGeometry.cuh"
#include "MuonRawToHits.cuh"
#include "MuonDecoding.cuh"
#include "Tools.h"

void read_binary_file(std::vector<char>& vector, const std::string& file_name) {
  std::ifstream file(file_name, std::ios::in | std::ios::binary);
  file.read(vector.data(), vector.size());
  file.close();
}
