prepend_path()
{
	local VAR="${1}"
	local NEWPATH="${2}"
	
    SAVED_IFS="$IFS"
    IFS=:
    
    local OLD_PATH="${!VAR}"
    local OLD_PATHS=($OLD_PATH)
    
    # Primitive set test
    contains()
    {
        local e
        for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
        return 1
    }
    
    local ALREADY=0
    for dir in $NEWPATH ; do
        if ! contains "$dir" "${OLD_PATHS[@]}"; then
            export ${VAR}="$dir${OLD_PATH:+:$OLD_PATH}"
        else
            if [[ "x${DEBUG-0}" != "x0" ]]; then
                echo "Warning: $dir already in $VAR"
            fi;
            ALREADY=1
        fi
    done
    
    IFS="$SAVED_IFS"
    unset dir
    
    return "$ALREADY"
}

remove_path()
{
    local VAR="${1}"
    local REMPATH="${2}"
    
    SAVED_IFS="$IFS"
    IFS=:
    
    local OLD_PATH="${!VAR}"
    local OLD_PATHS=($OLD_PATH)
    local NEW_PATHS=()
    
    export NOREMOVED=1
    
    for dir in ${OLD_PATHS[@]} ; do
        if [[ "$dir" != "$REMPATH" ]]; then
            NEW_PATHS+=("$dir")
        else
            NOREMOVED=0
        fi
    done
    
    export ${VAR}="${NEW_PATHS[*]}"
    
    IFS="$SAVED_IFS"
    unset dir
    
    return "$NOREMOVED"
}

use_prefix()
{
    local ALREADY=0
    
    prepend_path PATH "${1}/bin" || ALREADY=1
    prepend_path LD_LIBRARY_PATH "${1}/lib" || ALREADY=1
    prepend_path MANPATH "${1}/share/man" || ALREADY=1
    
    prepend_path CPATH "${1}/include" || ALREADY=1
    prepend_path LIBRARY_PATH "${1}/lib" || ALREADY=1
    
    prepend_path PKG_CONFIG_PATH "${1}/lib/pkgconfig" || ALREADY=1
    
    return "$ALREADY"
}

unuse_prefix()
{
    remove_path PATH "${1}/bin"
    remove_path LD_LIBRARY_PATH "${1}/lib"
    remove_path MANPATH "${1}/share/man"
    
    remove_path CPATH "${1}/include"
    remove_path LIBRARY_PATH "${1}/lib"
    
    remove_path PKG_CONFIG_PATH "${1}/lib/pkgconfig"    
}

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

case "${1-}" in
"")
    if ! use_prefix "${THIS_DIR}"; then
        echo -n "Note: ${BASH_SOURCE[0]} already present in some paths"
        if [[ "x${DEBUG-0}" == "x0" ]]; then
            echo -n " (next time set DEBUG=1 to find out where)"
        fi
        echo
    fi
    echo "${BASH_SOURCE[0]}: using prefix"
    ;;
remove|unset)
    if unuse_prefix "${THIS_DIR}"; then
        echo "${BASH_SOURCE[0]}: removed."
    else
        echo "${BASH_SOURCE[0]} ${1}: not currently present in paths"
    fi
    ;;
*)
    echo "${BASH_SOURCE[0]}: I don't understand '${1-}'. Try removing the argument or using 'remove'"
esac

unset THIS_DIR

