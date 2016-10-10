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

cmake_minimum_required(VERSION 3.1)


###################################
# Create a target
# args: TYPE [SHARED/STATIC] SOURCES LINK

function(AddTarget)
  # parse args
  set(option_args SHARED STATIC)
  set(one_val_args TYPE)
  set(multiple_val_args SOURCES LINK)
  cmake_parse_arguments(AddTarget "${option_args}" "${one_val_args}" "${multiple_val_args}" ${ARGN})

  # switch target type
  string(TOLOWER "${AddTarget_TYPE}" lower_case_TYPE)
  if (${lower_case_TYPE} STREQUAL "executable")
    add_executable(${ARGV0} "${AddTarget_SOURCES}")
  else()
    # for libraries, switch SHARED or STATIC. Default is SHARED
    if(${AddTarget_STATIC})
      add_library(${ARGV0} STATIC "${AddTarget_SOURCES}")
    else()
      add_library(${ARGV0} SHARED "${AddTarget_SOURCES}")
    endif()
  endif()

  # organize sources in group
  foreach(source_file ${AddTarget_SOURCES})
    # find if source or header
    get_filename_component(source_ext ${source_file} EXT)
    set(group_root_name "source")
    if(${source_ext} STREQUAL ".h")
      set(group_root_name "header")
    endif()
    # create a group name from the file path
    get_filename_component(absolute_path ${source_file} ABSOLUTE)
    string(REPLACE ${CMAKE_CURRENT_SOURCE_DIR} ${group_root_name} relative_path ${absolute_path})
    get_filename_component(relative_folder ${relative_path} DIRECTORY)
    string(REPLACE "/" "\\" group_name ${relative_folder})
    # add the file to the right group
    source_group(${group_name} FILES ${source_file})
  endforeach()

  # link to desired libraries
  # sometimes the library can be prefixed by debug/optimized/general
  foreach(source_file ${AddTarget_LINK})
    if (${source_file} STREQUAL "debug" OR ${source_file} STREQUAL "optimized" OR ${source_file} STREQUAL "general")
      set(link_prefix ${source_file})
    else ()
      target_link_libraries(${ARGV0} ${link_prefix} "${source_file}")
      unset(link_prefix)
    endif()
  endforeach()
endfunction(AddTarget)
