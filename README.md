## convenient:
### [clean_markdown_format_in_chatgpt.sh](clean_markdown_format_in_chatgpt.sh):<br>
clean up the markdown format in chatgpt<br>
usage:<br>
script.sh file<br>
pbpaste | script.sh | pbcopy

### [easy_to_type_mode.sh](easy_to_type_mode.sh):<br>
enter easy to type mode for typing like chinese<br>
usage:<br>
script.sh

### [find_alias.sh](find_alias.sh):<br>
find aliases for a command<br>
usage:<br>
script.sh command_name or alias_name

### [open_perl_doc_with_nvim.sh](open_perl_doc_with_nvim.sh):<br>
open perl doc with nvim -R

### [print_os_info.sh](print_os_info.sh):<br>
print os info

## git-branch:
### [git_backup_master_with_upstream.sh](git_backup_master_with_upstream.sh):<br>
备份master分支为master-backup,master-backup分支是跟踪分支

### [git_backup_master_without_upstream.sh](git_backup_master_without_upstream.sh):<br>
备份master分支为master-backup,master-backup分支不是跟踪分支

### [git_branch_fuzzy_jump.sh](git_branch_fuzzy_jump.sh):<br>
模糊跳转到某个分支

### [git_branch_status.sh](git_branch_status.sh):<br>
按类别打印分支的状态

### [git_create_branch_based_on_local_branch.sh](git_create_branch_based_on_local_branch.sh):<br>
基于本地仓库的某个分支,在本地创建一个新的分支并切换到该分支<br>
usage:<br>
script.sh local_branch new_branch<br>
无需提前切换到local_branch

### [git_create_branch_based_on_remote_branch.sh](git_create_branch_based_on_remote_branch.sh):<br>
基于远程仓库的某个分支,在本地创建一个新的分支并切换到该分支

### [git_create_branch_based_on_top_stash.sh](git_create_branch_based_on_top_stash.sh):<br>
基于stash栈顶端的条目创建一个新的分支并切换到该分支,然后删除stash栈顶端的条目

### [git_delete_branch.sh](git_delete_branch.sh):<br>
删除本地分支,本地的远程分支,远程仓库中的分支

### [git_rebase_branch_to_master.sh](git_rebase_branch_to_master.sh):<br>
usage:<br>
script.sh branch_name<br>
无需提前git checkout branch_name

### [git_rename_branch.sh](git_rename_branch.sh):<br>
重命名本地分支,本地的远程分支和远程仓库的分支

### [git_set_local_branch_to_track_a_upstream.sh](git_set_local_branch_to_track_a_upstream.sh):<br>
设置当前分支去跟踪一个远程分支,或者修改当前分支正在跟踪的上游分支

### [git_update_branch_from_master.sh](git_update_branch_from_master.sh):<br>
usage:<br>
script.sh branch<br>
当master包含了branch分支里面的所有提交,并且master还具有branch分支里面所没有的提交,这时候就可以根据master来更新branch分支

## git-clone:
### [git_clone.sh](git_clone.sh):<br>
在当前目录clone远程仓库

## git-commit:
### [git_squash_commits.sh](git_squash_commits.sh):<br>
压缩给定数量的提交为一个提交

## git-diff:
### [git_diff_branch_master.sh](git_diff_branch_master.sh):<br>
查看某个分支和master分支之间的差异(无需提前切换到"某个"分支)<br>
查看某个分支的某些文件和master分支之间的差异<br>
可以使用普通的diff,或通过-t选项调用difftool(例如nvimdiff)

### [git_diff_current_branch_master.sh](git_diff_current_branch_master.sh):<br>
查看当前分支和master分支之间的差异<br>
查看当前分支的某些文件和master分支之间的差异<br>
可以使用普通的diff,或通过-t选项调用difftool(例如nvimdiff)

### [git_diff_index_lastcommit.sh](git_diff_index_lastcommit.sh):<br>
查看暂存区和上次提交之间的差异

### [git_diff_lastcommit_beforelastcommit.sh](git_diff_lastcommit_beforelastcommit.sh):<br>
查看上次提交和上上次提交之间的差异

### [git_diff_workingtree_index.sh](git_diff_workingtree_index.sh):<br>
查看工作区和暂存区之间的差异<br>
注意:无法对untracked files进行比较

### [git_diff_workingtree_lastcommit.sh](git_diff_workingtree_lastcommit.sh):<br>
查看工作区和上次提交之间的差异

## git-libs:
### [git_build_url.sh](git_build_url.sh):<br>
构建GitHub仓库的https URL<br>
支持的输入格式:<br>
完整的https URL<br>
完整的ssh URL(将会被自动转换为https URL)<br>
username/reponame<br>
reponame

### [git_check.sh](git_check.sh):<br>
各种检查

### [git_get.sh](git_get.sh):<br>
各种get

## git-log:
### [git_log_file_or_dir.sh](git_log_file_or_dir.sh):<br>
打印给定文件或目录的log<br>
usage:<br>
script.sh file<br>
script.sh dir

### [git_log_graph.sh](git_log_graph.sh):<br>
看分支结构

### [git_log_num.sh](git_log_num.sh):<br>
打印给定数量的log

### [git_log_pattern_history.sh](git_log_pattern_history.sh):<br>
基于一个正则表达式来打印某个文件中一行代码或者一个函数的历史<br>
usage:<br>
script.sh /pattern/ file<br>
script.sh /function_name/ file

### [git_log_pickaxe_add_or_delete.sh](git_log_pickaxe_add_or_delete.sh):<br>
给定一个字符串,找到该字符串被添加或者删除的全部提交<br>
usage:<br>
script.sh "some_string"

### [git_log_pickaxe_changes.sh](git_log_pickaxe_changes.sh):<br>
给定一个字符串,找到该字符串被添加,删除,修改的全部提交<br>
usage:<br>
script.sh "some_string"

## git-push:
### [git_push_new_branch.sh](git_push_new_branch.sh):<br>
把本地新建的分支给push到远程仓库<br>
无需手动检出被push的分支

### [git_push_to_empty_repository.sh](git_push_to_empty_repository.sh):<br>
在本地新建了一个仓库,添加了一些提交,然后把这些提交给push到远程的空仓库

### [git_push_to_non_empty_repository.sh](git_push_to_non_empty_repository.sh):<br>
在本地新建了一个仓库,添加了一些提交,然后把这些提交给push到远程的非空仓库

## git-reset:
### [git_reset_HEAD.sh](git_reset_HEAD.sh):<br>
重置本地的HEAD到某个提交(回退到git commit之前,git add之后)

### [git_reset_HEAD_and_index.sh](git_reset_HEAD_and_index.sh):<br>
重置本地的HEAD到某个提交,然后用该提交来填充index(回退到git add之前,工作区被修改之后)

### [git_reset_HEAD_and_index_and_workingtree.sh](git_reset_HEAD_and_index_and_workingtree.sh):<br>
重置本地的HEAD到某个提交,然后用该提交来填充index和working tree(回退到工作区被修改之前,注意:工作区所做的修改全部被丢弃了,如果有创建目录,那么目录还在但是被清空了)

## git-stash:
### [git_stash_apply.sh](git_stash_apply.sh):<br>
应用stash，但是不删除栈上的条目

### [git_stash_drop.sh](git_stash_drop.sh):<br>
移除stash栈上的一个条目

### [git_stash_list.sh](git_stash_list.sh):<br>
查看stash栈

### [git_stash_pop.sh](git_stash_pop.sh):<br>
应用stash,然后删除栈上的条目

### [git_stash_workingtree_and_index.sh](git_stash_workingtree_and_index.sh):<br>
stash工作区的修改,和index的修改

### [git_stash_workingtree_and_index_and_untracked.sh](git_stash_workingtree_and_index_and_untracked.sh):<br>
stash工作区的修改,index的修改和未被跟踪的修改,但是没有stash被ignore的文件

## git-tag:
### [git_delete_tags.sh](git_delete_tags.sh):<br>
删除本地标签,同时删除远程仓库中的标签

### [git_retag.sh](git_retag.sh):<br>
重新打标签<br>
usage: script.sh tag_name

### [git_tag.sh](git_tag.sh):<br>
打标签<br>
usage: script.sh tag_name

## git-tools:
### [git_ggg.sh](git_ggg.sh):<br>
合并git status,diff,add,commit,push<br>
usage:script.sh "commit messages"

## git-tree:
### [git_add.sh](git_add.sh):<br>
add.sh:添加文件到git仓库<br>
支持以下选项和参数:<br>
-u:添加已跟踪的修改过的文件<br>
不加参数:添加所有跟踪和未跟踪的文件<br>
参数为文件路径时:添加指定路径的文件

### [git_discard_workingtree.sh](git_discard_workingtree.sh):<br>
用于丢弃工作区的修改,并恢复到上次提交或索引的状态

### [git_restore_workingtree_to_a_commit.sh](git_restore_workingtree_to_a_commit.sh):<br>
丢弃工作区的修改,然后用某个指定的提交来填充工作区,暂存区里面的状态没有被改变

### [git_unstage.sh](git_unstage.sh):<br>
add的逆操作,恢复到add之前的状态

## go:
### [go_list_installed.sh](go_list_installed.sh):<br>
列出安装在$GOPATH/bin/的工具

### [go_mod_init.sh](go_mod_init.sh):<br>
go mod init<br>
usage:<br>
-l:local<br>
cd project_root_dir && script.sh [-l]

## gpg:
### [gpg_encrypt_decrypt_file.sh](gpg_encrypt_decrypt_file.sh):<br>
使用gpg加密,解密某个文件<br>
usage:<br>
encrypt:<br>
script.sh -e file<br>
decrypt:<br>
script.sh -d file

### [gpg_encrypt_decrypt_string.sh](gpg_encrypt_decrypt_string.sh):<br>
使用gpg对称加密,解密一个字符串<br>
usage:<br>
encrypt:<br>
script.sh -e string<br>
decrypt:<br>
script.sh -d string

### [gpg_export_keys.sh](gpg_export_keys.sh):<br>
export public key and private key<br>
usage:<br>
script.sh

## install:
### [install_perl_package.sh](install_perl_package.sh):<br>
安装perl的常用库

## libs:
### [getoptions.sh](getoptions.sh):<br>
解析命令行参数<br>
"ab.c:d;"<br>
a后没有符号,那么a为bool选项<br>
b后跟一个点号,那么b有零个或一个参数值<br>
c后跟一个冒号,那么b有一个参数值<br>
d后跟一个分号,那么d有一个或多个参数值<br>
usage:<br>
parse_options "option string" "${@}"<br>
set -- "${SCRIPT_ARGUMENTS[@]}"<br>
shift "${SHIFT_VALUE}"<br>
选项参数:OPTIONS[opt]<br>
位置参数:"${@}"

## log:
### [log.sh](log.sh):<br>
日志系统<br>
usage:<br>
1:source BASH_TOOLS_LOG_SH<br>
2:enable log:call enable_log "$0"(default log dir:/tmp/log/bash-tools/)<br>
3.a:log_debug messages<br>
3.b:log_info messages<br>
3.c:log_warn messages<br>
3.d:log_error messages<br>
4:disable log:<br>
4.a:comment out the call to the function:enable_log<br>
or:<br>
4.b:comment out the:source log.sh

## mac:
### [mac_sleep.sh](mac_sleep.sh):<br>
退出音乐,照片和备忘录App,然后结束Amphetamine的当前会话,然后锁屏准备休眠<br>
usage:<br>
script.sh

## pack:
### [pack_local_origin_repository.sh](pack_local_origin_repository.sh):<br>
backup local origin repository<br>
usage:<br>
script.sh

### [pack_notes_database.sh](pack_notes_database.sh):<br>
backup notes database on mac<br>
usage:<br>
nohup script.sh > /tmp/notes.log 2>&1 &

### [pack_nvim_mason.sh](pack_nvim_mason.sh):<br>
pack the dir of ~/.local/share/nvim/mason/packages/ to ~/pack/

### [pack_nvim_plugins.sh](pack_nvim_plugins.sh):<br>
pack the dir of ~/.local/share/nvim/lazy/ to ~/pack/

### [pack_ohmyzsh.sh](pack_ohmyzsh.sh):<br>
pack the dir of ~/.oh-my-zsh to ~/pack/

### [pack_photo_library.sh](pack_photo_library.sh):<br>
backup photo library on mac<br>
usage:<br>
nohup script.sh > /tmp/photo.log 2>&1 &

## password:
### [keychain.sh](keychain.sh):<br>
add,update,delete password in keychain<br>
usage:<br>
note:<br>
service_name:网站域名/服务器名称/App名称<br>
account_name:注册时候的用户名/邮件地址<br>
add:<br>
keychain.sh -a --[or ,] service_name account_name 'password'<br>
update:<br>
keychain.sh -u --[or ,] service_name account_name 'new_password'<br>
delete:<br>
keychain.sh -d --[or ,] service_name account_name<br>
get:<br>
keychain.sh -g --[or ,] service_name account_name

### [totp.sh](totp.sh):<br>
generate totp(Time-Based One-Time Password)<br>
usage:<br>
totp.sh "totp_uri"

## python:
### [pip_clear_installed.sh](pip_clear_installed.sh):<br>
uninstall python packages,but do not delete requirements.txt

### [pip_freeze.sh](pip_freeze.sh):<br>
generate requirements.txt

### [pip_install.sh](pip_install.sh):<br>
make pip only execute in the virtual environment,and generate uninstall files

### [pip_uninstall.sh](pip_uninstall.sh):<br>
uninstall packages of pip based on package_name.unpip file

### [poetry_create_envrc.sh](poetry_create_envrc.sh):<br>
create .envrc in the current directory(created by poetry) for direnv<br>
usage:<br>
script.sh

### [poetry_modify_python_version.sh](poetry_modify_python_version.sh):<br>
读取.python-version,然后修改pyproject.toml里面的python版本<br>
usage:<br>
在项目根目录运行<br>
script.sh

### [pyenv_install_python.sh](pyenv_install_python.sh):<br>
通过pyenv安装python<br>
usage:<br>
script.sh 3.12.0<br>
script.sh 12<br>
script.sh 12.2

### [pyenv_list_available_versions.sh](pyenv_list_available_versions.sh):<br>
列出可以通过pyenv安装的python版本<br>
会对版本号进行筛选,可以接收用户输入的目标版本号,默认为3.10.0<br>
usage<br>
script.sh

### [python_create_directory_structure.sh](python_create_directory_structure.sh):<br>
create .envrc .gitignore and LICENSE<br>
usage:script.sh project_name

### [python_create_envrc.sh](python_create_envrc.sh):<br>
create .envrc in the current directory for direnv

### [python_jump_to_root_directory.sh](python_jump_to_root_directory.sh):<br>
从python项目的任意子目录跳转到根目录<br>
usage:source script.sh

### [python_sort_imports.sh](python_sort_imports.sh):<br>
sort import statements of python<br>
usage:<br>
一个脚本文件:<br>
sort_python_import.sh source.py<br>
多个脚本文件:<br>
sort_python_import.sh source1.py source2.py ...<br>
当前目录:<br>
sort_python_import.sh<br>
当前目录:<br>
sort_python_import.sh .<br>
其它目录:<br>
sort_python_import.sh dir

## telegram:
### [send_clipboard_to_telegram.sh](send_clipboard_to_telegram.sh):<br>
send the text in clipboard to telegram<br>
usage<br>
script.sh chat_partner_name

### [telegram_get_chat_id.sh](telegram_get_chat_id.sh):<br>
获取用户的chat_id<br>
usage:<br>
发送消息给某个bot<br>
script.sh TOKEN

## text:
### [text_belly.sh](text_belly.sh):<br>
读取文本文件,然后输出指定的行范围,其中第一个数字表示起始行,第二个数字表示需要显示的行数<br>
usage:<br>
script.sh text.txt 101 20

### [text_create_or_open_encrypted_file.sh](text_create_or_open_encrypted_file.sh):<br>
创建或者以只读模式打开一个加密的文本文件<br>
usage:<br>
script.sh encrypted_text_file

### [text_delete_blank_lines_at_the_end_of_file.sh](text_delete_blank_lines_at_the_end_of_file.sh):<br>
删除掉文本文件末尾的一行或多行空行<br>
usage:<br>
script.sh file.txt

### [text_insert_line_into_all_files.sh](text_insert_line_into_all_files.sh):<br>
给当前目录下的所有文本文件插入一行<br>
usage:<br>
script.sh 1 "插入第一行的内容"<br>
script.sh $ "插入最后一行的内容"

### [text_merge_empty_lines.sh](text_merge_empty_lines.sh):<br>
合并连续的空行,参数可以是一个/多个文件,一个/多个目录,或者文件与目录

### [text_parse_csv.sh](text_parse_csv.sh):<br>
parse csv file

### [text_parse_key_value_pairs.sh](text_parse_key_value_pairs.sh):<br>
parse key value pairs<br>
usage:<br>
script.sh key_value_file[.txt]

### [text_replace_chinese_punctuation_marks.sh](text_replace_chinese_punctuation_marks.sh):<br>
replace chinese punctuation marks<br>
usage:<br>
一个文件:<br>
replace_punctuation_marks.sh file<br>
多个文件:<br>
replace_punctuation_marks.sh file1 file2 ...<br>
当前目录:<br>
replace_punctuation_marks.sh<br>
当前目录:<br>
replace_punctuation_marks.sh .<br>
其它目录:<br>
replace_punctuation_marks.sh dir

## tmux:
### [create_tmux_layout.sh](create_tmux_layout.sh):<br>
create layout of session<br>
usage:script.sh session_name

### [create_tmux_short_commands.sh](create_tmux_short_commands.sh):<br>
创建tmux的短小命令到~/.local/bin/下,以便于在命令行和rofi使用

### [tmux_commands.sh](tmux_commands.sh):<br>
tmux命令集

## tools:
### [bak.sh](bak.sh):<br>
create a file/dir.bak from file/dir,or create a file/dir from file/dir.bak<br>
usage:<br>
bak.sh file/dir -> file/dir.bak<br>
bak.sh file/dir.bak -> file/dir

### [cat_files.sh](cat_files.sh):<br>
拼接文本文件<br>
usage:<br>
script.sh(默认当前目录)<br>
script.sh dir<br>
script.sh files

### [change_dir_like_cross.sh](change_dir_like_cross.sh):<br>
横向:在兄弟目录之间跳转<br>
纵向:在祖孙目录之间跳转(向上至\~或者/,向下受fd命令的--max-results选项限制)<br>
附近:在附近(向上至\~或者/,向下受fd命令的--max-results选项限制,以及每个祖先的兄弟目录)跳转:

### [change_dir_to_marker.sh](change_dir_to_marker.sh):<br>
cd to marker,which located in ~/.marker_dirs

### [chinese_characters_to_pinyin.sh](chinese_characters_to_pinyin.sh):<br>
将汉字转换为拼音,或拼音的首字母<br>
usage:<br>
转换为拼音:<br>
script.sh 汉字<br>
转换为拼音的首字母:<br>
script.sh -f 汉字

### [clear_subdirectory.sh](clear_subdirectory.sh):<br>
快速清空参数所给的子目录

### [clear_tmp.sh](clear_tmp.sh):<br>
clear $HOME/tmp

### [compare_dirs.sh](compare_dirs.sh):<br>
compare two dirs<br>
usage:<br>
script.sh dir1 dir2

### [copy_file_names.sh](copy_file_names.sh):<br>
copy filenames to general pasteboard<br>
usage:script.sh file1.sh file2.py file3.txt ...

### [count_files.sh](count_files.sh):<br>
报告当前目录下非隐藏文件,隐藏文件以及总文件数量

### [create_LICENSE_MIT.sh](create_LICENSE_MIT.sh):<br>
create a MIT license<br>
usage:<br>
script.sh github_name

### [create_layout_of_swift.sh](create_layout_of_swift.sh):<br>
create layout of swift command line

### [create_password.sh](create_password.sh):<br>
合成密码后,存储于~/.password

### [delete_old_files.sh](delete_old_files.sh):<br>
keep only the latest few files and delete the older ones<br>
usage:<br>
script.sh dir keep_num

### [dropbox_download_from_shared_link.sh](dropbox_download_from_shared_link.sh):<br>
下载dropbox的共享链接

### [dropbox_downloader.sh](dropbox_downloader.sh):<br>
download dir or file from dropbox<br>
usage:<br>
script.sh remote_path_to_dir_or_file

### [file_is_equal.sh](file_is_equal.sh):<br>
通过计算两个文件的sha256来判断两个文件是否相同

### [fuzzy_find_bash_tools.sh](fuzzy_find_bash_tools.sh):<br>
fuzzy find a bash script<br>
usage:<br>
source fuzzy_find_bash_tools.sh

### [fuzzy_find_git_tools.sh](fuzzy_find_git_tools.sh):<br>
fuzzy find a git script<br>
usage:<br>
source fuzzy_find_git_tools.sh

### [fuzzy_jump.sh](fuzzy_jump.sh):<br>
directory jump through fuzzy matching<br>
usage:<br>
fuzzy_jump.sh pattern1 pattern2 ...

### [list_most_memory_apps.sh](list_most_memory_apps.sh):<br>
list the top three apps that take up the most memory

### [new_script.sh](new_script.sh):<br>
create a new script

### [pick_mail.sh](pick_mail.sh):<br>
pick a mail address

### [print_env_path.sh](print_env_path.sh):<br>
print $PATH

### [remove_suffix.sh](remove_suffix.sh):<br>
移除文件的后缀名

### [save_clipboard.sh](save_clipboard.sh):<br>
saves the content of the clipboard to a specified directory<br>
it can handle both text and image data<br>
必须是文字或图像内容直接在剪贴板上,不能说通过cmd+c来拷贝一个文本文件或图像文件在剪贴板上,然后再去运行该脚本<br>
requirements:<br>
macos:brew install pngpaste<br>
linux:xclip imagemagick<br>
usage:<br>
script.sh<br>
script.sh /directory/to/save/

### [send_mail.sh](send_mail.sh):<br>
usage:<br>
send_mail.sh "subject" "body" recipient

### [simulate_command_c.sh](simulate_command_c.sh):<br>
like command+c(or ctrl+c) for files and dirs

### [simulate_command_v.sh](simulate_command_v.sh):<br>
like command+v(or ctrl+v)(with -x option will move) for files and dirs

### [smart_cp.sh](smart_cp.sh):<br>
smart cp

### [smart_mv.sh](smart_mv.sh):<br>
smart mv

### [smart_rm.sh](smart_rm.sh):<br>
smart rm

### [tar_gzip_folder_exclude_git.sh](tar_gzip_folder_exclude_git.sh):<br>
tgz a folder but exclude .git and .DS_Store<br>
usage:bash script_name.sh /path/to/directory

### [tgz.sh](tgz.sh):<br>
bring tar gzip zip and 7z together<br>
usage:tgz.sh -h

### [update_brew.sh](update_brew.sh):<br>
更新通过homebrew安装的包,但是除了perl

### [zip_folder_exclude_git.sh](zip_folder_exclude_git.sh):<br>
zip a folder but exclude .git and .DS_Store<br>
usage:bash script_name.sh /path/to/directory

## transfer:
### [curl_download_https.sh](curl_download_https.sh):<br>
download a file from https by curl<br>
usage:<br>
script.sh url [path/local_file]

### [transfer.sh](transfer.sh):<br>
upload file to transfer.sh and download file from transfer.sh<br>
script.sh -u /localpath/to/file<br>
script.sh -d XXXXXX /localpath/to/file(note:the file name should be same as the remote file)
