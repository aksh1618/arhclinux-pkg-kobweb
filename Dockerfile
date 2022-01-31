FROM archlinux:base-devel

# makepkg cannot (and should not) be run as root:
RUN useradd -m build && \
    pacman -Syu --noconfirm && \
    pacman -Sy --noconfirm git && \
    # Allow build to run stuff as root (to install dependencies):
    echo "build ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/build

# Continue execution (and CMD) as build:
USER build
WORKDIR /home/build

# Copy PKGBUILD and script
COPY PKGBUILD .
COPY kobweb .

# Build & install the package
RUN makepkg --noconfirm --syncdeps --rmdeps --install --clean
CMD kobweb version
