vim.api.nvim_create_user_command("CreateProject", function(_)
  require("nviq.util.template"):create_project()
end, { desc = "Create project with templates" })
