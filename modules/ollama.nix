{ config, pkgs, lib, ... }:

{
  # Ollama — local LLM server. Vulkan backend so it uses the NVIDIA GPU:
  # nixpkgs' CUDA build targets sm_75+ only, which excludes this Pascal card.
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    environmentVariables = {
      # Raise the serving context window from Ollama's 4096 default.
      # 8192 keeps both 7–8B models fully resident in 8 GiB of VRAM.
      OLLAMA_CONTEXT_LENGTH = "8192";
    };
  };
}
