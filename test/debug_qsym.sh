cd ../symcc/build_qsym
rm -rf *
cmake -G "Ninja" -DCMAKE_CXX_FLAGS="-lstdc++fs" -DQSYM_BACKEND=ON -DCMAKE_BUILD_TYPE=Release -DZ3_TRUST_SYSTEM_VERSION=ON -DLLVM_DIR=/usr/lib/llvm-10/cmake -DZ3_DIR=/data/z3/build ..
ninja check
/data/SymCC/symcc/build_qsym/symcc /data/SymCC/test/sample4.c -o /data/SymCC/test/sample4