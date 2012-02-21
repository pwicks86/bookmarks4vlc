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


-- Script descriptor, called when the extensions are scanned
function descriptor()
    return { title = "VLC Bookmarks" ;
             version = "1.0" ;
             author = "Paul Wicks" ;
             url = 'http://pwicks.com/code/bookmarks4vlc';
             shortdesc = "Bookmarks!";
             description = "<center><b>Bookmarks for VLC</b></center><br />"
                        .. "Save your place in a movie!" ;
             capabilities = { "input-listener" } }
end

-- First function to be called when the extension is activated
function activate()
    create_dlg()
end

function deactivate()
    debug_msg("deactivated!")
end

-- col, row, col_span, row_span, width, heighte

-- Create the main dialog
function create_dlg()
    dialog = vlc.dialog("Bookmarks")

    dialog:add_label("Current Bookmarks", 2, 1, 1, 1)

    bmarks_widget = dialog:add_list(2,1,1,5)

    add_button = dialog:add_button("Add Bookmark",add_bookmark,1,2,1,1)
    go_button = dialog:add_button("Go To Selected Bookmark", go_to_mark,1,3,1,1)
    del_button = dialog:add_button("Delete Selected Bookmark(s)", del_bookmarks,1,4,1,1)
    clear_button = dialog:add_button("Clear Bookmarks", clear_bookmarks,1,5,1,1)
    dialog:show()
end

-- Called when the Add Bookmark button is pressed
function add_bookmark()
    --TODO: add error check here
    --go_to_time(get_position() + 10)
    local cur_time = get_position()
    local video_name = get_name()
    local video_uri = get_uri()
    local mark = { time=cur_time, name=video_name, uri=video_uri}
    table.insert(bookmark_table, mark)
    update_marks()
    --debug_msg(cur_time)
    -- temp
    --local pl = vlc.playlist.get("playlist",false)
    --debug_msg(pl)
end

-- Called when the Go to Selected Bookmark button is pressed
function go_to_mark()
    debug_msg("clicked go to mark")
    -- Handle the case when there are no bookmarks
    if table_is_empty(bookmark_table) then
        return
    end
    -- Ok, there are bookmarks, let's get the selected bookmark
    local mark_entry = bmarks_widget:get_selection()
    local index = get_first_index(mark_entry)
    local cur_mark = bookmark_table[index]

    -- Check if we are playing the right file and if not, switch to that file 
    -- Either way, once the right file is playing, go to the correct time
    if(get_uri() ~= cur_mark.uri) then
        local new_playlist_item = {}
        new_playlist_item.path = cur_mark.uri
        new_playlist_item.name = cur_mark.name
        new_playlist_item.options = {}
        table.insert(new_playlist_item.options, "start-time="..cur_mark.time)
        vlc.playlist.add({new_playlist_item})
    else
        go_to_time(cur_mark.time)
    end
end

function del_bookmarks()
end

function clear_bookmarks()
end

-- Update the mark list with the current marks
function update_marks()
    bmarks_widget:clear()
    for i,v in pairs(bookmark_table) do
        bmarks_widget:add_value(v.time .. " - " .. v.name, i)
    end
end

-- given a time in seconds, go to that time in the currently playing file
function go_to_time(seconds)
    local input = vlc.object.input()
    vlc.var.set(input, "time", seconds)
end

-- print a message to the screen
function debug_msg(x)
    vlc.osd.message(x,channel1)
end


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


--function input_changed()
    -- check if going to a bookmark has been deferred.
--end

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
