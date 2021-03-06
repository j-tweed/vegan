`scores.cca` <-
    function (x, choices = c(1, 2), display = c("sp", "wa", "cn"),
              scaling = "species", hill = FALSE, ...)
{
    if(inherits(x, "pcaiv")) {
        warning("looks like ade4::cca object: you better use ade4 functions")
        x <- ade2vegancca(x)
    }
    ## Check the na.action, and pad the result with NA or WA if class
    ## "exclude"
    if (!is.null(x$na.action) && inherits(x$na.action, "exclude"))
        x <- ordiNApredict(x$na.action, x)
    tabula <- c("species", "sites", "constraints", "biplot",
                "centroids")
    names(tabula) <- c("sp", "wa", "lc", "bp", "cn")
    if (is.null(x$CCA))
        tabula <- tabula[1:2]
    display <- match.arg(display, c("sites", "species", "wa",
                                    "lc", "bp", "cn"),
                         several.ok = TRUE)
    if("sites" %in% display)
        display[display == "sites"] <- "wa"
    if("species" %in% display)
        display[display == "species"] <- "sp"
    take <- tabula[display]
    slam <- sqrt(c(x$CCA$eig, x$CA$eig)[choices])
    rnk <- x$CCA$rank
    sol <- list()
    ## check scaling for character & process it if so
    if (is.character(scaling)) {
        scaling <- scalingType(scaling = scaling, hill = hill)
    }
    if ("species" %in% take) {
        v <- cbind(x$CCA$v, x$CA$v)[, choices, drop = FALSE]
        if (scaling) {
            scal <- list(1, slam, sqrt(slam))[[abs(scaling)]]
            v <- sweep(v, 2, scal, "*")
            if (scaling < 0) {
                scal <- sqrt(1/(1 - slam^2))
                v <- sweep(v, 2, scal, "*")
            }
        }
        sol$species <- v
    }
    if ("sites" %in% take) {
        wa <- cbind(x$CCA$wa, x$CA$u)[, choices, drop = FALSE]
        if (scaling) {
            scal <- list(slam, 1, sqrt(slam))[[abs(scaling)]]
            wa <- sweep(wa, 2, scal, "*")
            if (scaling < 0) {
                scal <- sqrt(1/(1 - slam^2))
                wa <- sweep(wa, 2, scal, "*")
            }
        }
        sol$sites <- wa
    }
    if ("constraints" %in% take) {
        u <- cbind(x$CCA$u, x$CA$u)[, choices, drop = FALSE]
        if (scaling) {
            scal <- list(slam, 1, sqrt(slam))[[abs(scaling)]]
            u <- sweep(u, 2, scal, "*")
            if (scaling < 0) {
                scal <- sqrt(1/(1 - slam^2))
                u <- sweep(u, 2, scal, "*")
            }
        }
        sol$constraints <- u
    }
    if ("biplot" %in% take && !is.null(x$CCA$biplot)) {
        b <- matrix(0, nrow(x$CCA$biplot), length(choices))
        b[, choices <= rnk] <- x$CCA$biplot[, choices[choices <=
            rnk]]
        colnames(b) <- c(colnames(x$CCA$u), colnames(x$CA$u))[choices]
        rownames(b) <- rownames(x$CCA$biplot)
        sol$biplot <- b
    }
    if ("centroids" %in% take) {
        if (is.null(x$CCA$centroids))
            sol$centroids <- NA
        else {
            cn <- matrix(0, nrow(x$CCA$centroids), length(choices))
            cn[, choices <= rnk] <- x$CCA$centroids[, choices[choices <=
                 rnk]]
            colnames(cn) <- c(colnames(x$CCA$u), colnames(x$CA$u))[choices]
            rownames(cn) <- rownames(x$CCA$centroids)
            if (scaling) {
                scal <- list(slam, 1, sqrt(slam))[[abs(scaling)]]
                cn <- sweep(cn, 2, scal, "*")
                if (scaling < 0) {
                    scal <- sqrt(1/(1 - slam^2))
                    cn <- sweep(cn, 2, scal, "*")
                }
            }
            sol$centroids <- cn
        }
    }
    ## Take care that scores have names
    if (length(sol)) {
        for (i in seq_along(sol)) {
            if (is.matrix(sol[[i]]))
                rownames(sol[[i]]) <-
                    rownames(sol[[i]], do.NULL = FALSE,
                             prefix = substr(names(sol)[i], 1, 3))
        }
    }
    ## Only one type of scores: return a matrix instead of a list
    if (length(sol) == 1)
        sol <- sol[[1]]
    sol
}
