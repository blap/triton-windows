@echo off
echo Testing NVIDIA toolchain ZIP file downloads...
echo ==============================================

echo Testing ptxas (cuda_nvcc 12.9.86)
curl -I -s "https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/windows-x86_64/cuda_nvcc-windows-x86_64-12.9.86-archive.zip" | findstr "HTTP"

echo Testing cuobjdump (cuda_cuobjdump 12.9.82)
curl -I -s "https://developer.download.nvidia.com/compute/cuda/redist/cuda_cuobjdump/windows-x86_64/cuda_cuobjdump-windows-x86_64-12.9.82-archive.zip" | findstr "HTTP"

echo Testing nvdisasm (cuda_nvdisasm 12.9.88)
curl -I -s "https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvdisasm/windows-x86_64/cuda_nvdisasm-windows-x86_64-12.9.88-archive.zip" | findstr "HTTP"

echo Testing cudacrt (cuda_nvcc 12.9.86)
curl -I -s "https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/windows-x86_64/cuda_nvcc-windows-x86_64-12.9.86-archive.zip" | findstr "HTTP"

echo Testing cudart (cuda_cudart 12.9.79)
curl -I -s "https://developer.download.nvidia.com/compute/cuda/redist/cuda_cudart/windows-x86_64/cuda_cudart-windows-x86_64-12.9.79-archive.zip" | findstr "HTTP"

echo Testing cupti (cuda_cupti 12.9.79)
curl -I -s "https://developer.download.nvidia.com/compute/cuda/redist/cuda_cupti/windows-x86_64/cuda_cupti-windows-x86_64-12.9.79-archive.zip" | findstr "HTTP"

echo ==============================================
echo Test completed.