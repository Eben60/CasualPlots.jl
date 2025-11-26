using CasualPlots
using Bonito
using Observables

# Mock data
Main.eval(:(x_data = 1:10))
Main.eval(:(y_data = rand(10)))

# Initialize app
app = casualplots_app()

# Access internal state (this is a bit hacky as we don't have direct access to the internal state from the App object easily without exposing it, 
# but we can check if the app construction succeeds)

println("App constructed successfully.")

# We can also try to call the helper functions directly to verify they return what we expect
using CasualPlots: create_dropdown, create_x_dropdown, create_y_dropdown, create_art_dropdown

# Test create_dropdown
dd = create_dropdown(["A", "B"], Observable("A"); placeholder="Select")
println("create_dropdown created: ", typeof(dd))

# Test create_x_dropdown
x_dd = create_x_dropdown("Select X", ["x_data"], Observable("x_data"))
println("create_x_dropdown created: ", typeof(x_dd))

# Test create_y_dropdown
y_dd = create_y_dropdown("Select Y")
println("create_y_dropdown created: ", typeof(y_dd))

# Test create_art_dropdown
art_dd = create_art_dropdown(Observable("Scatter"))
println("create_art_dropdown created: ", typeof(art_dd))

println("Verification script finished.")
