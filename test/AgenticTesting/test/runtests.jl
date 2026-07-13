using Test
using SafeTestsets
using CasualPlots
using AgenticTesting

# Clear the results file so tests don't append to a massive file
if isfile(AgenticTesting.RESULTS_FILE)
    write(AgenticTesting.RESULTS_FILE, "")
end

# Populate Main with dummy data so dropdowns are not empty
@eval Main begin
    caspl_x_10 = rand(10)
    caspl_y_10 = rand(10)
end

# ---- App startup ----
app = casualplots_app()
Ele.serve_app(app; show=false)

# Bind to Main so get_active_session() can find it
@eval Main app = $app

# Poll for browser readiness
wait_for_session(; timeout=15)

try
    @safetestset "Session & DOM Interaction Utils" include("gui_interaction_test.jl")
    @safetestset "Agent Verification Utils"        include("agent_verification_test.jl")
finally
    try close(app)                       catch end
    try Ele.close_display(; strict=true) catch end
    
    # Truncate results.md again after tests
    if isfile(AgenticTesting.RESULTS_FILE)
        write(AgenticTesting.RESULTS_FILE, "")
    end
end
