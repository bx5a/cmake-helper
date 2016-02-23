cmake_minimum_required(VERSION 3.1)

########################################
# find and/or build the openssl library.
# args: SOURCE_DIR
# returns: OPENSSL_ROOT_DIR and OPENSSL_LIBRARIES

function(FindOpenSSL)
  # parse args
  set(one_val_args SOURCE_DIR MINIMUM_VERSION)
  set(options STATIC SHARED)
  cmake_parse_arguments(FindOpenSSL 
    "${options}" "${one_val_args}" "" ${ARGN})

  set(openssl_sources ${FindOpenSSL_SOURCE_DIR})
  set(openssl_build_dir ${CMAKE_BINARY_DIR}/thirdparty/openssl)
  set(use_static ${FindOpenSSL_STATIC})
  set(use_shared ${FindOpenSSL_SHARED})


  if (${use_static}) 
    if(WIN32)
      set(lib_suffix .lib)
    else()
      set(lib_suffix .a)
    endif()
  elseif(${use_shared})
    if(WIN32)
      set(lib_suffix .dll)
    elseif(APPLE)
      set(lib_suffix .dylib)
    else()
      set(lib_suffix .so)
    endif()
  endif() 
  set(lib_suffix ${lib_suffix})

  # create thirdparty folder
  file(MAKE_DIRECTORY ${openssl_build_dir})

  # first, try to find
  find_package(OpenSSL ${FindOpenSSL_MINIMUM_VERSION})
  # check if found libraries has the right extension
  foreach(library ${OPENSSL_LIBRARIES})
    get_filename_component(extension ${library} EXT)
    if (NOT "${CMAKE_FIND_LIBRARY_SUFFIXES}" STREQUAL "${extension}")
      set(OPENSSL_FOUND FALSE)
    endif()
  endforeach()

  if (NOT OPENSSL_FOUND)
    # force use of previously built libraries
    set(OPENSSL_LIBRARIES 
          "${openssl_build_dir}/lib/libssl${lib_suffix}" 
          "${openssl_build_dir}/lib/libcrypto${lib_suffix}")
    set(OPENSSL_INCLUDE_DIR "${openssl_sources}/include")
    set(OPENSSL_FOUND TRUE)
    foreach(library ${OPENSSL_LIBRARIES})
      if(NOT EXISTS ${library})
        set(OPENSSL_FOUND FALSE)
      endif()
    endforeach()
  endif()

  if (NOT OPENSSL_FOUND)
    # do build    
    message(STATUS "OpenSSL - Configure")

    execute_process(COMMAND 
      ./Configure darwin64-x86_64-cc --prefix=${openssl_build_dir} --shared
      WORKING_DIRECTORY ${openssl_sources}
      RESULT_VARIABLE cmd_result 
      OUTPUT_VARIABLE cmd_output 
      ERROR_VARIABLE cmd_error)
    if(NOT cmd_result EQUAL "0")
      message(FATAL_ERROR "Failed to Configure:\n${cmd_error}\n")
    endif()

    message(STATUS "OpenSSL - Building")

    execute_process(COMMAND make clean 
      WORKING_DIRECTORY ${openssl_sources}
      RESULT_VARIABLE cmd_result 
      OUTPUT_VARIABLE cmd_output 
      ERROR_VARIABLE cmd_error)
    if(NOT cmd_result EQUAL "0")
      message(FATAL_ERROR "Failed to Make:\n${cmd_error}\n")
    endif()


    execute_process(COMMAND make 
      WORKING_DIRECTORY ${openssl_sources}
      RESULT_VARIABLE cmd_result 
      OUTPUT_VARIABLE cmd_output 
      ERROR_VARIABLE cmd_error)
    if(NOT cmd_result EQUAL "0")
      message(FATAL_ERROR "Failed to Make:\n${cmd_error}\n")
    endif()

    message(STATUS "OpenSSL - Installing")

    execute_process(COMMAND make install 
      WORKING_DIRECTORY ${openssl_sources}
      RESULT_VARIABLE cmd_result 
      OUTPUT_VARIABLE cmd_output 
      ERROR_VARIABLE cmd_error)
    if(NOT cmd_result EQUAL "0")
      message(FATAL_ERROR "Failed to Make Install:\n${cmd_error}\n")
    endif()

    # try to build once more
    message(STATUS "OpenSSL - Installed")
    message(WARNING "OpenSSL - You might have to remove CMakeCache.txt and CMakeFiles/ for your new build to be taken into account")

    set(OPENSSL_ROOT_DIR "${openssl_sources}")
    
    find_package(OpenSSL ${FindOpenSSL_MINIMUM_VERSION})
  endif()

  set(OPENSSL_ROOT_DIR "${openssl_sources}" PARENT_SCOPE)
  set(OPENSSL_LIBRARIES "${OPENSSL_LIBRARIES}" PARENT_SCOPE)
  set(OPENSSL_FOUND "${OPENSSL_FOUND}" PARENT_SCOPE)
  set(OPENSSL_INCLUDE_DIR "${OPENSSL_INCLUDE_DIR}" PARENT_SCOPE)
  if (OPENSSL_FOUND) 
    message(STATUS "OpenSSL Found: ${OPENSSL_LIBRARIES}")
  endif()

endfunction(FindOpenSSL)
