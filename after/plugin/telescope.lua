local telescope_ok, telescope = pcall(require, "telescope")
if not telescope_ok then
    return
end
 
local actions = require("telescope.actions")
local transform_mod = require("telescope.actions.mt").transform_mod
local action_state = require("telescope.actions.state")
 
local function multiopen(prompt_bufnr, method)
    local edit_file_cmd_map = {
        vertical = "vsplit",
        horizontal = "split",
        tab = "tabedit",
        default = "edit",
    }
    local edit_buf_cmd_map = {
        vertical = "vert sbuffer",
        horizontal = "sbuffer",
        tab = "tab sbuffer",
        default = "buffer",
    }
    local picker = action_state.get_current_picker(prompt_bufnr)
    local multi_selection = picker:get_multi_selection()
 
    if #multi_selection > 1 then
        require("telescope.pickers").on_close_prompt(prompt_bufnr)
        pcall(vim.api.nvim_set_current_win, picker.original_win_id)
 
        for i, entry in ipairs(multi_selection) do
            local filename, row, col
 
            if entry.path or entry.filename then
                filename = entry.path or entry.filename
 
                row = entry.row or entry.lnum
                col = vim.F.if_nil(entry.col, 1)
            elseif not entry.bufnr then
                local value = entry.value
                if not value then
                    return
                end
 
                if type(value) == "table" then
                    value = entry.display
                end
 
                local sections = vim.split(value, ":")
 
                filename = sections[1]
                row = tonumber(sections[2])
                col = tonumber(sections[3])
            end
 
            local entry_bufnr = entry.bufnr
 
            if entry_bufnr then
                if not vim.api.nvim_buf_get_option(entry_bufnr, "buflisted") then
                    vim.api.nvim_buf_set_option(entry_bufnr, "buflisted", true)
                end
                local command = i == 1 and "buffer" or edit_buf_cmd_map[method]
                pcall(vim.cmd, string.format("%s %s", command, vim.api.nvim_buf_get_name(entry_bufnr)))
            else
                local command = i == 1 and "edit" or edit_file_cmd_map[method]
                if vim.api.nvim_buf_get_name(0) ~= filename or command ~= "edit" then
                    filename = require("plenary.path"):new(vim.fn.fnameescape(filename)):normalize(vim.loop.cwd())
                    pcall(vim.cmd, string.format("%s %s", command, filename))
                end
            end
 
            if row and col then
                pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
            end
        end
    else
        actions["select_" .. method](prompt_bufnr)
    end
end
 
local custom_actions = transform_mod({
    multi_selection_open_vertical = function(prompt_bufnr)
        multiopen(prompt_bufnr, "vertical")
    end,
    multi_selection_open_horizontal = function(prompt_bufnr)
        multiopen(prompt_bufnr, "horizontal")
    end,
    multi_selection_open_tab = function(prompt_bufnr)
        multiopen(prompt_bufnr, "tab")
    end,
    multi_selection_open = function(prompt_bufnr)
        multiopen(prompt_bufnr, "default")
    end,
})
 
local function stopinsert(callback)
    return function(prompt_bufnr)
        vim.cmd.stopinsert()
        vim.schedule(function()
            callback(prompt_bufnr)
        end)
    end
end
 
-- Telescope keymaps
vim.keymap.set("n", "<Leader>fE", function()
    require("telescope").extensions.file_browser.file_browser({ hidden = true, cwd = "$HOME" })
end, {})
vim.keymap.set("n", "<Leader>fe", function()
    require("telescope").extensions.file_browser.file_browser({ hidden = true })
end, {})
vim.keymap.set("n", "<Leader>ff", function()
    require("telescope").extensions.file_browser.file_browser({ hidden = false })
end, {desc = "Search including files"})
vim.keymap.set("n", "z=", ":Telescope spell_suggest<CR>", {})
vim.keymap.set("n", "<Leader>fr", ":Telescope live_grep<CR>", {})
vim.keymap.set("n", "<Leader>fg", ":Telescope git_files<CR>", {})
vim.keymap.set("n", "<Leader>fb", ":Telescope buffers<CR>", {})
vim.keymap.set("n", "<Leader>fq", ":Telescope quickfix<CR>", {})
vim.keymap.set("n", "<Leader>fl", ":Telescope loclist<CR>", {})
vim.keymap.set("n", "<Leader>fv", ":Telescope diagnostics<CR>", {})
vim.keymap.set("n", "<Leader>fo", ":Telescope oldfiles<CR>", {})
vim.keymap.set("n", "<Leader>fs", ":Telescope grep_string<CR>", {})
 
local cdPicker = function(name, cmd)
    require("telescope.pickers").new({}, {
        prompt_title = name,
        finder = require("telescope.finders").new_table({
            results = require("telescope.utils").get_os_command_output(cmd),
        }),
        previewer = require("telescope.previewers").vim_buffer_cat.new({}),
        sorter = require("telescope.sorters").get_fuzzy_file(),
        attach_mappings = function(prompt_bufnr)
            require("telescope.actions.set").select:replace(function(_)
                local entry = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                local dir = require("telescope.from_entry").path(entry)
                vim.api.nvim_set_current_dir(dir)
            end)
            return true
        end,
    }):find()
end
 
telescope.setup({
    defaults = {
        file_sorter = require("telescope.sorters").get_fzf_sorter,
        prompt_prefix = " > ",
        color_devicons = true,
 
        file_previewer = require("telescope.previewers").vim_buffer_cat.new,
        grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
        qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
 
        layout_strategy = "flex",
        -- layout_strategy = "horizontal",
 
        layout_config = {
            preview_cutoff = 10,
            horizontal = {
                width = { padding = 0.05 },
                height = { padding = 0.05 },
                preview_width = 0.6,
            },
            vertical = {
                width = { padding = 0.05 },
                height = { padding = 0.05 },
                preview_height = 0.4,
            },
        },
 
        mappings = {
            i = {
                ["<C-q>"] = actions.smart_send_to_qflist,
                ["<C-k>"] = actions.move_selection_previous,
                ["<C-j>"] = actions.move_selection_next,
                ["<C-l>"] = actions.add_selection,
                ["<C-h>"] = actions.remove_selection,
                ["<C-b>"] = stopinsert(custom_actions.multi_selection_open),
                ["<C-v>"] = stopinsert(custom_actions.multi_selection_open_vertical),
                ["<C-x>"] = stopinsert(custom_actions.multi_selection_open_horizontal),
                ["<C-t>"] = stopinsert(custom_actions.multi_selection_open_tab),
                ["<C-e>"] = function(prompt_bufnr)
                    local selection = require("telescope.actions.state").get_selected_entry()
                    local dir = vim.fn.fnamemodify(selection.path, ":p:h")
                    require("telescope.actions").close(prompt_bufnr)
                    -- Depending on what you want put `cd`, `lcd`, `tcd`
                    vim.cmd(string.format("silent cd %s", dir))
                end,
            },
            n = {
                ["<C-b>"] = custom_actions.multi_selection_open,
                ["<C-v>"] = custom_actions.multi_selection_open_vertical,
                ["<C-x>"] = custom_actions.multi_selection_open_horizontal,
                ["<C-t>"] = custom_actions.multi_selection_open_tab,
            },
        },
    },
    extensions = {
        ["ui-select"] = {
            require("telescope.themes").get_dropdown({
                -- even more opts
            }),
        },
 --       fzf = {
 --           fuzzy = true,
 --           override_generic_sorter = true,
 --           override_file_sorter = true,
 --           case_mode = "smart_case",
 --       },
    },
})
 
telescope.load_extension("ui-select")
--telescope.load_extension("fzf")
telescope.load_extension("file_browser")
 
local M = {}
 
M.Cd = function(path)
    path = path or "."
    cdPicker("Cd", {
        vim.o.shell,
        "-c",
        "fd . " .. path .. " -t d -H --ignore-file " .. vim.fn.expand("$HOME/.config/ignore/vim-ignore"),
    })
end
 
M.search_home = function()
    require("telescope.builtin").find_files({
        prompt_title = "< ~ >",
        cwd = vim.fn.expand("$HOME"),
        hidden = true,
        find_command = { "fd", "--ignore-file", vim.fn.expand("$HOME/.config/ignore/vim-ignore"), "-t", "f", "-H" },
    })
end
 
M.search_current = function()
    require("telescope.builtin").find_files({
        prompt_title = "< . >",
        hidden = true,
        find_command = { "fd", "--ignore-file", vim.fn.expand("$HOME/.config/ignore/vim-ignore"), "-t", "f", "-H" },
        no_ignore = true,
    })
end


vim.keymap.set("n", "<Leader>fF", function()
    print(vim.inspect(M))
    M.search_home()
end, {})
vim.keymap.set("n", "<Leader>ff", function()
    M.search_current()
end, {})
-- vim.keymap.set("n", "<Leader>fD", function()
--     M.Cd("$HOME")
-- end, {})
-- vim.keymap.set("n", "<Leader>fd", function()
--     M.Cd()
-- end, {})
 
return M
