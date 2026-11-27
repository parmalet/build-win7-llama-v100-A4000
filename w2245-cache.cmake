# ============================================================================
# W-2245 (Cascade Lake) + RTX A4000 (sm_86) 构建缓存
# 复用 win7-cache.cmake 的 Win7 兼容宏，CPU 指令集基线改为【AVX2】。
# ============================================================================

# ---- Win7 兼容宏（与原包一致，编译产物需能在 Win7 启动）----
set(CMAKE_C_FLAGS "/D_WIN32_WINNT=0x0601 /DWINVER=0x0601" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS "/D_WIN32_WINNT=0x0601 /DWINVER=0x0601" CACHE STRING "" FORCE)
# CUDA 宏必须用 nvcc 的 -D 语法（/D 会被当输入文件，报 single input file）。
# 此值一次性给全：命令行 -DCMAKE_CUDA_FLAGS 会覆盖本 CACHE FORCE，workflow 不要重复传。
# -allow-unsupported-compiler：让 nvcc 11.4 接受 VS2019(cl 19.2x) host 编译器。
set(CMAKE_CUDA_FLAGS "-D_WIN32_WINNT=0x0601 -DWINVER=0x0601 -allow-unsupported-compiler" CACHE STRING "" FORCE)

# ---- CPU 指令集基线：AVX2 (W-2245 Cascade Lake，8C16T，双 FMA) ----
# 陷阱同 v1.0.0 ggml/CMakeLists.txt：
#   if (GGML_NATIVE OR NOT GGML_NATIVE_DEFAULT) set(INS_ENB OFF) else() set(INS_ENB ON)
#   -> 命令行设 -DGGML_NATIVE=OFF 会让 AVX/AVX2/BMI2/SSE42 默认全 ON。
# 这次运行机 W-2245 支持 AVX2/FMA/BMI2，所以「默认全开」方向正确，但：
#   (1) 必须显式 FORCE，保证跨 runner 可复现、不依赖 runner 自身 CPU；
#   (2) AVX-512 必须显式关 —— Cascade Lake 只有 AVX512F/CD/BW/DQ/VL，
#       没有 VNNI/BF16/VBMI；若 INS_ENB=ON 把它们开了，W-2245 会 0xc000001d。
#   (3) AVX2 + 双 FMA 已是 llama.cpp CPU 推理甜点，AVX512 对量化推理收益不稳定
#       （且部分实现会降频），故默认锁 AVX2 而非 AVX512。
# 想在 W-2245 上试 AVX512：把 GGML_AVX2 改 OFF、GGML_AVX512 改 ON，
#   并保持下面三个 AVX512 子项 = OFF，重编后务必实机跑一轮确认不崩。
set(GGML_NATIVE      OFF CACHE BOOL "" FORCE)
set(GGML_SSE42       ON  CACHE BOOL "" FORCE)
set(GGML_AVX         ON  CACHE BOOL "" FORCE)
set(GGML_AVX2        ON  CACHE BOOL "" FORCE)
set(GGML_FMA         ON  CACHE BOOL "" FORCE)
set(GGML_F16C        ON  CACHE BOOL "" FORCE)
set(GGML_BMI2        ON  CACHE BOOL "" FORCE)
set(GGML_AVX_VNNI    OFF CACHE BOOL "" FORCE)   # Cascade Lake 不支持 AVX-VNNI
set(GGML_AVX512      OFF CACHE BOOL "" FORCE)   # 默认关，见上说明
set(GGML_AVX512_VBMI OFF CACHE BOOL "" FORCE)   # Cascade Lake 不支持
set(GGML_AVX512_VNNI OFF CACHE BOOL "" FORCE)   # Cascade Lake 不支持
set(GGML_AVX512_BF16 OFF CACHE BOOL "" FORCE)   # Cascade Lake 不支持
set(GGML_AMX_TILE    OFF CACHE BOOL "" FORCE)
set(GGML_AMX_INT8    OFF CACHE BOOL "" FORCE)
set(GGML_AMX_BF16    OFF CACHE BOOL "" FORCE)
