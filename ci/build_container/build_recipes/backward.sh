#!/bin/bash

set -e

VERSION=1.3

wget -O backward-cpp-$VERSION.tar.gz https://github.com/bombela/backward-cpp/archive/v$VERSION.tar.gz
tar xf backward-cpp-$VERSION.tar.gz
cp backward-cpp-$VERSION/backward.hpp $THIRDPARTY_BUILD/include
cd $THIRDPARTY_BUILD/include
cat <<-EOF | patch -p0
--- backward.hpp
+++ backward.hpp
@@ -1951,6 +1951,8 @@
 		error_addr = reinterpret_cast<void*>(uctx->uc_mcontext.gregs[REG_EIP]);
 #elif defined(__arm__)
 		error_addr = reinterpret_cast<void*>(uctx->uc_mcontext.arm_pc);
+#elif defined(__aarch64__)
+		error_addr = reinterpret_cast<void*>(uctx->uc_mcontext.pc);
 #elif defined(__ppc__) || defined(__powerpc) || defined(__powerpc__) || defined(__POWERPC__)
 		error_addr = reinterpret_cast<void*>(uctx->uc_mcontext.regs->nip);
 #else
EOF
