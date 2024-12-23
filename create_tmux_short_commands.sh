#!/usr/bin/env bash

#=tmux
#@创建tmux的短小命令到~/.local/bin/下,以便于在命令行和rofi使用

shebang='#!/usr/bin/env bash'

tmux_path="$HOME"/.local/bin/tmux-tools

if ! [ -d "${tmux_path}" ]; then mkdir -p "${tmux_path}"; fi

#clear
rm "$tmux_path"/* 2> /dev/null

tmux_c=tmux_commands.sh

function write_shebang
{
    local scripts
    scripts=("$@")

    for name in "${scripts[@]}"; do
        echo "$shebang" >> "$name"
        echo >> "$name"
    done
}

cd "$tmux_path" || exit
#tmux session scripts names:
tmux_session_scripts=(_tsh _tsd _tsr _tsk _tsa)
#create tmux session scripts
write_shebang "${tmux_session_scripts[@]}"

echo "echo _tsh:print help info of tmux session tools" >> _tsh
echo "echo _tsd:[d]etach current client" >> _tsh
echo "echo _tsr:[r]ename session" >> _tsh
echo "echo _tsk:[k]ill session and detaching all clients attached to it" >> _tsh
echo "echo _tsa:kill the tmux clients and destroy [a]ll sessions" >> _tsh

#-s -s new session or attach if the session-name already exists
#echo "$tmux_c" -s -s '$1' >> _tss
echo "$tmux_c" -s -d >> _tsd
#echo "$tmux_c" -s -l >> _tsl
echo "$tmux_c" -s -r '$1' >> _tsr
echo "$tmux_c" -s -k '$1' >> _tsk
echo "$tmux_c" -s -a >> _tsa

#tmux window scripts names:
tmux_window_scripts=(_twh _tww _twp _twn _twl _tws _twr _twc)
#create tmux window scripts
write_shebang "${tmux_window_scripts[@]}"

echo "echo _twh:print help info of tmux window tools" >> _twh
echo "echo _tww:create a new [w]indow" >> _twh
echo "echo _twp:go to [p]revious window" >> _twh
echo "echo _twn:go to [n]ext window" >> _twh
echo "echo _twl:go to [l]ast window" >> _twh
echo "echo _tws:[s]elect window by name or by number" >> _twh
echo "echo _twr:[r]ename window" >> _twh
echo "echo _twc:[c]lose window" >> _twh

echo "$tmux_c" -w -w '$1' >> _tww
echo "$tmux_c" -w -p >> _twp
echo "$tmux_c" -w -n >> _twn
echo "$tmux_c" -w -l >> _twl
echo "$tmux_c" -w -s '$1' >> _tws
echo "$tmux_c" -w -r '$1' >> _twr
echo "$tmux_c" -w -c >> _twc

#tmux pane scripts names:
tmux_pane_scripts=(_tph _tpr _tpd _tpi _tpo _tpz _tpb _tpc)
#create tmux pane scripts
write_shebang "${tmux_pane_scripts[@]}"

echo "echo _tph:print help info of tmux pane tools" >> _tph
echo "echo _tpr:split a new pane on [r]ight" >> _tph
echo "echo _tpd:split a new pane on [d]own" >> _tph
echo "echo _tpi:split a new pane on r[i]ght,and specify a percentage\(%\) of the available space" >> _tph
echo "echo _tpo:split a new pane on d[o]wn,and specify a percentage\(%\) of the available space" >> _tph
echo "echo _tpz:toggle between [z]oomed and unzoomed" >> _tph
echo "echo _tpb:break the current pane off from its containing window,and make it the only pane into a new window" >> _tph
echo "echo _tpc:[c]lose current pane" >> _tph

echo "$tmux_c" -p -r >> _tpr
echo "$tmux_c" -p -d >> _tpd
echo "$tmux_c" -p -i '$1' >> _tpi
echo "$tmux_c" -p -o '$1' >> _tpo
echo "$tmux_c" -p -z >> _tpz
echo "$tmux_c" -p -b >> _tpb
echo "$tmux_c" -p -c >> _tpc

#executable
chmod 755 "$tmux_path"/*
