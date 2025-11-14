[RFC] CasualPlots.jl - (@Gemini: please suggest a post title)

[CasualPlots.jl](https://github.com/Eben60/CasualPlots.jl) (interim name, but actually I like it) aims to provide a GUI to simplify the creation of plots in Julia. The tool is positioned in the middle ground between purely script-based plotting and standalone GUI plotting applications, like e.g. Origin or Veusz.

The intended user is a **casual** Julia user, e.g. an experimental scientist or a "hands-on" engineer, for whom it could become an alternative to using Excel for ploting (@Gemini: add an "igitt" smiley here). The intention is to provide like 60..80% of features commonly expected by that kind of user. It will be limited only to the most common of 2D-Plots (scatter and line plots to start with). The GUI-available features should be just enough to produce typical plots for e.g. internal presentations, however fine polish can be manually applied to a GUI-produced plot afterwards.

**What it is not:** In now way the intention is to compete with any "serious" tools in features. It is also probably not interesting to a Julia developer who is using Julia day in, day out from Emacs or Vim and knows all Makie parameter by heart.

The package usage is as following: From the command line (or script) user would start a GUI, where they can select data sources. As soon as the X and Y data sources are selected the plot will be displayed, and the data in tabular form as well. Simultaneously, the corresponding `Figure` object will be exported into the `Main`, providing the user with opportunity to do the fine tuning by hand.

[here screenshot will go]

The package is based on Bonito.jl and Makie.jl; Electron window currently used for display.

Planned (and in a small part already implemented) features are:

*   A GUI including panes to 
    * select data sources and configure plot features, 
    * display the plot, 
    * display the source data in tabular form.
*   Data sources can be 
    * variables defined in the `Main` module (vectors, matrices, dataframes),
    * files which can be read into a DataFrame.
*   Saving plot to a file.
*   Export Figure, making it possible to set parameter which were not available from the GUI.
*   Automatic generation of Julia code corresponding to the user's actions in the GUI. This allows users to copy, modify, and reuse the generated code in their own scripts.
*   Applying least-squares-fit from the GUI (maybe).

The project is in very early stage, just a couple of days of Gemini-coding. Any suggestions, any critique are highly welcome.

Despite being in very early stage, you can already test it. See the file `/src/scripts/three_panes.jl` for code and instructions.

PS For my personal motivation - see [here](https://discourse.julialang.org/t/too-much-time-on-my-hands/117816?u=eben60) and [here](https://discourse.julialang.org/t/too-much-time-on-my-hands/117816/41?u=eben60)
