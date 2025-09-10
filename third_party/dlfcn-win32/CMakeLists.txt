# Add Windows SDK and Visual Studio C++ include paths for Windows build
if(WIN32)
  # Find Visual Studio installation
  set(VS_PATH "C:/Program Files/Microsoft Visual Studio/2022/Community")
  if(EXISTS ${VS_PATH})
    # Find the latest MSVC version
    file(GLOB MSVC_VERSIONS "${VS_PATH}/VC/Tools/MSVC/*")
    list(REVERSE MSVC_VERSIONS)
    list(GET MSVC_VERSIONS 0 LATEST_MSVC)
    
    if(EXISTS ${LATEST_MSVC})
      # Add Visual Studio C++ headers
      include_directories("${LATEST_MSVC}/include")
      include_directories("${LATEST_MSVC}/atlmfc/include")
      
      # Find Windows SDK
      file(GLOB WIN_SDK_VERSIONS "C:/Program Files (x86)/Windows Kits/10/Include/*")
      list(REVERSE WIN_SDK_VERSIONS)
      list(GET WIN_SDK_VERSIONS 0 LATEST_WIN_SDK)
      
      if(EXISTS ${LATEST_WIN_SDK})
        # Add Windows SDK headers
        include_directories("${LATEST_WIN_SDK}/ucrt")
        include_directories("${LATEST_WIN_SDK}/um")
        include_directories("${LATEST_WIN_SDK}/shared")
        include_directories("${LATEST_WIN_SDK}/winrt")
        include_directories("${LATEST_WIN_SDK}/cppwinrt")
      endif()
    endif()
  endif()
endif()

add_library(dlfcn STATIC ${CMAKE_CURRENT_SOURCE_DIR}/dlfcn.c)