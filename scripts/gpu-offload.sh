#!/bin/sh
# Run a command on the NVIDIA eGPU if available, otherwise use the iGPU
if nvidia-smi > /dev/null 2>&1; then
  exec env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only "$@"
else
  exec "$@"
fi
