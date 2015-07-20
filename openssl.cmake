cmake_minimum_required(VERSION 3.1)

########################################
# find and/or build the openssl library.
# args: SOURCE_DIR
# returns: OPENSSL_ROOT_DIR and OPENSSL_LIBRARIES

function(FindOpenSSL)
  # parse args
  set(one_val_args SOURCE_DIR MINIMUM_VERSION)
  cmake_parse_arguments(FindOpenSSL 
    "" "${one_val_args}" "" ${ARGN})

  set(openssl_sources ${FindOpenSSL_SOURCE_DIR})
  set(openssl_build_dir ${CMAKE_BINARY_DIR}/thirdparty/openssl)


  set(OPENSSL_ROOT_DIR "${openssl_build_dir}")
  set(OPENSSL_LIBRARIES "${openssl_build_dir}/lib")

  # create thirdparty folder
  file(MAKE_DIRECTORY ${openssl_build_dir})

  message(${OPENSSL_ROOT_DIR})

  # first, try to find
  find_package(OpenSSL ${FindOpenSSL_MINIMUM_VERSION})

  if (NOT OPENSSL_FOUND)
    # do build    
    message(STATUS "OpenSSL - Configure")

    execute_process(COMMAND 
      ./Configure darwin64-x86_64-cc --prefix=${openssl_build_dir} 
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
    find_package(OpenSSL ${FindOpenSSL_MINIMUM_VERSION} REQUIRED)
  endif()

  set(OPENSSL_ROOT_DIR "${openssl_sources}" PARENT_SCOPE)
  set(OPENSSL_LIBRARIES "${OPENSSL_LIBRARIES}" PARENT_SCOPE)

endfunction(FindOpenSSL)
