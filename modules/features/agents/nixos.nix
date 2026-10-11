{ inputs, ... }:
{
  nixpkgs.overlays = [
    (final: _: {
      # dsh boots through a native addon that cannot find Node's internal loader in
      # nixpkgs' node (numtide/llm-agents.nix#9994). The wrapper already passes
      # --expose-internals, so plain require reaches those modules. Drop once fixed upstream.
      dsh = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system}.dsh.overrideAttrs (old: {
        postInstall = old.postInstall + ''
          substituteInPlace \
            $out/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai/dsh-app-boot/lib/index.js \
            --replace-fail 'createRequire(import.meta.url)("node-addon-require-builtin")' \
            '{ requireBuiltin: createRequire(import.meta.url) }'
        '';
      });
    })
  ];
}
