local M = {}

M.lb = function()
    local branches = {}

    -- This reflog command returns output that looks like this:
    -- checkout: moving from branchA to branchB
    vim.fn.jobstart({ "git", "reflog", "show", "--pretty=format:%gs" }, {
        stdout_buffered = true,
        on_stdout = function(_, data)
            if not data then
                return
            end

            local on_current_branch = true
            local seen_branches = {}
            for _, datum in pairs(data) do
                if datum:find("checkout:") ~= nil then
                    local branch = datum:gsub("checkout: moving from %w+ to (%w+)%s*", "%1")

                    if on_current_branch then
                        -- The first checkout we see was the last one, so the branch we moved to is
                        -- the one we're currently on. We won't populate it as an option to
                        -- checkout.
                        on_current_branch = false
                    elseif not seen_branches[branch] then
                        table.insert(branches, branch)
                    end

                    seen_branches[branch] = true
                end
            end
        end,
        on_exit = function()
            if #branches == 0 then
                vim.print("No recently checked-out branches found.")
                return
            end

            vim.ui.select(branches, { prompt = "Choose a branch..." }, function(choice)
                if not choice then
                    return
                end
                vim.fn.system("git checkout " .. choice)
            end)
        end,
    })
end

return M
