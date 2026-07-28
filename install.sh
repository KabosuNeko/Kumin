#!/bin/sh
set -eu

KUMIN_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_FILE="$KUMIN_DIR/packages.txt"

sudo -v

echo "=========================================="
echo "  Kumin Dotfiles Installer"
echo "  Stow-based deployment to \$HOME"
echo "=========================================="

printf "===> Install yay (AUR helper)? (y/n): "
read -r confirm
if [ "$confirm" = y ] || [ "$confirm" = Y ]; then
    if ! git clone https://aur.archlinux.org/yay-bin.git /tmp/yay; then
        echo "XXX [ERROR] Failed to clone yay-bin repository." >&2
        exit 1
    fi
    if ! (cd /tmp/yay && makepkg -si --noconfirm); then
        echo "XXX [ERROR] makepkg failed to build/install yay." >&2
        exit 1
    fi
    rm -rf /tmp/yay
else
    echo ":: Skipping yay installation."
fi

if ! command -v yay > /dev/null 2>&1; then
    echo "XXX [ERROR] yay is not installed. Cannot proceed with package installation." >&2
    echo "    Install yay manually and rerun, or answer 'y' above." >&2
    exit 1
fi

for pkg in stow git curl; do
    if command -v "$pkg" > /dev/null 2>&1; then
        echo ":: $pkg ... found"
    else
        echo "XXX [MISSING] $pkg"
        printf "===> Install $pkg now? (y/n): "
        read -r confirm
        if [ "$confirm" = y ] || [ "$confirm" = Y ]; then
            yay -S --noconfirm "$pkg"
        else
            echo "XXX [ERROR] $pkg is required. Exiting." >&2
            exit 1
        fi
    fi
done

printf "===> Install packages from packages.txt? (y/n): "
read -r confirm
if [ "$confirm" = y ] || [ "$confirm" = Y ]; then
    yay -S --noconfirm - < "$PKG_FILE"
else
    echo ":: Skipping package installation."
fi

for folder in \
    "$HOME/.local/state/kumin_theme" \
    "$HOME/.icons" \
    "$HOME/.themes" \
    "$HOME/Pictures/Screenshots"
do
    if [ ! -d "$folder" ]; then
        mkdir -p "$folder"
        echo ":: Created directory: $folder"
    else
        echo ":: Directory already exists: $folder"
    fi
done

printf "===> Deploy dotfiles via GNU Stow (symlinks)? (y/n): "
read -r confirm
if [ "$confirm" = y ] || [ "$confirm" = Y ]; then
    echo ":: Deploying configs and scripts to \$HOME..."
    cd "$KUMIN_DIR"
    if stow --restow --no-folding -t "$HOME" home; then
        echo ":: Stow deployment complete."
        for f in "$HOME/.local/bin"/*.sh; do
            [ -f "$f" ] && chmod +x "$f"
        done
    else
        echo "XXX [ERROR] Stow deployment failed." >&2
        exit 1
    fi
else
    echo ":: Skipping dotfiles deployment."
fi

if ! command -v fish > /dev/null 2>&1; then
    printf "===> Fish shell not found. Install now? (y/n): "
    read -r confirm
    if [ "$confirm" = y ] || [ "$confirm" = Y ]; then
        yay -S --noconfirm fish
    fi
fi

printf "===> Download my Wallpapers collections? (y/n): "
read -r confirm
if [ "$confirm" = y ] || [ "$confirm" = Y ]; then
    echo "==> Fetching Wallpapers..."
    mkdir -p "$HOME/Pictures"
    WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

    if [ -d "$WALLPAPER_DIR/.git" ]; then
        echo ":: Wallpapers repository already exists. Pulling latest changes..."
        git -C "$WALLPAPER_DIR" pull
    elif [ ! -d "$WALLPAPER_DIR" ] || [ -z "$(ls -A "$WALLPAPER_DIR" 2>/dev/null)" ]; then
        echo ":: Cloning from https://github.com/KabosuNeko/Wallpapers.git..."
        git clone --depth 1 https://github.com/KabosuNeko/Wallpapers.git "$WALLPAPER_DIR"
        rm -rf "$WALLPAPER_DIR/.git" "$WALLPAPER_DIR/README.md"
    else
        echo ":: Directory $WALLPAPER_DIR already exists and is not empty. Skipping clone."
    fi
else
    echo ":: Skipping Wallpapers clone."
fi

get_latest_asset_url() {
    repo="$1" pattern="$2"
    curl -s "https://api.github.com/repos/$repo/releases/latest" | \
        grep "browser_download_url" | \
        grep -E "$pattern" | \
        head -1 | \
        cut -d'"' -f4
}

install_icon_release() {
    repo="$1" pattern="$2" dest="$3" label="$4"
    printf "===> Install $label? (y/n): "
    read -r confirm
    if [ "$confirm" != y ] && [ "$confirm" != Y ]; then
        echo ":: Skipping $label."
        return
    fi

    url=$(get_latest_asset_url "$repo" "$pattern")
    if [ -z "$url" ]; then
        echo "XXX [ERROR] Could not find download asset for $label" >&2
        return
    fi

    tmpdir=$(mktemp -d)
    filename=$(basename "$url")

    echo ":: Downloading $label from $repo..."
    curl -L -o "$tmpdir/$filename" "$url"

    mkdir -p "$dest"
    mkdir -p "$tmpdir/extracted"
    case "$filename" in
        *.zip)     unzip -qo "$tmpdir/$filename" -d "$tmpdir/extracted" ;;
        *.tar.xz)  tar -xf "$tmpdir/$filename" -C "$tmpdir/extracted" ;;
        *.tar.gz)  tar -xzf "$tmpdir/$filename" -C "$tmpdir/extracted" ;;
    esac

    for item in "$tmpdir/extracted"/*/; do
        [ -d "$item" ] || continue
        name=$(basename "$item")
        if [ -d "$dest/$name" ]; then
            echo ":: Skip $name (already exists in $dest)"
        else
            cp -r "$item" "$dest/"
            echo ":: Installed $name to $dest"
        fi
    done

    rm -rf "$tmpdir"
}

install_icon_release \
    "SylEleuth/gruvbox-plus-icon-pack" \
    "gruvbox-plus-icon-pack-.*\.zip" \
    "$HOME/.icons" \
    "Gruvbox Plus Icons"

install_icon_release \
    "ful1e5/Bibata_Cursor" \
    "Bibata-Modern-Amber\.tar\.xz" \
    "$HOME/.icons" \
    "Bibata Modern Amber Cursor"

if command -v gsettings > /dev/null 2>&1; then
    printf "===> Apply GTK theme settings? (y/n): "
    read -r confirm
    if [ "$confirm" = y ] || [ "$confirm" = Y ]; then
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
        gsettings set org.gnome.desktop.interface gtk-theme "Gruvbox-BL-LB-Dark"
        gsettings set org.gnome.desktop.interface icon-theme "Gruvbox-Plus-Dark"
        gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Amber"
        echo ":: GTK settings applied."
    fi
fi

printf "===> Enable system services (NetworkManager, bluetooth, ly)? (y/n): "
read -r confirm
if [ "$confirm" = y ] || [ "$confirm" = Y ]; then
    enable_svc() {
        svc="$1"
        if systemctl is-enabled "$svc" > /dev/null 2>&1; then
            echo ":: $svc already enabled."
            return
        fi
        if systemctl list-unit-files "$svc" > /dev/null 2>&1; then
            sudo systemctl enable --now "$svc" && echo ":: Enabled $svc"
        else
            echo "!!! $svc not found (package may not be installed). Skipping."
        fi
    }

    enable_svc "NetworkManager"
    enable_svc "bluetooth"

    if systemctl list-unit-files "ly@tty1.service" > /dev/null 2>&1; then
        if sudo systemctl enable ly@tty1.service; then
            sudo systemctl disable getty@tty1.service 2>/dev/null || true
            echo ":: ly display manager enabled (getty disabled)."
        fi
    else
        echo "!!! ly not installed. Skipping display manager setup."
    fi
fi

if command -v xdg-mime > /dev/null 2>&1 && command -v thunar > /dev/null 2>&1; then
    xdg-mime default thunar.desktop inode/directory
    echo ":: Default file manager: thunar"
fi

if [ -x "$HOME/.local/bin/kumin-style.sh" ]; then
    echo ":: Generating initial theme state..."
    "$HOME/.local/bin/kumin-style.sh"
fi

echo ""
echo "=========================================="
echo "  Installation complete!"
echo "  To uninstall:  cd ~/Kumin && stow -D -t ~ home"
echo "  To update:     cd ~/Kumin && stow --restow -t ~ home"
echo "=========================================="
