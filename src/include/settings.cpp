#include "settings.h"

namespace ranges = std::ranges;

/*
    parse_cli_settings(vector<string>& cli_settings, map<string, variant<bool, int, string>>& bowsie_settings) -> void: Parse settings from CLI
    ---
    Input:
    - cli_settings is a vector which holds the command line arguments
    - bowsie_settings is a vector to hold the settings

    Output:
    - exits with error if a setting does not exist
    - bowsie_settings now contains the processed settings
*/
void parse_cli_settings(std::vector<std::string>& cli_settings, std::map<std::string, std::variant<bool, std::string>>& tool_settings)
{
    if( (ranges::find(cli_settings, "-h")!=ranges::end(cli_settings) ) || ( ranges::find(cli_settings, "--help")!=ranges::end(cli_settings) ) )
    {
        fmt::println("\t objectool [switches] [rom] [list]\n");
        fmt::println("Command line switches");
        fmt::println("  -h, --help\t\tDisplay this message and quit\n");
        fmt::println("The following are passed as an argument of the form --<setting_name>=<value>");
        fmt::println("  verbose\t\tDisplay all info per object inserted");
        fmt::println("  generate_tooltip\tCreate .osc and .mw0/t files for LM display");
        fmt::println("  objects_path\t\tPath to the folder which contains custom objects");
        fmt::println("  routines_path\t\tPath to the folder which contains shared routines");
        fmt::println("  osc\t\t\tPath to an .osc file to which to append info");
        fmt::println("  mw0\t\t\tPath to an .mw0 file to which to append info");
        fmt::println("  mw0t\t\t\tPath to an .mw0t file to which to append info");

        std::exit(0);
    }

    std::string setting;
    std::string param;
    for(auto full_setting : cli_settings)
    {
        setting = ( full_setting.find("=")!=std::string::npos ) ? std::string(full_setting.begin(), full_setting.begin()+full_setting.find_first_of("=")) : full_setting;
        param = ( full_setting.find("=")!=std::string::npos ) ? std::string(full_setting.begin()+full_setting.find_first_of("=")+1, full_setting.end()) : "";

        if(ranges::find(cli_keys, setting)==ranges::end(cli_keys))
            exit(error("Unknown setting {}", setting));

        std::string setting_name = std::string(setting.begin()+2, setting.end());
        if(ranges::find(bool_keys, setting_name)!=ranges::end(bool_keys))
        {
            if(!(param=="true" || param=="false"))
                exit(error("Unknown parameter for {}: extected true/false", setting));
            else
                tool_settings[setting_name] = param=="true" ? true : false;
        }
        else
            tool_settings[setting_name] = param;
    }
}

