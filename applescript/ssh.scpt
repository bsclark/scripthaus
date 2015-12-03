#set hostnames to {"host1", "host2", "host3"}

set theName to the text returned of 
  (display dialog "Hostnames to SSH into: " default answer "")
display dialog theName

#activate application "iTerm"

#tell application "iTerm"
#    activate

#    -- ssh in split panes to my queue processor hosts
#    set myterm to (make new terminal)
#    tell myterm
#        launch session "Default Session"

#        -- make the window fullscreen
#        tell i term application "System Events" to key code 36 using command down

#        -- split horizontally
#        tell i term application "System Events" to keystroke "D" using command down
#        -- move to upper split
#        tell i term application "System Events" to keystroke "[" using command down

#        set num_hosts to count of hostnames

#        repeat with n from 1 to num_hosts
#            if n - 1 is num_hosts / 2 then
#                -- move to lower split
#                tell i term application "System Events" to keystroke "]" using command down
#            else if n > 1 then
#                -- split vertically
#               tell i term application "System Events" to keystroke "d" using command down
#            end if
#            delay 1
#            tell the current session to write text "ssh " & (item n of hostnames)
#        end repeat
#    end tell

#end tell

# Resources/References
# https://gist.github.com/seyhunak/04c8d84a25676d53b3a4
# https://github.com/TomAnthony/itermocil
# http://alvinalexander.com/blog/post/mac-os-x/applescript-add-textfield-dialog