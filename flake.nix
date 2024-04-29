{

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default =
        pkgs.mkShell
          {
            nativeBuildInputs = with pkgs; [
              # pkgsconfig
              pkg-config
              clang
              lld
            ];
            buildInputs = with pkgs; [
              # (odin.overrideAttrs (finalAttr: prevAttr: {
              #
              #   src = fetchFromGitHub {
              #     owner = "odin-lang";
              #     repo = "Odin";
              #     rev = "dev-2024-04a"; # version of the branch
              #     hash = "";
              #     # name = "${finalAttr.pname}-${finalAttr.version}"; # not gona work .
              #   };
              #
              #   preBuild = ''
              #
              #     echo "# for use of STB libraries"
              #     cd vendor/stb/src
              #     make
              #     cd ../../..
              #
              #   '';
              #
              # }))
              odin
              ols

              # SDL
              SDL2
              SDL2_mixer
              SDL2_ttf
              SDL

              glfw

              vulkan-headers
              vulkan-loader
              vulkan-tools

              glxinfo
              lld
              gnumake
              xorg.libX11.dev
              xorg.libX11
              xorg.libXft
              xorg.libXi
              xorg.libXinerama
              libGL

              # not need because of vendor
              stb
              lua

              # debugging stuff and profile
              valgrind
              rr
              gdb
              lldb
              gf

              renderdoc


              xorg.libXcursor
              xorg.libXrandr
              xorg.libXinerama
              wayland
            ];

            shellHook = ''
              export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${
                pkgs.lib.makeLibraryPath [
                  pkgs.libGL
                  pkgs.xorg.libX11
                  pkgs.xorg.libXi

                  # for SDL and SDL2
                  pkgs.SDL2
                  pkgs.SDL2_mixer
                  pkgs.SDL2_ttf
                  pkgs.SDL

                  # for vulkan and GLFW
                  pkgs.vulkan-loader
                  pkgs.glfw
                ]
              }"
            '';
          };
    };
}
