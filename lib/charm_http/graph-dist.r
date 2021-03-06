try_install <- function(package_names)
{
  for(n in package_names)
  {
    success = library(n, "logical.return" = TRUE, "character.only" = TRUE)
    if(!success)
    {
      paste(">> INSTALLING", n, "PACKAGE", " ")
      install.packages(n, repos='http://cran.cnr.berkeley.edu')
      library(n, "character.only" = TRUE)
    }
  }
}

# load required packages
try_install(c("scales", "ggplot2", "RColorBrewer"))
library("RColorBrewer")

# Parse args
args <- commandArgs(TRUE)
if(is.na(args[1])) {
  ">> ERROR: Missing output filename"
  q(status=1)
} else {
  outputfile = args[1]
}

# Load data
data = read.table('tmp/data-dist.ssv', header=T, sep=" ")

# Convert count to fraction of total count
total_counts <- sum(data$count)
data$percent <- data$count / total_counts
data$buckets <- with(data, reorder(buckets, order))

# Set up plot
png(outputfile, width=8, height=6, units = 'in', res=150)

# Set up colors
cols = brewer.pal(9, 'Set1')

# Add bars
bar_chart <- ggplot(data, aes(x=buckets, y=percent, color=cols[2], fill=cols[2])) +
  theme_bw() +
  geom_bar(stat="identity") +
  xlab("Response Time (ms)") +
  ylab("Percent") +
  scale_y_continuous(labels = percent_format(), limits=c(0,1))

if(is.na(args[2])) {
  bar_chart <- bar_chart + labs(title = "Response Time Distribution")
} else {
  bar_chart <- bar_chart + labs(title = args[2])
}

fortify_pareto_data <- function(data, xvar, yvar, sort = TRUE)
{
  for(v in c(xvar, yvar))
  {
    if(!(v %in% colnames(data)))
    {
      stop(sQuote(v), " is not a column of the dataset")
    }
  }

  if(sort) {
    o <- order(data[, yvar], decreasing = TRUE)
    data <- data[o, ]
    data[, xvar] <- factor(data[, xvar], levels = data[, xvar])
  }

  data[, yvar] <- as.numeric(data[, yvar])
  data$.cumulative.y <- cumsum(data[, yvar])

  data$.numeric.x <- as.numeric(data[, xvar])
  data
}

fortified_data <- fortify_pareto_data(data, "buckets", "percent", sort=FALSE)

pareto_plot <- bar_chart %+% fortified_data +
    geom_line(aes(.numeric.x, .cumulative.y, colour=cols[1])) +
    ylab("Cumulative Percentage") +
    scale_fill_identity() +
    scale_color_identity() +
    scale_y_continuous(labels = percent_format(), limits=c(0,1))
pareto_plot
