library(challengeR)
data_matrix <- read.csv(file.choose())

# Same as above but with 'by="task"' where variable "task" contains the task identifier
challenge <- as.challenge(data_matrix, 
                          by = "Task", 
                          algorithm = "Algorithm", case = "TestCase", value = "MetricValue", 
                          smallBetter = FALSE)

ranking <- challenge%>%aggregateThenRank(FUN = mean, # aggregation function, 
                                         # e.g. mean, median, min, max, 
                                         # or e.g. function(x) quantile(x, probs=0.05)
                                         na.treat=0, # either "na.rm" to remove missing data, 
                                         # set missings to numeric value (e.g. 0) 
                                         # or specify a function, 
                                         # e.g. function(x) min(x)
                                         ties.method = "min" # a character string specifying 
                                         # how ties are treated, see ?base::rank
)  

set.seed(123, kind = "L'Ecuyer-CMRG")
ranking_bootstrapped <- ranking%>%bootstrap(nboot = 1000)

meanRanks <- ranking%>%consensus(method = "euclidean") 
ranking_bootstrapped %>% 
  report(consensus = meanRanks,
       title = "Metric Analysis for Connectomics, Microstructure and Macrostructure", # used for the title of the report
         file = "eval_metrics", 
         format = "PDF", # format can be "PDF", "HTML" or "Word"
         latex_engine = "pdflatex", #LaTeX engine for producing PDF output. Options are "pdflatex", "lualatex", and "xelatex"
         clean = TRUE #optional. Using TRUE will clean intermediate files that are created during rendering.
  ) 
