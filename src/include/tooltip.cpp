#include "tooltip.h"

#include "misc.h"

namespace fs = std::filesystem;
using ios = std::ios;

// I/O functions

/*
    destroy_tooltip(std::string filename) -> void: delete object tooltip files
    ---
    Input:
    * filename is the ROM filepath+name (no extension)

    Output:
    * object tooltip files erased from disk (if they existed)
*/
bool destroy_tooltip(std::string filename)
{
    try
    {
        if(fs::exists(filename+".osc"))
            fs::remove(filename+".osc");
        if(fs::exists(filename+".mw0t"))
            fs::remove(filename+".mw0t");
        if(fs::exists(filename+".mw0"))
            fs::remove(filename+".mw0");

        return true;
    }
    catch(fs::filesystem_error const & err)
    {
        fmt::println("There was an error deleting the existing Tooltip files. Details: {}", err.code().message());
        return false;
    }
}

/*
    open_mw0(const char* filename) -> void: open .mw0
    ---
    Input:
    * filename is the ROM filepath+name (no extension)

    Output:
    * mw0 is now an ifstream with the raw object display data
*/
void Tooltip::open_mw0(const char* filename, const char* append)
{
    std::ofstream(filename, ios::app).write("", 0);
    if(append != "")
    {
        std::ifstream append_mw0(append, ios::binary);
        if(!append_mw0)
            exit(error("Couldn't open mw0 file {} for appending", append));

        mw0 = std::vector<unsigned char>(std::istream_iterator<unsigned char>(append_mw0), std::istream_iterator<unsigned char>());
        if(mw0.back() == 0xFF)
            mw0.pop_back();
    }
    else
        mw0 = {0x00, 0x00, 0x00, 0x00, 0x00};
}

/*
    open_mw0t(const char* filename) -> void: open .mw0t
    ---
    Input:
    * filename is the ROM filepath+name (no extension)

    Output:
    * mw0t is now an ifstream with the custom object list data
*/
void Tooltip::open_mw0t(const char* filename, const char* append)
{
    std::ofstream(filename, ios::app).write("", 0);

    mw0t = std::ofstream(filename, ios::app);
    if(append != "")
    {
        std::ifstream append_mw0t(append);
        if(!append_mw0t)
            exit(error("Couldn't open mw0t file {} for appending", append));

        for(std::string next; std::getline(append_mw0t, next);)
            mw0t.write(next.c_str(), next.size());
        mw0t.write("\n", 1);
    }
}

/*
    open_osc(const char* filename) -> void: open .osc
    ---
    Input:
    * filename is the ROM filepath+name (no extension)

    Output:
    * osc is now an ifstream with the custom object tooltip data
*/
void Tooltip::open_osc(const char* filename, const char* append)
{
    std::ofstream(filename, ios::app).write("", 0);

    osc = std::ofstream(filename, ios::app);
    if(append != "")
    {
        std::ifstream append_osc(append);
        if(!append_osc)
            exit(error("Couldn't open osc file {} for appending", append));

        for(std::string next; std::getline(append_osc, next);)
            osc.write(next.c_str(), next.size());
        osc.write("\n", 1);
    }
}

/*
    done(const char* filename) -> void: write .mw0 file to disk
    ---
    Input:
    * filename is the ROM filepath+name (no extension)
*/
void Tooltip::done(const char* filename)
{
    mw0.emplace_back(0xFF);
    std::ofstream(filename, ios::binary).write(reinterpret_cast<const char*>(mw0.data()), mw0.size());
}

// Tooltip functions

/*
    write_display_tooltip(bool passthrough, int object_number, std::string tooltip, bool extended, std::string* err_string) -> bool: Write object display tooltip
    ---
    Input:
    * passthrough indicates if this tooltip was passed through the list.
    * object_number is the object ID
    * tooltip is the string to write
    * extended indicates if this is an extended object
    * err_string is a pointer to a string to hold error data

    Output:
    * true in success, false otherwise
    * if false, err_string now contains the error info
*/
bool Tooltip::write_display_tooltip(bool passthrough, int object_number, std::string tooltip, bool extended, std::string* err_string)
{
    try
    {
        std::string write_tooltip;
        if(passthrough)
            write_tooltip = tooltip;
        else if(extended)
            write_tooltip = std::format(EXTENDED_DISPLAY_TOOLTIP, object_number, tooltip);
        else
            write_tooltip = std::format(STANDARD_DISPLAY_TOOLTIP, object_number, tooltip);
        osc.write(write_tooltip.c_str(), write_tooltip.size());

        return true;
    }
    catch(std::exception err)
    {
        (*err_string).append(err.what());
        return false;
    }
}

/*
    write_list_tooltip(bool passthrough, int object_number, std::string tooltip, std::string* err_string) -> bool: Write object list tooltip
    ---
    Input:
    * passthrough indicates if this tooltip was passed through the list.
    * object_number is the object ID
    * tooltip is the string to write
    * extended indicates if this is an extended object
    * err_string is a pointer to a string to hold error data

    Output:
    * true in success, false otherwise
    * if false, err_string now contains the error info
*/
bool Tooltip::write_list_tooltip(bool passthrough, int object_number, std::string tooltip, bool extended, std::string* err_string)
{
    std::string write_tooltip = passthrough ? tooltip : std::format(LIST_TOOLTIP, object_number, tooltip);
    try
    {
        mw0t.write(write_tooltip.c_str(), write_tooltip.size());
        if(extended)
            mw0.insert(mw0.end(), { 0x87, 0x07, static_cast<unsigned char>(object_number) });
        else
            mw0.insert(mw0.end(), { 0xC7, 0xD7, 0x00, static_cast<unsigned char>(object_number), 0x00 });

        return true;
    }
    catch(std::exception err)
    {
        (*err_string).append(err.what());
        return false;
    }
}

bool Tooltip::write_both_tooltips_from_defines
(
    std::map<std::string, std::string> object_defines,
    int object_number,
    bool inserting_extended,
    int word_parameter,
    std::string* object_display_tooltip,
    std::string* object_list_tooltip,
    std::string* err_string
)
{
    for(auto& [define_name, define_value] : object_defines)
    {
        bool tooltip_defined = false;
        bool list_defined = false;

        if(define_name.starts_with("tooltip") && !tooltip_defined)
        {
            if( define_name == std::format("tooltip_{:0>4X}", word_parameter) )
            {
                *object_display_tooltip = define_value;
                tooltip_defined = true;
            }
            else if(define_name == "tooltip")
                *object_display_tooltip = define_value;
        }
        else if(define_name.starts_with("list") && !list_defined)
        {
            if( define_name == std::format("list_{:0>4X}", word_parameter) )
            {
                *object_list_tooltip = define_value;
                list_defined = true;
            }
            else if(define_name == "list")
                *object_list_tooltip = define_value;
        }
    }

    const char* obj = inserting_extended ? "extended" : "standard";

    *err_string = std::format("A problem has ocurred while generating display tooltips for {} object {:0>2X} - details:\n", obj, object_number);
    if(!write_display_tooltip(false, object_number, *object_display_tooltip, inserting_extended, err_string))
        return false;

    *err_string = std::format("A problem has ocurred while generating list displays for {} object {:0>2X} - details:\n", obj, object_number);
    if(!write_list_tooltip(false, object_number, *object_list_tooltip, inserting_extended, err_string))
        return false;

    return true;
}

