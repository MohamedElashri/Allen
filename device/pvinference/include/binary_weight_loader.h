#pragma once

#include <cstdint>

namespace PVInference {

struct WeightHeader {
    uint32_t magic;          // 0x50564657 ("PVFW")
    uint32_t version;        // 1
    uint32_t num_layers;     // Number of weight layers
    uint32_t total_weights;  // Total float count
};

struct LayerHeader {
    char name[64];          // Layer name (null-terminated)
    uint32_t size;          // Number of floats
    uint32_t offset;        // Byte offset in data section
};

struct LayerInfo {
    uint32_t size;
    uint32_t offset;
};

// Allen-compatible weight loader with compile-time binary embedding
class AllenWeightLoader {
private:
    static const uint8_t* weight_binary_data_;
    static uint32_t weight_binary_size_;
    static bool initialized_;
    static const float* weight_data_;
    static LayerInfo layer_map_[50]; // Max 50 layers
    static char layer_names_[50][64]; // Layer names storage
    static uint32_t num_layers_;

public:
    // Initialize from embedded binary data
    static bool initialize();
    
    // Get pointer to specific layer weights by index (faster than name lookup)
    static const float* getLayerWeightsByIndex(uint32_t layer_index);
    
    // Get pointer to specific layer weights by name
    static const float* getLayerWeights(const char* layer_name);
    
    // Get layer size by index
    static uint32_t getLayerSizeByIndex(uint32_t layer_index);
    
    // Get layer size by name
    static uint32_t getLayerSize(const char* layer_name);
    
    // Get number of layers
    static uint32_t getNumLayers() { return num_layers_; }
    
    // Check if initialized
    static bool isInitialized() { return initialized_; }
    
    // Get layer name by index
    static const char* getLayerName(uint32_t layer_index);
};

} // namespace PVInference
