#!/usr/bin/env bash

demo_nothing_interpolates() {
    local interpolate_me="42"

    cat <<- 'EOF'
The hyphenated begin block `<<-` with quoted 'EOF' suppresses all interpolation.

So ${interpolate_me} will print literally.

EOF
}

demo_something_interpolates() {
    local interpolate_me="42"

    cat << EOF
The \$interpolate_me variable expands to $interpolate_me
EOF
}
