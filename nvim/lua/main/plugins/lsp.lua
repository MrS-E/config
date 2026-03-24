return {
    {
        'williamboman/mason.nvim',
        lazy = false,
        opts = {},
    },

    -- Autocompletion
    {
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        dependencies = {
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
        },
        config = function()
            local cmp = require('cmp')

            vim.o.completeopt = 'menu,menuone,noselect'

            cmp.setup({
                window = {
                    completion = cmp.config.window.bordered({
                        max_height = 15,
                        scrollbar = true,
                    }),
                    documentation = cmp.config.window.bordered(),
                },
                view = {
                    entries = { name = 'custom', selection_order = 'top_down' },
                },
                sources = {
                    { name = 'nvim_lsp' },
                    { name = 'buffer' },
                    { name = 'path' },
                },
                mapping = cmp.mapping.preset.insert({
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-d>'] = cmp.mapping.scroll_docs(4),

                    ['<CR>'] = cmp.mapping.confirm({
                        select = false,
                    }),

                    ['<C-j>'] = cmp.mapping.select_next_item({
                        behavior = cmp.SelectBehavior.Insert,
                    }),
                    ['<C-k>'] = cmp.mapping.select_prev_item({
                        behavior = cmp.SelectBehavior.Insert,
                    }),

                    ['<Tab>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.confirm({ select = true })
                        elseif vim.snippet and vim.snippet.active() then
                            vim.snippet.jump(1)
                        else
                            fallback()
                        end
                    end, { 'i', 's' }),
                }),
                snippet = {
                    expand = function(args)
                        vim.snippet.expand(args.body)
                    end,
                },
            })

            cmp.setup.cmdline(':', {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = 'path' },
                    { name = 'cmdline' },
                },
            })

            cmp.setup.cmdline({ '/', '?' }, {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = 'buffer' },
                },
            })
        end,
    },

    -- LSP
    {
        'neovim/nvim-lspconfig',
        cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = {
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },
        },
        init = function()
            vim.opt.signcolumn = 'yes'
        end,
        config = function()
            local lspconfig = require('lspconfig')
            local util = require('lspconfig.util')
            local capabilities = require('cmp_nvim_lsp').default_capabilities()

            local buffer_autoformat = function(bufnr)
                local group = 'lsp_autoformat'
                vim.api.nvim_create_augroup(group, { clear = false })
                vim.api.nvim_clear_autocmds({
                    group = group,
                    buffer = bufnr,
                })

                vim.api.nvim_create_autocmd('BufWritePre', {
                    buffer = bufnr,
                    group = group,
                    desc = 'LSP format on save',
                    callback = function()
                        vim.lsp.buf.format({
                            async = false,
                            timeout_ms = 10000,
                        })
                    end,
                })
            end

            vim.api.nvim_create_autocmd('LspAttach', {
                desc = 'LSP actions',
                callback = function(event)
                    local id = vim.tbl_get(event, 'data', 'client_id')
                    local client = id and vim.lsp.get_client_by_id(id)
                    if client == nil then
                        return
                    end

                    if client.supports_method('textDocument/formatting') then
                        buffer_autoformat(event.buf)
                    end

                    local opts = function(desc)
                        return { buffer = event.buf, desc = desc }
                    end

                    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts('Go to definition'))
                    vim.keymap.set(
                        'n',
                        'gD',
                        '<cmd>vsplit | wincmd L | lua vim.lsp.buf.declaration()<cr>',
                        { noremap = true, silent = true, buffer = event.buf, desc = 'Go to declaration in split window' }
                    )
                    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts('Go to implementation'))
                    vim.keymap.set('n', 'go', vim.lsp.buf.type_definition, opts('Go to type definition'))
                    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts('Show references'))
                    vim.keymap.set('n', 'gs', vim.lsp.buf.signature_help, opts('Show signature help'))
                    vim.keymap.set('n', 'gR', vim.lsp.buf.rename, opts('Rename'))
                    vim.keymap.set({ 'n', 'x' }, 'f', function()
                        vim.lsp.buf.format({ async = true })
                    end, opts('Format selection'))
                    vim.keymap.set('n', '<F4>', vim.lsp.buf.code_action, opts('Code action'))
                end,
            })

            require('mason').setup()

            require('mason-lspconfig').setup({
                ensure_installed = { 'eslint', 'clangd', 'lua_ls' },
                handlers = {
                    function(server_name)
                        local opts = {
                            capabilities = capabilities,
                        }

                        if server_name == 'clangd' then
                            opts.cmd = { 'clangd', '--background-index' }
                        elseif server_name == 'eslint' then
                            opts.settings = {
                                eslint = {
                                    enable = true,
                                    packageManager = 'yarn',
                                    configFile = '.eslint.config.mjs',
                                    validate = 'on',
                                },
                            }
                        elseif server_name == 'lua_ls' then
                            opts.settings = {
                                Lua = {
                                    diagnostics = {
                                        globals = { 'vim' },
                                    },
                                },
                            }
                        end

                        lspconfig[server_name].setup(opts)
                    end,
                },
            })

            lspconfig.sourcekit.setup({
                capabilities = capabilities,
                cmd = {
                    '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp',
                },
                root_dir = function(fname)
                    return util.root_pattern('buildServer.json')(fname)
                        or util.root_pattern('*.xcodeproj', '*.xcworkspace')(fname)
                        or util.find_git_ancestor(fname)
                        or util.root_pattern('Package.swift')(fname)
                end,
            })
        end,
    },
}