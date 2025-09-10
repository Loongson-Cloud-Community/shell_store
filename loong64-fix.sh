#!/usr/bin/env bash
set -e

echo "[INFO] Patching runc for loong64 support..."

# Makefile
sed -i 's/\(386 amd64 arm arm64\)/\1 loong64/' Makefile
sed -i 's/\(-a armhf\)/\1 -a loong64/' Makefile

# libcontainer/system/syscall_linux_64.go
# //go:build linux && (arm64 || amd64 || mips || mipsle || mips64 || mips64le || ppc || ppc64 || ppc64le || riscv64 || s390x)
#// +build linux
#// +build arm64 amd64 mips mipsle mips64 mips64le ppc ppc64 ppc64le riscv64 s390x
file="libcontainer/system/syscall_linux_64.go"
if [ -f "$file" ]; then
    echo "[INFO] Patching $file for loong64 support..."
    # 修改 //go:build 行
    sed -i 's/arm64 || amd64 || mips || mipsle || mips64 || mips64le || ppc || ppc64 || ppc64le || riscv64 || s390x/arm64 || amd64 || mips || mipsle || mips64 || mips64le || ppc || ppc64 || ppc64le || riscv64 || s390x || loong64/' "$file"
    # 修改 // +build 行
    sed -i 's/arm64 amd64 mips mipsle mips64 mips64le ppc ppc64 ppc64le riscv64 s390x/arm64 amd64 mips mipsle mips64 mips64le ppc ppc64 ppc64le riscv64 s390x loong64/' "$file"
else
    echo "[INFO] $file does not exist, skipping patch."
fi

# config.go
grep -q 'SCMP_ARCH_LOONGARCH64' libcontainer/seccomp/config.go || \
sed -i '/SCMP_ARCH_AARCH64/a\	"SCMP_ARCH_LOONGARCH64": "loong64",' libcontainer/seccomp/config.go

# enosys_linux.go
grep -q 'C_AUDIT_ARCH_LOONGARCH64' libcontainer/seccomp/patchbpf/enosys_linux.go || \
sed -i '/const uint32_t C_AUDIT_ARCH_AARCH64/a\const uint32_t C_AUDIT_ARCH_LOONGARCH64  = AUDIT_ARCH_LOONGARCH64;' libcontainer/seccomp/patchbpf/enosys_linux.go
# 获取当前 runc 版本
RUNC_VERSION=$(git describe --tags --abbrev=0 || echo "v0.0.0")
echo "[INFO] Current runc version: $RUNC_VERSION"

# 版本比较函数
version_gt() { # returns 0 if $1 > $2
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

enosys="libcontainer/seccomp/patchbpf/enosys_linux.go"

# 判断是否已经插入过
if ! grep -q 'ArchLOONGARCH64' "$enosys"; then
    echo "[INFO] Inserting ArchLOONGARCH64 case..."

    if version_gt "$RUNC_VERSION" "v1.1.14"; then
        # 高版本用 linuxAuditArch
        sed -i '/AARCH64), nil/ a\
\t\tcase libseccomp.ArchLOONGARCH64:\
\treturn linuxAuditArch(C.C_AUDIT_ARCH_LOONGARCH64), nil' "$enosys"
    else
        # 低版本用 nativeArch
        sed -i '/AARCH64), nil/ a\
\t\tcase libseccomp.ArchLOONGARCH64:\
\treturn nativeArch(C.C_AUDIT_ARCH_LOONGARCH64), nil' "$enosys"
    fi

    echo "[INFO] ArchLOONGARCH64 case inserted successfully."
else
    echo "[INFO] ArchLOONGARCH64 case already exists, skipping."
fi


