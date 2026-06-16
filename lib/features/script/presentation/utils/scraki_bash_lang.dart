import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/languages/lib/common.dart';

// Định nghĩa Custom comment mode dùng lookbehind
final _customCommentMode = Mode(
  scope: 'comment',
  begin: '(?<=^|\\s)#',
  end: '\$',
  contains: <Mode>[
    Mode(
      scope: 'doctag',
      begin: '(?:TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):',
      relevance: 0,
    ),
  ],
);

// Định nghĩa Placeholder variables (như {input}, {SERIAL}...)
final _placeholderVariableMode = Mode(
  className: 'template-variable',
  begin: '\\{[a-zA-Z0-9_:-]+\\}',
);

// Định nghĩa Parameter switches (ví dụ: -gt, -e, --es, -f)
final _parameterMode = Mode(
  className: 'attr',
  begin: '(?<=^|\\s)-[a-zA-Z0-9_-]+',
);

// Định nghĩa Variable Assignment (ví dụ: DELAY_TIME=)
final _variableAssignmentMode = Mode(
  className: 'variable',
  begin: '\\b[a-zA-Z_][a-zA-Z0-9_]*(?==)',
);

// Định nghĩa các nhãn chỉ thị đặc biệt của Scraki (#bash, #bash server, #run-script, #end...)
final _scrakiDirectivesMode = Mode(
  scope: 'keyword',
  begin: r'#(?:bash\s+server|bash|run-script|endbash|end\s+bash|end)\b',
  relevance: 10,
);

final scrakiBashLang = Mode(
  refs: {
    '~contains~3~contains~2': Mode(className: 'variable', variants: <Mode>[
      Mode(begin: "\\\$[\\w\\d#@][\\w\\d_]*(?![\\w\\d])(?![\$])"),
      Mode(begin: "\\\$\\{", end: "\\}", contains: <Mode>[
        Mode(self: true),
        Mode(
          begin: ":-",
          contains: <Mode>[Mode(ref: '~contains~3~contains~2')],
        ),
      ]),
    ]),
    '~contains~7': Mode(
      className: 'string',
      begin: "\"",
      end: "\"",
      contains: <Mode>[
        BACKSLASH_ESCAPE,
        Mode(ref: '~contains~3~contains~2'),
        // Tích hợp placeholder variable để highlight bên trong chuỗi double quotes
        _placeholderVariableMode,
        Mode(
          className: 'subst',
          begin: "\\\$\\(",
          end: "\\)",
          contains: <Mode>[
            BACKSLASH_ESCAPE,
            Mode(ref: '~contains~7'),
          ],
        ),
      ],
    ),
  },
  name: "scraki_bash",
  aliases: ["sh", "bash"],
  keywords: {
    "\$pattern": "\\b[a-z][a-z0-9._-]+\\b",
    "keyword": [
      "if", "then", "else", "elif", "fi", "for", "while", "until", "in", "do",
      "done", "case", "esac", "function", "select"
    ],
    "literal": ["true", "false"],
    "built_in": [
      "break", "cd", "continue", "eval", "exec", "exit", "export", "getopts",
      "hash", "pwd", "readonly", "return", "shift", "test", "times", "trap",
      "umask", "unset", "alias", "bind", "builtin", "caller", "command",
      "declare", "echo", "enable", "help", "let", "local", "logout", "mapfile",
      "printf", "read", "readarray", "source", "type", "typeset", "ulimit",
      "unalias", "set", "shopt", "autoload", "bg", "bindkey", "bye", "cap",
      "chdir", "clone", "comparguments", "compcall", "compctl", "compdescribe",
      "compfiles", "compgroups", "compquote", "comptags", "comptry", "compvalues",
      "dirs", "disable", "disown", "echotc", "echoti", "emulate", "fc", "fg",
      "float", "functions", "getcap", "getln", "history", "integer", "jobs",
      "kill", "limit", "log", "noglob", "popd", "print", "pushd", "pushln",
      "rehash", "sched", "setcap", "setopt", "stat", "suspend", "ttyctl",
      "unfunction", "unhash", "unlimit", "unsetopt", "vared", "wait", "whence",
      "where", "which", "zcompile", "zformat", "zftp", "zle", "zmodload",
      "zparseopts", "zprof", "zpty", "zregexparse", "zsocket", "zstyle", "ztcp",
      "chcon", "chgrp", "chown", "chmod", "cp", "dd", "df", "dir", "dircolors",
      "ln", "ls", "mkdir", "mkfifo", "mknod", "mktemp", "mv", "realpath", "rm",
      "rmdir", "shred", "sync", "touch", "truncate", "vdir", "b2sum", "base32",
      "base64", "cat", "cksum", "comm", "csplit", "cut", "expand", "fmt", "fold",
      "head", "join", "md5sum", "nl", "numfmt", "od", "paste", "ptx", "pr",
      "sha1sum", "sha224sum", "sha256sum", "sha384sum", "sha512sum", "shuf",
      "sort", "split", "sum", "tac", "tail", "tr", "tsort", "unexpand", "uniq",
      "wc", "arch", "basename", "chroot", "date", "dirname", "du", "env", "expr",
      "factor", "groups", "hostid", "id", "link", "logname", "nice", "nohup",
      "nproc", "pathchk", "pinky", "printenv", "seq", "sleep", "stat", "stdbuf",
      "stty", "tee", "timeout", "tty", "uname", "unlink", "uptime", "users",
      "who", "whoami", "yes"
    ]
  },
  contains: <Mode>[
    Mode(
      scope: 'meta',
      begin: "^#![ ]*\\/.*\\b(fish|bash|zsh|sh|csh|ksh|tcsh|dash|scsh)\\b.*",
      end: "\$",
      relevance: 10,
      onBegin: callbackOnBegin2,
    ),
    Mode(
      scope: 'meta',
      begin: "^#![ ]*\\/",
      end: "\$",
      relevance: 0,
      onBegin: callbackOnBegin2,
    ),
    Mode(
      className: 'function',
      begin: "\\w[\\w\\d_]*\\s*\\(\\s*\\)\\s*\\{",
      returnBegin: true,
      contains: <Mode>[
        Mode(scope: 'title', begin: "\\w[\\w\\d_]*", relevance: 0),
      ],
      relevance: 0,
    ),
    Mode(
      begin: "\\\$?\\(\\(",
      end: "\\)\\)",
      contains: <Mode>[
        Mode(begin: "\\d+#[0-9a-f]+", className: 'number'),
        NUMBER_MODE,
        Mode(ref: '~contains~3~contains~2'),
      ],
    ),
    // Nhãn chỉ thị của Scraki đặt trước comment để ưu tiên highlight
    _scrakiDirectivesMode,
    // Custom HASH_COMMENT_MODE
    _customCommentMode,
    Mode(
      begin: "<<-?\\s*(?=\\w+)",
      starts: Mode(
        contains: <Mode>[
          Mode(
            begin: "(\\w+)",
            end: "(\\w+)",
            className: 'string',
            onBegin: callbackOnBegin1,
            onEnd: callbackOnEnd1,
          ),
        ],
      ),
    ),
    Mode(match: "(\\/[a-z._-]+)+"),
    Mode(ref: '~contains~7'),
    Mode(match: "\\\\\""),
    Mode(className: 'string', begin: "'", end: "'"),
    Mode(match: "\\\\'"),
    
    // Đưa placeholder variables vào root contains
    _placeholderVariableMode,
    
    // Đưa parameter switches vào root contains
    _parameterMode,
    
    // Đưa variable assignment vào root contains
    _variableAssignmentMode,

    Mode(ref: '~contains~3~contains~2'),
  ],
);
