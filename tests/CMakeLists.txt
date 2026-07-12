cmake_minimum_required(VERSION 3.16)
project(maxwell-tests LANGUAGES C CXX)

find_package(Qt6 REQUIRED COMPONENTS Quick Test)

qt6_add_resources(TEST_QRC tst_main.qrc)

qt6_add_qml_module(
    maxwell-tests
    URI maxwell.tests
    VERSION 1.0
    QML_FILES tst_main.qml
    SOURCES ${TEST_QRC}
)

target_link_libraries(maxwell-tests PRIVATE Qt6::Quick Qt6::Test)

add_test(NAME MaxwellTests COMMAND qmltestrunner --module=maxwell.tests --root-path=${CMAKE_CURRENT_SOURCE_DIR})