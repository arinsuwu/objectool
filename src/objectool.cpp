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

#include "include/misc.h"
#include "include/tooltip.h"
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

    // Retry
    bool retry = rom.read<1>(0x008E5B) == 0x5C;
    bool retry_mmp = (rom.read<1>(OBJECTOOL_SIGNATURE_PTR+4) == 0x5C) && (rom.read<2>(rom.read<3>(0x0DA104+1, true)-3, true) == 0x1337);

    /*
        Actual tool execution
    */
    // Figure out whether the tool's been used and clean-up if so
    if(rom.read<2>(OBJECTOOL_SIGNATURE_PTR, true)==MAGIC_CONSTANT)
    {
        if(verbose)
            fmt::println("Performing clean-up of a previous execution...");
        if(!destroy_tooltip(rom_name))
            exit(error("Error cleaning up existing object tooltip files. Exiting..."));

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
            !{{inserted_<routine_name>}} #= 1\n\
            !routine_inserted            #= 1\n\
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
    unsigned char * standard_obj_ptrs = new unsigned char[0x100*3];
    unsigned char * extended_obj_ptrs = new unsigned char[EXTENDED_OBJECT_SIZE*3];

    // Arrays for word parameters
    unsigned char * standard_word_params = new unsigned char[0x100*2];
    unsigned char * extended_word_params = new unsigned char[EXTENDED_OBJECT_SIZE*2];

    for(int i=0;i<0x100;++i)
    {
        standard_obj_ptrs[i*3]   = 0x14;
        standard_obj_ptrs[1+i*3] = 0xA4;
        standard_obj_ptrs[2+i*3] = 0x0D;

        standard_word_params[i*2] = 0x00;
        standard_word_params[1+i*2] = 0x00;
    }

    for(int i=0;i<EXTENDED_OBJECT_SIZE;++i)
    {
        extended_obj_ptrs[i*3]   = 0x14;
        extended_obj_ptrs[1+i*3] = 0xA4;
        extended_obj_ptrs[2+i*3] = 0x0D;

        extended_word_params[i*2] = 0x00;
        extended_word_params[1+i*2] = 0x00;
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

    auto word_param_print = asar_getprints(&asar_errcount);
    std::string word_param_addr(word_param_print[0]);

    // Objects
    int standard_obj_count = 0;
    int extended_obj_count = 0;
    bool inserting_extended = false;
    bool display_mode = false;
    bool writing_tooltip = false;

    Tooltip tooltip;
    if(generate_tooltip)
    {
        tooltip.open_osc(std::string(rom_name+".osc").c_str());
        tooltip.open_mw0t(std::string(rom_name+".mw0t").c_str());
        tooltip.open_mw0(std::string(rom_name+".mw0").c_str());
    }

    // Object and list assembly
    std::string e;
    std::vector< std::tuple< std::string, int, bool, std::map<std::string, std::string> > > inserted_objects;
    for(std::string dirty_object; std::getline(list, dirty_object);)
    {
        std::size_t pos {};
        std::string object = dirty_object;

        if(display_mode)
        {
            std::string clean_obj;
            try
            {
                clean_obj = object.substr(object.find_first_not_of("\t "));
                clean_obj = clean_obj.substr(0, 1+clean_obj.find_last_not_of("\t "));
                clean_obj = clean_obj.substr(clean_obj.find_first_not_of("\t "), std::string::npos-object.find_last_not_of("\t "));
            }
            catch(...)
            {
                clean_obj = "";
            }

            if(clean_obj == "@osc" || clean_obj == "@mw0t")
            {
                writing_tooltip = clean_obj == "@osc";
                continue;
            }
            if(clean_obj == "EXTENDED:" || clean_obj == "STANDARD:")
            {
                inserting_extended = clean_obj == "EXTENDED:";
                continue;
            }

            if(writing_tooltip)
            {
                if(!tooltip.write_display_tooltip(true, -1, object, false, &e))
                    exit(error("An error occurred while writing to the osc file: {}", e));
            }
            else
            {
                int object_number;
                try
                {
                    object_number = std::stoi(object, &pos, 16);
                    if(object_number<0x00 || object_number>0xFF) throw std::out_of_range("");
                }
                catch(...)
                {
                    object_number = 0x00;
                }
                if(!tooltip.write_list_tooltip(true, object_number, object, inserting_extended, &e))
                    exit(error("An error occurred while writing to the mw0t file: {}", e));
            }
        }
        else
        {
            try
            {
                if(object.find_first_not_of("\t ")==std::string::npos) continue;

                object = object.substr(object.find_first_not_of("\t "));

                if(object.starts_with(";")) continue;

                object = object.substr(0, 1+object.find_last_not_of("\t "));

                std::string clean_obj = object.substr(object.find_first_not_of("\t "), std::string::npos-object.find_last_not_of("\t "));
                if(clean_obj == "@osc" || clean_obj == "@mw0t")
                {
                    display_mode = true;
                    writing_tooltip = clean_obj == "@osc";
                    inserting_extended = false;
                    continue;
                }
                if(clean_obj == "EXTENDED:" || clean_obj == "STANDARD:")
                {
                    inserting_extended = clean_obj == "EXTENDED:";
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

                bool already_inserted = false;
                for(std::tuple< std::string, int, bool, std::map<std::string, std::string> > inserted_object : inserted_objects)
                {
                    std::string inserted_object_filename = std::get<0>(inserted_object);
                    int inserted_object_number = std::get<1>(inserted_object);
                    bool inserted_extended_object = std::get<2>(inserted_object);
                    std::map<std::string, std::string> inserted_object_defines = std::get<3>(inserted_object);

                    if(object_filename == inserted_object_filename)
                    {
                        if(inserting_extended)
                        {
                            ++extended_obj_count;
                            if(inserted_extended_object)
                            {
                                extended_obj_ptrs[2+(object_number-EXTENDED_OBJECT_START)*3] = extended_obj_ptrs[2+(inserted_object_number-EXTENDED_OBJECT_START)*3];
                                extended_obj_ptrs[1+(object_number-EXTENDED_OBJECT_START)*3] = extended_obj_ptrs[1+(inserted_object_number-EXTENDED_OBJECT_START)*3];
                                extended_obj_ptrs[0+(object_number-EXTENDED_OBJECT_START)*3] = extended_obj_ptrs[0+(inserted_object_number-EXTENDED_OBJECT_START)*3];
                            }
                            else
                            {
                                extended_obj_ptrs[2+(object_number-EXTENDED_OBJECT_START)*3] = standard_obj_ptrs[2+inserted_object_number*3];
                                extended_obj_ptrs[1+(object_number-EXTENDED_OBJECT_START)*3] = standard_obj_ptrs[1+inserted_object_number*3];
                                extended_obj_ptrs[0+(object_number-EXTENDED_OBJECT_START)*3] = standard_obj_ptrs[0+inserted_object_number*3];
                            }

                            extended_word_params[1+(object_number-EXTENDED_OBJECT_START)*2] = (word_parameter>>8)&0xFF;
                            extended_word_params[0+(object_number-EXTENDED_OBJECT_START)*2] = word_parameter&0xFF;
                        }
                        else
                        {
                            ++standard_obj_count;
                            if(inserted_extended_object)
                            {
                                standard_obj_ptrs[2+object_number*3] = extended_obj_ptrs[2+(inserted_object_number-EXTENDED_OBJECT_START)*3];
                                standard_obj_ptrs[1+object_number*3] = extended_obj_ptrs[1+(inserted_object_number-EXTENDED_OBJECT_START)*3];
                                standard_obj_ptrs[0+object_number*3] = extended_obj_ptrs[0+(inserted_object_number-EXTENDED_OBJECT_START)*3];
                            }
                            else
                            {
                                standard_obj_ptrs[2+object_number*3] = standard_obj_ptrs[2+inserted_object_number*3];
                                standard_obj_ptrs[1+object_number*3] = standard_obj_ptrs[1+inserted_object_number*3];
                                standard_obj_ptrs[0+object_number*3] = standard_obj_ptrs[0+inserted_object_number*3];
                            }

                            standard_word_params[1+object_number*2] = (word_parameter>>8)&0xFF;
                            standard_word_params[0+object_number*2] = word_parameter&0xFF;
                        }

                        std::string inserted_object_tooltip;
                        std::string inserted_object_list;

                        if(!tooltip.write_both_tooltips_from_defines(inserted_object_defines, object_number, inserting_extended, word_parameter, &inserted_object_tooltip, &inserted_object_list, &e))
                            exit(error("{}", e));

                        if(verbose)
                        {
                            fmt::println
                            (
                                "{} object {:0>2X} - {}\n    asm file already inserted (was {} object {:0>2X})",
                                inserting_extended ? "Extended" : "Standard",
                                object_number,
                                object_filename,
                                inserted_extended_object ? "extended" : "standard",
                                inserted_object_number
                            );
                            fmt::println("    Tooltip text: {}", inserted_object_tooltip);
                            fmt::println("    List info:    {}", inserted_object_list);
                            fmt::println("-----------------------------------------------------------");
                        }

                        already_inserted = true;
                        break;
                    }
                }
                if(already_inserted) continue;

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
                    if( retry_mmp && ( (object_number<0x42) || (object_number==0x50) || (object_number==0x51) ) ) throw std::out_of_range("");
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
    standard_word_params    = ${5}|!bank\n\
    extended_word_params    = ${5}|!bank+512\n\
    !objectool_version     #= {6}\n\
    !objectool_subversion  #= {7}\n\
    !word_param            #= {8}\n\
    \n\
    namespace {1}\n\
        freecode cleaned\n\
        incsrc {4}\n\
        !tooltip   ?= \"Object with filename {2}\"\n\
        !list      ?= \"{2}\"\n\
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
                        word_param_addr,
                        VERSION,
                        SUBVER,
                        word_parameter
                    )
                );

                std::string object_display_tooltip;
                std::string object_list_tooltip;
                if(!rom.inline_patch(tool_folder, object_patch.c_str()))
                    exit(error("Could not insert {} object {}. Details: {}\n", inserting_extended ? "extended" : "standard", object_filename, asar_geterrors(&asar_errcount)->fullerrdata));

                auto object_definedata = asar_getalldefines(&asar_errcount);
                int total_defines = asar_errcount;
                std::map<std::string, std::string> object_defines;
                for(int i=0;i<total_defines;++i)
                    object_defines[object_definedata[i].name] = object_definedata[i].contents;

                auto object_print = asar_getprints(&asar_errcount);
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

                if(!tooltip.write_both_tooltips_from_defines(object_defines, object_number, inserting_extended, word_parameter, &object_display_tooltip, &object_list_tooltip, &e))
                    exit(error("{}", e));

                if(verbose)
                {
                    fmt::println("    Tooltip text: {}", object_display_tooltip);
                    fmt::println("    List info:    {}", object_list_tooltip);
                }

                if(verbose)
                    fmt::println("-----------------------------------------------------------");

                inserted_objects.emplace_back
                (
                    std::tuple<std::string, int, bool, std::map<std::string, std::string>>
                    {
                        object_filename,
                        object_number,
                        inserting_extended,
                        object_defines
                    }
                );
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
                const char * retry = retry_mmp&(!inserting_extended) ? "If using Retry's Multiple Midway Points, standard objects 00-42, 50 and 51 are reserved." : "";
                exit(error("Error parsing the list file: incorrect object number\n  {}\n{}", dirty_object, retry));
            }
        }
    }

    fmt::println("{} standard objects inserted.", standard_obj_count);
    std::ofstream(tool_folder+"asm/standard_ptrs.bin", ios::binary).write(reinterpret_cast<const char*>(standard_obj_ptrs), 0x100*3);
    std::ofstream(tool_folder+"asm/standard_word_params.bin", ios::binary).write(reinterpret_cast<const char*>(standard_word_params), 0x100*2);

    fmt::println("{} extended objects inserted.\n{}", extended_obj_count, verbose ? "===========================================================" : "");
    std::ofstream(tool_folder+"asm/extended_ptrs.bin", ios::binary).write(reinterpret_cast<const char*>(extended_obj_ptrs), EXTENDED_OBJECT_SIZE*3);
    std::ofstream(tool_folder+"asm/extended_word_params.bin", ios::binary).write(reinterpret_cast<const char*>(extended_word_params), EXTENDED_OBJECT_SIZE*2);

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
    if(retry && !retry_mmp)
        fmt::println("If using Retry's Multiple Midway Points, please re-insert Retry (run UberASMTool again)!");
    rom.done();
    tooltip.done(std::string(rom_name+".mw0").c_str());

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

