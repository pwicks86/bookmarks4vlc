 --[[
Bookmarks for vlc that actually work! 
 ]]

--global variables
dialog = nil --dialog box
bmarks_widget = nil --the list of bookmarks
add_button = nil --Add Bookmark button
go_button = nil --Go to Bookmark button
del_button = nil --Delete Bookmark button
clear_button = nil --Clear Bookmarks button

bookmark_table = {} --table to hold actual bookmarks

-- VLC defined callback functions --------------------------------------

-- Script descriptor, called when the extensions are scanned
function descriptor()
    return { title = "VLC Bookmarks" ;
             version = "1.0" ;
             author = "Paul Wicks" ;
             url = 'http://pwicks.com/code/bookmarks4vlc';
             shortdesc = "Bookmarks!";
             description = "<center><b>Bookmarks for VLC</b></center><br />"
                        .. "Save your place in a movie!" ;
             capabilities = {} }
end

-- First function to be called when the extension is activated
function activate()
    create_dlg()
    load_marks()
    update_gui_list()
end

-- Called when the function is deactivated
function deactivate()
end

-- End VLC defined callback functions ----------------------------------

-- GUI Setup and main callbacks ----------------------------------------

-- Create the main dialog
function create_dlg()
    dialog = vlc.dialog("Bookmarks")

    -- Gui positional args
    -- col, row, col_span, row_span, width, height

    dialog:add_label("Current Bookmarks", 2, 1, 1, 1)

    bmarks_widget = dialog:add_list(2,1,1,5)

    add_button = dialog:add_button("Add Bookmark",add_bookmark,1,2,1,1)
    go_button = dialog:add_button("Go To Selected Bookmark", go_to_mark,1,3,1,1)
    del_button = dialog:add_button("Delete Selected Bookmark(s)", del_bookmarks,1,4,1,1)
    clear_button = dialog:add_button("Clear All Bookmarks", clear_bookmarks,1,5,1,1)

    dialog:show()
end

-- Called when the Add Bookmark button is pressed
function add_bookmark()
    if not_stopped() then
        local cur_time = get_position()
        local video_name = get_name()
        local video_uri = get_uri()
        local mark = { time=cur_time, name=video_name, uri=video_uri}
        table.insert(bookmark_table, mark)
        update_gui_list()
    end
    write_marks() 
end

-- Called when the Go to Selected Bookmark button is pressed
function go_to_mark()
    vlc.msg.dbg("entered go to mark")
    -- Handle the case when there are no bookmarks
    if table_is_empty(bookmark_table) then
        vlc.msg.dbg("bookmarks_table is empty!")
        return
    end
    -- Ok, there are bookmarks, let's get the selected bookmark
    local mark_entry = bmarks_widget:get_selection()
    local index = get_first_index(mark_entry)
    local cur_mark = bookmark_table[index]

    -- Check if we are playing the right file and if not, switch to that file 
    -- Either way, once the right file is playing, go to the correct time
    vlc.msg.dbg("about to hit if in go_to_mark")
    if((not not_stopped()) or (get_uri() ~= cur_mark.uri)) then
        local new_playlist_item = {}
        vlc.msg.dbg("path of item to be played: " .. cur_mark.uri)
        new_playlist_item.path = cur_mark.uri
        new_playlist_item.name = cur_mark.name
        new_playlist_item.options = {}
        table.insert(new_playlist_item.options, "start-time="..cur_mark.time)
        vlc.playlist.add({new_playlist_item})
    else
        go_to_time(cur_mark.time)
    end
end

-- Called when the delete bookmark(s) button is pressed
function del_bookmarks()
    local selected_marks = bmarks_widget:get_selection()
    for i,v in pairs(selected_marks) do
        table.remove(bookmark_table, i)
    end
    update_gui_list()
    write_marks()
end

-- Called when the clear bookmarks button is presse. Deletes the entire bookmarks list
function clear_bookmarks()
    bookmark_table = {}
    update_gui_list()
    write_marks()
end

-- End GUI Setup and main callbacks -------------------------------------

-- VLC specific functions -----------------------------------------------

-- Return true if the player is playing or paused
function not_stopped()
    return vlc.playlist.status() == ("playing" or "paused")
end

-- Given a time in seconds, go to that time in the currently playing file
function go_to_time(seconds)
    local input = vlc.object.input()
    vlc.var.set(input, "time", seconds)
end

-- Get the uri of the currently playing item
function get_uri()
    local item = vlc.input.item()
    return item:uri()
end

-- Get the name of the currently playing item
function get_name()
    local item = vlc.input.item()
    return item:name()
end

-- Get the current time for the currently playing item
function get_position()
    -- Thanks to Rob Williams for this
    local input = vlc.object.input()
    local curtime = vlc.var.get(input, "time")
    return curtime
end

-- End VLC specific functions -------------------------------------------

-- Bookmark related functions -----------------------------------------

-- Load any available bookmarks
function load_marks()
    local mpath = get_mark_path()
    local mark_file = io.open(mpath, "r")
    if (mark_file ~= nil) then
        local num_marks = mark_file:read() 
        local mark_to_insert = {}
        local mark_i = 0
        for i = 0, num_marks - 1 do
            mark_i = mark_file:read()
            mark_to_insert.time = mark_file:read() + 0 -- Need to add 0 to convert to number
            mark_to_insert.name = mark_file:read()
            mark_to_insert.uri = mark_file:read()
            --bookmark_table[mark_i] = mark_to_insert
            table.insert(bookmark_table, mark_to_insert)
            mark_to_insert = {}
        end
    end
end

-- Persist the bookmarks to disk
function write_marks() 
    vlc.msg.dbg("Writing out Bookwarks")
    local mpath = get_mark_path()
    local mark_file = io.open(mpath, "w")
    -- First write the total number of bookmarks
    mark_file:write(get_num_marks() .. "\n")
    -- Then write the actual bookmarks out
    for i,v in pairs(bookmark_table) do
        local line = i .. "\n" .. v.time .. "\n" .. v.name .. "\n" .. v.uri .. "\n"
        vlc.msg.dbg("Writing bookmark: " .. line)
        mark_file:write(line)
    end
    mark_file:close()
    vlc.msg.dbg("Completed writing bookmarks")
end

function get_num_marks()
    size = 0
    for k, v in pairs(bookmark_table) do
        size = size + 1
    end
    return size
end
    
function get_mark_path()
    local datadir = vlc.misc.userdatadir()
    local mpath = datadir .. get_path_seperator() .. "marks.txt"
    vlc.msg.dbg("Path to bookmarks file is: " .. mpath)
    return mpath
end

-- Update the gui mark list to be in sync with the backing table
function update_gui_list()
    bmarks_widget:clear()
    for i,v in pairs(bookmark_table) do
        bmarks_widget:add_value(get_time_str(v.time) .. " - " .. v.name, i)
    end
end

-- End Bookmark related functions -------------------------------------

-- Generic Lua utility functions ----------------------------------------

-- Return true if t is empty
function table_is_empty(t) 
    return table.maxn(t) == 0
end

-- Get the index of the first thing in a table (according to pairs)
function get_first_index(t)
    for i,v in pairs(t) do
        return i
    end
end

-- Returns true if we are running on windows
-- (Hacky)
function is_windows()
    local home_dir = vlc.misc.homedir()
    local first_char = string.sub(home_dir,1,1)
    return not(first_char == "/")
end

-- Returns the appropriate path seperators for the platform
function get_path_seperator()
    if (is_windows()) then
        return "\\"
    else
        return "/"
    end
end
 
-- Get secs as a nicely formatted string
function get_time_str(secs)
    if secs == 0 then
        return "00:00:00"
    else
        local h = string.format("%02.f", math.floor(secs/3600))
        local m = string.format("%02.f", math.floor(secs/60 - (h*60)))
        local s = string.format("%02.f", math.floor(secs - h*3600 - m *60))
        return h..":"..m..":"..s
    end
end

-- End Generic Lua utility functions ------------------------------------

