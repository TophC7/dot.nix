{
  lib,
  pkgs,
  ...
}:
let
  modelDir = "/store/llama/models";
  coreFiles = [
    {
      repository = "Jackrong/Qwen3.5-9B-Claude-4.6-Opus-Reasoning-Distilled-GGUF";
      revision = "6b811564b420ece28d5a413a75a8d397e6220dae";
      name = "Qwen3.5-9B.Q8_0.gguf";
      sha256 = "01ab75e862bf61c2fd20babc55d396181580722b7af76ec4ebfb83224218c723";
    }
    {
      repository = "Jackrong/Qwen3.5-9B-Claude-4.6-Opus-Reasoning-Distilled-GGUF";
      revision = "6b811564b420ece28d5a413a75a8d397e6220dae";
      name = "mmproj-F32.gguf";
      sha256 = "21c10ed72802e4859575e051f5017432fce77501bb0329912fe9a8ad11f4400e";
    }
  ];
  extraFiles = [
    {
      repository = "bigatuna/Qwen3.5-9b-Sushi-Coder-RL-GGUF";
      revision = "c29d1417c6fead5838a928ccf3c5735a2604d0e2";
      name = "Qwen3.5-9b-Sushi-Coder-RL.Q8_0.gguf";
      sha256 = "e7c908a04634b895ada9be7efbdb3649cc146adea07b4438b964131f67c68bb4";
    }
    {
      repository = "bigatuna/Qwen3.5-9b-Sushi-Coder-RL-GGUF";
      revision = "c29d1417c6fead5838a928ccf3c5735a2604d0e2";
      name = "Qwen3.5-9b-Sushi-Coder-RL.BF16-mmproj.gguf";
      sha256 = "002e0f739eb83dd3a2bd8d9bb58909c0a85aa571ca0b3b140bece1c010535d6c";
    }
    {
      repository = "Jackrong/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-v2-GGUF";
      revision = "2fc6465288bfa3695eda8fc367e5ccb7e5609f0a";
      name = "Qwen3.5-27B.Q4_K_M.gguf";
      target = "Qwen3.5-27B-Opus-v2.Q4_K_M.gguf";
      sha256 = "51ce67b6936e98b60abc4f61af79c3f5edd1610871818a917df55baae06d631b";
    }
    {
      repository = "Jackrong/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-v2-GGUF";
      revision = "2fc6465288bfa3695eda8fc367e5ccb7e5609f0a";
      name = "mmproj-F32.gguf";
      target = "Qwen3.5-27B-Opus-v2.mmproj-F32.gguf";
      sha256 = "191cc67513358de838abaae1e35900f5f47cbeca2efffda0dae6713dbaf72240";
    }
    {
      repository = "deepreinforce-ai/Ornith-1.0-35B-GGUF";
      revision = "383064f72a1ef3087b779f268d3ca117eb989aac";
      name = "ornith-1.0-35b-Q4_K_M.gguf";
      sha256 = "ff25291b2599fb927a835e624d2b3540106af61761c3fa57ac4264046dbec002";
    }
  ];
  downloadFile =
    file:
    let
      target = file.target or file.name;
    in
    ''
      set target "${modelDir}/${target}"
      set partial "$target.part"

      echo "Verifying ${target}"
      if valid "${file.sha256}" "$target"
        ${pkgs.coreutils}/bin/chown root:root "$target"
        ${pkgs.coreutils}/bin/chmod 0444 "$target"
      else
        ${pkgs.coreutils}/bin/rm -f "$target"
        echo "Downloading ${target}"
        ${lib.getExe pkgs.curl} \
          --continue-at - \
          --connect-timeout 30 \
          --fail-with-body \
          --location \
          --output "$partial" \
          --retry 5 \
          --retry-all-errors \
          --show-error \
          --silent \
          "https://huggingface.co/${file.repository}/resolve/${file.revision}/${file.name}"

        if not valid "${file.sha256}" "$partial"
          echo "${target} failed SHA-256 verification" >&2
          ${pkgs.coreutils}/bin/rm -f "$partial"
          exit 1
        end

        ${pkgs.coreutils}/bin/mv "$partial" "$target"
        ${pkgs.coreutils}/bin/chown root:root "$target"
        ${pkgs.coreutils}/bin/chmod 0444 "$target"
      end
    '';
  provisionFiles =
    name: files:
    pkgs.writeScript name ''
      #!${lib.getExe pkgs.fish}

      function valid --argument-names hash path
        test -f "$path"; and echo "$hash  $path" | ${pkgs.coreutils}/bin/sha256sum --check --status
      end

      ${pkgs.coreutils}/bin/mkdir -p ${modelDir}
      ${lib.concatMapStringsSep "\n\n" downloadFile files}
    '';
  provisionCoreModels = provisionFiles "provision-llama-models" coreFiles;
  provisionExtraModels = provisionFiles "provision-extra-llama-models" extraFiles;
in
{
  environment.etc."llama/models.ini".text = ''
    version = 1

    [*]
    ctx-size = 131072
    parallel = 1
    flash-attn = on
    cache-type-k = f16
    cache-type-v = f16

    threads = 8
    threads-batch = 8
    batch-size = 4096
    ubatch-size = 1024

    temp = 0.6
    top-k = 20
    top-p = 0.95
    min-p = 0
    presence-penalty = 0

    jinja = true
    reasoning-format = deepseek

    cache-ram = 2048
    ctx-checkpoints = 8
    checkpoint-min-step = 4096

    [qwen3.5-9b-opus-reasoning]
    model = ${modelDir}/Qwen3.5-9B.Q8_0.gguf
    mmproj = ${modelDir}/mmproj-F32.gguf
    image-min-tokens = 1024
    gpu-layers = 99
    fit = off
    load-on-startup = true

    [qwen3.5-9b-sushi-coder-rl]
    model = ${modelDir}/Qwen3.5-9b-Sushi-Coder-RL.Q8_0.gguf
    mmproj = ${modelDir}/Qwen3.5-9b-Sushi-Coder-RL.BF16-mmproj.gguf
    image-min-tokens = 1024
    gpu-layers = 99
    fit = off

    [qwen3.5-27b-opus-reasoning-v2]
    model = ${modelDir}/Qwen3.5-27B-Opus-v2.Q4_K_M.gguf
    mmproj = ${modelDir}/Qwen3.5-27B-Opus-v2.mmproj-F32.gguf
    no-mmproj-offload = true
    image-min-tokens = 1024
    fit = on

    [ornith-1.0-35b]
    model = ${modelDir}/ornith-1.0-35b-Q4_K_M.gguf
    fit = on
  '';

  systemd.services = {
    llama-models = {
      description = "Provision required llama.cpp models";
      requires = [ "store.mount" ];
      after = [
        "network-online.target"
        "store.mount"
      ];
      wants = [ "network-online.target" ];
      unitConfig.RequiresMountsFor = modelDir;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = provisionCoreModels;
        RemainAfterExit = true;
        TimeoutStartSec = "30min";
      };
    };

    llama-models-extra = {
      description = "Provision optional llama.cpp models";
      wantedBy = [ "multi-user.target" ];
      requires = [ "store.mount" ];
      after = [
        "llama-cpp.service"
        "network-online.target"
        "store.mount"
      ];
      wants = [ "network-online.target" ];
      unitConfig.RequiresMountsFor = modelDir;
      serviceConfig = {
        Type = "exec";
        ExecStart = provisionExtraModels;
        Restart = "on-failure";
        RestartSec = "1min";
      };
    };

    llama-cpp = {
      requires = [ "llama-models.service" ];
      after = [ "llama-models.service" ];
    };
  };
}
