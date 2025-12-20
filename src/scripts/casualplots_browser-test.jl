include("casualplots_test_setup.jl");

app = casualplots_app();
# this opens the GUI in browser for debugging
@show server = Bonito.Server(app, "127.0.0.1", 8000);
println("Server should running at http://127.0.0.1:8000, except the port is busy.")
println("In this case, a Warning will be shown in Terminal telling which port is actually used")
println("Press Ctrl+C to stop the server")
wait(server)


# To close the app, please call:
# close(app)
