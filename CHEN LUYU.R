library(data.table)
library(caTools)            # Train-Test Split
library(rpart)              # CART
library(randomForest)       # Random Forest
library(glmnet)

setwd("/Users/chh/Desktop/MSBA/Analytic strategy/AY24 CBA")

data1 <- fread("INF002v4.csv", stringsAsFactors = T)

class(data1$Total.Charges)

data1$Total.Charges <- gsub(",", "", data1$Total.Charges) # 去掉逗号
data1$Total.Costs <- gsub(",", "", data1$Total.Costs)
data1$Total.Charges <- as.numeric(as.character(data1$Total.Charges))
data1$Total.Costs <- as.numeric(as.character(data1$Total.Costs))
data1$APR.Severity.of.Illness.Code <- factor(data1$APR.Severity.of.Illness.Code)
data1$APR.DRG.Code <- factor(data1$APR.DRG.Code)
summary(data1)


cols_to_drop <- c("Discharge.Year", "CCSR.Diagnosis.Code", "CCSR.Diagnosis.Description"
                  , "APR.DRG.Code")
dt <- data1[, !cols_to_drop, with = FALSE]
summary(dt)
colnames(dt)
plot(dt$Length.of.Stay)
# Train-test split ---------------------------------------------------------
set.seed(2)
train <- sample.split(Y=dt$Length.of.Stay, SplitRatio = 0.7)

trainset <- dt[train == T & APR.DRG.Description != "PANCREAS TRANSPLANT"
               & Hospital.Service.Area!=""
               &Patient.Disposition!="Expired"
               &Patient.Disposition!="Another Type Not Listed"
               &APR.DRG.Description!="UNGROUPABLE"
               &Ethnicity!="Unknown"
               &Length.of.Stay<=11]

testset <- dt[train == F & APR.DRG.Description != "PANCREAS TRANSPLANT"
              & Hospital.Service.Area!=""
              &Patient.Disposition!="Expired"
              &Patient.Disposition!="Another Type Not Listed"
              &APR.DRG.Description!="UNGROUPABLE"
              &Ethnicity!="Unknown"
              &Length.of.Stay<=11]#factor APR.DRG.Description has new levels PANCREAS TRANSPLANT and only one sample


RF <- randomForest(Length.of.Stay ~ . , data=trainset)
RF.yhat <- predict(RF, newdata = testset)
RMSE.test.RF <- round(sqrt(mean((testset$Length.of.Stay - RF.yhat)^2)),4)
print(RMSE.test.RF)#1.563
print(RF) 

#only variables with high significance put into RF
RF2 <- randomForest(Length.of.Stay ~ Total.Charges+Total.Costs+Hospital.Service.Area+APR.DRG.Description+Patient.Disposition, data=trainset)
RF2.yhat <- predict(RF2, newdata = testset)
RMSE.test.RF2 <- round(sqrt(mean((testset$Length.of.Stay - RF2.yhat)^2)),2)
print(RMSE.test.RF2)#1.64

##find optimal mtry
tuned_rf <- tuneRF(
  trainset[,c("Total.Charges","Total.Costs" ,"Hospital.Service.Area","APR.DRG.Description" ,"Patient.Disposition","Age.Group","Gender", 
    "Race" , "Ethnicity","Type.of.Admission","APR.Severity.of.Illness.Code", "APR.Severity.of.Illness.Description" , 
    "APR.Risk.of.Mortality" ,"APR.Medical.Surgical.Description" ,
    "Payment.Typology.1", "Payment.Typology.2","Payment.Typology.3",  
    "Emergency.Department.Indicator")],
  trainset$Length.of.Stay, 
  ntreeTry = 500, 
  stepFactor = 1.5,
  improve = 0.01, 
  trace = TRUE 
)
plot(RF, main = "OOB Error vs Number of Trees")
RF.final <- randomForest(Length.of.Stay ~ . ,mtry=9, data=trainset)
RF.yhat.final <- predict(RF.final, newdata = testset)
RMSE.test.RF.final <- round(sqrt(mean((testset$Length.of.Stay - RF.yhat.final)^2)),4)
var.impt <- importance(RF.final)
varImpPlot(RF.final)
print(RMSE.test.RF.final)#1.5589
print(RF.final)
###linear regression model

lr <- step(lm(Length.of.Stay ~ . , data=trainset))
lr.yhat <- predict(lr, newdata = testset)
RMSE.test.lr <- round(sqrt(mean((testset$Length.of.Stay - lr.yhat)^2)),2)
# 1.84
summary(lr)



##CART MODEL
cart.max <- rpart(Length.of.Stay ~ . , cp=0, data=trainset)
# Compute min CVerror + 1SE in maximal tree m2 
CVerror.cap <- cart.max$cptable[which.min(cart.max$cptable[,"xerror"]), "xerror"] + 
  cart.max$cptable[which.min(cart.max$cptable[,"xerror"]), "xstd"]

# Find the optimal CP region whose CV error is just below CVerror.cap in maximal tree cart.max.
i <- 1; j<- 4
while (cart.max$cptable[i,j] > CVerror.cap) {
  i <- i + 1
}

# Get geometric mean of the identified min CP value and the CP above if optimal tree has at least one split.
cp.opt = ifelse(i > 1, sqrt(cart.max$cptable[i,1] * cart.max$cptable[i-1,1]), 1)

# Get best tree based on 10 fold CV with 1 SE
cart.opt <- prune(cart.max, cp = cp.opt)

cart.yhat <- predict(cart.opt, newdata = testset)
RMSE.test.cart <- round(sqrt(mean((testset$Length.of.Stay - cart.yhat)^2)),2)
terminal_nodes <- sum(cart.opt$frame$var == "<leaf>")
print(terminal_nodes)
## 1.68