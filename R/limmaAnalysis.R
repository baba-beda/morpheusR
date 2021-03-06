limmaAnalysisImpl <- function(es, fieldValues) {
    fieldValues <- replace(fieldValues, fieldValues == "", NA)

    es.copy <- es
    es.copy$Comparison <- fieldValues
    fData(es.copy) <- data.frame(row.names = rownames(es.copy))

    es.copy <- es.copy[, !is.na(es.copy$Comparison)]

    # Getting rid of check NOTEs
    Comparison=ComparisonA=ComparisonB=NULL

    es.design <- stats::model.matrix(~0 + Comparison, data = pData(es.copy))

    fit <- lmFit(es.copy, es.design)

    A <- NULL; B <- NULL
    fit2 <- contrasts.fit(fit, makeContrasts(ComparisonB - ComparisonA, levels = es.design))
    fit2 <- eBayes(fit2)
    de <- topTable(fit2, adjust.method = "BH", number = Inf)
    de <- de[row.names(fData(es.copy)), ]
    de
}

#' Differential Expression analysis.
#'
#' \code{limmaAnalysis} performs differential expression analysis
#'     from limma package and returns a ProtoBuf-serialized resulting
#'     de-matrix.
#'
#' @param es ExpressionSet object. It should be normalized for
#'     more accurate analysis.
#'
#' @param fieldValues Vector of comparison values, mapping
#'     categories' names to columns/samples
#'
#' @return Name of the file containing serialized de-matrix.
#'
#' @import Biobase
#' @import limma
#'
#' @examples
#' \dontrun{
#' data(es)
#' limmaAnalysis(es, fieldValues = c("A", "A", "A", "B", "B"))
#' }
limmaAnalysis <- function(es, fieldValues) {
    fieldValues <- replace(fieldValues, fieldValues == "", NA)
    de <- limmaAnalysisImpl(es, fieldValues)

    toRemove <- intersect(colnames(fData(es)), colnames(de))
    fData(es)[, toRemove] <- NULL
    fData(es) <- cbind(fData(es), de)
    es$Comparison <- fieldValues
    assign("es", es, envir = parent.frame())

    f <- tempfile(pattern = "de", tmpdir = getwd(), fileext = ".bin")
    writeBin(protolite::serialize_pb(as.list(de)), f)
    jsonlite::toJSON(f)
}
