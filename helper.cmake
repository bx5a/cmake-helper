cmake_minimum_required(VERSION 3.1)

########################################
# Unpack a zip or tar.gz
# args: SOURCE DESTINATION.
# DOWNLOAD is optional. Set it if SOURCE is an URL
# returns: OPENSSL_ROOT_DIR and OPENSSL_LIBRARIES

function(Unpack)
  # parse args
  set(optional_args DOWNLOAD)
  set(one_val_args SOURCE DESTINATION)
  cmake_parse_arguments(Unpack  "${optional_args}" "${one_val_args}" "" ${ARGN})

  get_filename_component(source_filename ${Unpack_SOURCE} NAME)
  # Download if needed
  if (${Unpack_DOWNLOAD})
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/download)
    set(downloaded_path ${CMAKE_BINARY_DIR}/download/${source_filename})

    if (NOT EXISTS ${downloaded_path})
      message(STATUS "Unpack - Downloading...")
      file(DOWNLOAD 
        ${Unpack_SOURCE}
        ${downloaded_path}
      )
    endif()

    set(Unpack_SOURCE ${downloaded_path})
    message(STATUS "Unpack - Found downloaded archive ${source_filename}")
  endif()

  # check if doesn't exists
  if (NOT EXISTS ${Unpack_DESTINATION})
    get_filename_component(source_filename ${Unpack_SOURCE} NAME)
    message(STATUS "Unpack - Extracting ${source_filename}")

    file(MAKE_DIRECTORY ${Unpack_DESTINATION})
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E tar xzf ${Unpack_SOURCE}
      WORKING_DIRECTORY ${Unpack_DESTINATION}
      RESULT_VARIABLE cmd_result
      OUTPUT_VARIABLE cmd_output
      ERROR_VARIABLE cmd_error
    )
    if(NOT cmd_result EQUAL "0")
      message(FATAL_ERROR 
        "Failed unpacking ${source_filename}:\n${cmd_result}\n${cmd_output}\n${cmd_error}\n")
    endif()
  endif()
endfunction(Unpack)
