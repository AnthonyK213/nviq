local lib = require("nviq.util.lib")
local futil = require("nviq.util.f")

---@class nviq.appl.gui.Settings
---@field theme "auto"|"dark"|"light"
---@field opacity number
---@field ligature boolean
---@field popup_menu boolean
---@field tabline boolean
---@field scroll_bar boolean
---@field cursor_blink boolean
---@field line_space number
---@field font_size integer
---@field font_half string
---@field font_wide string

---@class nviq.appl.gui.Handlers
---@field set_font fun(font:string, size:integer)
---@field set_font_wide fun(font:string, size:integer)
---@field toggle_file_explorer function
---@field toggle_fullscreen function

-----------------------------------Neovim Qt------------------------------------

local function has_nvim_qt()
  return vim.fn.exists("*GuiName") == 1 and vim.fn.GuiName() == "nvim-qt"
end

---
---@param settings nviq.appl.gui.Settings
---@param handlers nviq.appl.gui.Handlers
local function nvim_qt_setup(settings, handlers)
  vim.cmd.GuiAdaptiveColor(1)
  vim.cmd.GuiAdaptiveStyle("Fusion")
  vim.cmd.GuiLinespace(tostring(settings.line_space))
  vim.cmd.GuiPopupmenu(settings.popup_menu and 1 or 0)
  vim.cmd.GuiRenderLigatures(settings.ligature and 1 or 0)
  vim.cmd.GuiScrollBar(settings.scroll_bar and 1 or 0)
  vim.cmd.GuiTabline(settings.tabline and 1 or 0)
  vim.cmd.GuiWindowOpacity(tostring(settings.opacity))

  handlers.set_font = function(font, size)
    vim.cmd.GuiFont { font .. ":h" .. tostring(size), bang = true }
  end

  handlers.toggle_file_explorer = function()
    vim.cmd.GuiTreeviewToggle()
  end

  handlers.toggle_fullscreen = function()
    if vim.g.GuiWindowFullScreen == 0 then
      vim.fn.GuiWindowFullScreen(1)
      vim.cmd.GuiScrollBar(0)
    else
      vim.fn.GuiWindowFullScreen(0)
      vim.cmd.GuiScrollBar(settings.scroll_bar and 1 or 0)
    end
  end
end

------------------------------------Neovide-------------------------------------

local function has_neovide()
  return vim.g.neovide == true
end

---
---@param settings nviq.appl.gui.Settings
---@param _ nviq.appl.gui.Handlers
local function neovide_setup(settings, _)
  vim.o.linespace = math.floor(settings.line_space)
  vim.g.neovide_padding_top = 13
  vim.g.neovide_padding_bottom = 13
  vim.g.neovide_padding_right = 13
  vim.g.neovide_padding_left = 13
  vim.g.neovide_theme = settings.theme
  vim.g.neovide_opacity = settings.opacity
  vim.g.neovide_floating_blur_amount_x = 2.0
  vim.g.neovide_floating_blur_amount_y = 2.0

  vim.api.nvim_create_autocmd("InsertEnter", {
    pattern = "*",
    callback = function(_) vim.g.neovide_input_ime = true end,
  })

  vim.api.nvim_create_autocmd({ "InsertLeave", "CmdlineEnter" }, {
    pattern = "*",
    callback = function(_) vim.g.neovide_input_ime = false end,
  })
end

-------------------------------------Setup--------------------------------------

if has_neovide() then
  require("nviq")
end

local _gui_settings = _G.NVIQ.settings.gui

local _gui_handlers = {
  set_font = function(font, size)
    vim.o.guifont = font .. ":h" .. tostring(size)
  end,
  set_font_wide = function(font, size)
    vim.o.guifontwide = font .. ":h" .. tostring(size)
  end,
  toggle_file_explorer = function()
    vim.notify("File explorer is unavailable", vim.log.levels.WARN)
  end,
  toggle_fullscreen = function()
    vim.notify("Unable to toggle fullscreen", vim.log.levels.WARN)
  end,
}

local _gui_font_size = _gui_settings.font_size

---
---@param font string
---@param font_wide string
---@param size integer
local function set_font(font, font_wide, size)
  _gui_handlers.set_font(font, size)
  _gui_handlers.set_font_wide(font_wide, size)
  _gui_font_size = size
end

local function font_size_reset()
  set_font(_gui_settings.font_half, _gui_settings.font_wide, _gui_settings.font_size)
end

local function font_size_decrement()
  set_font(_gui_settings.font_half, _gui_settings.font_wide, math.max(_gui_font_size - 1, 6))
end

local function font_size_increment()
  set_font(_gui_settings.font_half, _gui_settings.font_wide, math.min(_gui_font_size + 1, 42))
end

-- Vim options

vim.o.mouse = "a"

if _gui_settings.cursor_blink then
  vim.o.guicursor = [[n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,]] ..
      [[a:blinkwait800-blinkoff500-blinkon500-Cursor/lCursor,]] ..
      [[sm:block-blinkwait240-blinkoff150-blinkon150]]
end

-- Setup GUI

if has_nvim_qt() then
  nvim_qt_setup(_gui_settings, _gui_handlers)
elseif has_neovide() then
  neovide_setup(_gui_settings, _gui_handlers)
end

if not has_neovide() then
  require("nviq.appl.theme").set_theme(_gui_settings.theme)
end

set_font(_gui_settings.font_half, _gui_settings.font_wide, _gui_settings.font_size)

-- Set CWD

if futil.is_file(vim.api.nvim_buf_get_name(0)) then
  vim.api.nvim_set_current_dir(lib.buf_dir())
elseif futil.is_dir(_G.NVIQ.settings.path.desktop) then
  vim.api.nvim_set_current_dir(_G.NVIQ.settings.path.desktop)
end

-- Mappings

vim.keymap.set("n", "<C-0>", font_size_reset)
vim.keymap.set("n", "<C-->", font_size_decrement)
vim.keymap.set("n", "<C-=>", font_size_increment)
vim.keymap.set("n", "<C-ScrollWheelDown>", font_size_decrement)
vim.keymap.set("n", "<C-ScrollWheelUp>", font_size_increment)
vim.keymap.set("n", "<F3>", _gui_handlers.toggle_file_explorer)
vim.keymap.set("n", "<F11>", _gui_handlers.toggle_fullscreen)
