include("casualplots_test_setup.jl");

app = casualplots_app();
# this opens the GUI in browser for debugging
@show server = Bonito.Server(app, "127.0.0.1", 8000);
println("Server should running at http://127.0.0.1:8000, except the port is busy.")
println("In this case, a Warning will be shown in Terminal telling which port is actually used")
println("Press Ctrl+C to stop the server")
# Run the server wait loop in the background so the REPL remains responsive
# @async wait(server)

# @show isopen(server)

println("To stop the server, run: close(server)")


# To close the app and server, please call:
# close(server); close(app)
