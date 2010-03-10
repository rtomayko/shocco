#!/bin/sh
# **shocco** is a quick-and-dirty, hundred-line-long, literate-programming-style
# documentation generator written for and in __POSIX shell__.
#
# shocco reads shell scripts and produces annotated source documentation
# in HTML format. Comments are formatted with Markdown and presented
# alongside syntax highlighted code so as to give an annotation effect. This
# page is the result of running shocco against its own source file.
#
# shocco can be installed with `make(1)`:
#
#     git clone git://github.com/rtomayko/schocco.git
#     (cd schocco && make && make install)
#
# Once installed, the `shocco` program can be used to generate documentation
# for a shell script:
#
#     shocco shocco.sh
#
# The HTML files are written to the current working directory.

# Setup
# -----

# The most important line in any shell program.
set -e

# There's a lot of different ways to do usage messages in shell scripts.
# This is my favorite: you write the usage message in a comment --
# typically right after the shebang line -- *BUT*, use a special comment prefix
# like `#/` so that its easy to pull these lines out.
#
# This also illustrates one of shocco's corner features. Only comment lines
# padded with a space are considered documentation. A `#` followed by any
# other character is considered code.
#
#/ Usage: shocco [<input>]
#/ Create literate-programming-style documentation for shell scripts.
#/
#/ The shocco program reads from <input> and writes generated documentation
#/ in HTML format to stdout. When <input> is '-' or not specified, shocco
#/ reads from stdin.

# This is the second part of the usage message technique: `grep` yourself
# for the usage message comment prefix and then cut off the first few
# characters so that everything lines up.
test "$1" = "--help" && {
    grep '^#/' <"$0" | cut -c4-
    exit 0
}

# Make sure we have a `TMPDIR` set. The `:=` parameter expansion assigns
# the value if `TMPDIR` is unset or null.
: ${TMPDIR:=/tmp}

# Create a temporary directory for doing work. Use `mktemp(1)` if
# available; but, since `mktemp(1)` is not POSIX specified, fallback on naive
# (and insecure) temp dir generation using the program's basename and pid.
: ${WORK:=$(
      if command -v mktemp 1>/dev/null 2>&1
      then
          mktemp -dt $(basename $0)
      else
          dir="$TMPDIR/$(basename $0).$$"
          mkdir "$dir"
          echo "$dir"
      fi
  )}

# We're about to create a ton of shit under our `$WORK` directory. Register
# an `EXIT` trap that cleans everything up. This guarantees we don't leave
# anything hanging around unless we're killed with a `SIGKILL`.
trap "rm -rf $WORK" EXIT

# Preformatting
# -------------

# We slurp the input file, apply some light preformatting to make the
# code and doc formatting phases a bit easier, and then write the result
# out to a temp file under the `$WORK` directory.
#
# Generally speaking, I like to avoid temp files but the two-pass formatting
# logic makes that hard in this case. We may be reading from `stdin` or a
# fifo, so we don't want to assume _input_ can be read more than once.
cat "$1"                               |

# Remove comment leader text from all comment lines. Then prefix all
# comment lines with "DOCS" and interpreted / code lines with "CODE".
# The stream text might look like this after moving through the `sed`
# filters:
#
#     CODE #!/bin/sh
#     CODE #/ Usage: schocco <file>
#     DOCS Docco for and in POSIX sh.
#     CODE
#     CODE PATH="/bin:/usr/bin"
#     CODE
#     DOCS Start by numbering all lines in the input file...
#     ...
#
sed -n '
    s/^/:/
    s/^: \{0,\}# /DOCS /p
    s/^: \{0,\}#$/DOCS /p
    s/^:/CODE /p
'                                      |


# Write the result out to a temp file. We'll take two passes over it: one
# to extract and format the documentation comments and another to extract
# and syntax highlight the source code.
cat > "$WORK/raw"


# Now that we've read and formatted our input file for further parsing,
# change into the work directory. The program will finish up in there.
cd "$WORK"

# First Pass: Comment Formatting
# ------------------------------

# Start a pipeline going on our preformatted input file.
cat raw                                      |

# Replace all CODE lines with entirely blank lines.
sed 's/^CODE.*//'                            |

# Now squeeze multiple blank lines into a single blank line.
#
# __TODO:__ `cat -s` is not POSIX and doesn't squeeze lines on BSD. Use
# the sed line squeezing code mentioned in the POSIX `cat(1)` manual page
# instead.
cat -s                                       |


# At this point in the pipeline, our stream text looks something like this:
#
#     DOCS Now that we've read and formatted ...
#     DOCS change into the work directory. The rest ...
#     DOCS in there.
#
#     DOCS First Pass: Comment Formatting
#     DOCS ------------------------------
#
# Blank lines represent code segments. We want to replace all blank lines
# with a dividing marker and remove the "DOCS" prefix from docs lines.
sed '
    s/^$/##### DIVIDER/
    s/^DOCS //'                              |

# The current stream text is suitable for input to `markdown(1)`. It takes
# our doc text with embedded `DIVIDER`s and outputs HTML.
markdown                                     |

# Now this where shit starts to get a little crazy. We use `csplit(1)` to
# split the HTML into a bunch of individual files. The files are named
# as `docs0000`, `docs0001`, `docs0002`, ... Each file includes a single
# *section*. These files will sit here while we take a similar pass over the
# source code.
(
    csplit -sk                               \
           -f docs                           \
           -n 4                              \
           - '/<h5>DIVIDER<\/h5>/' '{9999}'  \
           2>/dev/null                      ||
    true
)

# Second Pass: Code Formatting
# ----------------------------
#
# Boom.

# Get another pipeline going on our performatted input file.
cat raw |

# Replace DOCS lines with blank lines.
sed 's/^DOCS.*//' |

# Squeeze multiple blank lines into a single blank line
cat -s |

# Replace blank lines with a DIVIDER marker and remove prefix
# from CODE lines.
sed '
    s/^$/# DIVIDER/
    s/^CODE //' |

# Pass code through pygments for syntax highlighting.
pygmentize -l sh -f html |

# Post filter the pygments output to remove partial `<pre>` blocks. We add
# these back in at each section when we build the output document.
sed '
    s/<div class="highlight"><pre>//
    s/^<\/pre><\/div>//'  |

#
(
    csplit -sk                                                         \
           -f code                                                     \
           -n 4 -                                                      \
           '%# DIVIDER%' '/<span class="c"># DIVIDER</span>/' '{9999}' \
           2>/dev/null ||
    true
)


# Recombining
# -----------

# At this point, we have separate files for each docs section and separate
# files for each code section.
cat <<HTML
<!DOCTYPE html>
<html>
<head>
    <meta http-eqiv='content-type' content='text/html;charset=utf-8'>
    <title>$(basename $1)</title>
    <link rel=stylesheet href="http://jashkenas.github.com/docco/resources/docco.css">
</head>
<body>
<div id=container>
    <div id=background></div>
    <table cellspacing=0 cellpadding=0>
    <thead>
      <tr>
        <th class=docs><h1>$(basename $1)</h1></th>
        <th class=code></th>
      </tr>
    </thead>
    <tbody>
        <tr style=display:none><td><div><pre>
HTML

# List the split out temp files - one file per line.
ls -1 docs[0-9]* code[0-9]* |

# Now sort the list of files by the *number* first and then by the type. The
# list will look something like this when `sort` is done with it:
#
#     docs0000
#     code0000
#     docs0001
#     code0001
#     docs0002
#     code0002
#     ...
#
sort -n -k1.5 -k1.1r |

# And if we pass those files to `cat` in that order, it's concatenate them
# in exactly the way we need. The `xargs` command reads from `stdin` and
# passes each line of input as a separate argument to the program given. We
# could also have written this as:
#
#     cat $(ls -1 docs* code* | sort -n -k1.5 -k1.1r)
#
# I like to keep things to a simple flat pipeline when possible, hence the
# `xargs` approach.
xargs cat            |


# Now replace the dividers with table markup.
sed '
    s/<h5>DIVIDER<\/h5>/<\/pre><\/div><\/td><\/tr><tr><td class=docs>/
    s/<span class="c"># DIVIDER<\/span>/<\/td><td class=code><div class=highlight><pre>/
    '

# And output the remaining bit of HTML.
cat <<HTML
            </pre></div></td>
        </tr>
    </tbody>
    </table>
</body>
</html>
HTML

# And that's it
