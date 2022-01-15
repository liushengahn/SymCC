cd ../symcc/build_simple
rm -rf *
cmake -G "Ninja" -DQSYM_BACKEND=OFF -DCMAKE_BUILD_TYPE=Release -DZ3_TRUST_SYSTEM_VERSION=ON -DLLVM_DIR=/usr/lib/llvm-12/cmake -DZ3_DIR=/data/z3/build ..
ninja check
/data/SymCC/symcc/build_simple/symcc /data/SymCC/test/sample.c -o /data/SymCC/test/sample