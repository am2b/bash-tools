#!/usr/bin/env bash

#!/usr/bin/env bash

#=convenient
#@clean up the markdown format in google gemini
#@usage:
#@pbpaste | script.sh | pbcopy

gawk '
BEGIN { in_code=0; blank=0 }

{
  raw = $0

  # 1) 识别 ``` 代码块围栏
  if (raw ~ /^[[:space:]]*```/) {
    in_code = !in_code
    next # 丢弃围栏行，包括 ```bash
  }

  if (in_code) {
    # 代码块内部原样输出
    print raw
    next
  }

  # 2) 代码块外 Markdown 清理
  line = raw
  gsub(/\*\*/, "", line)                   # 粗体 **
  sub(/^#{1,6}[ \t]*/, "", line)           # 标题 #
  sub(/^[>][ \t]*/, "", line)              # 引用 >
  gsub(/`/, "", line)                      # 行内反引号 `

  # 3) 修复有序列表反斜杠 1\. 2\. 3\. → 1. 2. 3.
  line = gensub(/([0-9]+)\\\./, "\\1.", "g", line)

  # 4) 分隔线处理 --- 或 *** 等
  if (line ~ /^[ \t]*[-*_]{3,}[ \t]*$/) {
    if (blank == 0) { print ""; blank=1 }
    next
  }

  # 5) 合并连续空行
  if (line ~ /^[ \t]*$/) {
    if (blank == 0) { print ""; blank=1 }
    next
  }

  print line
  blank = 0
}
' <<< "$(pbpaste)" | pbcopy
