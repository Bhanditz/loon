
#' @title Scatterplot Matrix in Loon
#'   
#' @description Function creates a scatterplot matrix using loon's scatterplot 
#'   widgets
#'   
#' @param data a data.frame with numerical data to create the scatterplot matrix
#' @param showHistograms logical (default FALSE) to show histograms of each variable or not
#' @param histLocation one "edge" or "diag", when showHistograms = TRUE
#' @param histHeightProp a positive number giving the height of the histograms as a proportion of the height of the scatterplots
#' @param histArgs arguments to modify the `l_hist` states
#' @param showSerialAxes logical (default FALSE) indication of whether to show a serial axes plot 
#' in the bottom left of the pairs plot (or not)
#' @param serialAxesArgs additional arguments given to `l_serialaxes()` 
#' @template param_parent
#' @param ... named arguments to modify the `l_plot` states of the scatterplots
#' 
#' @return a list with handles for the plots
#' 
#' @seealso \code{\link{l_plot}}
#' 
#' @export
#' 
#' @examples
#' p <- l_pairs(iris[,-5], color=iris$Species)
#' 
#' p <- l_pairs(iris[,-5], color=iris$Species, showHistograms = TRUE, showSerialAxes = TRUE)

l_pairs <- function(data, showHistograms = FALSE, histLocation = c("edge", "diag"), histHeightProp = 1, histArgs = list(),
                    showSerialAxes = FALSE, serialAxesArgs = list(), parent=NULL, ...) {

    args <- list(...)
    if(!identical(class(data), "data.frame")) { # use of identical to deal with tibbles
        data <- as.data.frame(data)
    }

    if (is.null(args[['linkingGroup']])) {
        args[['linkingGroup']] <- deparse(substitute(data))
    }
    
    args[['x']] <- NULL
    args[['y']] <- NULL

    if (dim(data)[2] <= 2) {
        args[['x']] <- data
        args[['parent']] <- parent
        return(do.call(l_plot, args))
    }

    args[['showLabels']] <- FALSE
    args[['showScales']] <- FALSE
    args[['swapAxes']] <- FALSE
    
    new.toplevel <- FALSE
    if(is.null(parent)) {
        new.toplevel <- TRUE
        parent <- l_toplevel()
        title <- paste("loon scatterplot matrix for",
                       deparse(substitute(data)), "data")
        tktitle(parent) <- title
    }
    
    child <- as.character(tcl('frame', l_subwin(parent, 'pairs')))

    ## parent for individual scatterplots
    args[['parent']] <- child
    
    nvar <- dim(data)[2]
    pair <- utils::combn(nvar, 2)
    varnames <- names(data)

    ## combn returns the variable combinations for the scatterplot
    ## matrix. The scatterplot arrangements is as follows
    ##
    ##      1      2      3      4
    ##  1  [1]   (2,1)  (3,1)  (4,1)
    ##  2         [2]   (3,2)  (4,2)
    ##  3                [3]   (4,3)
    ##  4                       [4]
    ##
    ##
    ## pair is
    ##  1  1  1  2  2  3
    ##  2  3  4  3  4  4
    cells <- nvar - 1
    text_adjustValue <- 1
    scatter_adjustValue <- 0
    span <- 1
    histLocation <- match.arg(histLocation)
    
    if (showHistograms) {
        histArgs <- c(args, histArgs)
        if(is.null(histArgs[['showStackedColors']])) histArgs[['showStackedColors']] <- TRUE
        if(is.null(histArgs[['showOutlines']])) histArgs[['showOutlines']] <- FALSE
        if(is.null(histArgs[['yshows']])) histArgs[['yshows']] <- "density"
        if(is.null(histArgs[['showBinHandle']])) histArgs[['showBinHandle']] <- FALSE
        histograms <- list()
        
        if(histLocation == "edge") {
            span <- ifelse(round(1/histHeightProp) >= 1, 1, round(1/histHeightProp))
            # The first half are top hists, the second half are right hists
            for(i in 1:(2*nvar)){
                if (i <= nvar) {
                    histArgs[['x']] <- as.numeric(data[, i])
                    histArgs[['xlabel']] <- varnames[i]
                    # top level histograms  
                    histArgs[['swapAxes']] <- FALSE
                    ix <- i
                    iy <- 1
                } else {
                    histArgs[['x']] <- as.numeric(data[, i - nvar])
                    histArgs[['xlabel']] <- varnames[i - nvar]
                    # right level histograms  
                    histArgs[['swapAxes']] <- TRUE
                    ix <- nvar + 1 
                    iy <- i - nvar + 1
                }
                histograms[[i]] <- do.call(l_hist, histArgs)
                names(histograms)[i] <- paste('x',ix,'y',iy, sep="")
            }
            # throw errors
            if (any(sapply(histograms, function(p) {is(p, 'try-error')}))) {
                if(new.toplevel) tkdestroy(parent)
                stop("histogram could not be created.")
            }
            sapply(seq_len(2*nvar), 
                   function(i) {
                       h <- histograms[[i]]
                       if(i <= nvar){
                           tkconfigure(paste(h,'.canvas',sep=''), width=50, height=50 * histHeightProp)
                       } else {
                           tkconfigure(paste(h,'.canvas',sep=''), width=50 * histHeightProp, height=50)
                       }
                   }
            )
            # grid layout
            lapply(2:(2*nvar-1), 
                   function(i){
                       if(i <= nvar) {
                           tkgrid(histograms[[i]], row = 0, column = (i-1) * span, 
                                  rowspan = 1, columnspan = span,
                                  sticky="nesw") 
                       } else {
                           tkgrid(histograms[[i]], row = 1 + (i - nvar - 1)* span, column = nvar * span, 
                                  rowspan = span, columnspan = 1,
                                  sticky="nesw") 
                       }
                   }
            )
            
            cells <- nvar
            text_adjustValue <- 0
            scatter_adjustValue <- 1
        } else {
            if(histHeightProp != 1) warning("histHeightProp must be 1 when histograms are placed on diagonal")
            for(i in 1:nvar){
                histArgs[['x']] <- as.numeric(data[, i])
                histArgs[['xlabel']] <- varnames[i]
                histArgs[['swapAxes']] <- FALSE
                histograms[[i]] <- do.call(l_hist, histArgs)
                xText <- histograms[[i]]['panX'] + histograms[[i]]['deltaX']/(2*histograms[[i]]['zoomX'])
                yText <- histograms[[i]]['panY'] + histograms[[i]]['deltaY']/(2*histograms[[i]]['zoomY'])
                layerText <- l_layer_text(histograms[[i]], xText, yText, text = names(data)[i], 
                                          color = "black", size = 8)
                names(histograms)[i] <- paste('x',i,'y',i, sep="")
            }
            # throw errors
            if (any(sapply(histograms, function(p) {is(p, 'try-error')}))) {
                if(new.toplevel) tkdestroy(parent)
                stop("histogram could not be created.")
            }
            sapply(seq_len(nvar), 
                   function(i) {
                       h <- histograms[[i]]
                       tkconfigure(paste(h,'.canvas',sep=''), width=50, height=50)
                   }
            )
            # grid layout
            lapply(seq_len(nvar), 
                   function(i){
                       tkgrid(histograms[[i]], row = (i-1), column = (i-1), 
                              rowspan = span, columnspan = span,
                              sticky="nesw") 
                   }
            )
        }
    }

    if (showSerialAxes) {
        serialAxesArgs <- c(args, serialAxesArgs)
        serialAxesArgs[['data']] <- data
        serialAxesArgs[['showScales']] <- NULL
        serialAxesArgs[['swapAxes']] <- NULL
        serialAxesArgs[['axesLayout']] <- "parallel"
        serialAxesSpan <- floor(nvar/2)
        serialAxes <- do.call(l_serialaxes, serialAxesArgs)
        tkconfigure(paste(serialAxes,'.canvas',sep=''), 
                    width= serialAxesSpan * 50, 
                    height = serialAxesSpan * 50)
        tkgrid(serialAxes, 
               row = (cells - serialAxesSpan) * span + 1, column = 0, 
               rowspan = serialAxesSpan * span, columnspan = serialAxesSpan * span,
               sticky="nesw") 
    }
    scatterplots <- vector(mode="list", dim(pair)[2])
    
    ## create first plot
    for (i in 1:dim(pair)[2]) {
        ix <- pair[2,i]; iy <- pair[1,i]
        args[['x']] <- data[,ix]
        args[['y']] <- data[,iy]
        args[['xlabel']] <- varnames[ix]
        args[['ylabel']] <- varnames[iy]
        scatterplots[[i]] <- do.call(l_plot, args)
        # reset names (if showHistograms)
        if (showHistograms & histLocation == "edge") {
            names(scatterplots)[i] <- paste('x',ix,'y',iy + 1, sep="")
        } else {
            names(scatterplots)[i] <- paste('x',ix,'y',iy, sep="")  
        }
    }
    
    if (any(sapply(scatterplots, function(p) {is(p, 'try-error')}))) {
        if(new.toplevel) tkdestroy(parent)
        stop("scatterplot matrix could not be created.")
    }
    
    ## resize the min canvas size
    sapply(scatterplots, 
           function(p) {
               tkconfigure(paste(p,'.canvas',sep=''), width=50, height=50)
           }
    )
    
    ## grid layout
    apply(rbind(unlist(scatterplots), pair - 1), 2, 
          function(obj) {
              tkgrid(obj[1], 
                     row= as.numeric(obj[2]) * span + scatter_adjustValue, 
                     column = as.numeric(obj[3]) * span, 
                     rowspan = span,
                     columnspan = span,
                     sticky="nesw")
          }
    )
    
    ## Column and Row wheight such that the cells expand
    for (i in seq(0, cells)) {
        tkgrid.columnconfigure(child, i, weight = 1)
        tkgrid.rowconfigure(child, i, weight = 1)
    }
    
    ## Add Variable Label
    if (!showHistograms | all(c(showHistograms, histLocation == "edge"))){
        maxchar <- max(sapply(names(data), nchar))
        strf <- paste("%-", maxchar,'s', sep='')
        for (i in 1:nvar) {
            lab <- as.character(tcl('label', as.character(l_subwin(child,'label')),
                                    text= sprintf(strf, names(data)[i])))
            tkgrid(lab, row = (i - text_adjustValue - 1) * span + 1, column = (i - 1) * span,
                   rowspan = span, columnspan = span)
        }
    }
    
    if(new.toplevel) {
        tkpack(child, fill="both", expand=TRUE)
    }
    plotsHash <- vector(mode="list", dim(pair)[2])
    for (i in 1:dim(pair)[2]) {
        ix <- pair[2,i]
        iy <- pair[1,i]
        
        tmpX <- which(pair[2,] == ix)
        shareX <- tmpX[tmpX != i]
        
        tmpY <- which(pair[1,] == iy)
        shareY <- tmpY[tmpY != i]
        plotsHash[[paste("scatter_y_",scatterplots[i],sep="")]] <- scatterplots[shareY]
        if(showHistograms) {
            plotsHash[[paste("scatter_x_",scatterplots[i],sep="")]] <- c(scatterplots[shareX], histograms[pair[2,i]])
            if(histLocation == "edge") {
                plotsHash[[paste("swap_hist_",scatterplots[i],sep="")]] <- histograms[pair[1,i] + nvar] 
            } else {
                plotsHash[[paste("swap_hist_",scatterplots[i],sep="")]] <- histograms[pair[1,i]]
            }
        } else {
            plotsHash[[paste("scatter_x_",scatterplots[i],sep="")]] <- scatterplots[shareX]
        }
    }
    
    ## Make bindings for scatter synchronizing zoom and pan
    busy <- FALSE

    synchronizeScatterBindings <- function(W) {
        #print(paste(W, ', busy', busy))
        if (!busy) {
            busy <<- TRUE
            class(W) <- "loon"
            zoomX <- W['zoomX']; zoomY <- W['zoomY']
            panX <- W['panX']; panY <- W['panY']
            deltaX <- W['deltaX']; deltaY <- W['deltaY']
            
            lapply(plotsHash[[paste("scatter_x_",W,sep="")]], function(p) {
                l_configure(p, zoomX=zoomX, panX=panX, deltaX=deltaX)
            })
            lapply(plotsHash[[paste("scatter_y_",W,sep="")]], function(p) {
                l_configure(p, zoomY=zoomY, panY=panY, deltaY=deltaY)
            })
            if (showHistograms) {
                lapply(plotsHash[[paste("swap_hist_",W,sep="")]], function(p) {
                    l_configure(p, zoomX=zoomY, panX=panY, deltaX=deltaY)
                }) 
            }
            busy <<- FALSE
            tcl('update', 'idletasks')
            ##assign("busy", FALSE, envir=parent.env(environment()))
        }
    }
    
    lapply(scatterplots, 
           function(p) {
               tcl(p, 'systembind', 'state', 'add',
                   c('zoomX', 'panX', 'zoomY', 'panY', 'deltaX', 'deltaY'),
                   synchronizeScatterBindings)
           }
    )
    
    # forbidden scatter plots
    lapply(scatterplots,
           function(p) {
               tcl(p, 'systembind', 'state', 'add',
                   c('showLabels', 'showScales', 'swapAxes'),
                   undoScatterStateChanges)
           }
    )

    plots <- scatterplots
    if (showHistograms) {
        # synchronize hist bindings
        histsHash <- list()
        namesHist <- names(histograms)
        namesScatter <- names(scatterplots)
        
        scatterLayout <- xy_layout(namesScatter)
        scatterX <- scatterLayout$x
        scatterY <- scatterLayout$y
        
        if(histLocation == "edge") {
            for(i in 1:length(histograms)) {
                nameHist <- namesHist[i]
                if(i != 1 & i != length(histograms)) {
                    if(i <= nvar) {
                        histX <- xy_layout(nameHist)$x
                        shareX <- which(scatterX %in% histX == TRUE)
                        histsHash[[paste("hist_x_", histograms[i],sep="")]] <- c(scatterplots[shareX])  
                    } else {
                        histY <- xy_layout(nameHist)$y
                        shareY <- which(scatterY %in% histY == TRUE)
                        histsHash[[paste("hist_y_", histograms[i],sep="")]] <- c(scatterplots[shareY]) 
                    }
                }
            }
            
        } else {
           for(i in 1:length(histograms)){
               nameHist <- namesHist[i]
               histLayout <- xy_layout(nameHist)
               histX <- histLayout$x
               histY <- histLayout$y
               shareX <- which(scatterX %in% histX == TRUE)
               shareY <- which(scatterY %in% histY == TRUE)
               if(length(shareX) > 0) {
                  histsHash[[paste("hist_x_", histograms[i],sep="")]] <- c(scatterplots[shareX]) 
               }
               if(length(shareY) > 0) {
                   histsHash[[paste("hist_y_", histograms[i],sep="")]] <- c(scatterplots[shareY])  
               }
           } 
        }
        
        synchronizeHistBindings <- function(W) {
            #print(paste(W, ', busy', busy))
            if (!busy) {
                busy <<- TRUE
                class(W) <- "loon"
                zoomX <- W['zoomX']; zoomY <- W['zoomY']
                panX <- W['panX']; panY <- W['panY']
                deltaX <- W['deltaX']; deltaY <- W['deltaY']
                
                lapply(histsHash[[paste("hist_x_",W,sep="")]], function(h) {
                    l_configure(h, zoomX=zoomX, panX=panX, deltaX=deltaX)
                })
                
                lapply(histsHash[[paste("hist_y_",W,sep="")]], function(h) {
                    l_configure(h, zoomY=zoomX, panY=panX, deltaY=deltaX)
                })
                busy <<- FALSE
                tcl('update', 'idletasks')
                ##assign("busy", FALSE, envir=parent.env(environment()))
            }
        }
        # synchronize
        lapply(histograms, function(h) {
            tcl(h, 'systembind', 'state', 'add',
                c('zoomX', 'panX', 'zoomY', 'panY', 'deltaX', 'deltaY'),
                synchronizeHistBindings)
        })
        # forbidden
        lapply(histograms, function(h) {
            tcl(h, 'systembind', 'state', 'add',
                c('showLabels', 'showScales'),
                undoHistStateChanges)
        })

        if(histLocation == "edge") {
            plots<- c(plots, histograms[2:(2*nvar-1)])
        } else {
            plots<- c(plots, histograms)
        }
        
        callbackFunctions$state[[paste(child,"synchronizeHist", sep="_")]] <- synchronizeHistBindings
        callbackFunctions$state[[paste(child,"undoHistStateChanges", sep="_")]] <- undoHistStateChanges
    }
    if(showSerialAxes) {
        plots <- c(plots, list(serialAxes = serialAxes))
    }
    
    ## beware undoScatterStateChanges and synchronizeScatterBindings from garbage collector
    callbackFunctions$state[[paste(child,"synchronizeScatter", sep="_")]] <- synchronizeScatterBindings
    callbackFunctions$state[[paste(child,"undoScatterStateChanges", sep="_")]] <- undoScatterStateChanges
    
    structure(
        plots,
        class = c("l_pairs", "l_compound", "loon")
    )
}



## forbidden states
undoScatterStateChanges <- function(W) {
    warning("showLabels, showScales, and swapAxes can not be changed for scatterplot matrix.")
    l_configure(W, showLabels = FALSE, showScales = FALSE, swapAxes = FALSE)
}

undoHistStateChanges <- function(W) {
    warning("showLabels, showScales can not be changed for scatterplot matrix.")
    l_configure(W, showLabels = FALSE, showScales = FALSE)
}

# names must follow the pattern xayb, (a,b) is the coords of the corresponding layout
xy_layout <- function(names){
    namesSplit <- strsplit(names, split = "")
    lay_out <- as.data.frame(
        t(
            sapply(namesSplit,
                   function(char){
                       xpos <- which(char %in% "x" == TRUE)
                       ypos <- which(char %in% "y" == TRUE)
                       len_char <- length(char)
                       c(as.numeric(paste0(char[(xpos + 1) : (ypos - 1)], collapse = "")),
                         as.numeric(paste0(char[(ypos + 1) : (len_char)], collapse = "")))
                   }
            )
        )
    )
    colnames(lay_out) <- c("x", "y")
    lay_out
}
