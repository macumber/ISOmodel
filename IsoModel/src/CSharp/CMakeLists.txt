
#add_test(NAME test_csharp
#  COMMAND ipy ${PROJECT_SOURCE_DIR}/CSharp/test.py
#  WORKING_DIRECTORY $<TARGET_FILE_DIR:csharp_isomodel>
#)

install(TARGETS csharp_isomodel
  DESTINATION csharp
)

enable_language(CSharp)

set_source_files_properties(${CS_FILES} PROPERTIES GENERATED True)

add_library(isomodel_cs
  SHARED
  ${CS_FILES}
)
set_target_properties(isomodel_cs PROPERTIES LINKER_LANGUAGE CSharp)
add_dependencies(isomodel_cs generate_csharp_isomodel_wrap)

set_target_properties(isomodel_cs PROPERTIES OUTPUT_NAME "isomodel")
set_target_properties(isomodel_cs PROPERTIES ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/csharp/")
set_target_properties(isomodel_cs PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/csharp/")
set_target_properties(isomodel_cs PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/csharp/")

install(TARGETS isomodel_cs
  DESTINATION csharp
)
