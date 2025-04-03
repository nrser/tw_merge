# Ref: https://ryantm.github.io/nixpkgs/languages-frameworks/beam/#elixir---phoenix-project
# 
# Start up with:
# 
#     nix-shell
# 
# > Initializing the project will require the following steps:
# > 
# > 1.  create the db directory (inside your mix project folder)
# >     
# >         initdb ./var/db
# >     
# > 2.  start the postgres instance
# >     
# >         pg_ctl -l "$PGDATA/server.log" start
# > 
# > 3.  create the postgres user
# >     
# >         createuser postgres -ds
# >     
# > 4.  create the db
# >     
# >         createdb adept_dev
# >     
# > 5.  you can start your phoenix server and get a shell with
# >     
# >         iex -S mix phx.server
# >     
# >     but we use
# >     
# >         ./dev/bin/console phx.server
# >     
# 
with import <nixpkgs> { };

let
  # define packages to install
  basePackages = [
    glibcLocales
    git
    # replace with beam.packages.erlang.elixir_1_13 if you need
    beam.packages.erlang.elixir
    beam.packages.erlang.elixir-ls
    starship
  ];

  inputs = basePackages ++ lib.optionals stdenv.isLinux [ inotify-tools ]
    ++ lib.optionals stdenv.isDarwin
    (with darwin.apple_sdk.frameworks; [ CoreFoundation CoreServices ]);

  # define shell startup command
  hooks = ''
    # this allows mix to work on the local directory
    mkdir -p .nix-mix .nix-hex
    export MIX_HOME=$PWD/.nix-mix
    export HEX_HOME=$PWD/.nix-mix
    
    # Enable git tab completion
    source ${pkgs.git}/share/git/contrib/completion/git-completion.bash
    
    # make hex from Nixpkgs available
    # `mix local.hex` will install hex into MIX_HOME and should take precedence
    export MIX_PATH="${beam.packages.erlang.hex}/lib/erlang/lib/hex/ebin"
    export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    export LC_CTYPE=en_US.UTF-8
    # keep your shell history in iex
    export ERL_AFLAGS="-kernel shell_history enabled"
    
    # shell aliases
    alias ll='ls -lahG'

    # Initialize starship prompt
    eval "$(starship init bash)"

    # Wrap `mix` command in a shell function to turn a failed
    # 
    #     mix NAME [...] --help
    # 
    # into
    # 
    #     mix help NAME | less
    #
    mix() {
      command mix "$@" || {
        if [[ " $* " =~ " --help " ]]; then
          mix help $(echo "$1" | cut -d. -f1) | less
        else
          return $?
        fi
      }
    }
  '';

in mkShell {
  buildInputs = inputs;
  shellHook = hooks;
  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
}