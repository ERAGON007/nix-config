final:
let
  inherit (final)
    fetchpatch
    lib
    linuxKernel
    overrideCC
    ;
  inherit (lib.kernel) yes no;

  llvmPackages = "llvmPackages_12";

  stdenvLLVM =
    let
      hostLLVM = final.buildPackages.${llvmPackages}.override {
        bootBintools = null;
        bootBintoolsNoLibc = null;
      };
      buildLLVM = final.${llvmPackages}.override {
        bootBintools = null;
        bootBintoolsNoLibc = null;
      };

      mkLLVMPlatform = platform: platform // {
        useLLVM = true;
        linux-kernel = platform.linux-kernel // {
          makeFlags = (platform.linux-kernel.makeFlags or [ ]) ++ [
            "LLVM=1"
            "LLVM_IAS=1"
            "CC=${buildLLVM.clangUseLLVM}/bin/clang"
            "LD=${buildLLVM.lld}/bin/ld.lld"
            "HOSTLD=${hostLLVM.lld}/bin/ld.lld"
            "AR=${buildLLVM.llvm}/bin/llvm-ar"
            "HOSTAR=${hostLLVM.llvm}/bin/llvm-ar"
            "NM=${buildLLVM.llvm}/bin/llvm-nm"
            "STRIP=${buildLLVM.llvm}/bin/llvm-strip"
            "OBJCOPY=${buildLLVM.llvm}/bin/llvm-objcopy"
            "OBJDUMP=${buildLLVM.llvm}/bin/llvm-objdump"
            "READELF=${buildLLVM.llvm}/bin/llvm-readelf"
            "HOSTCC=${hostLLVM.clangUseLLVM}/bin/clang"
            "HOSTCXX=${hostLLVM.clangUseLLVM}/bin/clang++"
          ];
        };
      };

      stdenvClangUseLLVM = overrideCC hostLLVM.stdenv hostLLVM.clangUseLLVM;

      stdenvPlatformLLVM = stdenvClangUseLLVM.override (old: {
        hostPlatform = mkLLVMPlatform old.hostPlatform;
        buildPlatform = mkLLVMPlatform old.buildPlatform;
      });
    in
    stdenvPlatformLLVM // {
      passthru = (stdenvPlatformLLVM.passthru or { }) // { llvmPackages = buildLLVM; };
    };

  applyCfg = config: kernel: kernel.override {
    argsOverride.kernelPatches = kernel.kernelPatches;
    argsOverride.structuredExtraConfig = kernel.structuredExtraConfig // config;
  };

  applyLTO = kernel: kernel.override {
    stdenv = stdenvLLVM;
    buildPackages = final.buildPackages // { stdenv = stdenvLLVM; };
    argsOverride.kernelPatches = kernel.kernelPatches;
    argsOverride.structuredExtraConfig = kernel.structuredExtraConfig // {
      LTO_CLANG_FULL = yes;
      LTO_NONE = no;
      # XXX: https://www.mail-archive.com/linux-kernel@vger.kernel.org/msg2519405.html
      DEBUG_INFO = lib.mkForce no;
    };
  };

  applyUarches = kernel: kernel.override {
    argsOverride.kernelPatches = kernel.kernelPatches ++ [{
      name = "more-uarches-for-kernel-5.15";
      patch = fetchpatch {
        name = "more-uarches-for-kernel-5.15";
        url = "https://raw.githubusercontent.com/graysky2/kernel_compiler_patch/master/more-uarches-for-kernel-5.15%2B.patch";
        sha256 = "sha256-WSN+1t8Leodt7YRosuDF7eiSL5/8PYseXzxquf0LtP8=";
      };
    }];
    argsOverride.structuredExtraConfig = kernel.structuredExtraConfig;
  };

  inherit (linuxKernel) packagesFor;
in
_: {
  linuxPackages_latest_lto_skylake = packagesFor
    (applyCfg
      { MSKYLAKE = yes; }
      (applyUarches
        (applyLTO linuxKernel.packageAliases.linux_latest.kernel)));

  linuxPackages_xanmod_lto_zen3 = packagesFor
    (applyCfg
      { MZEN3 = yes; }
      (applyLTO linuxKernel.kernels.linux_xanmod));
}
