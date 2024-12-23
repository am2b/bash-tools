#!/usr/bin/env bash

#=tmux
#@tmux命令集

help_info()
{
cat << EOF
-h print this [h]elp

session:
-s -s new session or attach if the session-name already exists
-s -d [d]etach current client
-s -l [l]ist sessions
-s -r [r]ename session
-s -k [k]ill session and detaching all clients attached to it
-s -a kill the tmux clients and destroy [a]ll sessions

window:
-w -w create a new [w]indow
-w -p go to [p]revious window
-w -n go to [n]ext window
-w -l go to [l]ast window
-w -s [s]elect window by name or by number
-w -r [r]ename window
-w -c [c]lose window

pane:
-p -r split a new pane on [r]ight
-p -d split a new pane on [d]own
-p -i split a new pane on r[i]ght,and specify a percentage(%) of the available space
-p -o split a new pane on d[o]wn,and specify a percentage(%) of the available space
-p -z toggle between [z]oomed and unzoomed
-p -b break the current pane off from its containing window,and make it the only pane into a new window
-p -c [c]lose current pane
EOF
}

#session
new_or_attach_session()
{
    local session_name="$1"
    tmux new-session -A -s "$session_name"
}

detach_client()
{
    tmux detach-client
}

list_sessions()
{
    tmux list-sessions
}

rename_session()
{
    local session_new_name="$1"
    tmux rename-session "$session_new_name"
}

kill_session()
{
    local session_name="$1"
    tmux kill-session -t "$session_name"
}

kill_clients_and_sessions()
{
    tmux kill-server
}

process_session()
{
    local option="$1"
    local session_name="$2"

    case "$option" in
        "-s") new_or_attach_session "$session_name";;
        "-d") detach_client;;
        "-l") list_sessions;;
        "-r") rename_session "$session_name";;
        "-k") kill_session "$session_name";;
        "-a") kill_clients_and_sessions;;
        *) help_info && exit 1;;
    esac
}

#window
new_window()
{
    local window_name="$1"
    tmux new-window -n "$window_name"
}

prev_window()
{
    tmux previous-window
}

next_window()
{
    tmux next-window
}

last_window()
{
    tmux last-window
}

select_window()
{
    local window_name_or_num="$1"
    tmux select-window -t "$window_name_or_num"
}

rename_window()
{
    local window_new_name="$1"
    tmux rename-window "$window_new_name"
}

close_window()
{
    tmux confirm-befor -p "kill window #W? (y/N)" kill-window
}

process_window()
{
    local option="$1"
    local window_name_or_num="$2"

    case "$option" in
        "-w") new_window "$window_name_or_num";;
        "-p") prev_window;;
        "-n") next_window;;
        "-l") last_window;;
        "-s") select_window "$window_name_or_num";;
        "-r") rename_window "$window_name_or_num";;
        "-c") close_window;;
        *) help_info && exit 1;;
    esac
}

#pane
new_right_pane()
{
    tmux split-window -h -d
}

new_down_pane()
{
    tmux split-window -v -d
}

new_right_pane_by_percentage()
{
    local percentage="$1"
    if [[ -z "$percentage" ]]; then
        percentage=30%
    fi

    tmux split-window -h -l "$percentage"
}

new_down_pane_by_percentage()
{
    local percentage="$1"
    if [[ -z "$percentage" ]]; then
        percentage=30%
    fi

    tmux split-window -v -l "$percentage"
}

toggle_zoom_pane()
{
    tmux resize-pane -Z
}

break_pane()
{
    tmux break-pane
}

close_pane()
{
    tmux kill-pane
}

process_pane()
{
    local option="$1"
    local size="$2"

    case "$option" in
        "-r") new_right_pane;;
        "-d") new_down_pane;;
        "-i") new_right_pane_by_percentage "$size";;
        "-o") new_down_pane_by_percentage "$size";;
        "-z") toggle_zoom_pane;;
        "-b") break_pane;;
        "-c") close_pane;;
        *) help_info && exit 1;;
    esac
}

main()
{
    local parent_option="$1"
    local child_option="$2"
    #session name
    #or
    #window name or number
    #or
    #pane size
    local name_or_number_or_size="$3"

    case "$parent_option" in
        "-h") help_info;;

        "-s") process_session "$child_option" "$name_or_number_or_size";;

        "-w") process_window "$child_option" "$name_or_number_or_size";;

        "-p") process_pane "$child_option" "$name_or_number_or_size";;

        *) help_info && exit 1;;
    esac
}

#$1:parent_option
#$2:child_option
#$3:session name or window name or window number or pane size
main "$1" "$2" "$3"
