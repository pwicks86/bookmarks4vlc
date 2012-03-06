# bookmarks4vlc #
A simple bookmarks extension for VLC.

## Why? ##
VLC claims to have a bookmark system, but it doesn't work (see [here][http://wiki.videolan.org/How_to_save_bookmarks]. This is a lua extension for VLC that implements a simple bookmarking system that actually works (at least for the simple use cases that I use it for)

## Installation ##
Put bookmarks4vlc.lua in your VLC extension folder. Generally, this is _VLC Directory_/VLC/lua/extensions

## Known bugs/issues ##
* bookmarks4vlc currently tracks items by absolute path, so if a file is moved then the associated bookmark won't work
* bookmarks4vlc has limited capability for saving bookmarks in DVDs. Bookmarks will work within a title, but only while that title is playing.
* Currently broken on OS X
