#Packages Utilized
require(dplyr)
require(ggplot2)
require(reshape2)
require(ROCR)
set.seed(101)
#Set pathway
setwd('C:/Users/paulb/Documents/DSBA6156/Final_Project/DSBA6156_FP')

#Data reading; nitpicky transformations
#Source for data: https://www.kaggle.com/ntnu-testimon/paysim1
data <- read.csv('PS_20174392719_1491204439457_log.csv')
colnames(data)[colnames(data) == 'oldbalanceOrg'] <- 'oldbalanceOrig'
data$isFlaggedFraud <- NULL

#String indicator columns
data$nameDestTag <- substr(data$nameDest, 1, 1)

#Binary columns for transactions
table(data$type, data$isFraud)

data$TRANSFER <- ifelse(data$type == 'TRANSFER', 1, 0)
data$CASH_OUT <- ifelse(data$type == 'CASH_OUT', 1, 0)
data$OTHER <- ifelse(data$type != 'TRANSFER' & data$type != 'CASH_OUT', 1, 0)
data$nameDestC <- ifelse(data$nameDestTag == 'C', 1, 0)

data$nameDestTag <- NULL

table(data$oldbalanceOrig == data$newbalanceOrig, data$oldbalanceOrig == 0)
unique(data$type)
unique(data$nameDestC)
table(data$nameDestC, data$OTHER)

#Creating transformed table
trial <- data %>%
  select(-type, -nameOrig, -nameDest, -isFraud)
trial$isFraud <- data$isFraud

#Creating trimmed table
trial.trim <- trial %>%
  filter(nameDestC == 1 & OTHER == 0) %>%
  select(-OTHER, -nameDestC, -CASH_OUT)

trial$OTHER <- NULL
rm(data)

#Creating Correlation Matrix
#SOURCE (for correlation mapping): http://www.sthda.com/english/wiki/ggplot2-quick-correlation-matrix-heatmap-r-software-and-data-visualization
reorder_cormat <- function(cormat){
  dd <- as.dist((1-cormat)/2)
  hc <- hclust(dd)
  cormat <-cormat[hc$order, hc$order]
}

cormat <- round(cor(trial), 2)
cormat <- reorder_cormat(cormat)

cormat.trim <- round(cor(trial.trim), 2)
cormat.trim <- reorder_cormat(cormat.trim)

#Correlation Map - Full dataset
melt1 <- melt(cormat, na.rm = TRUE)

trial.cor <- ggplot(data = melt1, aes(x=Var1, y=Var2, fill=value)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1,1), space = "Lab", 
                       name="Pearson\nCorrelation") +
  theme_minimal() + 
  geom_text(aes(Var2, Var1, label = value), color = "black", size = 4) +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        panel.grid.major = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.ticks = element_blank(),
        legend.position = 'none')+
  guides(fill = guide_colorbar(barwidth = 7, barheight = 1,
                               title.position = "top", title.hjust = 0.5))
trial.cor

#Correlation Map - Trimmed dataset
melt2 <- melt(cormat.trim)

trim.cor <- ggplot(data = melt2, aes(x=Var1, y=Var2, fill=value)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1,1), space = "Lab", 
                       name="Pearson\nCorrelation") +
  theme_minimal() + 
  geom_text(aes(Var2, Var1, label = value), color = "black", size = 4) +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        panel.grid.major = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank(),
        axis.ticks = element_blank(),
        legend.position = 'none')+
  guides(fill = guide_colorbar(barwidth = 7, barheight = 1,
                               title.position = "top", title.hjust = 0.5))
trim.cor

rm(melt1, melt2, cormat, cormat.trim, get_lower_tri, get_upper_tri, reorder_cormat)

#Final manipulations - Type -> Factor for regression
trial[,7:10] <- lapply(trial[,7:10], as.factor)
trial.trim[,7:8] <- lapply(trial.trim[,7:8], as.factor)

#Full dataset - Train/test 70/30
trial$id <- 1:nrow(trial)
train <- trial %>% sample_frac(.7)
test  <- anti_join(trial, train, by = 'id')
train$id <- NULL
test$id <- NULL

mod1 <- glm(isFraud ~ ., data = train[, -9], family=binomial(link="logit"))
predicted1t <- predict(mod1, train, type="response")
predicted1 <- predict(mod1, test, type="response")

#AUC mod1 for training set
pr <- prediction(predicted1t, train$isFraud)
prf <- performance(pr, measure = "tpr", x.measure = "fpr")
plot(prf)

auc <- performance(pr, measure = "auc")
auc <- auc@y.values[[1]]
auc

#Sens/spec of mod1 on training set
sas.perf <- performance(pr, measure = 'sens', x.measure = 'spec')
plot(sas.perf)

#Threshold of mod1 on training set
z1 <- sas.perf@alpha.values[[1]][which.max(sas.perf@x.values[[1]]+sas.perf@y.values[[1]])]
max(sas.perf@x.values[[1]]+sas.perf@y.values[[1]])

table(train$isFraud, predicted1t > z1)
prop.table(table(train$isFraud, predicted1t > z1), 1)

#AUC mod1 on testing set
pr1 <- prediction(predicted1, test$isFraud)
prf1 <- performance(pr1, measure = "tpr", x.measure = "fpr")
plot(prf1)

auc1 <- performance(pr1, measure = "auc")
auc1 <- auc1@y.values[[1]]
auc1

#Sens/spec mod1 on testing set
sas.perf1 <- performance(pr1, measure = 'sens', x.measure = 'spec')
plot(sas.perf1)

#Threshold mod1 on testing set
z2 <- sas.perf1@alpha.values[[1]][which.max(sas.perf1@x.values[[1]]+sas.perf1@y.values[[1]])]
max(sas.perf1@x.values[[1]]+sas.perf1@y.values[[1]])

table(test$isFraud, predicted1 > z2)
prop.table(table(test$isFraud, predicted1 > z2), 1)

#Trimmed dataset - Train/test 70/30
trial.trim$id <- 1:nrow(trial.trim)
train.trim <- trial.trim %>% sample_frac(.7)
test.trim  <- anti_join(trial.trim, train.trim, by = 'id')
trial.trim$id <- NULL
train.trim$id <- NULL
test.trim$id <- NULL

mod2 <- glm(isFraud ~ ., data = train.trim, family=binomial(link="logit"))
predicted2t <- predict(mod2, train.trim, type="response")
predicted2 <- predict(mod2, test.trim, type="response")

#AUC mod2 on training set
pr2t <- prediction(predicted2t, train.trim$isFraud)
prf2t <- performance(pr2t, measure = "tpr", x.measure = "fpr")
plot(prf2t)

auc2t <- performance(pr2t, measure = "auc")
auc2t <- auc2t@y.values[[1]]
auc2t

#Sens/spec mod2 on training set
sas.perf2t <- performance(pr2t, measure = 'sens', x.measure = 'spec')
plot(sas.perf2t)

#Threshold mod2 on training set
z3 <- sas.perf2t@alpha.values[[1]][which.max(sas.perf2t@x.values[[1]]+sas.perf2t@y.values[[1]])]
max(sas.perf2t@x.values[[1]]+sas.perf2t@y.values[[1]])

table(train.trim$isFraud, predicted2t > z3)
prop.table(table(train.trim$isFraud, predicted2t > z3), 1)

#AUC mod2 on testing set
pr2 <- prediction(predicted2, test.trim$isFraud)
prf2 <- performance(pr2, measure = "tpr", x.measure = "fpr")
plot(prf2)

auc2 <- performance(pr2, measure = "auc")
auc2 <- auc2@y.values[[1]]
auc2

#Sens/spec mod2 on testing set
sas.perf2 <- performance(pr2, measure = 'sens', x.measure = 'spec')
plot(sas.perf2)

#Threshold mod2 on testing set
z4 <- sas.perf2@alpha.values[[1]][which.max(sas.perf2@x.values[[1]]+sas.perf2@y.values[[1]])]
max(sas.perf2@x.values[[1]]+sas.perf2@y.values[[1]])

table(test.trim$isFraud, predicted2 > z4)
prop.table(table(test.trim$isFraud, predicted2 > z4), 1)

#Histogram of results
hist(predicted2t, xlim = c(0, .01), breaks = 10000)

plot(trial.trim$score.1, trial.trim$score.2,
     col = as.factor(trial.trim$isFraud))

ggplot(data = trial.trim, aes(x = step, y = newbalanceOrig, fill = isFraud)) +
  geom_point() +
  facet_wrap(~TRANSFER, ncol = 2)