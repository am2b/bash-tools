#!/usr/bin/env bash

#=tools
#@合成密码后,存储于~/.password

password_file="${HOME}/repos/safedata/password.txt"
if ! [ -f "$password_file" ]; then
    password_file="${HOME}/password.txt"
    if ! [ -f "$password_file" ]; then
        echo "$password_file" does not exist && exit 1
    fi
fi

read -r public_password < "$password_file"

read -r -s -p 'Main passowrd:' main_password

echo 'Main password length:' "${#main_password}"

read -r -n 1 -p "Proceed?[Y/n]" proceed
echo
case "$proceed" in
    'y'|'Y'|'');;
    *)
        exit
        ;;
esac

read -r -p 'First salt index:' first_index
read -r -p 'Second salt index:' second_index

main_password_length_1="$first_index"
main_password_length_2=$((${#main_password} - first_index))
main_password_split_1="${main_password:0:$main_password_length_1}"
main_password_split_2="${main_password:$main_password_length_1:$main_password_length_2}"

public_password_length="${#public_password}"
public_password_length_1="$first_index"
public_password_length_2=$((second_index - 2 * main_password_length_1))
public_password_length_3=$((public_password_length - public_password_length_1 - public_password_length_2))
public_password_split_1="${public_password:0:$public_password_length_1}"
public_password_split_2="${public_password:$first_index:$public_password_length_2}"
public_password_split_3="${public_password:$((public_password_length_1 + public_password_length_2)):public_password_length_3}"

password="${public_password_split_1}""${main_password_split_1}""${public_password_split_2}""${main_password_split_2}""${public_password_split_3}"

echo "$password" > "${HOME}"/.password

if [ -f "${HOME}"/password.txt ]; then
    rm "${HOME}"/password.txt
fi
