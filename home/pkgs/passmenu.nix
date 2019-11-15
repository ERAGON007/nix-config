{ config, pkgs, ... }:
let
  alacritty = "${pkgs.alacritty}/bin/alacritty";
  fzf = "${pkgs.fzf}/bin/fzf";
  gopass = "${pkgs.gopass}/bin/gopass";
  notify-send = "${pkgs.libnotify}/bin/notify-send";
  wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
in
{
  nixpkgs.overlays = [
    (self: super: {
      passmenu = super.writeScriptBin "passmenu" ''
        #!${super.stdenv.shell}

        shopt -s nullglob globstar
        passmenu_path="$(readlink -f "$0")"
        passmenu_fifo="/tmp/passmenu_fifo"
        passmenu_lock="/tmp/passmenu_lock"
        passmenu_icon="${config.home.homeDirectory}/.config/gopass/gopass-logo-small.png"

        function passmenu_lock() {
            if [[ -f "$passmenu_lock" ]]; then
                notify-send "✖️ Passmenu already running"
                exit 1
            else
                touch "$passmenu_lock"
            fi
        }

        function passmenu_unlock() {
            if [[ -f "$passmenu_lock" ]]; then
                rm -f "$passmenu_lock"
            fi
        }

        function passmenu_window() {
            prefix=''${PASSWORD_STORE_DIR-~/.password-store}
            password_files=( "$prefix"/**/*.gpg )
            password_files=( "''${password_files[@]#"$prefix"/}" )
            password_files=( "''${password_files[@]%.gpg}" )

            name="$(printf '%s\n' "''${password_files[@]}" | ${fzf} --delimiter '/' --nth 2)"

            echo "$name" > "$passmenu_fifo"
        }

        function passmenu_backend() {
            passmenu_lock
            export PASSMENU_BEHAVE_AS_WINDOW=1;
            ${alacritty} -d 80 20 -t passmenu --class passmenu -e "$passmenu_path"

            name="$(cat /tmp/passmenu_fifo)"
            rm -f /tmp/passmenu_fifo
            if [ "$name" == "" ]; then
                passmenu_unlock
                exit 1
            fi

            ${gopass} show --password "$name" | ${wl-copy} -o
            ${notify-send} -i "$passmenu_icon" "Copied ''${name#*/} to clipboard."
            passmenu_unlock
        }

        if [[ -v PASSMENU_BEHAVE_AS_WINDOW ]]; then
            passmenu_window
        else
            passmenu_backend
        fi
      '';
    })
  ];
}
