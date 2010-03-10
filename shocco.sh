#!/bin/sh
#/ Usage: shocco <file>

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

# The most important line in any shell program.
set -e

# 
cat $1                                       |

# Remove comment leader text from all comment lines. Then prefix all
# comment lines with "DOCS" and interpreted / code lines with "CODE".
# After passing through `sed`, the stream text might look like this:
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
' |


# Write the result out to a temp file but keep the pipeline going.
# We'll come back
cat > raw


# First Pass: Comment Formatting
# ------------------------------

# Get another pipeline going on our preformatted input file.
cat raw |

# Replace CODE lines with blank lines.
sed 's/^CODE.*//'    |

# Squeeze multiple blank lines into a single blank line
cat -s               |

# Replace blank lines with a DIVIDER marker and remove "DOCS LINE"
# prefix from DOCS lines.
sed '
    s/^$/##### DIVIDER/
    s/^DOCS //' |

# Pass the current document through markdown
markdown                   |

# Split the HTML out into separate files.
# The `-k` option to csplit 
(csplit -sk -f docs -n 4 - '/<h5>DIVIDER<\/h5>/' '{9999}' 2>/dev/null || true)

# Second Pass: Code Formatting
# ----------------------------

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

# Post filter the output to remove
sed '
    s/<div class="highlight"><pre>//
    s/^<\/pre><\/div>//'  |

(csplit -sk -f code -n 4 - '%# DIVIDER%' '/<span class="c"># DIVIDER</span>/' '{9999}' 2>/dev/null || true)


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
    <link rel="stylesheet" href="http://jashkenas.github.com/docco/resources/docco.css">
</head>
<body>
<div id='container'>
    <div id="background"></div>
    <table cellspacing=0 cellpadding=0>
    <thead>
      <tr>
        <th class=docs><h1>$(basename $1)</h1></th>
        <th class=code></th>
      </tr>
    </thead>
    <tbody>
        <tr style='display:none'><td><div><pre>
HTML

# 
cat $(ls -1 docs[0-9]* code[0-9]* | sort -n -k1.5 -k1.1r) |
sed '
    s/<h5>DIVIDER<\/h5>/<\/pre><\/div><\/td><\/tr><tr><td class=docs>/
    s/<span class="c"># DIVIDER<\/span>/<\/td><td class=code><div class=highlight><pre>/
    '

cat <<HTML
            </pre></div></td>
        </tr>
    </tbody>
    </table>
</body>
</html>
HTML
