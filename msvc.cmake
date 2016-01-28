cmake_minimum_required(VERSION 3.1)

function(ConfigureMSVC)
  set(optional_args RUNTIME_STATIC RUNTIME_SHARED)
  cmake_parse_arguments(ConfigureMSVC  "${optional_args}" "" "" ${ARGN})

  # every flags are in these variables
  set(variables
      CMAKE_C_FLAGS
      CMAKE_C_FLAGS_DEBUG
      CMAKE_C_FLAGS_MINSIZEREL
      CMAKE_C_FLAGS_RELEASE
      CMAKE_C_FLAGS_RELWITHDEBINFO
      CMAKE_CXX_FLAGS
      CMAKE_CXX_FLAGS_DEBUG
      CMAKE_CXX_FLAGS_MINSIZEREL
      CMAKE_CXX_FLAGS_RELEASE
      CMAKE_CXX_FLAGS_RELWITHDEBINFO)

  # If we are in static runtime, we need to use /MT or /MTd. Shared: /MD /MDd
  set(option_to_replace "/MT")
  set(new_option "/MD")
  if(${ConfigureMSVC_RUNTIME_STATIC})
    set(option_to_replace "/MD")
    set(new_option "/MT")
  endif()

  foreach(variable ${variables})
    if(${variable} MATCHES ${option_to_replace})
      string(REGEX REPLACE
        ${option_to_replace}
        ${new_option}
        ${variable}
        "${${variable}}")
    endif()
    set(${variable} "${${variable}}" PARENT_SCOPE)
  endforeach()
endfunction(ConfigureMSVC)
