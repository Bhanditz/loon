#' loon: A Toolkit for Interactive Data Visualization and Exploration
#' 
#' Loon is a toolkit for highly interactive data visualization. Interactions 
#' with plots are provided with mouse and keyboard gestures as well as via 
#' command line control and with inspectors that provide graphical user 
#' interfaces (GUIs) for modifying and overseeing plots.
#' 
#' Currently, loon implements the following statistical graphs: histogram, 
#' scatterplot, serialaxes plot (star glyphs, parallel coordinates) and a graph 
#' display for creating navigation graphs.
#' 
#' Some of the implemented scatterplot features, for example, are zooming, 
#' panning, selection and moving of points, dynamic linking of plots, layering 
#' of visual information such as maps and regression lines, custom point glyphs 
#' (images, text, star glyphs), and event bindings. Event bindings provide hooks
#' to evaluate custom code at specific plot state changes or mouse and keyboard 
#' interactions. Hence, event bindings can be used to add to or modify the 
#' default behavior of the plot widgets.
#' 
#' Loon's capabilities are very useful for statistical analysis tasks such as 
#' interactive exploratory data analysis, sensitivity analysis, animation, 
#' teaching, and creating new graphical user interfaces.
#' 
#' To get started using loon read the package vigniettes or visit the loon
#' website at \url{http://waddella.github.io/loon/learn_R_intro.html}.
#' 
#' 
#' @docType package
#' @name loon
#' @import tcltk
#' @import methods
#' 
"_PACKAGE"