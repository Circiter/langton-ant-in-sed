#!/bin/sed -Enf

# (c) Circiter (mailto:xcirciter@gmail.com).
# Official source: github.com/Circiter/langton-ant-in-sed
# License: MIT.

# Bug: too slow.

# TODO: Try to extend this script to be able to view a "highway"
# (if it is possible in such a restricted environment).

# Langton's ant in sed.

# Example usage: echo xxxxxxxxxxxx | ./langton-ant.sed, where x'es represent
# the order (size) of a matrix or, de-facto, its first row.

# TODO: Make it possible to fully specify an initial
# configuration in command-line.

# N.B., can be implemented as a [multiple-color] cellular automaton
# but here a more direct approach is used.

:load $!{N; bload}

# Generate a square matrix.
h # Copy text to hold space.
:make_matrix
    /x/{ # While the given unary number is not a zero.
        x # Swap hold space and pattern space.
        # Add one new line to hold space for each character in the input string.
        s/^([^\n]*\n)(.*)$/\1\1\2/
        /^([^\n]*)$/s/^.*$/&\n/
        x # Swap again.
        s/x// # Decrement.
        bmake_matrix
    }

g # Copy the resulting matrix back to the pattern space.

s/$/\nd/ # Direction.

s/^x/X/; s/^y/Y/ # Initial position of the scanning window.

# Move down.
# FIXME: Remove code-duplication.
s/([XY])([^\n]*\n)(.)/\3\2\1/
s/([XY])([^\n]*\n)(.)/\3\2\1/
s/([XY])([^\n]*\n)(.)/\3\2\1/
s/([XY])([^\n]*\n)(.)/\3\2\1/

# Move to the right.
# FIXME: Remove code-duplication.
s/([XY])(.)/\2\1/
s/([XY])(.)/\2\1/
s/([XY])(.)/\2\1/
s/([XY])(.)/\2\1/
s/([XY])(.)/\2\1/
s/([XY])(.)/\2\1/
s/([XY])(.)/\2\1/

# Insert stop-markers, @, before and after the matrix;
# then duplicate the last line of the matrix thus creating
# a counter, and, finally, ensure that the direction
# information is stored just before the EOF.
s/^(.*)(\n[^\n]*)\n(\n.)$/@\1\2@\2\3/

# Slide the window across the matrix.
:scan
    # Insert auxiliary markers.
    s/[XY]/<&>/; s/\n</<\n/; s/>\n/\n>/

    # Shift the aux-markers in two opposite directions,
    # one character at a time.
    :shift
        s/@</@/; s/>@/@/
        s/([^@])</<\1/; s/\n</<\n/ # The first marker moves to the left.
        s/>([^@])/\1>/; s/>\n/\n>/ # The second marker moves to the right.

        s/(\n[^\n]*)[^\n](\n.$)/\1\2/ # Shorten the last duplicated line.
        #p
        /[^\n]\n.$/bshift # While the last line is not empty.

    # Now the first aux. marker is located just after the NW
    # corner, if any, of 8-neighborhood of the main X/Y marker. The second
    # marker, correspondingly, is located just before the SE corner, if any.

    # Invert current cell.
    y/XY/YX/
    # Move the ant.
    /u$/ s/<[xy]/&c/
    /r$/ s/[XY][xy]/&c/
    /d$/ s/([xy])>/\1c>/
    /l$/ s/([xy])([XY])/\1c\2/
    y/XY/xy/
    s/xc/X/; s/yc/Y/

    # Rotate ant's direction (according to current cell's value).
    /X/ y/urdl/rdlu/
    /Y/ y/urdl/lurd/

    s/[<>]//g; # Remove the auxiliary markers.

    # Display. A yellow block shows the ant's location.
    h; x; y/xy/ #/
    s/[@urdl!]//g
    s/#/\x1b[42m \x1b[0m/g
    s/[XY]/\x1b[43m \x1b[0m/
    s/^/\x1b\[\?25l\x1b\[H/
    p; x

    # Duplicate the counter and preserve the direction variable.
    s/^(.*)(\n[^\n]*)@.*(.)$/\1\2@\2\n\3/
    /[XY]/bscan # Until the ant is on the stage.
