add_library(f2reduce
  f2reduce.cpp
)

target_include_directories(f2reduce PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}
)