file_data=history

line2path() {
    line=$1
    candidate=$(echo "$line" | cut -d "|" -f 1)
    echo "$candidate"
}

line2access_time() {
    line=$1
    access_time=$(echo "$line" | cut -d "|" -f 2)
    echo "$access_time"
}

add_or_update_history() {
    added_path=$1
    new_access_time=$2
    file_lines=$(cat $file_data | tr "\n" " ")

    new_updated_file_date=""
    for line in $file_lines
    do
        path=$(line2path "$line")
        access_time=$(line2access_time "$line")

        if [ "$path" != "$added_path" ]
        then
            new_updated_file_date="${new_updated_file_date}${path}|${access_time}\n"
        fi
    done       

    new_updated_file_date="${new_updated_file_date}${added_path}|${new_access_time}\n"

    echo "$new_updated_file_date" > $file_data
}

jump() {
    [ $# = 0 ] && (cd || exit)

    search_pattern="$1"

    file_data=history
    file_lines=$(cat $file_data | tr "\n" " ")

    # get cd's candidate
    best_candidate=0
    best_candidate_time=0
    for line in $file_lines
    do
        candidate=$(line2path "$line")
        access_time=$(line2access_time "$line")

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
        (echo cd "$best_candidate"; add_or_update_history "$best_candidate" "$(date +%s)") || exit
    else
        echo "no candidate in cd history"
    fi
}

## main scripts
#autoload -Uz add-zsh-hook
#add-zsh-hook chpwd add_or_update_history

# parse options
while getopts :l opt 2> /dev/null
do
    case $opt in
        l)
            cat "$file_data"
            ;;
        \?)
            echo "unexpected opt: $OPTARG"
            exit 1
            ;;
    esac
done

shift "$(expr $OPTIND - 1)"

jump "$1"