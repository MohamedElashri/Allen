#!/usr/bin/env python3
"""
Script to convert model files to C++if __name__ == "__main__":
    model_dir = "../device/pvfinder/include/model"
    output_file = "../device/pvfinder/include/ModelConstants.cuh"
    convert_txt_to_header(model_dir, output_file)
    print(f"Generated {output_file}")tant arrays.
This eliminates runtime file I/O overhead.
"""

import os
import sys

def convert_txt_to_header(model_dir, output_file):
    """Convert model .txt files to C++ constant arrays"""
    
    print(f"Reading model files from: {model_dir}")
    print(f"Writing output to: {output_file}")
    
    with open(output_file, 'w') as f:
        f.write("#pragma once\n\n")
        f.write("namespace PVFinder {\n\n")
        
        # Layer sizes
        layer_sizes = [9, 20, 20, 20, 20, 20, 100]
        f.write("constexpr unsigned LAYER_SIZES[] = {")
        f.write(", ".join(map(str, layer_sizes)))
        f.write("};\n\n")
        
        # Weights
        f.write("constexpr float MODEL_WEIGHTS[] = {\n")
        all_weights = []
        for i in range(1, 7):
            weight_file = os.path.join(model_dir, f"layer{i}.weight.txt")
            if os.path.exists(weight_file):
                with open(weight_file, 'r') as wf:
                    for line in wf:
                        line = line.strip()
                        if line:
                            # Split line by whitespace and convert each to float
                            weights = [float(val) for val in line.split()]
                            all_weights.extend(weights)
        
        # Write weights in chunks of 8 per line for readability
        for i in range(0, len(all_weights), 8):
            chunk = all_weights[i:i+8]
            f.write("  " + ", ".join(f"{w:.6f}f" for w in chunk))
            if i + 8 < len(all_weights):
                f.write(",\n")
            else:
                f.write("\n")
        f.write("};\n\n")
        
        # Biases
        f.write("constexpr float MODEL_BIASES[] = {\n")
        all_biases = []
        for i in range(1, 7):
            bias_file = os.path.join(model_dir, f"layer{i}.bias.txt")
            if os.path.exists(bias_file):
                with open(bias_file, 'r') as bf:
                    for line in bf:
                        line = line.strip()
                        if line:
                            # Split line by whitespace and convert each to float
                            biases = [float(val) for val in line.split()]
                            all_biases.extend(biases)
        
        for i in range(0, len(all_biases), 8):
            chunk = all_biases[i:i+8]
            f.write("  " + ", ".join(f"{b:.6f}f" for b in chunk))
            if i + 8 < len(all_biases):
                f.write(",\n")
            else:
                f.write("\n")
        f.write("};\n\n")
        
        f.write("} // namespace PVFinder\n")

if __name__ == "__main__":
    model_dir = "device/pvfinder/include/model"
    output_file = "device/pvfinder/include/ModelConstants.cuh"
    convert_txt_to_header(model_dir, output_file)
    print(f"Generated {output_file}")
