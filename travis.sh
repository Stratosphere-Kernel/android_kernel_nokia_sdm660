#!/bin/bash -e


# Clone the repositories
git clone --depth 1 https://github.com/kdrag0n/proton-clang
git clone --depth 1 https://github.com/taalojarvi/AnyKernel3
git clone --depth 1 https://github.com/Stratosphere-Kernel/Stratosphere-Canaries

# Export Environment Variables
export PATH="$(pwd)/proton-clang/bin:$PATH"
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export KBUILD_BUILD_USER="Taalojarvi"
export USE_HOST_LEX=yes
export ZipID=$TRAVIS_BUILD_NUMBER
export KERNEL_IMG=output/arch/arm64/boot/Image.gz-dtb
export USE_CCACHE=1
export CCACHE_EXEC=$( command -v ccache )

# Make defconfig
make stratosphere_defconfig CC=clang O=output/

# Make Kernel
make -j$(nproc --all) CC='ccache clang' O=output/

# Check if Image.gz-dtb exists. If not, stop executing.
if ! [ -a $KERNEL_IMG ];
  then
    echo -e "An error has occured during compilation. Please check your code."
    exit 1
  fi 
  
# Create Release Notes
touch releasenotes.md
echo -e "This is an Early Access build of Stratosphere Kernel. Flash at your own risk!" >> releasenotes.md
echo -e >> releasenotes.md
echo -e "Build Information" >> releasenotes.md
echo -e >> releasenotes.md
echo -e "Build Server Name: "$TRAVIS_APP_HOST >> releasenotes.md
echo -e "Build ID: "$TRAVIS_BUILD_ID >> releasenotes.md
echo -e "Build Number: "$TRAVIS_BUILD_NUMBER >> releasenotes.md
echo -e "Build URL: "$TRAVIS_BUILD_WEB_URL >> releasenotes.md
echo -e "Build Date: $(date +%c)" >> releasenotes.md
echo -e >> releasenotes.md
echo -e "CCACHE Statistics: " >> releasenotes.md
ccache -s >> releasenotes.md
echo -e >>releasenotes.md
echo -e "Last 5 Commits before Build:-" >> releasenotes.md
git log --decorate=auto --pretty=format:'%C(yellow)%d%Creset %s %C(bold blue)<%an>%Creset %n' --graph -n 10 >> releasenotes.md
echo -e >> releasenotes.md
echo -e >> "Downloads available at https://www.github.com/Stratosphere-Kernel/Stratosphere-Canaries" >> releasenotes.md
cp releasenotes.md ~/build/taalojarvi/android_kernel_nokia_sdm660/Stratosphere-Canaries

# Make Flashable Zip
cp output/arch/arm64/boot/Image.gz-dtb AnyKernel3
cd AnyKernel3
zip -r9 UPDATE-AnyKernel2.zip * -x README UPDATE-AnyKernel2.zip
mv UPDATE-AnyKernel2.zip Stratosphere-Kernel-$ZipID.zip
cp Stratosphere-Kernel-$ZipID.zip ~/build/taalojarvi/android_kernel_nokia_sdm660/Stratosphere-Canaries
cd ~/build/taalojarvi/android_kernel_nokia_sdm660/Stratosphere-Canaries

# Upload Flashable Zip to GitHub Releases <3
gh release create ci-$TRAVIS_BUILD_ID Stratosphere-Kernel-$ZipID.zip -F releasenotes.md -p -t "Stratosphere Kernel: Automated Build"
