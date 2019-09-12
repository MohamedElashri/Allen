#pragma once

#include <vector>
#include <fstream>
#include <iostream>
#include <string>
#include "MuonRawToHitsDecoding.h"
#include "MuonDefinitions.cuh"
#include "Tools.h"

void read_binary_file(std::vector<char>& vector, const std::string& file_name)
{
  std::ifstream file(file_name, std::ios::in | std::ios::binary);
  file.read(vector.data(), vector.size());
  file.close();
}
