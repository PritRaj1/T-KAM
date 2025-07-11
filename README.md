# T-KAM 

T-KAM is a MLE model presented [here.](http://arxiv.org/abs/2506.14167)

## Setup:

Need [Conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html) and [Julia](https://github.com/JuliaLang/juliaup). Choose your favourite installer and run: 

```bash
bash <conda-installer-name>-latest-Linux-x86_64.sh
curl -fsSL https://install.julialang.org | sh
```

The [shell script](setup/setup.sh) will install all requirements auto-magically. Python dependencies will be installed into a conda environment called "T-KAM", (including [tmux](https://github.com/tmux/tmux/wiki) from conda forge). Just need to run:

```bash
bash setup/setup.sh
```

[Optional;] Test all Julia scripts:

```bash
tmux new-session -d -s T_KAM_tests "bash run_tests.sh"
```

### Note for windows users:

This repo uses shell scripts solely for convenience, you can run everything without them too. If you want to use the shell scripts, [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) is recommended.

## To run experiments:

Edit the config files:

```bash
vim config/nist_config.ini
```

For main experiments run:

```bash
tmux new-session -d -s T_KAM_main "bash run.sh"
```

For benchmarking run:

```bash
tmux new-session -d -s T_KAM_benchmark "bash benches/run_benchmarks.sh"
```

## Personal preferences

In this project, implicit types/quantization are never used. Quantization is explicitly declared in function headers using `half_quant` and `full_quant`, defined in [utils.jl](src/utils.jl). Model parameterization is also explicit.

Julia/Lux is adopted instead of PyTorch or JAX due to ‧₊˚✩♡ [substantial personal inclination](https://www.linkedin.com/posts/prithvi-raj-eng_i-moved-from-pytorch-to-jax-to-julia-a-activity-7330842135534919681-9XJF?utm_source=share&utm_medium=member_desktop&rcm=ACoAADUTwcMBFnTsuwtIbYGuiSVLmSAnTVDeOQQ)₊˚✩♡.

## Citation/license [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

The MIT license open-sources the code. The paper is licensed separately with CC license - also open with citation:

```bibtex
@misc{raj2025structuredinformedprobabilisticmodeling,
      title={Structured and Informed Probabilistic Modeling with the Thermodynamic Kolmogorov-Arnold Model}, 
      author={Prithvi Raj},
      year={2025},
      eprint={2506.14167},
      archivePrefix={arXiv},
      primaryClass={cs.LG},
      url={https://arxiv.org/abs/2506.14167}, 
}
```
