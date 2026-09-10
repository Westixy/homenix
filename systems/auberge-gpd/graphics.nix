{ ... }:

{
  # AMD Radeon 780M integrated GPU (Ryzen 7 8840U APU).
  # The `amdgpu` kernel module is loaded automatically by the kernel;
  # the video driver entry here tells X11/Wayland to use the modesetting
  # driver (which delegates to amdgpu via kernel modesetting).
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Hardware-accelerated Vulkan/OpenCL for LLM inference (Ollama, etc.).
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}