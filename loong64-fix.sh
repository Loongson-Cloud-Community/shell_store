#!/usr/bin/env bash
set -e

echo "[INFO] Patching runc for loong64 support..."

# Makefile
sed -i 's/\(386 amd64 arm arm64\)/\1 loong64/' Makefile
sed -i 's/\(-a armhf\)/\1 -a loong64/' Makefile

# config.go
grep -q 'SCMP_ARCH_LOONGARCH64' libcontainer/seccomp/config.go || \
sed -i '/SCMP_ARCH_AARCH64/a\	"SCMP_ARCH_LOONGARCH64": "loong64",' libcontainer/seccomp/config.go

# enosys_linux.go
grep -q 'C_AUDIT_ARCH_LOONGARCH64' libcontainer/seccomp/patchbpf/enosys_linux.go || \
sed -i '/const uint32_t C_AUDIT_ARCH_AARCH64/a\const uint32_t C_AUDIT_ARCH_LOONGARCH64  = AUDIT_ARCH_LOONGARCH64;' libcontainer/seccomp/patchbpf/enosys_linux.go
#sed -i '/C_AUDIT_ARCH_AARCH64/a\const uint32_t C_AUDIT_ARCH_LOONGARCH64  = AUDIT_ARCH_LOONGARCH64;' libcontainer/seccomp/patchbpf/enosys_linux.go

sed -i '/AARCH64), nil/ a\
\tcase libseccomp.ArchLOONGARCH64:\
\t\treturn linuxAuditArch(C.C_AUDIT_ARCH_LOONGARCH64), nil' libcontainer/seccomp/patchbpf/enosys_linux.go

