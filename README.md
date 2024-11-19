# Length-of-stay-prediction
The dataset reflects the length of stay(LOS) of patients who are all diagnosed as Septicemia.The dependent variable has a skewed distribution and a long tail,75% of  LOS is below 11 days, while 25% of LOS ranges from 12days to 120days.
I drop some observations that is unknown or de-identification, so about 62k observations are dropped, remaining 21,881 observations. I also dropped 4,991 observations that has over 11days of LOS(the 3rd quantile) to improve the accuracy of my model because high skewness of samples can have a huge implication on model’s error, remaining 16,890 observations.

I built 3 models to make prediction.

Linear regression model: As the dependent variable has a skewed distribution, I made a log transformation to y variable to see whether it can produce a lower RMSE for linear regression model without filtering out observations of LOS over 11days. But unfortunately, log y model gave an even huge RMSE result, reaching over 180 without filtering out LOS over 11days. And  Lasso regression also produce a similar RMSE as stepwise linear regression.

CART: I have searched the optimal CP value for my decision tree model, but the RMSE is still higher than my random forest model.

RF model: The random forest model has the lowest RMSE, which means that it has the best predictive ability among three models. And I utilized tuneRF() function (reference from ChatGPT) to search the optimal mtry and further reduce RMSE of my RF model. The default setting of mtry is 6 (because there are 18 x variables), and RMSE is 1.563. When mtry is 9, the model reflects the minimum OOB error and RMSE reduces to 1.5589. And I plotted a graph about OOB error and ntree numbers. When ntree is 500,OOB error remain steady .So there is no need to increase the tree number.

Summary:This random forest model may only have high predictive ability for those Septicemia patients whose total cost of cure is less than 240,000 and total charge less than 1,000,000. When hospital admitted a Septicemia patient and input the estimated cost and charge of cure and other detailed information about the patient, the model can tell a relatively accurate length of stay. However, when comes to a more severe Septicemia patient, prediction may not be so accurate.

We can extend the model by collecting more data from more severe patients who have LOS more than 11days, or who are infected with other diseases, or who are discharged in other year rather than 2022. In that case, we can build a model that have a wider business application.
