include(CMakeParseArguments)


# add a swig target
# KEY_I_FILE should include path, see src/utilities/CMakeLists.txt.
macro(MAKE_SWIG_TARGET NAME SIMPLENAME KEY_I_FILE I_FILES PARENT_TARGET PARENT_SWIG_TARGETS)
  set(SWIG_DEFINES "")
  set(SWIG_COMMON "")

  ##
  ## Begin collection of requirements to reduce SWIG regenerations
  ## and fix parallel build issues
  ##

  # Get all of the source files for the parent target this SWIG library is wrapping
  get_target_property(target_files ${PARENT_TARGET} SOURCES)

  foreach(f ${target_files})
    # Get the extension of the source file
    get_source_file_property(p "${f}" LOCATION)
    get_filename_component(extension "${p}" EXT)

    # If it's a header file ("*.h*") add it to the list of headers
    if("${extension}" MATCHES "\\.h.*")
      if("${extension}" MATCHES "\\..xx" OR "${p}" MATCHES "ui_.*\\.h")
        list(APPEND GeneratedHeaders "${p}")
      else()
        list(APPEND RequiredHeaders "${p}")
      endif()
    endif()
  endforeach()

  set(Prereq_Dirs
      "${PROJECT_BINARY_DIR}/Products/"
      "${PROJECT_BINARY_DIR}/Products/Release"
      "${PROJECT_BINARY_DIR}/Products/Debug"
      "${LIBRARY_SEARCH_DIRECTORY}"
  )


  # Now, append all of the .i* files provided to the macro to the
  # list of required headers.
  foreach(i ${I_FILES} ${KEY_I_FILE})
    get_source_file_property(p "${i}" LOCATION)
    get_filename_component(extension "${p}" EXT)
    if("${extension}" MATCHES "\\..xx")
      list(APPEND GeneratedHeaders "${p}")
    else()
      list(APPEND RequiredHeaders "${p}")
    endif()
  endforeach()



  # RequiredHeaders now represents all of the headers and .i files that all
  # of the SWIG targets generated by this macro call rely on.
  # And GeneratedHeaders contains all .ixx and .hxx files needed to make
  # these SWIG targets

  set(ParentSWIGWrappers "")
  # Now we loop through all of the parent swig targets and collect the requirements from them
  foreach(p ${PARENT_SWIG_TARGETS})
    list(APPEND ParentSWIGWrappers ${${p}_SWIG_Depends})
  endforeach()

  # Reduce the size of the RequiredHeaders list
  list(REMOVE_DUPLICATES RequiredHeaders)

  if(GeneratedHeaders)
    list(REMOVE_DUPLICATES GeneratedHeaders)
  endif()

  # Here we now have:
  #  RequiredHeaders: flat list of all of the headers from the library we are currently wrapping and
  #                   all of the libraries that it depends on

  # Export the required headers variable up to the next level so that further SWIG targets can look it up
  #set(exportname "${NAME}RequiredHeaders")

  # Oh, and also export it to this level, for peers, like the Utilities breakouts and the Model breakouts
  set(${exportname} "${RequiredHeaders}")
  #set(${exportname} "${RequiredHeaders}" PARENT_SCOPE)

  if(NOT TARGET ${PARENT_TARGET}_GeneratedHeaders)
    if ("${NAME}" STREQUAL "OpenStudioUtilitiesCore")
      # Workaround appending GenerateIddFactoryRun to GeneratedHeaders, so we ensure that the custom command below actually is called AFTER
      # GenerateIddFactoryRun has been called
      list(APPEND GeneratedHeaders "GenerateIddFactoryRun")
    endif()

    # Add a command to generate the generated headers discovered at this point.
    add_custom_command(
      OUTPUT "${PROJECT_BINARY_DIR}/${PARENT_TARGET}_HeadersGenerated_done.stamp"
      COMMAND ${CMAKE_COMMAND} -E touch "${PROJECT_BINARY_DIR}/${PARENT_TARGET}_HeadersGenerated_done.stamp"
      DEPENDS ${GeneratedHeaders}
    )

    # And a target that calls the above command
    add_custom_target(${PARENT_TARGET}_GeneratedHeaders
      SOURCES "${PROJECT_BINARY_DIR}/${PARENT_TARGET}_HeadersGenerated_done.stamp"
    )

    # Now we say that our PARENT_TARGET depends on this new GeneratedHeaders
    # target. This is where the magic happens. By making both the parent
    # and this *_swig.cxx files below rely on this new target we force all
    # of the generated files to be generated before either the
    # PARENT_TARGET is built or the cxx files are generated. This solves the problems with
    # parallel builds trying to generate the same file multiple times while still
    # allowing files to compile in parallel
    add_dependencies(${PARENT_TARGET} ${PARENT_TARGET}_GeneratedHeaders)
  endif()

  ##
  ## Finish requirements gathering
  ##

  if(WIN32)
    set(SWIG_DEFINES "-D_WINDOWS")
    set(SWIG_COMMON "-Fmicrosoft")
  endif()

  set(swig_target "ruby_${NAME}")

  # wrapper file output
  set(SWIG_WRAPPER "ruby_${NAME}_wrap.cxx")
  set(SWIG_WRAPPER_FULL_PATH "${CMAKE_CURRENT_BINARY_DIR}/${SWIG_WRAPPER}")
  # ruby dlls should be all lowercase
  string(TOLOWER "${NAME}" LOWER_NAME)

  set(MODULE "IsoModel")

  set(this_depends ${ParentSWIGWrappers})
  list(APPEND this_depends ${PARENT_TARGET}_GeneratedHeaders)
  list(APPEND this_depends ${RequiredHeaders})
  list(REMOVE_DUPLICATES this_depends)
  set(${NAME}_SWIG_Depends "${this_depends}")
  #set(${NAME}_SWIG_Depends "${this_depends}" PARENT_SCOPE)

  # Ruby bindings
  if(BUILD_RUBY_BINDINGS)
    add_custom_command(
      OUTPUT "${SWIG_WRAPPER}"
      COMMAND ${CMAKE_COMMAND} -E env SWIG_LIB="${SWIG_LIB}"
              "${SWIG_EXECUTABLE}"
              "-ruby" "-c++" "-fvirtual" "-I${PROJECT_SOURCE_DIR}/" ${RUBY_AUTODOC}
              -module "${MODULE}" -initname "${LOWER_NAME}"
              -o "${SWIG_WRAPPER_FULL_PATH}"
              "${SWIG_DEFINES}" ${SWIG_COMMON} "${KEY_I_FILE}"
      DEPENDS ${this_depends}
    )

    if(MAXIMIZE_CPU_USAGE)
      add_custom_target(${swig_target}_swig
        SOURCES "${SWIG_WRAPPER}"
      )
      add_dependencies(${PARENT_TARGET} ${swig_target}_swig)
    endif()

    include_directories(${PROJECT_SOURCE_DIR})

    add_library(
      ${swig_target}
      MODULE
      ${SWIG_WRAPPER}
    )

    if( WIN32 )
      target_link_libraries(
        ${swig_target}
        ${PARENT_TARGET}
        ${RUBY_MINGW_STUB_LIB}
      )
    else()
      target_link_libraries(
        ${swig_target}
        ${PARENT_TARGET}
      )
    endif()

    set_target_properties(${swig_target} PROPERTIES OUTPUT_NAME ${LOWER_NAME})
    set_target_properties(${swig_target} PROPERTIES PREFIX "")
    if(APPLE)
      set_target_properties(${swig_target} PROPERTIES SUFFIX ".bundle" )
    else()
      set_target_properties(${swig_target} PROPERTIES SUFFIX ".so" )
    endif()

    # run rdoc
    if(BUILD_DOCUMENTATION)
      add_custom_target(${swig_target}_rdoc
        ${CMAKE_COMMAND} -E chdir "${PROJECT_BINARY_DIR}/ruby/${CMAKE_CFG_INTDIR}" "${CONAN_BIN_DIRS_OPENSTUDIO_RUBY}/ruby" "${PROJECT_SOURCE_DIR}/../developer/ruby/SwigWrapToRDoc.rb" "${PROJECT_BINARY_DIR}/" "${SWIG_WRAPPER_FULL_PATH}" "${NAME}"
        DEPENDS ${SWIG_WRAPPER}
      )

      # Add this documentation target to the list of all targets
      list(APPEND ALL_RDOC_TARGETS ${swig_target}_rdoc)
      #set(ALL_RDOC_TARGETS "${ALL_RDOC_TARGETS}" PARENT_SCOPE)

    endif()

    if(MSVC)
      #set_target_properties(${swig_target} PROPERTIES COMPILE_FLAGS "-DRUBY_EXTCONF_H=<osruby_config.h> -DRUBY_EMBEDDED /bigobj /wd4996") ## /wd4996 suppresses deprecated warning
      set_target_properties(${swig_target} PROPERTIES COMPILE_FLAGS "/bigobj /wd4996 /wd5033 /wd4244") ## /wd4996 suppresses deprecated warning, /wd5033 supresses 'register' is no longer a supported storage class, /wd4244 supresses conversion from 'type1' to 'type2' possible loss of data
    elseif(UNIX)
      # If 'AppleClang' or 'Clang'
      if("${CMAKE_CXX_COMPILER_ID}" MATCHES "^(Apple)?Clang$")
        # Prevent excessive warnings from generated swig files, suppress deprecated declarations
        # Suppress 'register' storage class specified warnings (coming from Ruby)
        set_target_properties(${swig_target} PROPERTIES COMPILE_FLAGS "-Wno-dynamic-class-memaccess -Wno-deprecated-declarations -Wno-sign-compare -Wno-register -Wno-sometimes-uninitialized")
      else()
        set_target_properties(${swig_target} PROPERTIES COMPILE_FLAGS "-Wno-deprecated-declarations -Wno-sign-compare -Wno-register -Wno-conversion-null -Wno-misleading-indentation")
      endif()
    endif()

    set_target_properties(${swig_target} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/ruby/")
    set_target_properties(${swig_target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/ruby/")
    set_target_properties(${swig_target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/ruby/")
    target_link_libraries(${swig_target} ${${PARENT_TARGET}_depends})
    target_include_directories(${swig_target} PRIVATE ${RUBY_INCLUDE_DIRS})
    add_dependencies(${swig_target} ${PARENT_TARGET})

    add_custom_command(TARGET ${swig_target}
      POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/../test_data $<TARGET_FILE_DIR:${swig_target}>/test_data
    )

    execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy \"\${resolved_item_var}\" \"\${CMAKE_INSTALL_PREFIX}/Ruby/openstudio/\")

    # add this target to a "global" variable so ruby tests can require these
    list(APPEND ALL_RUBY_BINDING_TARGETS "${swig_target}")
    #set(ALL_RUBY_BINDING_TARGETS "${ALL_RUBY_BINDING_TARGETS}" PARENT_SCOPE)

    # add this target to a "global" variable so ruby tests can require these
    list(APPEND ALL_RUBY_BINDING_WRAPPERS "${SWIG_WRAPPER}")
    #set(ALL_RUBY_BINDING_WRAPPERS "${ALL_RUBY_BINDING_WRAPPERS}" PARENT_SCOPE)

    # add this target to a "global" variable so ruby tests can require these
    list(APPEND ALL_RUBY_BINDING_WRAPPERS_FULL_PATH "${SWIG_WRAPPER_FULL_PATH}")
    #set(ALL_RUBY_BINDING_WRAPPERS_FULL_PATH "${ALL_RUBY_BINDING_WRAPPERS_FULL_PATH}" PARENT_SCOPE)
  endif()

  # Python bindings
  if(BUILD_PYTHON_BINDINGS)
    set(swig_target "python_${NAME}")

    # utilities goes into OpenStudio. directly, everything else is nested
    # DLM: SWIG generates a file ${MODULE}.py for each module, however we have several libraries in the same module
    # so these clobber each other.  Making these unique, e.g. MODULE = TOLOWER "${NAME}", generates unique .py wrappers
    # but the module names are unknown and the bindings fail to load.  I think we need to write our own custom OpenStudio.py
    # wrapper that imports all of the libraries/python wrappers into the appropriate modules.
    # http://docs.python.org/2/tutorial/modules.html
    # http://docs.python.org/2/library/imp.html

    set(MODULE ${LOWER_NAME})

    set(SWIG_WRAPPER "python_${NAME}_wrap.cxx")
    set(SWIG_WRAPPER_FULL_PATH "${CMAKE_CURRENT_BINARY_DIR}/${SWIG_WRAPPER}")

    set(PYTHON_GENERATED_SRC_DIR "${PROJECT_BINARY_DIR}/python_wrapper/generated_sources/")
    file(MAKE_DIRECTORY ${PYTHON_GENERATED_SRC_DIR})

    set(PYTHON_GENERATED_SRC "${PYTHON_GENERATED_SRC_DIR}/${LOWER_NAME}.py")

    set(PYTHON_AUTODOC "")
    if(BUILD_DOCUMENTATION)
      set(PYTHON_AUTODOC -features autodoc=1)
    endif()


    # Add the -py3 flag if the version used is Python 3
    set(SWIG_PYTHON_3_FLAG "")
    if (Python_VERSION_MAJOR)
      if (Python_VERSION_MAJOR EQUAL 3)
        set(SWIG_PYTHON_3_FLAG -py3)
        message(STATUS "${MODULE} - Building SWIG Bindings for Python 3")
      else()
        message(STATUS "${MODULE} - Building SWIG Bindings for Python 2")
      endif()
    else()
      # Python2 has been EOL since January 1, 2020
      set(SWIG_PYTHON_3_FLAG -py3)
      message(STATUS "${MODULE} - Couldnt determine version of Python - Building SWIG Bindings for Python 3")
    endif()

    add_custom_command(
      OUTPUT "${SWIG_WRAPPER_FULL_PATH}"
      COMMAND ${CMAKE_COMMAND} -E env SWIG_LIB="${SWIG_LIB}"
              "${SWIG_EXECUTABLE}"
              "-python" ${SWIG_PYTHON_3_FLAG} "-c++" ${PYTHON_AUTODOC}
              -outdir ${PYTHON_GENERATED_SRC_DIR} "-I${PROJECT_SOURCE_DIR}/"
              -module "${MODULE}"
              -o "${SWIG_WRAPPER_FULL_PATH}"
              "${SWIG_DEFINES}" ${SWIG_COMMON} ${KEY_I_FILE}
      DEPENDS ${this_depends}
    )


    set_source_files_properties(${SWIG_WRAPPER_FULL_PATH} PROPERTIES GENERATED TRUE)
    set_source_files_properties(${PYTHON_GENERATED_SRC} PROPERTIES GENERATED TRUE)

    #add_custom_target(${SWIG_TARGET}
    #  DEPENDS ${SWIG_WRAPPER_FULL_PATH}
    #)

    add_library(
      ${swig_target}
      MODULE
      ${SWIG_WRAPPER}
    )

    # TODO: for local testing, PYTHON_GENERATED_SRC should go into Products/python next to the .so files
    install(FILES "${PYTHON_GENERATED_SRC}" DESTINATION Python COMPONENT "Python")
    install(TARGETS ${swig_target} DESTINATION Python COMPONENT "Python")

    set_target_properties(${swig_target} PROPERTIES OUTPUT_NAME _${LOWER_NAME})
    set_target_properties(${swig_target} PROPERTIES PREFIX "")
    set_target_properties(${swig_target} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/python/")
    set_target_properties(${swig_target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/python/")
    set_target_properties(${swig_target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/python/")
    if(MSVC)
      set_target_properties(${swig_target} PROPERTIES COMPILE_FLAGS "/bigobj /wd4996 /wd4005") ## /wd4996 suppresses deprecated warning, /wd4005 suppresses macro redefinition warning
      set_target_properties(${swig_target} PROPERTIES SUFFIX ".pyd")
    elseif(UNIX)
      if(APPLE AND NOT CMAKE_COMPILER_IS_GNUCXX)
        set_target_properties(${swig_target} PROPERTIES COMPILE_FLAGS "-Wno-dynamic-class-memaccess -Wno-deprecated-declarations -Wno-sign-compare -Wno-sometimes-uninitialized")
      else()
        set_target_properties(${swig_target} PROPERTIES COMPILE_FLAGS "-Wno-deprecated-declarations -Wno-sign-compare -Wno-misleading-indentation")
      endif()
    endif()

    target_link_libraries(${swig_target} ${PARENT_TARGET} ${PYTHON_Libraries})

    add_dependencies(${swig_target} ${PARENT_TARGET})

    add_custom_command(TARGET ${swig_target}
      POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_SOURCE_DIR}/../test_data $<TARGET_FILE_DIR:${swig_target}>/test_data
    )

    add_custom_command(TARGET ${swig_target}
      POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_BINARY_DIR}/python_wrapper/generated_sources/isomodel.py $<TARGET_FILE_DIR:${swig_target}>/isomodel.py
    )

    # add this target to a "global" variable so python tests can require these
    list(APPEND ALL_PYTHON_BINDINGS "${swig_target}")
    #set(ALL_PYTHON_BINDINGS "${ALL_PYTHON_BINDINGS}" PARENT_SCOPE)

    list(APPEND ALL_PYTHON_BINDING_DEPENDS "${PARENT_TARGET}")
    #set(ALL_PYTHON_BINDING_DEPENDS "${ALL_PYTHON_BINDING_DEPENDS}" PARENT_SCOPE)

    list(APPEND ALL_PYTHON_WRAPPER_FILES "${SWIG_WRAPPER_FULL_PATH}")
    #set(ALL_PYTHON_WRAPPER_FILES "${ALL_PYTHON_WRAPPER_FILES}" PARENT_SCOPE)

    list(APPEND ALL_PYTHON_WRAPPER_TARGETS "${SWIG_TARGET}")
    #set(ALL_PYTHON_WRAPPER_TARGETS "${ALL_PYTHON_WRAPPER_TARGETS}" PARENT_SCOPE)
  endif()

  # csharp
  if(BUILD_CSHARP_BINDINGS)
    set(swig_target "csharp_${NAME}")

    # keep the following lists aligned with translator_wrappers in \openstudiocore\csharp\CMakeLists.txt
    set( translator_names
      OpenStudioAirflow
      OpenStudioEnergyPlus
      OpenStudioGBXML
      OpenStudioISOModel
      OpenStudioRadiance
      OpenStudioSDD
    )

    set( model_names
      OpenStudioMeasure
      OpenStudioModel
      OpenStudioModelAirflow
      OpenStudioModelAvailabilityManager
      OpenStudioModelCore
      OpenStudioModelGenerators
      OpenStudioModelGeometry
      OpenStudioModelHVAC
      OpenStudioModelPlantEquipmentOperationScheme
      OpenStudioModelRefrigeration
      OpenStudioModelResources
      OpenStudioModelSetpointManager
      OpenStudioModelSimulation
      OpenStudioModelStraightComponent
      OpenStudioModelZoneHVAC
      OpenStudioOSVersion
      OpenStudioModelEditor
    )

    if(IS_UTILTIES)
      set(NAMESPACE "OpenStudio")
      set(MODULE "${NAME}")
    else()
      set(NAMESPACE "OpenStudio")
      set(MODULE "${NAME}")
    endif()

    set(SWIG_WRAPPER "csharp_${NAME}_wrap.cxx")
    set(SWIG_WRAPPER_FULL_PATH "${CMAKE_CURRENT_BINARY_DIR}/${SWIG_WRAPPER}")
    set(SWIG_TARGET "generate_csharp_${NAME}_wrap")

    list(FIND translator_names ${NAME} name_found)
    if( name_found GREATER -1 )
      if(MSVC)
        set(CSHARP_OUTPUT_NAME "openstudio_translators_csharp.dll")
      else()
        set(CSHARP_OUTPUT_NAME "libopenstudio_translators_csharp.so")
      endif()
    else()
      list(FIND model_names ${NAME} name_found)
      if( name_found GREATER -1 )
        if(MSVC)
          set(CSHARP_OUTPUT_NAME "openstudio_model_csharp.dll")
        else()
          set(CSHARP_OUTPUT_NAME "libopenstudio_model_csharp.so")
        endif()
      else()
        if(MSVC)
          set(CSHARP_OUTPUT_NAME "openstudio_csharp.dll")
        else()
          set(CSHARP_OUTPUT_NAME "libopenstudio_csharp.so")
        endif()
      endif()
    endif()

    set(CSHARP_GENERATED_SRC_DIR "${PROJECT_BINARY_DIR}/csharp_wrapper/generated_sources/${NAME}")
    file(MAKE_DIRECTORY ${CSHARP_GENERATED_SRC_DIR})

    set(CSHARP_AUTODOC "")
    if(BUILD_DOCUMENTATION)
      set(CSHARP_AUTODOC -features autodoc=1)
    endif()

    add_custom_command(
      OUTPUT ${SWIG_WRAPPER_FULL_PATH}
      COMMAND "${CMAKE_COMMAND}" -E remove_directory "${CSHARP_GENERATED_SRC_DIR}"
      COMMAND "${CMAKE_COMMAND}" -E make_directory "${CSHARP_GENERATED_SRC_DIR}"
      COMMAND ${CMAKE_COMMAND} -E env SWIG_LIB="${SWIG_LIB}"
              "${SWIG_EXECUTABLE}"
              "-csharp" "-c++" -namespace ${NAMESPACE} ${CSHARP_AUTODOC}
              -outdir "${CSHARP_GENERATED_SRC_DIR}"  "-I${PROJECT_SOURCE_DIR}/"
              -module "${MODULE}"
              -o "${SWIG_WRAPPER_FULL_PATH}"
              -dllimport "${CSHARP_OUTPUT_NAME}"
              "${SWIG_DEFINES}" ${SWIG_COMMON} ${KEY_I_FILE}
      DEPENDS ${this_depends}

      )

      add_custom_target(${SWIG_TARGET}
        DEPENDS ${SWIG_WRAPPER_FULL_PATH}
      )


    #add_library(
    #  ${swig_target}
    #  STATIC
    #  ${SWIG_WRAPPER}
    #)

    #set_target_properties(${swig_target} PROPERTIES OUTPUT_NAME "${CSHARP_OUTPUT_NAME}")
    #set_target_properties(${swig_target} PROPERTIES PREFIX "")
    #set_target_properties(${swig_target} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/csharp/")
    #set_target_properties(${swig_target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/csharp/")
    #set_target_properties(${swig_target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/csharp/")
    #if(MSVC)
    #  set_target_properties(${swig_target} PROPERTIES COMPILE_FLAGS "/bigobj /wd4996")  ## /wd4996 suppresses deprecated warnings
    #endif()
    #target_link_libraries(${swig_target} ${PARENT_TARGET})

    #ADD_DEPENDENCIES("${swig_target}" "${PARENT_TARGET}_resources")
    #    add_dependencies(${SWIG_TARGET} ${PARENT_TARGET})

    # add this target to a "global" variable so csharp tests can require these
    list(APPEND ALL_CSHARP_BINDING_DEPENDS "${${PARENT_TARGET}_depends}")
    #set(ALL_CSHARP_BINDING_DEPENDS "${ALL_CSHARP_BINDING_DEPENDS}" PARENT_SCOPE)

    list(APPEND ALL_CSHARP_WRAPPER_FILES "${SWIG_WRAPPER_FULL_PATH}")
    #set(ALL_CSHARP_WRAPPER_FILES "${ALL_CSHARP_WRAPPER_FILES}" PARENT_SCOPE)

    list(APPEND ALL_CSHARP_WRAPPER_TARGETS "${SWIG_TARGET}")
    #set(ALL_CSHARP_WRAPPER_TARGETS "${ALL_CSHARP_WRAPPER_TARGETS}" PARENT_SCOPE)

    #if(WIN32)
    #  install(TARGETS ${swig_target} DESTINATION CSharp/openstudio/)
    #
    #  install(CODE "
    #    include(GetPrerequisites)
    #    get_prerequisites(\${CMAKE_INSTALL_PREFIX}/CSharp/openstudio/openstudio_${NAME}_csharp.dll PREREQUISITES 1 1 \"\" \"${Prereq_Dirs}\")
    #
    #    if(WIN32)
    #      list(REVERSE PREREQUISITES)
    #    endif()
    #
    #    foreach(PREREQ IN LISTS PREREQUISITES)
    #      gp_resolve_item(\"\" \${PREREQ} \"\" \"${Prereq_Dirs}\" resolved_item_var)
    #      execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy \"\${resolved_item_var}\" \"\${CMAKE_INSTALL_PREFIX}/CSharp/openstudio/\")
    #
    #      get_filename_component(PREREQNAME \${resolved_item_var} NAME)
    #    endforeach()
    #  ")
    #endif()
  endif()

  # java
  if(BUILD_JAVA_BINDINGS)
    set(swig_target "java_${NAME}")

    string(SUBSTRING ${NAME} 10 -1 SIMPLIFIED_NAME)
    string(TOLOWER ${SIMPLIFIED_NAME} SIMPLIFIED_NAME)

    if(IS_UTILTIES)
      set(NAMESPACE "gov.nrel.openstudio")
      set(MODULE "${SIMPLIFIED_NAME}_global")
    else()
      #set( NAMESPACE "OpenStudio.${NAME}")
      set( NAMESPACE "gov.nrel.openstudio")
      set( MODULE "${SIMPLIFIED_NAME}_global")
    endif()

    set(SWIG_WRAPPER "java_${NAME}_wrap.cxx")
    set(SWIG_WRAPPER_FULL_PATH "${CMAKE_CURRENT_BINARY_DIR}/${SWIG_WRAPPER}")

    set(JAVA_OUTPUT_NAME "${NAME}_java")
    set(JAVA_GENERATED_SRC_DIR "${PROJECT_BINARY_DIR}/java_wrapper/generated_sources/${NAME}")
    file(MAKE_DIRECTORY ${JAVA_GENERATED_SRC_DIR})

    add_custom_command(
      OUTPUT ${SWIG_WRAPPER}
      COMMAND "${CMAKE_COMMAND}" -E remove_directory "${JAVA_GENERATED_SRC_DIR}"
      COMMAND "${CMAKE_COMMAND}" -E make_directory "${JAVA_GENERATED_SRC_DIR}"
      COMMAND ${CMAKE_COMMAND} -E env SWIG_LIB="${SWIG_LIB}"
              "${SWIG_EXECUTABLE}"
              "-java" "-c++"
              -package ${NAMESPACE}
              #-features autodoc=1
              -outdir "${JAVA_GENERATED_SRC_DIR}"  "-I${PROJECT_SOURCE_DIR}/"
              -module "${MODULE}"
              -o "${SWIG_WRAPPER_FULL_PATH}"
              #-dllimport "${JAVA_OUTPUT_NAME}"
              "${SWIG_DEFINES}" ${SWIG_COMMON} ${KEY_I_FILE}
      DEPENDS ${this_depends}

    )

    if(MAXIMIZE_CPU_USAGE)
      add_custom_target(${swig_target}_swig
        SOURCES "${SWIG_WRAPPER}"
        )
      add_dependencies(${PARENT_TARGET} ${swig_target}_swig)
    endif()


    include_directories("${JAVA_INCLUDE_PATH}" "${JAVA_INCLUDE_PATH2}")

    add_library(
      ${swig_target}
      MODULE
      ${SWIG_WRAPPER}
    )

    set_target_properties(${swig_target} PROPERTIES OUTPUT_NAME "${JAVA_OUTPUT_NAME}")
    #set_target_properties(${swig_target} PROPERTIES PREFIX "")
    set_target_properties(${swig_target} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/java/")
    set_target_properties(${swig_target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/java/")
    set_target_properties(${swig_target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/java/")
    if(MSVC)
      set_target_properties(${swig_target} PROPERTIES COMPILE_FLAGS "/bigobj /wd4996") ## /wd4996 suppresses deprecated warnings
      set(final_name "${JAVA_OUTPUT_NAME}.dll")
    elseif(UNIX)
      # If 'AppleClang' or 'Clang'
      if("${CMAKE_CXX_COMPILER_ID}" MATCHES "^(Apple)?Clang$")
        set_target_properties(${swig_target} PROPERTIES COMPILE_FLAGS "-Wno-deprecated-declarations -Wno-sign-compare -Wno-sometimes-uninitialized")
      else()
        set_target_properties(${swig_target} PROPERTIES COMPILE_FLAGS "-Wno-deprecated-declarations -Wno-sign-compare -Wno-misleading-indentation")
      endif()
    endif()

    target_link_libraries(${swig_target} ${PARENT_TARGET} ${JAVA_JVM_LIBRARY})
    if(APPLE)
      set_target_properties(${swig_target} PROPERTIES SUFFIX ".dylib")
      set(final_name "lib${JAVA_OUTPUT_NAME}.dylib")
    endif()

    #add_dependencies("${swig_target}" "${PARENT_TARGET}_resources")

    # add this target to a "global" variable so java tests can require these
    list(APPEND ALL_JAVA_BINDING_TARGETS "${swig_target}")
    set(ALL_JAVA_BINDING_TARGETS "${ALL_JAVA_BINDING_TARGETS}" PARENT_SCOPE)

    list(APPEND ALL_JAVA_SRC_DIRECTORIES "${JAVA_GENERATED_SRC_DIR}")
    set(ALL_JAVA_SRC_DIRECTORIES "${ALL_JAVA_SRC_DIRECTORIES}" PARENT_SCOPE)


    if(WIN32 OR APPLE)
      install(TARGETS ${swig_target} DESTINATION Java/openstudio/)

      install(CODE "
        include(GetPrerequisites)
        get_prerequisites(\${CMAKE_INSTALL_PREFIX}/Java/openstudio/${final_name} PREREQUISITES 1 1 \"\" \"${Prereq_Dirs}\")

        if(WIN32)
          list(REVERSE PREREQUISITES)
        endif()

        foreach(PREREQ IN LISTS PREREQUISITES)
          gp_resolve_item(\"\" \${PREREQ} \"\" \"${Prereq_Dirs}\" resolved_item_var)
          execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy \"\${resolved_item_var}\" \"\${CMAKE_INSTALL_PREFIX}/Java/openstudio/\")

          get_filename_component(PREREQNAME \${resolved_item_var} NAME)

          if(APPLE)
            execute_process(COMMAND \"install_name_tool\" -change \"\${PREREQ}\" \"@loader_path/\${PREREQNAME}\" \"\${CMAKE_INSTALL_PREFIX}/Java/openstudio/${final_name}\")
            foreach(PR IN LISTS PREREQUISITES)
              gp_resolve_item(\"\" \${PR} \"\" \"\" PRPATH)
              get_filename_component(PRNAME \${PRPATH} NAME)
              execute_process(COMMAND \"install_name_tool\" -change \"\${PR}\" \"@loader_path/\${PRNAME}\" \"\${CMAKE_INSTALL_PREFIX}/Java/openstudio/\${PREREQNAME}\")
            endforeach()
          endif()
        endforeach()
      ")
    else()
      install(TARGETS ${swig_target} DESTINATION "lib/openstudio-${OpenStudio_VERSION}/java")
    endif()
  endif()


  # v8
  if(BUILD_V8_BINDINGS)
    set(swig_target "v8_${NAME}")

    if(IS_UTILTIES)
      set(NAMESPACE "OpenStudio")
      set(MODULE "${NAME}")
    else()
      #set(NAMESPACE "OpenStudio.${NAME}")
      set(NAMESPACE "OpenStudio")
      set(MODULE "${NAME}")
    endif()

    set(SWIG_WRAPPER "v8_${NAME}_wrap.cxx")
    set(SWIG_WRAPPER_FULL_PATH "${CMAKE_CURRENT_BINARY_DIR}/${SWIG_WRAPPER}")

    set(v8_OUTPUT_NAME "${NAME}")
    #set(CSHARP_GENERATED_SRC_DIR "${PROJECT_BINARY_DIR}/csharp_wrapper/generated_sources/${NAME}")
    #file(MAKE_DIRECTORY ${CSHARP_GENERATED_SRC_DIR})

    if(BUILD_NODE_MODULES)
      set(V8_DEFINES "-DBUILD_NODE_MODULE")
      set(SWIG_ENGINE "-node")
    else()
      set(V8_DEFINES "")
      set(SWIG_ENGINE "-v8")
    endif()

    add_custom_command(
      OUTPUT ${SWIG_WRAPPER}
      COMMAND ${CMAKE_COMMAND} -E env SWIG_LIB="${SWIG_LIB}"
              "${SWIG_EXECUTABLE}"
              "-javascript" ${SWIG_ENGINE} "-c++"
              #-namespace ${NAMESPACE}
              #-features autodoc=1
              #-outdir "${CSHARP_GENERATED_SRC_DIR}"
              "-I${PROJECT_SOURCE_DIR}/"
              -module "${MODULE}"
              -o "${SWIG_WRAPPER_FULL_PATH}"
              "${SWIG_DEFINES}" ${V8_DEFINES} ${SWIG_COMMON} ${KEY_I_FILE}
              DEPENDS ${this_depends}

    )

    if(BUILD_NODE_MODULES)
      include_directories("${NODE_INCLUDE_DIR}" "${NODE_INCLUDE_DIR}/deps/v8/include" "${NODE_INCLUDE_DIR}/deps/uv/include" "${NODE_INCLUDE_DIR}/src")
    else()
      include_directories(${V8_INCLUDE_DIR})
    endif()

    if(MAXIMIZE_CPU_USAGE)
      add_custom_target(${swig_target}_swig
        SOURCES "${SWIG_WRAPPER}"
        )
      add_dependencies(${PARENT_TARGET} ${swig_target}_swig)
    endif()


    add_library(
      ${swig_target}
      MODULE
      ${SWIG_WRAPPER}
    )

    set_target_properties(${swig_target} PROPERTIES OUTPUT_NAME ${v8_OUTPUT_NAME})
    set_target_properties(${swig_target} PROPERTIES PREFIX "")
    set(_NAME "${v8_OUTPUT_NAME}.node")
    if(BUILD_NODE_MODULES)
      set_target_properties(${swig_target} PROPERTIES SUFFIX ".node")
    endif()
    set_target_properties(${swig_target} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/v8/")
    set_target_properties(${swig_target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/v8/")
    set_target_properties(${swig_target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/v8/")

    if(MSVC)
      set_target_properties(${swig_target} PROPERTIES COMPILE_FLAGS "/bigobj /DBUILDING_NODE_EXTENSION /wd4996")  ## /wd4996 suppresses deprecated warnings
    elseif(UNIX)
      # If 'AppleClang' or 'Clang'
      if("${CMAKE_CXX_COMPILER_ID}" MATCHES "^(Apple)?Clang$")
        set_target_properties(${swig_target} PROPERTIES COMPILE_FLAGS "-DBUILDING_NODE_EXTENSION -Wno-deprecated-declarations -Wno-sign-compare -Wno-sometimes-uninitialized")
      else()
        set_target_properties(${swig_target} PROPERTIES COMPILE_FLAGS "-DBUILDING_NODE_EXTENSION -Wno-deprecated-declarations -Wno-sign-compare -Wno-misleading-indentation")
      endif()
    endif()

    if(APPLE)
      set_target_properties(${swig_target} PROPERTIES LINK_FLAGS "-undefined suppress -flat_namespace")
    endif()
    target_link_libraries(${swig_target} ${PARENT_TARGET})

    #add_dependencies("${swig_target}" "${PARENT_TARGET}_resources")

    # add this target to a "global" variable so v8 tests can require these
    list(APPEND ALL_V8_BINDING_TARGETS "${swig_target}")
    #set(ALL_V8_BINDING_TARGETS "${ALL_V8_BINDING_TARGETS}" PARENT_SCOPE)

    if(BUILD_NODE_MODULES)
      set(V8_TYPE "node")
    else()
      set(V8_TYPE "v8")
    endif()

    if(WIN32 OR APPLE)
      install(TARGETS ${swig_target} DESTINATION "${V8_TYPE}/openstudio/")

      install(CODE "
        #message(\"INSTALLING SWIG_TARGET: ${swig_target}  with NAME = ${_NAME}\")
        include(GetPrerequisites)
        get_prerequisites(\${CMAKE_INSTALL_PREFIX}/${V8_TYPE}/openstudio/${_NAME} PREREQUISITES 1 1 \"\" \"${Prereq_Dirs}\")
        #message(\"PREREQUISITES = \${PREREQUISITES}\")


        if(WIN32)
          list(REVERSE PREREQUISITES)
        endif()

        foreach(PREREQ IN LISTS PREREQUISITES)
          gp_resolve_item(\"\" \${PREREQ} \"\" \"${Prereq_Dirs}\" resolved_item_var)
          #message(\"prereq = ${PREREQ}  resolved = ${resolved_item_var} \")
          execute_process(COMMAND \"${CMAKE_COMMAND}\" -E copy \"\${resolved_item_var}\" \"\${CMAKE_INSTALL_PREFIX}/${V8_TYPE}/openstudio/\")

          get_filename_component(PREREQNAME \${resolved_item_var} NAME)

          if(APPLE)
            execute_process(COMMAND \"install_name_tool\" -change \"\${PREREQ}\" \"@loader_path/\${PREREQNAME}\" \"\${CMAKE_INSTALL_PREFIX}/${V8_TYPE}/openstudio/${_NAME}\")
            foreach(PR IN LISTS PREREQUISITES)
              gp_resolve_item(\"\" \${PR} \"\" \"\" PRPATH)
              get_filename_component(PRNAME \${PRPATH} NAME)
              execute_process(COMMAND \"install_name_tool\" -change \"\${PR}\" \"@loader_path/\${PRNAME}\" \"\${CMAKE_INSTALL_PREFIX}/${V8_TYPE}/openstudio/\${PREREQNAME}\")
            endforeach()
          endif()
        endforeach()
      ")
    else()
      install(TARGETS ${swig_target} DESTINATION "lib/openstudio-${OpenStudio_VERSION}/${V8_TYPE}")
    endif()
  endif()


endmacro() # End of MAKE_SWIG_TARGET
