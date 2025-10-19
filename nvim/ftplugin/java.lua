-- ftplugin/java.lua
-- Starts/attaches Eclipse JDT Language Server via nvim-jdtls.
-- Works alongside your existing LspAttach mappings/format-on-save.

local ok, jdtls = pcall(require, "jdtls")
if not ok then
  return
end

-- Detect project root
local root_markers = { "gradlew", "mvnw", "pom.xml", "build.gradle", ".git" }
local root_dir = require("jdtls.setup").find_root(root_markers)
if not root_dir then
  return
end

-- Per-project workspace
local home = vim.env.HOME
local ws_dir = home .. "/.local/share/jdtls-workspace/" .. vim.fn.fnamemodify(root_dir, ":p:h:t")

-- Mason paths
local mason = vim.fn.stdpath("data") .. "/mason"
local jdtls_dir = mason .. "/packages/jdtls"

-- OS config dir for JDTLS
local uname = vim.loop.os_uname().sysname
local config_os = (uname == "Darwin") and "config_mac"
  or (uname == "Windows_NT") and "config_win"
  or "config_linux"

-- Launcher jar
local launcher = vim.fn.glob(jdtls_dir .. "/plugins/org.eclipse.equinox.launcher_*.jar")

-- Debug & Test bundles (if installed)
local bundles = {}
local dbg = vim.fn.glob(mason .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar")
if dbg ~= "" then table.insert(bundles, dbg) end
for _, b in ipairs(vim.split(vim.fn.glob(mason .. "/packages/java-test/extension/server/*.jar"), "\n")) do
  if b ~= "" then table.insert(bundles, b) end
end

-- Capabilities (use your cmp capabilities)
local capabilities = require("cmp_nvim_lsp").default_capabilities()

local cmd = {
  "java",
  "-Declipse.application=org.eclipse.jdt.ls.core.id1",
  "-Dosgi.bundles.defaultStartLevel=4",
  "-Declipse.product=org.eclipse.jdt.ls.core.product",
  "-Dlog.protocol=true",
  "-Dlog.level=ALL",
  "-Xms1g",
  "--add-modules=ALL-SYSTEM",
  "--add-opens", "java.base/java.util=ALL-UNNAMED",
  "--add-opens", "java.base/java.lang=ALL-UNNAMED",
  "-jar", launcher,
  "-configuration", jdtls_dir .. "/" .. config_os,
  "-data", ws_dir,
}

local settings = {
  java = {
    format = { enabled = true }, -- your LspAttach already formats on save
    signatureHelp = { enabled = true },
    contentProvider = { preferred = "fernflower" },
  },
}

local on_attach = function(_, bufnr)
  jdtls.setup_dap({ hotcodereplace = "auto" })
  jdtls.add_commands()

  -- Java extras (your global LSP keymaps already exist)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end
  map("n", "<leader>oi", jdtls.organize_imports, "Java: Organize Imports")
  map("n", "<leader>tc", jdtls.test_class, "Java Test: Class")
  map("n", "<leader>tn", jdtls.test_nearest_method, "Java Test: Nearest")
  map("v", "<leader>em", function() jdtls.extract_method(true) end, "Java: Extract Method")
end

jdtls.start_or_attach({
  cmd = cmd,
  root_dir = root_dir,
  settings = settings,
  capabilities = capabilities,
  init_options = { bundles = bundles },
  on_attach = on_attach,
})

