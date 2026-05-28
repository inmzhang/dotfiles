-- Rust tooling built around rust-analyzer.
-- https://github.com/mrcjkb/rustaceanvim

local gh = require('config.util').gh

vim.pack.add { { src = gh 'mrcjkb/rustaceanvim', version = vim.version.range '6.*' } }

vim.g.rustaceanvim = {
  server = {
    default_settings = {
      ['rust-analyzer'] = {
        cargo = {
          buildScripts = {
            enable = true,
          },
          extraEnv = { CARGO_PROFILE_RUST_ANALYZER_INHERITS = 'dev' },
          extraArgs = { '--profile', 'rust-analyzer' },
        },
        procMacro = {
          enable = true,
        },
      },
    },
  },
}
