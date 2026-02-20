{
  description = "Mitsuba development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        };

        llvmPackages = pkgs.llvmPackages_18;

        # Main Python packages (installed first)
        pythonRequirements = pkgs.writeText "requirements.txt" ''
          pytest>=8.3.3,<9
          numpy>=2.1.2,<3
          tqdm>=4.67.1,<5
          notebook>=7.4.2,<8
          ipywidgets>=8.1.7,<9
          matplotlib>=3.10.1,<4
          cholespy>=2.1.0,<3
          torch>=2.5.1,<3
          torchvision>=0.20.1,<0.21
          torchaudio>=2.5.1,<3
          gpytoolbox>=0.3.0,<0.4
          sphinx>=8.2.3,<9
          sphinxcontrib-katex>=0.9.10,<0.10
          furo
          enum-tools[sphinx]>=0.13.0,<0.14
          sphinxcontrib-svg2pdfconverter>=1.3.0,<2
          esbonio>=0.16.5,<0.17
          importlib-resources>=6.5.2,<7
          pythreejs>=2.4.2,<3
          scipy>=1.15.3,<2
          typing-extensions
          nvtx>=0.2.12,<0.3
          omegaconf>=2.3.0,<3
          commentjson>=0.9.0,<0.10
          polyscope>=2.4.0,<3
          jupytext>=1.17.2,<2
          graphviz>=0.21,<0.22
          tyro>=1.0.2,<2
          flip-evaluator>=1.6.0.1,<2
        '';

        # Packages that depend on torch (installed second)
        pythonRequirementsTcnn = pkgs.writeText "requirements-tcnn.txt" ''
          git+https://github.com/NVlabs/tiny-cuda-nn.git@2e757bbe781db59c4980d389d7dccbf5edc09669#subdirectory=bindings/torch
        '';
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            # Build tools
            cmake
            ninja
            pkg-config
            ccache

            # Bash with completion support for setpath.sh
            bashInteractive
            bash-completion

            # Compilers - GCC
            gcc13

            # Compilers - LLVM/Clang 18
            llvmPackages.clang
            llvmPackages.libcxx
            llvmPackages.libcxxClang
            llvmPackages.compiler-rt
            llvmPackages.llvm
            llvmPackages.lld

            # Linkers
            mold

            # Debugger
            gdb

            # Other tools
            curl

            # CUDA and OptiX
            cudaPackages.cudatoolkit
            cudaPackages.cuda_nvcc
            cudaPackages.cuda_cudart

            # Python with venv
            python312
            python312Packages.pip
            python312Packages.virtualenv
          ];

          buildInputs = with pkgs; [
            # Libraries
            zlib
            embree

            # EGL
            libglvnd
            mesa

            # Additional system libraries that might be needed
            xorg.libX11
            xorg.libXrandr
            xorg.libXinerama
            xorg.libXcursor
            xorg.libXi
            libGL

            # For building Python packages
            stdenv.cc.cc.lib
          ];

          shellHook = ''
            # Patch bin2c.cmake for CMake 4.x compatibility
            if [ -f "mitsuba3/ext/nanogui/resources/bin2c.cmake" ]; then
              sed -i '1s/cmake_minimum_required (VERSION [0-9.]*)/cmake_minimum_required (VERSION 3.5)/' \
                mitsuba3/ext/nanogui/resources/bin2c.cmake
            fi

            # Set up environment variables similar to pixi
            export CMAKE_CXX_COMPILER_LAUNCHER=ccache
            export CMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH:${pkgs.cudaPackages.cudatoolkit}"
            export CUDA_TOOLKIT_ROOT_DIR="${pkgs.cudaPackages.cudatoolkit}"
            export CUDA_PATH="${pkgs.cudaPackages.cudatoolkit}"
            # Set LD_LIBRARY_PATH with Nix libraries first (higher priority)
            # Then append system paths for OptiX and other Ubuntu libs
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
              pkgs.zlib
              pkgs.embree
              pkgs.libglvnd
              pkgs.mesa
              pkgs.cudaPackages.cudatoolkit
              llvmPackages.libcxx
              llvmPackages.llvm
              llvmPackages.compiler-rt
              pkgs.stdenv.cc.cc.lib
            ]}:$LD_LIBRARY_PATH:/usr/lib/x86_64-linux-gnu:/usr/lib"

            # LLVM-specific environment variables for Dr.Jit
            export LLVM_DIR="${llvmPackages.llvm.dev}"
            export LLVM_LIBRARY_DIR="${llvmPackages.llvm.lib}/lib"
            export DRJIT_LIBLLVM_PATH="${llvmPackages.llvm.lib}/lib/libLLVM.so"

            # OptiX paths (if available in CUDA toolkit)
            if [ -d "${pkgs.cudaPackages.cudatoolkit}/include/optix" ]; then
              export OPTIX_ROOT="${pkgs.cudaPackages.cudatoolkit}"
            fi

            # Set up Python virtual environment
            export VENV_DIR=".venv"

            if [ ! -d "$VENV_DIR" ]; then
              echo "Creating Python virtual environment..."
              python -m venv "$VENV_DIR"
            fi

            # Activate virtual environment
            source "$VENV_DIR/bin/activate"

            # Install/update Python dependencies if requirements changed
            REQUIREMENTS_HASH=$(sha256sum ${pythonRequirements} ${pythonRequirementsTcnn} | sha256sum | cut -d' ' -f1)
            INSTALLED_HASH_FILE="$VENV_DIR/.requirements_hash"

            if [ ! -f "$INSTALLED_HASH_FILE" ] || [ "$(cat $INSTALLED_HASH_FILE)" != "$REQUIREMENTS_HASH" ]; then
              echo "Installing Python dependencies (stage 1: main packages)..."
              pip install --upgrade pip
              pip install -r ${pythonRequirements}

              echo "Installing Python dependencies (stage 2: packages requiring torch)..."
              pip install --no-build-isolation -r ${pythonRequirementsTcnn}

              echo "$REQUIREMENTS_HASH" > "$INSTALLED_HASH_FILE"
              echo "Python dependencies installed successfully!"
            fi

            # Source the Mitsuba setpath script if it exists
            if [ -f mitsuba3/build-mitsuba/setpath.sh ]; then
              source mitsuba3/build-mitsuba/setpath.sh
            fi

            echo ""
            echo "Mitsuba development environment loaded"
            echo "======================================="
            echo "Python: $(python --version)"
            echo "CMake: $(cmake --version | head -n1)"
            echo "Clang: $(clang --version | head -n1)"
            echo "GCC: $(gcc --version | head -n1)"
            echo "CUDA: ${pkgs.cudaPackages.cudatoolkit.version}"
            echo ""
            echo "Virtual environment active at: $VENV_DIR"
          '';
        };
      }
    );
}
