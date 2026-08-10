/*
 * ObjecTool
 * ---
 * C++ code is (c) 2023 Burning Loaf, 2026 Arinsu (Ari)
 * licensed under the BSD 2-clause license
 * 
 * 65816 ASM code is due to 0x400, imamelia, Burning Loaf and Ari
 * 
 * Asar is (c) 2011 Alcaro, RPG Hacker, trillian/randomdude999 et al.
*/

#include <filesystem>
#include <iostream>
#include <string>
#include <map>
#include <variant>
#include <vector>
#include <format>

#include <cstdint>

#include <fmt/base.h>

#ifdef ASAR_DYNAMIC_LINK
    #include "include/asar/asardll.h"
#else
    #include "include/asar/asar.h"
#endif
#include <nlohmann/json.hpp>

#include "include/misc.h"
#include "include/map16.h"
#include "include/rom.h"
#include "include/settings.h"

#define VERSION 2
#define SUBVER 0
#define BUGFIX 0

using ios = std::ios;

namespace fs = std::filesystem;

// Constants
#define OBJECTOOL_SIGNATURE_PTR 0x0DA100
#define MAGIC_CONSTANT 0x544F

#define OBJECTOOL_SSR_PTR 0x0DC620

#define EXTENDED_OBJECT_PTRS 0x0DA10F
#define EXTENDED_OBJECT_START 0x98
#define EXTENDED_OBJECT_SIZE (0x100-EXTENDED_OBJECT_START)

#define MAX_ROUTINES 100

int main(int argc, char *argv[])
{
    fmt::println("ObjecTool");
    fmt::println("\t v{}.{}.{}", VERSION, SUBVER, BUGFIX);
    fmt::println("\t By Burning Loaf, Arinsu\n");

    #ifdef ASAR_DYNAMIC_LINK
        const bool asar_dll = true;
        if(!asar_init())
            exit(error("Couldn't initialize Asar DLL. Make sure asar.dll is in the same directory as ObjecTool."));
    #else
        const bool asar_dll = false;
    #endif

    Rom rom;

    std::string list_path;
    std::map<std::string, std::variant<bool, std::string>> objectool_settings;
    objectool_settings["verbose"] = false;
    objectool_settings["generate_tooltip"] = true;
    objectool_settings["objects_path"] = "objects";
    objectool_settings["routines_path"] = "routines";
    objectool_settings["osc"] = "";
    objectool_settings["mw0"] = "";
    objectool_settings["mw0t"] = "";

    bool cli_settings = false;
    bool rom_passed;
    bool list_passed;

    /*
        Parse inputs
    */
    switch(argc)
    {
        case 0:
        case 1:
            acquire_rom(&rom.rom_path);
            acquire_list(&list_path);
            break;
        default:
            std::vector<std::string> clean_argv;
            bool rom_acquired = false;
            bool list_acquired = false;

            for(int i=0;i<argc-1;++i)
            {
                std::string tmp = argv[i+1];
                cleanup_str(&tmp);
                if(tmp.ends_with(".smc") || tmp.ends_with(".sfc"))
                {
                    rom.rom_path = tmp;
                    rom_acquired = true;
                }
                else if(tmp.ends_with(".txt"))
                {
                    list_path = tmp;
                    list_acquired = true;
                }
                else
                    clean_argv.push_back(tmp);
            }

            if(clean_argv.size()>0)
            {
                parse_cli_settings(clean_argv, objectool_settings);
                cli_settings = true;
            }

            if(!rom_acquired)
                acquire_rom(&rom.rom_path);
            if(!list_acquired)
                acquire_list(&list_path);
    }

    /*
        Existence checks
    */
    if(!rom.open_rom())
        exit(error("Couldn't open ROM file {}", rom.rom_path));
    std::ifstream list(list_path);
    if(!list)
        exit(error("Couldn't open list file {}", list_path));

    bool verbose = std::get<bool>(objectool_settings["verbose"]);
    bool generate_tooltip = std::get<bool>(objectool_settings["generate_tooltip"]);
    std::string objects_path = std::get<std::string>(objectool_settings["objects_path"]);
    std::string routines_path = std::get<std::string>(objectool_settings["routines_path"]);
    std::string osc = std::get<std::string>(objectool_settings["osc"]);
    std::string mw0 = std::get<std::string>(objectool_settings["mw0"]);
    std::string mw0t = std::get<std::string>(objectool_settings["mw0t"]);

    // Misc. ROM checks
    if(rom.rom_size<0x100000)
        exit(error("This ROM is clean. Please edit it in Lunar Magic."));
    if((rom.read<3>(0x00FFC0))!=0x535550) // SUP
        exit(error("Title mismatch. Is this ROM headered?"));
    const int lm_ver = 100*(rom.read<1>(0x0FF0B4)&0xF)+10*(rom.read<1>(0x0FF0B4+2)&0xF)+1*(rom.read<1>(0x0FF0B4+3)&0xF);

    if(verbose)
    {
        fmt::println("\nVerbose mode enabled.");
        fmt::println("Running ObjecTool with");
        fmt::println("Tooltip generation:\t{}", generate_tooltip ? "Enabled" : "Disabled");
        fmt::println("Objects folder:\t\t{}", objects_path);
        fmt::println("Routines folder:\t{}", routines_path);
        fmt::println("osc file to append to:\t{}", osc.empty() ? "None" : osc );
        fmt::println("mw0 file to append to:\t{}", mw0.empty() ? "None" : mw0 );
        fmt::println("mw0t file to append to:\t{}", mw0t.empty() ? "None" : mw0t );
        fmt::println("Asar version:\t\tv{}.{}{}", (int)(((asar_version()%100000)-(asar_version()%1000))/10000),
                                                 (int)(((asar_version()%1000)-(asar_version()%10))/100),
                                                 (int)(asar_version()%10));
        fmt::println("Asar library:\t\t{}", asar_dll ? "Dynamic" : "Static");
        fmt::println("Lunar Magic version:\t{}.{}\n", (int)(lm_ver/100), lm_ver%100);
    }
    else
        fmt::println("");


    int asar_errcount = 0;
    std::string tool_folder = fs::absolute(argv[0]).parent_path().string()+"/";
    std::string rom_name = fs::absolute(rom.rom_path).parent_path().string()+"/"+fs::path(rom.rom_path).stem().string();

    std::string full_patch
    (
        std::format
        (
"\
!objectool_version     #= {1}\n\
!objectool_subversion  #= {2}\n\
incsrc \"{0}asm/defines.asm\"\n\
incsrc \"{0}asm/ssr.asm\"\n\
incsrc \"{0}asm/macro.asm\"\n\
",
            tool_folder,
            VERSION,
            SUBVER
        )
    );

    // Figure out whether the tool's been used and clean-up if so
    if(rom.read<2>(OBJECTOOL_SIGNATURE_PTR, true)==MAGIC_CONSTANT)
    {
        if(verbose)
            fmt::println("Performing clean-up of a previous execution...");
        if(!destroy_map16(rom_name))
            exit(error("Error cleaning up existing Map16 files. Exiting..."));

        std::string clean_patch;
        for(int i=EXTENDED_OBJECT_START; i<0x100; ++i)
            clean_patch.append(std::format("autoclean ${:0>6X}\n", rom.read<3>(EXTENDED_OBJECT_PTRS+(i*3), true)));

        int standard_object_ptrs = rom.read<3>(OBJECTOOL_SIGNATURE_PTR+8, true);
        for(int i=0; i<0x100; ++i)
            clean_patch.append(std::format("autoclean ${:0>6X}\n", rom.read<3>(standard_object_ptrs+(i*3), true)));
        clean_patch.append(std::format("autoclean ${:0>6X}\n", standard_object_ptrs));

        
        for(int i=0;i<MAX_ROUTINES;i+=3)
        {
            clean_patch.append(std::format("autoclean ${:0>6X}\norg ${:0>6X}\n    dl $FFFFFF\n", rom.read<3>(OBJECTOOL_SSR_PTR+i, true),
                                                                                               OBJECTOOL_SSR_PTR+i));
        }

        int word_param_ptrs = rom.read<3>(OBJECTOOL_SIGNATURE_PTR+8+3, true);
        clean_patch.append(std::format("autoclean ${:0>6X}\n", word_param_ptrs));

        if(!rom.inline_patch(tool_folder, clean_patch.c_str()))
            exit(error("An error ocurred while cleaning up. Details:\n  {}", asar_geterrors(&asar_errcount)->fullerrdata));
        if(!rom.reload())
            exit(error("An error ocurred while cleaning up."));
        else if(verbose)
            fmt::println("Clean-up done.\n");
    }

    // Shared sub-routines
    if(!fs::exists(tool_folder+routines_path))
        exit(error("Couldn't find directory for routines folder {}", routines_path));

    std::string individual_routine_macro;
    std::string routine_inserter_macro
    (
        std::format
        (
"\
macro insert_routine(routine_name, routine_path, routine_offset)\n\
    if defined(\"inserted_<routine_name>\")\n\
        if not(!{{inserted_<routine_name>}})\n\
            pushpc\n\
                if read3(${0:0>6X}+<routine_offset>) != $FFFFFF\n\
                    <routine_name>  = read3(${0:0>6X}+<routine_offset>)\n\
                else\n\
                    freecode cleaned\n\
                    print \"Shared subroutine %<routine_name>() inserted at $\", pc\n\
                    global #<routine_name>:\n\
                        namespace <routine_name>\n\
                            incsrc \"<routine_path>\"\n\
                        namespace off\n\
                    org ${0:0>6X}+<routine_offset>\n\
                        dl <routine_name>\n\
                endif\n\
            pullpc\n\
            !{{inserted_<routine_name>}}   #= 1\n\
            !routine_inserted              #= 1\n\
        endif\n\
    endif\n\
endmacro\n\
\n\n\
macro insert_all_routines()\n\
",
            OBJECTOOL_SSR_PTR
        )
    );

    int routines = 0;
    int routine_offset = 0;
    for(auto routine : fs::directory_iterator(tool_folder+routines_path))
    {
        std::string routine_path( routine.path().string() );
        cleanup_str(&routine_path);
        std::string routine_name( routine.path().stem().string() );
        individual_routine_macro.append(
            std::format
            (
"\
macro {0}()\n\
    !inserted_{0}  ?= 0\n\
    JSL {0}\n\
endmacro\n\n\
",
                routine_name
            )
        );
        routine_inserter_macro.append(std::format("    %insert_routine({0}, \"{1}\", {2})\n", routine_name, routine_path, routine_offset));
        routine_offset += 3;
        if(++routines == MAX_ROUTINES)
            exit(error("Maximum number of shared subroutines exceeded"));
    }

    routine_inserter_macro.append(
"\
endmacro\n\n\
!routine_inserted      #= 1\n\
while !routine_inserted != 0\n\
    !routine_inserted  #= 0\n\
    %insert_all_routines()\n\
endwhile\n\
"
    );
    fmt::println("{} shared subroutines found.", routines);
    if(verbose)
        fmt::println("-----------------------------------------------------------");
    std::ofstream(tool_folder+"asm/ssr_insert.asm").write(routine_inserter_macro.c_str(), routine_inserter_macro.size());
    std::ofstream(tool_folder+"asm/ssr.asm").write(individual_routine_macro.c_str(), individual_routine_macro.size());

    // Pointers for object code
    unsigned char * standard_obj_ptrs = new unsigned char[0x100*3] {};
    unsigned char * extended_obj_ptrs = new unsigned char[EXTENDED_OBJECT_SIZE*3] {};

    // Arrays for word parameters
    unsigned char * standard_word_params = new unsigned char[0x100*2] {};
    unsigned char * extended_word_params = new unsigned char[EXTENDED_OBJECT_SIZE*2] {};

    for(int i=0;i<0x100;i+=3)
    {
        standard_obj_ptrs[i]   = 0x14;
        standard_obj_ptrs[1+i] = 0xA4;
        standard_obj_ptrs[2+i] = 0x0D;

        standard_word_params[i] = 0x00;
    }

    for(int i=0;i<EXTENDED_OBJECT_SIZE;i+=3)
    {
        extended_obj_ptrs[i]   = 0x14;
        extended_obj_ptrs[1+i] = 0xA4;
        extended_obj_ptrs[2+i] = 0x0D;

        extended_word_params[i] = 0x00;
    }

    // Word parameters
    std::string word_params_patch
    (
        std::format
        (
"\
freecode cleaned\n\
standard_word_params:\n\
    for i = 0..$100\n\
        dw $0000\n\
    endfor\n\
extended_word_params:\n\
    for i = ${:0>2X}..$100\n\
        dw $0000\n\
    endfor\n\n\
print hex(standard_word_params, 6) \n\
",
            EXTENDED_OBJECT_START
        )
    );
    if(!rom.inline_patch(tool_folder, word_params_patch.c_str()))
        exit(error("Something went wrong while inserting the word parameters. Details: {}\n", asar_geterrors(&asar_errcount)->fullerrdata));
    if(!rom.reload())
        exit(error("Something went wrong while inserting the word parameters."));

    auto word_param_print = asar_getprints(&asar_errcount);
    std::string word_param_addr(word_param_print[0]);

    // Objects
    int standard_obj_count = 0;
    int extended_obj_count = 0;
    bool inserting_extended = false;

    // TODO: Tooltip

    for(std::string dirty_object; std::getline(list, dirty_object);)
    {
        try
        {
            std::size_t pos {};
            std::string object = dirty_object;

            if(object.find_first_not_of("\t ")==std::string::npos) continue;

            object = object.substr(object.find_first_not_of("\t "));

            if(object.starts_with(";")) continue;

            object = object.substr(0, 1+object.find_last_not_of("\t "));

            if(object.substr(object.find_first_not_of("\t "), std::string::npos-object.find_last_not_of("\t ")) == "EXTENDED:")
            {
                inserting_extended = true;
                continue;
            }
            if(object.substr(object.find_first_not_of("\t "), std::string::npos-object.find_last_not_of("\t ")) == "STANDARD:")
            {
                inserting_extended = false;
                continue;
            }

            int object_number = std::stoi(object, &pos, 16);
            if(object_number<0x00 || object_number>0xFF) throw std::out_of_range("");
            
            object = object.substr(pos);
            int word_parameter;
            try { word_parameter = std::stoi(object, &pos, 16); }
            catch(...) { pos = 0; word_parameter = 0x0000; }

            std::string object_filename(object.substr(object.find_first_not_of("\t ", pos)));
            cleanup_str(&object_filename);
            if(!object_filename.ends_with(".asm") && !object_filename.ends_with(".asm\""))
                exit(error("Unknown extension for object {}", object_filename));

            std::string object_labelname(object_filename.substr(0, object_filename.find_first_of("."))+"_"+std::to_string(object_number));
            cleanup_str(&object_labelname);

            auto clean_it = std::remove(object_labelname.begin(), object_labelname.end(), '\\');
            object_labelname.erase(clean_it, object_labelname.end());
            clean_it = std::remove(object_labelname.begin(), object_labelname.end(), '/');
            object_labelname.erase(clean_it, object_labelname.end());
            clean_it = std::remove(object_labelname.begin(), object_labelname.end(), ' ');
            object_labelname.erase(clean_it, object_labelname.end());

            if(!inserting_extended)
            {
                // Standard objects
                if( (standard_obj_ptrs[2+object_number*3]<<16 | standard_obj_ptrs[1+object_number*3]<<8 | standard_obj_ptrs[object_number*3]) != 0x0DA414 ) throw std::invalid_argument("");
            }
            else
            {
                // Extended objects
                if(object_number<EXTENDED_OBJECT_START) throw std::out_of_range("");
                if
                (
                    (
                        extended_obj_ptrs[2+(object_number-EXTENDED_OBJECT_START)*3]<<16 | \
                        extended_obj_ptrs[1+(object_number-EXTENDED_OBJECT_START)*3]<<8 | \
                        extended_obj_ptrs[(object_number-EXTENDED_OBJECT_START)*3]
                    ) != 0x0DA414
                ) throw std::invalid_argument("");
            }

            std::ifstream curr_object(tool_folder+objects_path+"/"+object_filename);
            if(!curr_object)
                exit(error("Could not open object with number {:0>2X} and filename {}. Make sure it exists and is in the {} directory.", object_number, object_filename, objects_path));

            std::string object_patch
            (
                std::format
                (
"\
incsrc defines.asm\n\
incsrc ssr.asm\n\
incsrc macro.asm\n\
standard_word_params = ${5}|!bank\n\
extended_word_params = ${5}|!bank+512\n\
\n\
namespace {1}\n\
    freecode cleaned\n\
    incsrc {4}\n\
    print \"{0} object {3:0>2X} - {2}\"\n\
    print \"    Inserted at: $\", hex({1}_load)\n\n\
    incsrc ssr_insert.asm\n\
namespace off\n\
",
                    inserting_extended ? "Extended" : "Standard",
                    object_labelname,
                    object_filename,
                    object_number,
                    ("\""+tool_folder+objects_path+"/"+object_filename+"\""),
                    word_param_addr
                )
            );

            if(!rom.inline_patch(tool_folder, object_patch.c_str()))
                exit(error("Could not insert {} object {}. Details: {}\n", inserting_extended ? "extended" : "standard", object_filename, asar_geterrors(&asar_errcount)->fullerrdata));

            if(!rom.reload())
                exit(error("Could not insert {} object {}.", inserting_extended ? "extended" : "standard", object_filename));
            else
            {
                auto object_print = asar_getprints(&asar_errcount);
                std::size_t pos {};
                for(int i=0;i<asar_errcount;++i)
                {
                        std::string object_addr(object_print[i]);
                        if(verbose)
                            fmt::println("{}", object_addr);
                        if( (object_addr.substr(0,6) != "Shared") && (object_addr.find('$') != std::string::npos) )
                        {
                            object_addr = std::string(object_addr.begin()+object_addr.find_first_of("$")+1, object_addr.end());
                            if(inserting_extended)
                            {
                                extended_obj_ptrs[2+(object_number-EXTENDED_OBJECT_START)*3] = std::stoi(std::string(object_addr.begin(),object_addr.begin()+2), &pos, 16);
                                extended_obj_ptrs[1+(object_number-EXTENDED_OBJECT_START)*3] = std::stoi(std::string(object_addr.begin()+2,object_addr.begin()+4), &pos, 16);
                                extended_obj_ptrs[0+(object_number-EXTENDED_OBJECT_START)*3] = std::stoi(std::string(object_addr.begin()+4,object_addr.begin()+6), &pos, 16);

                                extended_word_params[1+(object_number-EXTENDED_OBJECT_START)*2] = (word_parameter>>8)&0xFF;
                                extended_word_params[0+(object_number-EXTENDED_OBJECT_START)*2] = word_parameter&0xFF;
                            }
                            else
                            {
                                standard_obj_ptrs[2+object_number*3] = std::stoi(std::string(object_addr.begin(),object_addr.begin()+2), &pos, 16);
                                standard_obj_ptrs[1+object_number*3] = std::stoi(std::string(object_addr.begin()+2,object_addr.begin()+4), &pos, 16);
                                standard_obj_ptrs[0+object_number*3] = std::stoi(std::string(object_addr.begin()+4,object_addr.begin()+6), &pos, 16);

                                standard_word_params[1+object_number*2] = (word_parameter>>8)&0xFF;
                                standard_word_params[0+object_number*2] = word_parameter&0xFF;
                            }
                        }
                }
            }
            // TODO - tooltips
            // if(generate_map16)
            // {
            //     std::string sprite_tooltip_path = tool_folder+"sprites/"+std::string(sprite_filename.begin(), sprite_filename.begin()+sprite_filename.find_first_of(".")+1)+"json";
            //     std::ifstream ifs(sprite_tooltip_path);
            //     if(!(!ifs))
            //     {
            //         std::string e;
            //         if(verbose)
            //             fmt::println("Parsing tooltip information for {}...", sprite_filename);
            //         nlohmann::json sprite_tooltip = nlohmann::json::parse(ifs, nullptr, false);
            //         if(sprite_tooltip.is_discarded())
            //         exit(error("A problem occurred while parsing {}. Please ensure the file isn't corrupted and has a valid JSON format.", sprite_tooltip_path));
            //         if(!map16.deserialize_json(sprite_tooltip, &e))
            //         exit(error("A problem occurred while parsing specific tooltips for {}. Details:\n{}", sprite_tooltip_path, e));
            //         e = "";
            //         if(!map16.write_tooltip(sprite_number, &e))
            //             exit(error("A problem has ocurred while generating tooltips for {}. Details:\n{}", sprite_tooltip_path, e));
            //         else if(verbose)
            //             fmt::println("Done.");
            //     }
            //     else if(verbose)
            //         fmt::println("{} has no tooltip information.", sprite_filename);
            // }
            if(verbose)
                fmt::println("-----------------------------------------------------------");
            if(inserting_extended)
                ++extended_obj_count;
            else
                ++standard_obj_count;
        }
        catch(std::invalid_argument const & err)
        {
            exit(error("Error parsing the list file: duplicate object number\n  {}\n", dirty_object));
        }
        catch(std::out_of_range const & err)
        {
            fmt::println("{}", err.what());
            exit(error("Error parsing the list file: incorrect object number\n  {}\n", dirty_object));
        }
    }

    fmt::println("{} standard objects inserted.", standard_obj_count);
    std::ofstream(tool_folder+"asm/standard_ptrs.bin", ios::binary).write((char *)standard_obj_ptrs, 0x100*3);
    std::ofstream(tool_folder+"asm/standard_word_params.bin", ios::binary).write((char *)standard_word_params, 0x100*2);

    fmt::println("{} extended objects inserted.\n{}", extended_obj_count, verbose ? "===========================================================" : "");
    std::ofstream(tool_folder+"asm/extended_ptrs.bin", ios::binary).write((char *)extended_obj_ptrs, EXTENDED_OBJECT_SIZE*3);
    std::ofstream(tool_folder+"asm/extended_word_params.bin", ios::binary).write((char *)extended_word_params, EXTENDED_OBJECT_SIZE*2);

    // Objects patch
    full_patch.append
    (
        std::format
        (
"\
standard_word_params = ${1}|!bank \n\
extended_word_params = ${1}|!bank+512 \n\
incsrc \"{2}asm/main.asm\"\n\n\
standard_object_ptrs:\n\
    incbin standard_ptrs.bin\n\n\
org ${1}\n\
    incbin standard_word_params.bin\n\
    incbin extended_word_params.bin\n\
org extended_object_ptrs+(${0:0>2X}*3)\n\
    incbin extended_ptrs.bin\n\
",
            EXTENDED_OBJECT_START,
            word_param_addr,
            tool_folder
        )
    );

    if(!rom.inline_patch(tool_folder, full_patch.c_str()))
    {
        if(verbose)
        {
            auto system_prints = asar_getprints(&asar_errcount);
            for(int i=0;i<asar_errcount;++i)
                fmt::println("Captured print while inserting ObjecTool: {}", system_prints[i]);
        }
        exit(error("Something went wrong while applying ObjecTool. Details:\n  {}", asar_geterrors(&asar_errcount)->fullerrdata));
    }

    // Done
    fmt::println("All objects inserted successfully!");
    rom.done();
    // map16.done(std::string(rom_name+".s16ov").c_str());

    if(!cleanup(tool_folder))
        exit(error("Error cleaning up temporary files. Exiting... (Your ROM was still saved anyway)"));
    #if defined(_WIN32)
        std::system("pause");
    #else
        printf("Press Enter to continue");
        getchar();
    #endif
    exit(0);
}

