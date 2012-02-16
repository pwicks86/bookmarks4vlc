 --[[
Bookmarks for vlc that actually work! 
 ]]

-- load the table serialization stuff
--dofile( "table.save-1.0.lua" )

--global variables
dialog = nil                                --dialog box
blist = nil -- the list of bookmarks
add_button = nil -- Add Bookmark button

debug_label = nil

-- Script descriptor, called when the extensions are scanned
function descriptor()
    return { title = "VLC Bookmarks" ;
             version = "1.0" ;
             author = "Paul Wicks" ;
             url = 'http://google.com';
             shortdesc = "Bookmarks!";
             description = "<center><b>Bookmarks for VLC</b></center><br />"
                        .. "Save your place in a movie!" ;
             capabilities = { "input-listener" } }
end

-- First function to be called when the extension is activated
function activate()
    create_dlg()
end

-- col, row, col_span, row_span, width, heighte

-- Create the main dialog with a simple search bar
function create_dlg()
    dialog = vlc.dialog("Bookmarks")
    debug_label = dialog:add_label("debug label",1,3,1,1)
    dialog:add_label("Current Bookmarks", 1, 1, 1, 1)
    blist = dialog:add_list(2,1,1,2)
    add_button = dialog:add_button("Add Bookmark",add_bookmark,1,2,1,1)
    --local item = vlc.input.item()
    --text = dialog:add_text_input(item and item:name() or "", 2, 1, 1, 1)
    --dialog:add_button("Search", search, 3, 1, 1, 1)
    dialog:show()
end

function dbgmsg(x)
    vlc.osd.message(x,channel1)
    debug_label:set_text(x)
end

function add_bookmark()
    --dbgmsg(get_filename())
    dbgmsg(get_position())
end

function get_uri()
    local item = vlc.input.item()
    return item:uri()
end

function get_name()
    local item = vlc.input.item()
    return item:name()
end

function get_position()
    local item = vlc.object.input
    local curtime = vlc.var.get(input, "time")
    return curtime

end

-- Get clean title from filename
function get_title()
    local item = vlc.item or vlc.input.item()
    if not item then
        return ""
    end
    local metas = item:metas()
    if metas["title"] then
        return metas["title"]
    else
        local filename = string.gsub(item:name(), "^(.+)%.%w+$", "%1")
        return filename
        --return trim(filename or item:name())
    end
end

-- Remove leading and trailing spaces
function trim(str)
    if not str then return "" end
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

