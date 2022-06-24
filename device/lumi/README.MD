# Instruction to add a lumi counter

## Add the definition of the counter to the header file `LumiCounters.h`
* The counters are all stored in bits, and the offsets and sizes are defined in `device/lumi/include/LumiCounters.h`.
* The size should be larger than the maximum value of the new counter, and safe from overflow.
* Also check the `size_t const max_average_lumi_summary_size` defined in `stream/sequence/src/HostBuffers.cpp`. If
```cpp
TotalSize / 8 > max_average_lumi_summary_size
```
modified `max_average_lumi_summary_size` to be `TotalSize / 8`.

## Write the counters to the `dev_lumi_summaries`
* If a new input is needed, modify `device/lumi/include/MakeLumiSummary.cuh` as well as `configuration/python/AllenConf/lumi_reconstruction.py`.
* Use `setField` to set the bits of the counter.
