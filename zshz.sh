#!/bin/sh

file_data=history

_jump_line2path() {
    line=$1
    candidate=$(echo "$line" | cut -d "|" -f 1)
    echo "$candidate"
}

_jump_line2access_time() {
    line=$1
    access_time=$(echo "$line" | cut -d "|" -f 2)
    echo "$access_time"
}

_jump_line2access_rank() {
    line=$1
    rank=$(echo "$line" | cut -d "|" -f 3)
    echo "$rank"
}

# About frecency: https://udn.realityripple.com/docs/Mozilla/Tech/Places/Frecency_algorithm
# this frecency algorithm was optimized by dcervenkov. (https://github.com/rupa/z/issues/248)
# NOTE: Use bc command for comparing frecencies. Frecency is decimal.
_jump_calc_frecency() {
    last_access_time=$1
    rank=$2

    current_time=$(date +%s) 
    dt=$((current_time - last_access_time))

    echo "$rank * (3.75/((0.0001 * $dt + 1) + 0.25))" | bc
}

_jump_add_or_update_history() {
    setopt LOCAL_OPTIONS SH_WORD_SPLIT 2> /dev/null

    added_path=$1
    new_access_time=$2

    file_lines=$(cat $file_data)

    new_updated_file_date=""
    added_path_current_rank="0"
    for line in $file_lines
    do
        dir_path=$(_jump_line2path "$line")
        access_time=$(_jump_line2access_time "$line")
        rank=$(_jump_line2access_rank "$line")

        if [ -z "$dir_path" ] || [ -z "$access_time" ]
        then
            continue
        fi 

        if [ "$dir_path" != "$added_path" ]
        then
            new_updated_file_date="${new_updated_file_date}${dir_path}|${access_time}|${rank}\n"
        else 
            added_path_current_rank=${rank}
        fi
    done
    new_updated_file_date="${new_updated_file_date}${added_path}|${new_access_time}|$((added_path_current_rank + 1))"

    echo "$new_updated_file_date" > $file_data
}

jump() {
    setopt LOCAL_OPTIONS SH_WORD_SPLIT 2> /dev/null
    [ $# != 1 ] && (cd || exit)

    search_pattern="$1"
    method=${2:-frecency}

    file_data=history
    file_lines=$(cat $file_data)

    # get cd's candidate
    best_candidate=0
    best_candidate_score=0
    for line in $file_lines
    do
        candidate=$(_jump_line2path "$line")
        access_time=$(_jump_line2access_time "$line")
        rank=$(_jump_line2access_rank "$line")

        case $method in
            frecency) 
                candidate_score=$(_jump_calc_frecency "$access_time" "$rank")
                ;;
            
            recency)
                candidate_score="$access_time"
                ;;

            frequency)
                candidate_score="$rank"
                ;;

            *)
                echo "invalid matching method"
                exit 1
                ;;
        esac

        # pattern match for following POSIX
        # https://www.shellcheck.net/wiki/SC3015
        ! expr "X${candidate}" : "X.*${search_pattern}.*" >/dev/null && continue        


        candidate_comparison_equation="$best_candidate_score < $candidate_score"
        if [ "$best_candidate_score" = "0" ] || [ "$(echo "$candidate_comparison_equation" | bc)" ]
        then
            best_candidate_score=$access_time
            best_candidate=$candidate
        fi
    done

    # cd
    if [ -d "$best_candidate" ]
    then
        (echo cd "$best_candidate"; _jump_add_or_update_history "$best_candidate" "$(date +%s)") || exit
    else
        echo "no candidate in cd history"
    fi
}

_jump_add_or_pwd_to_history() {
    _jump_add_or_update_history "$(pwd)" "$(date +%s)"
}

## main scripts
# autoload -Uz add-zsh-hook
# add-zsh-hook chpwd _jump_add_or_pwd_to_history

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

shift "$((OPTIND - 1))"
jump "$1"
