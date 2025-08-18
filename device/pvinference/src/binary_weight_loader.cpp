#include "binary_weight_loader.h"
#include <cstring>
#include <cstdio>

namespace PVInference {

// Static member definitions
const uint8_t* AllenWeightLoader::weight_binary_data_ = nullptr;
uint32_t AllenWeightLoader::weight_binary_size_ = 0;
bool AllenWeightLoader::initialized_ = false;
const float* AllenWeightLoader::weight_data_ = nullptr;
LayerInfo AllenWeightLoader::layer_map_[50];
char AllenWeightLoader::layer_names_[50][64];
uint32_t AllenWeightLoader::num_layers_ = 0;

// Embedded binary data - will be set by build system
extern "C" {
    extern const uint8_t _binary_pvfinder_weights_bin_start[];
    extern const uint8_t _binary_pvfinder_weights_bin_end[];
}

bool AllenWeightLoader::initialize() {
    if (initialized_) {
        return true;
    }

    // Get embedded binary data
    weight_binary_data_ = _binary_pvfinder_weights_bin_start;
    weight_binary_size_ = _binary_pvfinder_weights_bin_end - _binary_pvfinder_weights_bin_start;

    if (weight_binary_size_ < sizeof(WeightHeader)) {
        return false;
    }

    // Read header
    const WeightHeader* header = reinterpret_cast<const WeightHeader*>(weight_binary_data_);
    
    // Validate magic number
    if (header->magic != 0x50564657) { // "PVFW"
        return false;
    }

    if (header->version != 1) {
        return false;
    }

    num_layers_ = header->num_layers;
    if (num_layers_ > 50) {
        return false; // Too many layers
    }

    // Read layer headers
    const LayerHeader* layers = reinterpret_cast<const LayerHeader*>(
        weight_binary_data_ + sizeof(WeightHeader));

    // Build layer lookup map
    for (uint32_t i = 0; i < num_layers_; ++i) {
        // Copy layer name
        strncpy(layer_names_[i], layers[i].name, 63);
        layer_names_[i][63] = '\0';
        
        // Convert offset from bytes to float indices
        uint32_t float_offset = (layers[i].offset - sizeof(WeightHeader) - num_layers_ * sizeof(LayerHeader)) / sizeof(float);
        layer_map_[i].size = layers[i].size;
        layer_map_[i].offset = float_offset;
    }

    // Set weight data pointer
    weight_data_ = reinterpret_cast<const float*>(
        weight_binary_data_ + sizeof(WeightHeader) + num_layers_ * sizeof(LayerHeader));

    initialized_ = true;
    return true;
}

const float* AllenWeightLoader::getLayerWeightsByIndex(uint32_t layer_index) {
    if (!initialized_ || layer_index >= num_layers_) {
        return nullptr;
    }
    return weight_data_ + layer_map_[layer_index].offset;
}

const float* AllenWeightLoader::getLayerWeights(const char* layer_name) {
    if (!initialized_) {
        return nullptr;
    }

    for (uint32_t i = 0; i < num_layers_; ++i) {
        if (strcmp(layer_names_[i], layer_name) == 0) {
            return weight_data_ + layer_map_[i].offset;
        }
    }
    return nullptr;
}

uint32_t AllenWeightLoader::getLayerSizeByIndex(uint32_t layer_index) {
    if (!initialized_ || layer_index >= num_layers_) {
        return 0;
    }
    return layer_map_[layer_index].size;
}

uint32_t AllenWeightLoader::getLayerSize(const char* layer_name) {
    if (!initialized_) {
        return 0;
    }

    for (uint32_t i = 0; i < num_layers_; ++i) {
        if (strcmp(layer_names_[i], layer_name) == 0) {
            return layer_map_[i].size;
        }
    }
    return 0;
}

const char* AllenWeightLoader::getLayerName(uint32_t layer_index) {
    if (!initialized_ || layer_index >= num_layers_) {
        return nullptr;
    }
    return layer_names_[layer_index];
}

} // namespace PVInference
