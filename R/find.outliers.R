#' Find Statistical Outliers in a Meta-Analysis
#'
#' Searches for statistical outliers in meta-analysis results generated by \code{\link[meta]{meta}} functions or
#' \code{\link[metafor]{rma.uni}} in \code{metafor}.
#'
#' @usage find.outliers(x)
#'
#' @param x Either (1) an object of class \code{meta}, generated by the \code{metabin}, \code{metagen},
#' \code{metacont}, \code{metacor}, \code{metainc}, \code{metarate} or \code{metaprop} function; or (2)
#' and object of class \code{rma.uni} created with the \code{\link[metafor]{rma.uni}} function in \code{metafor}.
#'
#' @details
#' This function searches for outlying studies in a meta-analysis results object. Studies are defined as outliers when
#' their 95\% confidence interval lies ouside the 95\% confidence interval of the pooled effect.
#'
#' When outliers are found, the function automatically recalculates the meta-analysis results, using the same settings as
#' in the object provided in \code{x}, but excluding the detected outliers.
#'
#' @references Harrer, M., Cuijpers, P., Furukawa, T.A, & Ebert, D. D. (2019).
#' \emph{Doing Meta-Analysis in R: A Hands-on Guide}. DOI: 10.5281/zenodo.2551803. \href{https://bookdown.org/MathiasHarrer/Doing_Meta_Analysis_in_R/detecting-outliers-influential-cases.html}{Chapter 6.2}
#'
#' @author Mathias Harrer & David Daniel Ebert
#'
#' @return
#' Returns the identified outliers and the meta-analysis results when the outliers are removed.
#'
#' If the provided meta-analysis object is of class \code{meta}, the following objects are returned if the
#' results of the function are saved to another object:
#' \itemize{
#' \item \code{out.study.fixed}: A numeric vector containing the names of the outlying studies when
#' assuming a fixed-effect model.
#' \item \code{out.study.random}: A numeric vector containing the names of the outlying studies when
#' assuming a random-effects model. The tau-squared estimator \code{method.tau} is inherited from \code{x}.
#' \item \code{m.fixed}: An object of class \code{meta} containing the results of the meta-analysis with outliers
#' removed (assuming a fixed-effect model).
#' \item \code{m.random}: An object of class \code{meta} containing the results of the meta-analysis with outliers
#' removed (assuming a random-effects model, and using the same \code{method.tau} as in the original analysis).
#'}
#'
#' If the provided meta-analysis object is of class \code{rma.uni}, the following objects are returned if the
#' results of the function are saved to another object:
#' \itemize{
#' \item \code{out.study}: A numeric vector containing the names of the outlying studies.
#' \item \code{m}: An object of class \code{rma.uni} containing the results of the meta-analysis with outliers
#' removed (using the same settings as in the meta-analysis object provided).
#'}
#'
#' @importFrom metafor rma.uni
#' @importFrom meta update.meta
#'
#' @export find.outliers
#'
#' @aliases spot.outliers.random spot.outliers.fixed spot.outliers
#'
#' @seealso \code{\link[metafor]{influence.rma.uni}}, \code{\link[meta]{metainf}}, \code{\link[meta]{baujat}}
#'
#' @examples
#' suppressPackageStartupMessages(library(dmetar))
#' suppressPackageStartupMessages(library(meta))
#' suppressPackageStartupMessages(library(metafor))
#'
#' # Pool with meta
#' m1 <- metagen(TE, seTE, data = ThirdWave,
#'               studlab = ThirdWave$Author, comb.fixed = FALSE)
#'
#' # Pool with metafor
#' m2 <- rma(yi = TE, sei = seTE, data = ThirdWave,
#'           slab = ThirdWave$Author, method = "PM")
#'
#' # Find outliers
#' find.outliers(m1)
#' find.outliers(m2)


find.outliers = spot.outliers.random = spot.outliers.fixed = function(x){


  if (class(x)[1] %in% c("rma.uni", "rma")){

    token = "metafor"

    # Generate lower/upper for all effects
    lower = as.numeric(x$yi - 1.96*sqrt(x$vi))
    upper = as.numeric(x$yi + 1.96*sqrt(x$vi))

    # Select outliers
    mask = upper < x$ci.lb | lower > x$ci.ub
    dat = data.frame("yi" = x$yi[!mask],
                     "vi" = x$vi[!mask])
    out.study = x$slab[mask]

    # Update metafor model
    method.tau = x$method
    m = metafor::rma.uni(dat$yi, vi = dat$vi, method = method.tau)

    if (length(out.study) < 1){

      cat(paste0("No outliers detected (", method.tau,")."))
      out.study = NULL

    } else {

      cat(paste0("Identified outliers (", method.tau,")"), "\n")
      cat("-------------------------", "\n")
      cat(paste(shQuote(out.study, type="cmd"), collapse=", "), "\n", "\n")
      cat("Results with outliers removed", "\n")
      cat("-----------------------------", "\n")
      print(m)

    }

  }

  if (class(x)[1] %in% c("metagen", "metapropr",
                         "metacor", "metainc",
                         "metaprop", "metabin", "metabin")){

    token = "meta"

    if (class(x)[1] == "metaprop"){

      lower = x$TE - 1.96*x$seTE
      upper = x$TE + 1.96*x$seTE

      # Generate mask with outliers (fixed/random)
      mask.fixed = upper < x$lower.fixed | lower > x$upper.fixed
      mask.random = upper < x$lower.random | lower > x$upper.random

    } else {

      # Generate mask with outliers (fixed/random)
      mask.fixed = x$upper < x$lower.fixed | x$lower > x$upper.fixed
      mask.random = x$upper < x$lower.random | x$lower > x$upper.random

    }

    # Update meta-analysis with outliers removed
    m.fixed = update.meta(x, exclude = mask.fixed)
    m.random = update.meta(x, exclude = mask.random)

    # Select names of outlying studies
    out.study.fixed = x$studlab[mask.fixed]
    out.study.random = x$studlab[mask.random]

    if (x$comb.fixed == TRUE & x$comb.random == FALSE){

      if (length(out.study.fixed) < 1){

        cat("No outliers detected (fixed-effect model).")
        out.study.fixed = NULL

      } else {

        cat("Identified outliers (fixed-effect model)", "\n")
        cat("----------------------------------------", "\n")
        cat(paste(shQuote(out.study.fixed, type="cmd"), collapse=", "), "\n", "\n")
        cat("Results with outliers removed", "\n")
        cat("-----------------------------", "\n")
        print(m.fixed)

      }

    }

    if (x$comb.fixed == FALSE & x$comb.random == TRUE){

      if (length(out.study.random) < 1){

        cat("No outliers detected (random-effects model).")
        out.study.random = NULL

      } else {

        cat("Identified outliers (random-effects model)", "\n")
        cat("------------------------------------------", "\n")
        cat(paste(shQuote(out.study.random, type="cmd"), collapse=", "), "\n", "\n")
        cat("Results with outliers removed", "\n")
        cat("-----------------------------", "\n")
        print(m.random)

      }

    }

    if (x$comb.fixed == TRUE & x$comb.random == TRUE){

      if (length(out.study.fixed) < 1 & length(out.study.random) < 1){

        cat("No outliers detected (fixed-effect/random-effects model).")
        out.study.fixed = NULL
        out.study.random = NULL

      } else {

        cat("Identified outliers (fixed-effect model)", "\n")
        cat("----------------------------------------", "\n")
        cat(paste(shQuote(out.study.fixed, type="cmd"), collapse=", "), "\n", "\n")
        cat("Results with outliers removed", "\n")
        cat("-----------------------------", "\n")
        print(m.fixed)

        cat("\n")

        cat("Identified outliers (random-effects model)", "\n")
        cat("------------------------------------------", "\n")
        cat(paste(shQuote(out.study.random, type="cmd"), collapse=", "), "\n", "\n")
        cat("Results with outliers removed", "\n")
        cat("-----------------------------", "\n")
        print(m.random)

      }

    }

  }

  if (!class(x)[1] %in% c("rma.uni", "rma",
                          "metagen", "metapropr",
                          "metacor", "metainc",
                          "metaprop", "metabin", "metabin")){

    message("Input must be of class 'meta' or 'rma.uni'")

  }

  if (token == "metafor"){

    invisible(list("out.study" = out.study,
                   "m" = m))

  } else {


    invisible(list("out.study.fixed" = out.study.fixed,
                   "out.study.random" = out.study.random,
                   "m.fixed" = m.fixed,
                   "m.random" = m.random))

  }

}













