return { {
    'williamboman/mason.nvim',
    lazy = false,
    opts = {}
}, -- Autocompletion
    {
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        config = function()
            local cmp = require('cmp')

            cmp.setup({
                sources = { {
                    name = 'nvim_lsp'
                } },
                mapping = cmp.mapping.preset.insert({
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-d>'] = cmp.mapping.scroll_docs(4),

                    -- Use enter to confirm completion
                    ['<CR>'] = cmp.mapping.confirm({
                        select = false
                    }),

                    -- Navigate completions with <C-j> and <C-k>
                    ["<C-j>"] = cmp.mapping.select_next_item({
                        behavior = cmp.SelectBehavior.Insert
                    }),
                    ["<C-k>"] = cmp.mapping.select_prev_item({
                        behavior = cmp.SelectBehavior.Insert
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
                    end
                }
            })
        end
    }, -- LSP
    {
        'neovim/nvim-lspconfig',
        cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = { { 'hrsh7th/cmp-nvim-lsp' }, { 'williamboman/mason.nvim' }, { 'williamboman/mason-lspconfig.nvim' } },
        init = function()
            -- Reserve a space in the gutter
            -- This will avoid an annoying layout shift in the screen
            vim.opt.signcolumn = 'yes'
        end,
        config = function()
            local lsp_defaults = require('lspconfig').util.default_config

            -- Add cmp_nvim_lsp capabilities settings to lspconfig
            -- This should be executed before you configure any language server
            lsp_defaults.capabilities = vim.tbl_deep_extend('force', lsp_defaults.capabilities,
                require('cmp_nvim_lsp').default_capabilities())

            -- Define the autoformat function locally
            local buffer_autoformat = function(bufnr)
                local group = 'lsp_autoformat'
                vim.api.nvim_create_augroup(group, {
                    clear = false
                })
                vim.api.nvim_clear_autocmds({
                    group = group,
                    buffer = bufnr
                })

                vim.api.nvim_create_autocmd('BufWritePre', {
                    buffer = bufnr,
                    group = group,
                    desc = 'LSP format on save',
                    callback = function()
                        -- note: do not enable async formatting
                        vim.lsp.buf.format({
                            async = false,
                            timeout_ms = 10000
                        })
                    end
                })
            end

            -- LspAttach is where you enable features that only work
            -- if there is a language server active in the file
            vim.api.nvim_create_autocmd('LspAttach', {
                desc = 'LSP actions',
                callback = function(event)
                    -- Autoformat on save
                    local id = vim.tbl_get(event, 'data', 'client_id')
                    local client = id and vim.lsp.get_client_by_id(id)
                    if client == nil then
                        return
                    end

                    if client.supports_method('textDocument/formatting') then
                        buffer_autoformat(event.buf)
                    end

                    -- vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>',
                    --     { buffer = event.buf, desc = "Hover over selection" })
                    vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>',
                        { buffer = event.buf, desc = "Go to definition" })
                    -- Go to definition in split window: Split window, move to left and open definition
                    vim.keymap.set('n', 'gD', '<cmd>vsplit | wincmd L | lua vim.lsp.buf.declaration()<cr>',
                        { noremap = true, silent = true, desc = "Go to definition in split window" })
                    vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>',
                        { buffer = event.buf, desc = "Go to implementation" })
                    vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>',
                        { buffer = event.buf, desc = "Go to type definition" })
                    vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>',
                        { buffer = event.buf, desc = "Show references" })
                    vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>',
                        { buffer = event.buf, desc = "Show signature help" })
                    vim.keymap.set('n', 'gR', '<cmd>lua vim.lsp.buf.rename()<cr>',
                        { buffer = event.buf, desc = "Rename" })
                    vim.keymap.set({ 'n', 'x' }, 'f', '<cmd>lua vim.lsp.buf.format({async = true})<cr>',
                        { buffer = event.buf, desc = "Format selection" })
                    vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>',
                        { buffer = event.buf, desc = "Code action" })
                end
            })

            require('lspconfig').eslint.setup({
                settings = {
                    eslint = {
                        enable = true,
                        packageManager = "yarn",
                        configFiles = ".eslint.config.mjs",
                        validate = "on"
                    }
                }
            })

            require('mason').setup()

            require('mason-lspconfig').setup({
                ensure_installed = { "eslint", "clangd" },
                handlers = { -- this first function is the "default handler"
                    -- it applies to every language server without a "custom handler"
                    function(server_name)
                        require('lspconfig')[server_name].setup({})
                    end }
            })
        end
    } }
