/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <dlfcn.h>
#include <cstdio>

#include <IStream.h>
#include <StreamLoader.h>
#include <Common.h>
#include <Logger.h>

#ifdef USE_BOOST_FILESYSTEM
#include <boost/filesystem.hpp>
namespace {
  namespace fs = boost::filesystem;
}
#else
#include <filesystem>
namespace {
  namespace fs = std::filesystem;
}
#endif

std::tuple<Allen::StreamFactory, bool> Allen::load_stream(std::string const& sequence)
{
  using factory_t = Allen::StreamFactory::element_type;
  Allen::StreamFactory factory {nullptr, [](factory_t*) {}};

  Dl_info dl_info;
  dladdr((void*) load_stream, &dl_info);

  fs::path lib_path = fs::path {dl_info.dli_fname}.parent_path();
  debug_cout << "Found libAllenLib.so in directory" << lib_path.string() << "\n";

  // Prefer the "sequences" subdirectory, but also consider the same
  // directory as the libAllenLib library to a stack build work when
  // running from the build directory.
  fs::path stream_path;
  for (std::string_view d : {"sequences", ""}) {
    stream_path = lib_path;
    if (!d.empty()) stream_path /= d;

#ifdef __APPLE__
    const auto dynlib_extension = "dylib";
#else
    const auto dynlib_extension = "so";
#endif

    stream_path /= fs::path {std::string {"libStream_"} + sequence + "." + dynlib_extension};
    debug_cout << "Looking for stream library " << stream_path.string() << "\n";
    if (fs::exists(stream_path)) break;
  }

  void* handle = dlopen(stream_path.c_str(), RTLD_LAZY);

  if (!handle) {
    error_cout << "Cannot open stream library " << stream_path.string() << " : " << dlerror() << "\n";
    return {std::move(factory), false};
  }

  typedef IStream* (*create_stream_t)(
    const bool param_print_memory_usage,
    const size_t param_reserve_mb,
    const size_t reserve_host_mb,
    const unsigned required_memory_alignment,
    const Constants& constants,
    HostBuffersManager* buffers_manager);

  typedef bool (*do_check_t)();

  do_check_t do_check;
  create_stream_t create_stream;

  auto functions = std::tuple {std::make_tuple(&do_check, std::string {"contains_validator_algorithm"}),
                               std::make_tuple(&create_stream, std::string("create_stream"))};

  bool error = false;
  for_each(functions, [&error, handle](auto& entry) {
    if (error) return;

    auto& [fun, sym] = entry;
    dlerror();
    *fun = reinterpret_cast<std::remove_reference_t<decltype(*fun)>>(dlsym(handle, sym.c_str()));
    const char* dlsym_error = dlerror();
    if (dlsym_error) {
      error_cout << "Cannot load " << sym << " function: " << dlsym_error << "\n";
      dlclose(handle);
      error = true;
    }
  });

  if (error) {
    return {std::move(factory), false};
  }

  factory =
    Allen::StreamFactory {new factory_t {[create_stream](
                                           const bool print_memory_usage,
                                           const size_t reserve_mb,
                                           const size_t reserve_host_mb,
                                           const unsigned mem_align,
                                           const Constants& constants,
                                           HostBuffersManager* buffers_manager) -> std::unique_ptr<IStream> {
                            return std::unique_ptr<IStream> {create_stream(
                              print_memory_usage, reserve_mb, reserve_host_mb, mem_align, constants, buffers_manager)};
                          }},
                          [handle](factory_t* f) {
                            delete f;
                            dlclose(handle);
                          }};

  return {std::move(factory), do_check()};
}
