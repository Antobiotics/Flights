# Ok a few things here:
# * the code is horrid
# * I realise now that I should have followed my first intuition
# * need to run `brew install imagemagick` to run that
# Not sure if I can show the output in the report. It lives in `./output/`
BuildFlightNetworkAnimation <- function(flights,
                                        airports.schedule,
                                        variable) {
  system("rm ./output/*.png")
  col.1 <- adjustcolor("green", alpha.f = 0.5)
  col.2 <- adjustcolor("red", alpha.f = 0.5)
  edge.pal <- colorRampPalette(c(col.1, col.2), alpha = TRUE)
  edge.col <- edge.pal(100)
  prefix <- sprintf("./output/%s__map", variable)
  output.format <- prefix %+% "%02d.png"
  png(file = output.format, width = 1024, height = 1024)
  lapply(X = sort(unique(flights$dep_hour)),
         FUN = function(h) {
           print(sprintf("Building map at hour %s", h))
           # h <- 0
           flights.at <- flights %>%
             dplyr::filter(dep_hour == h)

           schedule <-
             airports.schedule %>%
             dplyr::filter(hour == h)

           tab <- table(flights.at$source)
           big.ids <- names(tab)[tab > 0] # Arbitrary cutoff to reduce noise
           hubs <- schedule[schedule$iata %in% big.ids, ]
           # hubs <- airports
           flights.sub.set <- flights.at[flights.at$source %in% big.ids |
                                           flights.at$target %in% big.ids, ]

           # Create the map background:
           map("state", col = "grey20", fill = TRUE, bg = "black", lwd = 0.1)
           # Plot the hubs:
           points(x = hubs$longitude, y = hubs$latitude,
                  pch = 19,  col = edge.col[as.integer(100 * hubs[, variable])])

           # Plot the flights as arcs
           lapply(X = 1:nrow(flights.sub.set),
                  FUN = function(i) {
                    node1 <- hubs[hubs$iata == flights.sub.set[i,]$source,]
                    node2 <- hubs[hubs$iata == flights.sub.set[i,]$target,]


                    if (nrow(node1) != 0 & nrow(node2)) { # we never know
                      arc <- gcIntermediate(
                        c(node1[1,]$longitude, node1[1,]$latitude),
                        c(node2[1,]$longitude, node2[1,]$latitude),
                        n = 1000, addStartEnd = TRUE
                      )
                      edge.ind <- as.integer(100 * node1[, variable])
                      lines(arc, col = edge.col[edge.ind], lwd = edge.ind/20)
                    }
                  })
         })
  dev.off()
  system(sprintf("convert -delay 80 ./output/*.png %s.gif", prefix))
}
