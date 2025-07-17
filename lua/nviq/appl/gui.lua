local _gui = _G.NVIQ.settings.gui

local _gui_handles = {
  set_font = function(font, size)
    vim.o.guifont = font .. ":h" .. tostring(size)
  end,
  set_font_wide = function(font, size)
    vim.o.guifontwide = font .. ":h" .. tostring(size)
  end,
  toggle_fullscreen = function()
    vim.notify("Unable to toggle fullscreen", vim.log.levels.WARN)
  end,
  toggle_file_explorer = function()
    vim.notify("File explorer is unavailable", vim.log.levels.WARN)
  end,
}

local _gui_font_size = _gui.font_size

local function set_font(font, font_wide, size)
  _gui_handles.set_font(font, size)
  _gui_handles.set_font_wide(font_wide, size)
  _gui_font_size = size
end

local function font_size_reset()
  set_font(_gui.font_half, _gui.font_wide, _gui.font_size)
end

local function font_size_decrement()
  set_font(_gui.font_half, _gui.font_wide, math.max(_gui_font_size - 1, 6))
end

local function font_size_increment()
  set_font(_gui.font_half, _gui.font_wide, math.min(_gui_font_size + 1, 42))
end

-----------------------------------Neovim Qt------------------------------------

local function has_nvim_qt()
  return vim.fn.exists("*GuiName") == 1 and vim.fn.GuiName() == "nvim-qt"
end

local function nvim_qt_setup()
  vim.cmd.GuiAdaptiveColor(1)
  vim.cmd.GuiAdaptiveStyle("Fusion")
  vim.cmd.GuiLinespace(tostring(_gui.line_space))
  vim.cmd.GuiPopupmenu(_gui.popup_menu and 1 or 0)
  vim.cmd.GuiRenderLigatures(_gui.ligature and 1 or 0)
  vim.cmd.GuiScrollBar(_gui.scroll_bar and 1 or 0)
  vim.cmd.GuiTabline(_gui.tabline and 1 or 0)
  vim.cmd.GuiWindowOpacity(tostring(_gui.opacity))

  _gui_handles.set_font = function(font, size)
    vim.cmd.GuiFont { font .. ":h" .. tostring(size), bang = true }
  end

  _gui_handles.toggle_file_explorer = function()
    vim.cmd.GuiTreeviewToggle()
  end

  _gui_handles.toggle_fullscreen = function()
    if vim.g.GuiWindowFullScreen == 0 then
      vim.fn.GuiWindowFullScreen(1)
      vim.cmd.GuiScrollBar(0)
    else
      vim.fn.GuiWindowFullScreen(0)
      vim.cmd.GuiScrollBar(_gui.scroll_bar and 1 or 0)
    end
  end
end

-------------------------------------Setup--------------------------------------

vim.o.mouse = "a"

if _gui.cursor_blink then
  vim.o.guicursor = [[n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,]] ..
      [[a:blinkwait800-blinkoff500-blinkon500-Cursor/lCursor,]] ..
      [[sm:block-blinkwait240-blinkoff150-blinkon150]]
end

require("nviq.appl.theme").set_theme(_gui.theme)

if has_nvim_qt() then
  nvim_qt_setup()
end

set_font(_gui.font_half, _gui.font_wide, _gui.font_size)

vim.keymap.set("n", "<C-0>", font_size_reset)
vim.keymap.set("n", "<C-->", font_size_decrement)
vim.keymap.set("n", "<C-=>", font_size_increment)
vim.keymap.set("n", "<C-ScrollWheelDown>", font_size_decrement)
vim.keymap.set("n", "<C-ScrollWheelUp>", font_size_increment)
vim.keymap.set("n", "<F3>", _gui_handles.toggle_file_explorer)
vim.keymap.set("n", "<F11>", _gui_handles.toggle_fullscreen)
