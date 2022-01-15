#!/bin/bash

set -u

function usage() {
    echo "Usage: $0 -i INPUT_DIR [-o OUTPUT_DIR] TARGET..."
    echo
    echo "Run SymCC-instrumented TARGET in a loop, feeding newly generated inputs back "
    echo "into it. Initial inputs are expected in INPUT_DIR, and new inputs are "
    echo "continuously read from there. If OUTPUT_DIR is specified, a copy of the corpus "
    echo "and of each generated input is preserved there. TARGET may contain the special "
    echo "string \"@@\", which is replaced with the name of the current input file."
    echo
    echo "Note that SymCC never changes the length of the input, so be sure that the "
    echo "initial inputs cover all required input lengths."
}

while getopts "i:o:" opt; do
    case "$opt" in
        i)
            in=$OPTARG
            ;;
        o)
            out=$OPTARG
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))
target=$@
timeout="timeout -k 5 90"

if [[ ! -v in ]]; then
    echo "Please specify the input directory!"
    usage
    exit 1
fi

# Create the work environment
# 创建临时目录,其下有next，symcc_out目录和analyzed_inputs文件
work_dir=$(mktemp -d)
mkdir $work_dir/{next,symcc_out}
touch $work_dir/analyzed_inputs
#-v 文件是否存在，不存在创建out
if [[ -v out ]]; then
    mkdir -p $out
fi

function cleanup() {
    rm -rf $work_dir
}
#在shell结束前执行cleanup
trap cleanup EXIT

# Copy all files in the source directory to the destination directory, renaming
# them according to their hash.将源目录中的所有文件复制到目标目录，并根据其哈希值重命名它们
function copy_with_unique_name() {
    local source_dir="$1"
    local dest_dir="$2"
#-A 将列出包括隐藏文件或目录在内的所有文件和目录，不包括“.”和“..”
    if [ -n "$(ls -A $source_dir)" ]; then
        local f
        for f in $source_dir/*; do
            #对源目录中的文件内容进行hash处理，并作为文件名
            local dest="$dest_dir/$(sha256sum $f | cut -d' ' -f1)"
            cp "$f" "$dest"
        done
    fi
}

# Copy files from the source directory into the next generation.
function add_to_next_generation() {
    local source_dir="$1"
    copy_with_unique_name "$source_dir" "$work_dir/next"
}

# If an output directory is set, copy the files in the source directory there.
function maybe_export() {
    local source_dir="$1"
    if [[ -v out ]]; then
        copy_with_unique_name "$source_dir" "$out"
    fi
}

# Copy those files from the input directory to the next generation that haven't
# been analyzed yet.
function maybe_import() {
    #-n 不为空
    if [ -n "$(ls -A $in)" ]; then
        local f
        for f in $in/*; do
            #如果文件存在于analyzed_inputs中，丢弃
            if grep -q "$(basename $f)" $work_dir/analyzed_inputs; then
                continue
            fi
            #如果next目录中与存在该文件，丢弃
            if [ -e "$work_dir/next/$(basename $f)" ]; then
                continue
            fi
            #否则，将此文件拷贝至next目录中
            echo "Importing $f from the input directory"
            cp "$f" "$work_dir/next"
        done
    fi
}

# Set up the shell environment
export SYMCC_OUTPUT_DIR=$work_dir/symcc_out
export SYMCC_ENABLE_LINEARIZATION=1
# export SYMCC_AFL_COVERAGE_MAP=$work_dir/map

# Run generation after generation until we don't generate new inputs anymore
gen_count=0
while true; do
    # Initialize the generation
    #将next文件夹重命名为cur，并新建next文件夹
    maybe_import
    mv $work_dir/{next,cur}
    mkdir $work_dir/next
    
    # Run it (or wait if there's nothing to run on)
    if [ -n "$(ls -A $work_dir/cur)" ]; then
        echo "Generation $gen_count..."
        #对cur文件夹下的文件内容进行处理
        for f in $work_dir/cur/*; do
            #如果文件存在于analyzed_inputs中，丢弃
            if  grep -q "$(basename $f)" $work_dir/analyzed_inputs; then
                continue
            fi
            #如果next目录中与存在该文件，丢弃
            if [ -e "$work_dir/next/$(basename $f)" ]; then
                continue
            fi
            
            # echo "Running on $f"
            if [[ "$target " =~ " @@ " ]]; then
                #
                env SYMCC_INPUT_FILE=$f $timeout ${target[@]/@@/$f} >/dev/null 2>&1
            else
                # $timeout $target <$f >/dev/null 2>&1
                $timeout $target <$f &>>sample4-out.txt
                tail -n 1 Path.txt >> PathSum.txt
                echo >> PathSum.txt
                tail -n 1 Token.txt >> TakenSum.txt
                echo >> TakenSum.txt
                # rm Path.txt
                # rm Token.txt
                # touch Path.txt
                # touch Token.txt
            fi

            # Make the new test cases part of the next generation
            add_to_next_generation $work_dir/symcc_out
            maybe_export $work_dir/symcc_out
            echo $(basename $f) >> $work_dir/analyzed_inputs
            rm -f $f
            rm -f $work_dir/symcc_out/*
        done
        rm -rf $work_dir/cur
        gen_count=$((gen_count+1))
    else
        echo "Waiting for more input..."
        rmdir $work_dir/cur
        sleep 5
    fi
done
