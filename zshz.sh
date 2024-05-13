#!/bin/sh

add_history() {
    added_path=$1

    
}

jump()
{
    [ $# = 0 ] && (cd || exit)

    search_pattern="$1"

    file_data=history
    file_lines=$(cat $file_data | tr "\n" " ")

    # get cd's candidate
    best_candidate=0
    best_candidate_time=0
    for line in $file_lines
    do
        candidate=$(echo "$line" | cut -d "|" -f 1)
        access_time=$(echo "$line" | cut -d "|" -f 2)
        echo $candidate $access_time

        # pattern match for following POSIX
        # https://www.shellcheck.net/wiki/SC3015
        ! expr "X${candidate}" : "X.*${search_pattern}.*" >/dev/null && continue

        if [ "$best_candidate_time" = "0" ] || [ "$best_candidate_time" -lt "$access_time" ]
        then
            best_candidate_time=$access_time
            best_candidate=$candidate
        fi
    done

    # cd
    if [ -d "$best_candidate" ]
    then
        echo cd "$best_candidate" || exit
    else
        echo "no candidate in cd history"
    fi
}