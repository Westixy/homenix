{ ... }:

{
  # NVIDIA GPU (GeForce GTX 1070 Ti, Pascal).
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    # Pascal cards are not supported by the open kernel modules.
    open = false;
    # Long-lived 580 (LTSB) branch — the one for GeForce GTX 9xx–10xx.
    branch = "legacy_580";
    # Kernel modesetting; required for Wayland compositors like COSMIC.
    modesetting.enable = true;
  };
}