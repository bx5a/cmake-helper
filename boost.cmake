cmake_minimum_required(VERSION 3.1)

###################################
# find and build the boost library.
# args: COMPONENTS & SOURCE_DIR
# that function sets: Boost_LIBRARIES, BOOST_INCLUDEDIR and BOOST_ROOT

function(FindBoost)
  # parse args
  set(option_args STATIC SHARED RUNTIME_STATIC RUNTIME_SHARED)
  set(multiple_val_args COMPONENTS)
  set(one_val_args SOURCE_DIR)
  cmake_parse_arguments(FindBoost
                        "${option_args}"
                        "${one_val_args}"
                        "${multiple_val_args}"
                        ${ARGN})

  # default is static link type
  set(boost_link_type static)
  set(Boost_USE_STATIC_LIBS ON)

  if (${FindBoost_SHARED})
    add_definitions(-DBOOST_LOG_DYN_LINK)
    set(boost_link_type shared)
    set(Boost_USE_STATIC_LIBS OFF)
  endif()

  # default runtime type is static
  # TODO(bx5a): if lib were already built with the wrong runtime, rebuild it
  # instead of using the existing ones
  set(boost_runtime_link_type static)
  if (${FindBoost_RUNTIME_SHARED})
    set(boost_runtime_link_type shared)
  endif()


  # variables
  set(boost_build_dir ${CMAKE_BINARY_DIR}/thirdparty/boost)
  set(boost_sources ${FindBoost_SOURCE_DIR})
  set(boost_b2_command ./b2)
  set(BOOST_INCLUDEDIR ${boost_sources})
  set(BOOST_LIBRARYDIR ${boost_build_dir}/lib)

  if (WIN32)
    set(boost_bootstrap_command bootstrap.bat)
  elseif(APPLE)
    set(boost_bootstrap_command ./bootstrap.sh)
  else()
    message(FATAL_ERROR "Boost - Can't build boost for that system")
  endif()

  # try to find package first.
  find_package(Boost
    COMPONENTS
      ${FindBoost_COMPONENTS})

  # If fail, build using b2 and try to find again
  if(NOT Boost_FOUND)
    set(b2_components "")
    foreach(component ${FindBoost_COMPONENTS})
      set(b2_components ${b2_components} --with-${component})
    endforeach()

    # configure
    message(STATUS "Boost - Bootstrap configure ${boost_sources}")
    execute_process(COMMAND ${boost_bootstrap_command}
                    WORKING_DIRECTORY ${boost_sources}
                    RESULT_VARIABLE cmd_result
                    OUTPUT_VARIABLE cmd_output
                    ERROR_VARIABLE cmd_error)
    if(NOT cmd_result EQUAL "0")
      message(FATAL_ERROR
        "Failed running ${boost_bootstrap_command}:\n${cmd_output}\n${cmd_error}\n")
    endif()

    # create build dir
    file(MAKE_DIRECTORY ${boost_build_dir})

    # build
    message(STATUS "Boost - Building")

    set(boost_b2_options
      ${b2_components}
    	--build-dir=${boost_build_dir}
      --prefix=${boost_build_dir}
      --stagedir=${boost_build_dir}
      link=${boost_link_type}
      runtime-link=${boost_runtime_link_type}
      variant=debug,release)

    execute_process(COMMAND ${boost_b2_command} ${boost_b2_options}
                    WORKING_DIRECTORY ${boost_sources}
    				        RESULT_VARIABLE cmd_result
                    OUTPUT_VARIABLE cmd_output
                    ERROR_VARIABLE cmd_error)
    if(NOT cmd_result EQUAL "0")
      message(FATAL_ERROR
        "Failed running ${boost_b2_command}:\n${cmd_output}\n${cmd_error}\n")
    endif()

    message(STATUS "Boost - Build Succeeded")

    # try to find again
    find_package(Boost
      REQUIRED
      COMPONENTS
        ${FindBoost_COMPONENTS})
  endif()

  # fix for visual studio: split release and debug libraries
  if(MSVC)
    foreach(library ${Boost_LIBRARIES})
      # add debug flag to separate release/debug libraries
      string(REGEX REPLACE "-s-" "-sgd-" debug_library "${library}")
      set(Boost_debug_and_release_LIBRARIES
      "${Boost_debug_and_release_LIBRARIES}"
      "optimized" "${library}"
      "debug" "${debug_library}")
    endforeach()
    set(Boost_LIBRARIES ${Boost_debug_and_release_LIBRARIES})
  endif()

  # set variable scope
  set(Boost_LIBRARIES ${Boost_LIBRARIES} PARENT_SCOPE)
  set(BOOST_ROOT ${boost_build_dir} PARENT_SCOPE)
  set(BOOST_INCLUDEDIR ${Boost_INCLUDE_DIRS} PARENT_SCOPE)
endfunction(FindBoost)
