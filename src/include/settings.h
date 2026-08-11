#pragma once

#include <algorithm>
#include <filesystem>
#include <iostream>
#include <string>
#include <map>
#include <ranges>
#include <variant>
#include <vector>

#include <fmt/base.h>

#include "misc.h"


// CLI settings
static const char * cli_keys[] = {"--verbose", "--generate_tooltip", "--objects_path", "--routines_path", "--osc", "--mw0", "--mw0t"};

// Settings which happen to be boolean
static const char * bool_keys[] = {"verbose", "generate_tooltip"};

/*
    Functions for ObjecTool settings
    ---
    Check the readme for more info
*/

void parse_cli_settings(std::vector<std::string>&, std::map<std::string, std::variant<bool, std::string>>&);

