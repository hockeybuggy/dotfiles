#!/usr/bin/env bash
#
# setup.sh -- install the tools this dotfiles repo expects.
#
# Cross-platform: macOS (via Homebrew) and Debian/Ubuntu (via apt plus a few
# official installers / prebuilt binaries). This script only *installs* tools;
# run ./bootstrap.sh afterwards to symlink the config files into place.
#
# Idempotent: every install is guarded so re-running skips what's present.

set -euo pipefail

# Colours, matching bootstrap.sh's style.
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3); RED=$(tput setaf 1); RESET=$(tput sgr0)
else
    GREEN=""; YELLOW=""; RED=""; RESET=""
fi

LOCAL_BIN="$HOME/.local/bin"

info() { echo "${GREEN}==>${RESET} $*"; }
skip() { echo "${YELLOW}--- skip:${RESET} $*"; }
warn() { echo "${RED}!!! ${RESET}$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

# Download $1 to $2. Prefer curl, fall back to wget.
download() {
    if have curl; then
        curl -fsSL "$1" -o "$2"
    else
        wget -qO "$2" "$1"
    fi
}

# ---------------------------------------------------------------------------
# macOS (Homebrew)
# ---------------------------------------------------------------------------

setup_macos() {
    if ! have brew; then
        info "Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        skip "Homebrew already installed"
    fi

    info "Installing formulae with Homebrew"
    brew install \
        neovim tmux zsh git fzf ripgrep fd bat eza bottom starship zoxide \
        uv fnm gnupg diff-so-fancy node markdownlint-cli duti \
        reattach-to-user-namespace uutils-coreutils

    info "Installing the Inconsolata Nerd Font"
    brew install --cask font-inconsolata-nerd-font || warn "Font install failed (continuing)"

    if ! have rustup || ! have cargo; then
        info "Installing rustup"
        brew install rustup
        rustup default stable
    else
        skip "rustup/cargo already installed"
    fi

    setup_macos_markdown_handler
}

# ---------------------------------------------------------------------------
# macOS: open Markdown files in Neovim (in a new Ghostty window)
# ---------------------------------------------------------------------------
#
# `open foo.md` asks LaunchServices for the default handler, so a shell alias
# can't change it. Instead we compile a tiny AppleScript app whose `on open`
# handler launches Ghostty running Neovim on the file, then make it the default
# Markdown handler with `duti`.

MD_HANDLER_APP="$HOME/Applications/Open in Neovim.app"
MD_HANDLER_ID="com.hockeybuggy.open-in-neovim"

setup_macos_markdown_handler() {
    have duti || { warn "duti unavailable; skipping Markdown handler setup"; return; }

    info "Building the 'Open in Neovim' Markdown handler app"
    local tmpdir src
    tmpdir=$(mktemp -d)
    src="$tmpdir/open-in-neovim.applescript"
    # Ghostty spawns a login shell, so `nvim` resolves via the usual PATH even
    # though `do shell script` runs with a minimal one. Detach with nohup/& so
    # the handler returns immediately instead of blocking until Neovim quits.
    cat > "$src" <<'APPLESCRIPT'
on open theFiles
    repeat with f in theFiles
        set p to POSIX path of f
        do shell script "nohup /Applications/Ghostty.app/Contents/MacOS/ghostty -e nvim " & quoted form of p & " >/dev/null 2>&1 &"
    end repeat
end open
APPLESCRIPT

    mkdir -p "$HOME/Applications"
    rm -rf "$MD_HANDLER_APP"
    osacompile -o "$MD_HANDLER_APP" "$src"
    rm -rf "$tmpdir"

    # osacompile leaves no bundle id and a catch-all Viewer document type. Give
    # it a stable id and declare it a Markdown editor so it can be the handler.
    local plist="$MD_HANDLER_APP/Contents/Info.plist"
    /usr/libexec/PlistBuddy \
        -c "Add :CFBundleIdentifier string $MD_HANDLER_ID" \
        -c "Set :CFBundleDocumentTypes:0:CFBundleTypeRole Editor" \
        -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes array" \
        -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:0 string net.daringfireball.markdown" \
        "$plist" >/dev/null

    # Register the new bundle id with LaunchServices before duti references it.
    local lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
    "$lsregister" -f "$MD_HANDLER_APP"

    # net.daringfireball.markdown is the UTI macOS assigns to .md/.markdown.
    info "Setting 'Open in Neovim' as the default Markdown handler"
    duti -s "$MD_HANDLER_ID" net.daringfireball.markdown all
}

# ---------------------------------------------------------------------------
# Debian / Ubuntu (apt + installers)
# ---------------------------------------------------------------------------

# Machine architecture normalised for release-asset URLs.
arch_rust() {
    case "$(uname -m)" in
        x86_64|amd64) echo "x86_64" ;;
        aarch64|arm64) echo "aarch64" ;;
        *) warn "Unsupported architecture: $(uname -m)"; return 1 ;;
    esac
}

arch_nvim() {
    case "$(uname -m)" in
        x86_64|amd64) echo "x86_64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) warn "Unsupported architecture: $(uname -m)"; return 1 ;;
    esac
}

# Install an eza/bottom-style GitHub release: a tarball whose sole payload is
# the named binary. Args: <repo> <asset-url> <binary-name>
install_release_binary() {
    local name="$1" url="$2" bin="$3" tmp
    if have "$bin"; then skip "$name already installed"; return; fi
    info "Installing $name"
    tmp=$(mktemp -d)
    download "$url" "$tmp/dl.tar.gz"
    tar -xzf "$tmp/dl.tar.gz" -C "$tmp"
    # The binary may sit at the top level or one directory down.
    local found
    found=$(find "$tmp" -type f -name "$bin" | head -n 1)
    if [ -z "$found" ]; then warn "Could not find $bin in $name release"; rm -rf "$tmp"; return 1; fi
    install -m 0755 "$found" "$LOCAL_BIN/$bin"
    rm -rf "$tmp"
}

apt_install() {
    info "Updating apt and installing base packages"
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends \
        zsh tmux git gnupg curl ca-certificates build-essential \
        python3 python3-pip python3-venv ripgrep fd-find bat fzf unzip tar
}

# Debian ships fd as `fdfind` and bat as `batcat`; expose the usual names.
link_debian_aliases() {
    if have fdfind && ! have fd; then
        info "Linking fdfind -> fd"
        ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
    fi
    if have batcat && ! have bat; then
        info "Linking batcat -> bat"
        ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
    fi
}

setup_linux() {
    if ! have apt-get; then
        warn "This script only supports apt-based Linux (Debian/Ubuntu)."
        exit 1
    fi

    mkdir -p "$LOCAL_BIN"
    apt_install
    link_debian_aliases

    local ra na
    ra=$(arch_rust)
    na=$(arch_nvim)

    # rustup / cargo
    if ! have cargo && ! have rustup; then
        info "Installing rustup"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    else
        skip "rustup/cargo already installed"
    fi

    # starship
    if ! have starship; then
        info "Installing starship"
        curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$LOCAL_BIN"
    else
        skip "starship already installed"
    fi

    # zoxide
    if ! have zoxide; then
        info "Installing zoxide"
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    else
        skip "zoxide already installed"
    fi

    # uv
    if ! have uv; then
        info "Installing uv"
        curl -LsSf https://astral.sh/uv/install.sh | sh
    else
        skip "uv already installed"
    fi

    # eza and bottom (prebuilt release binaries)
    install_release_binary "eza" \
        "https://github.com/eza-community/eza/releases/latest/download/eza_${ra}-unknown-linux-gnu.tar.gz" \
        "eza"
    install_release_binary "bottom" \
        "https://github.com/ClementTsang/bottom/releases/latest/download/bottom_${ra}-unknown-linux-gnu.tar.gz" \
        "btm"

    # neovim (official tarball; apt's is far older than the README's 11.0)
    if ! have nvim; then
        info "Installing neovim"
        local tmp
        tmp=$(mktemp -d)
        download "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${na}.tar.gz" "$tmp/nvim.tar.gz"
        tar -xzf "$tmp/nvim.tar.gz" -C "$HOME/.local" --strip-components=1
        rm -rf "$tmp"
    else
        skip "neovim already installed"
    fi

    # fnm + node + npm-distributed tools (markdownlint-cli, diff-so-fancy)
    if ! have fnm; then
        info "Installing fnm"
        curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/share/fnm" --skip-shell
    else
        skip "fnm already installed"
    fi
    export PATH="$HOME/.local/share/fnm:$LOCAL_BIN:$PATH"
    if have fnm; then
        # --shell bash: fnm can't infer the shell from a non-interactive script.
        eval "$(fnm env --shell bash)"
        if ! fnm ls 2>/dev/null | grep -q 'v[0-9]'; then
            info "Installing the LTS Node via fnm"
            fnm install --lts
        fi
        fnm use lts-latest >/dev/null 2>&1 || true
        fnm default lts-latest >/dev/null 2>&1 || true
        if have npm; then
            have markdownlint || { info "Installing markdownlint-cli"; npm install -g markdownlint-cli; }
            have diff-so-fancy || { info "Installing diff-so-fancy"; npm install -g diff-so-fancy; }
        fi
    fi

    skip "reattach-to-user-namespace, uutils-coreutils and Nerd Font are macOS-only"
}

# ---------------------------------------------------------------------------
# Python tools (uv)
# ---------------------------------------------------------------------------

setup_python_tools() {
    info "Installing Python 3.14, ruff, ty and pgcli"
    uv python install 3.14
    uv tool install --python 3.14 ruff
    uv tool install --python 3.14 ty
    uv tool install --python 3.14 --with psycopg-binary pgcli
}

# ---------------------------------------------------------------------------
# Coding agents (Claude Code, Pi)
# ---------------------------------------------------------------------------

setup_agents() {
    # Claude Code: official native installer, drops `claude` into ~/.local/bin.
    if have claude; then
        skip "Claude Code already installed"
    else
        info "Installing Claude Code"
        curl -fsSL https://claude.ai/install.sh | bash || warn "Claude Code install failed (continuing)"
    fi

    # Pi coding agent: npm-distributed, exposes the `pi` command. Needs node/npm,
    # which the macOS and Linux paths above install.
    if have pi; then
        skip "Pi coding agent already installed"
    elif have npm; then
        info "Installing the Pi coding agent"
        npm install -g --ignore-scripts @earendil-works/pi-coding-agent || warn "Pi install failed (continuing)"
    else
        warn "npm unavailable; cannot install the Pi coding agent"
    fi
}

main() {
    case "$(uname -s)" in
        Darwin) info "Detected macOS"; setup_macos ;;
        Linux)  info "Detected Linux";  setup_linux ;;
        *) warn "Unsupported OS: $(uname -s)"; exit 1 ;;
    esac

    setup_python_tools
    setup_agents

    echo
    info "Done. Tools installed."
    echo "${YELLOW}Note:${RESET} some tools install into ~/.local/bin, ~/.cargo/bin and"
    echo "      ~/.local/share/fnm -- the dotfiles' .zshrc adds these to PATH."
    echo "      Run ${GREEN}./bootstrap.sh${RESET} next to symlink the config files."
}

main "$@"
