#pragma once

#include <filesystem>
#include <fstream>
#include <iostream>
#include <map>
#include <string>
#include <vector>
#include <format>

#ifdef ASAR_DYNAMIC_LINK
    #include "asar/asardll.h"
#else
    #include "asar/asar.h"
#endif

#include <fmt/base.h>

#define STANDARD_DISPLAY_TOOLTIP "2D\t{:0>2X}\t0\t{}\n"
#define EXTENDED_DISPLAY_TOOLTIP "0\t{:0>2X}\t0\t{}\n"
#define LIST_TOOLTIP "{:0>2X}\t{}\n"

/*
    struct Tooltip: object tooltip generation
    ---
*/
struct Tooltip
{
    std::ofstream osc;
    std::ofstream mw0t;
    std::vector<unsigned char> mw0;

    // I/O functions
    void open_osc(const char*);
    void open_mw0t(const char*);
    void open_mw0(const char*);
    void done(const char*);

    // Tooltip (and main) function
    bool write_display_tooltip(bool, int, std::string, bool, std::string*);
    bool write_list_tooltip(bool, int, std::string, bool, std::string*);
    bool write_both_tooltips_from_defines(std::map<std::string, std::string>, int, bool, int, std::string*, std::string*, std::string*);
};

bool destroy_tooltip(std::string filename);

