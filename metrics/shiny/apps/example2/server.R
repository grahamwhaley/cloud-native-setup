# Define server logic required to draw a histogram ----
source("/inputdir/Env.R")
pdf(NULL)
source(paste(scriptdir, 'collectd_scaling.R', sep='/'))

server <- function(input, output) {

  # Histogram of the Old Faithful Geyser Data ----
  # with requested number of bins
  # This expression that generates a histogram is wrapped in a call
  # to renderPlot to indicate that:
  #
  # 1. It is "reactive" and therefore should be automatically
  #    re-executed when inputs (input$bins) change
  # 2. Its output type is a plot
  output$distPlot <- renderPlot({

	cpu_line_plot <- ggplot() +
		geom_line(data=cpuidledata,
		aes(x=s_offset, y=value, colour=interaction(testname, node),
		group=interaction(testname, node)),
		alpha=input$alpha)

	cpu_line_plot

#    x    <- faithful$waiting
#    bins <- seq(min(x), max(x), length.out = input$bins + 1)

#    hist(x, breaks = bins, col = "#75AADB", border = "white",
#         xlab = "Waiting time to next eruption (in mins)",
#         main = "Histogram of waiting times")

    })


}
