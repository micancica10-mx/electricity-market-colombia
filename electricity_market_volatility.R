library(corrgram)
library(tseries)
library(nortest)
library(lubridate)
library(pastecs)
library(psych)
library(timeSeries)
library(readxl)
library(e1071)
library(sjPlot)
library(sjmisc)
library(sjstats)
library(xtable)
library(ggplot2)
library(forecast)
library(aTSA)
library(vars)
library(FinTS)
library(rugarch)
library(quantmod)
library(rmgarch)
library(xts)
library(zoo)
library(dplyr)
library(tidyr)
library(stargazer)

#Import data
# Load the data from the Excel file
setwd("C:/Users") 
rm(list=ls())

data.dc <- read_excel("data.xlsx", sheet = "data_dc")
data.nces <- read_excel("data.xlsx", sheet = "data_nces")
data.cap <- read_excel("data.xlsx", sheet = "data_cap")

data.all <- cbind(data.dc, data.nces[, -1])

data.ts <- as.ts(xts::xts(order.by = as.Date(data.all$fecha, "%Y-%m-%d"), 
                           x = data.all[,-c(1,10, 11, 17)]))
head(data.ts)

# Transform to GWh
data.ts[, 13] <- data.ts[, 13]/1000000
data.ts[, 3] <- data.ts[, 3]/1000000

# Select relevant variables
# Spot price, hydroelectric price, water availability, and NCRE generation
data <- data.frame(
  dates=data.dc$fecha,
  pbolsa = data.dc$pbolsa,
  pofe_hidro = data.dc$pofe_hidro,
  disp_hidro = data.dc$disp_hidro,
  gen_frnc = data.nces$gen_frnc
)

attach(data)

dates=as.Date(data$dates,format="%y-%m-%d") 
data$dates<-as.Date(data$dates,format="%y-%m-%d")

#Define variables as time series

# Convert variables into daily time series
pbolsa.ts <- ts(data$pbolsa, start = c(2018, 1), frequency = 365)     # Spot price
pofe_hidro.ts <- ts(data$pofe_hidro, start = c(2018, 1), frequency = 365) # Weighted Hydroelectric Price
disp_hidro.ts <- ts(data$disp_hidro, start = c(2018, 1), frequency = 365) # Hydropower Availability
gen_frnc.ts <- ts(data$gen_frnc, start = c(2018, 1), frequency = 365)     # NCRES Generation

#Data summary
n <- ncol(data)  # Number of columns
variables <- data[, 2:n]  # Select numeric variables (excluding dates)
tabla <- stat.desc(variables)  # Descriptive statistics
print(tabla)

# Time-series plots
library(ggplot2)

par(mfrow = c(2, 2))
# Spot price (pbolsa)
ggplot(data, aes(x = dates, y = pbolsa)) +
  geom_line() +
  scale_x_date('Dates', date_breaks = "1 year") +
  ylab("Spot Price (pbolsa)") +
  theme(axis.text.x = element_text(angle = 90))

# Weighted Hydroelectric Price (pofe_hidro)
ggplot(data, aes(x = dates, y = pofe_hidro)) +
  geom_line() +
  scale_x_date('Dates', date_breaks = "1 year") +
  ylab("Hydroelectric Price (pofe_hidro)") +
  theme(axis.text.x = element_text(angle = 90))

#data[, 5] <- data[, 5]/1000000
#data[, 4] <- data[, 4]/1000000

# NCRES Generation (gen_frnc)
ggplot(data, aes(x = dates, y = gen_frnc)) +
  geom_line() +
  scale_x_date('Dates', date_breaks = "1 year") +
  ylab("NCRES Generation (gen_frnc)") +
  theme(axis.text.x = element_text(angle = 90))

# Hydropower Availability (disp_hidro)
ggplot(data, aes(x = dates, y = disp_hidro)) +
  geom_line() +
  scale_x_date('Dates', date_breaks = "1 year") +
  ylab("Hydropower Availability (disp_hidro)") +
  theme(axis.text.x = element_text(angle = 90))

# Compute logarithmic differences
data$ret_pbolsa <- c(NA, diff(log(data$pbolsa)))         # Difference in pbolsa
data$ret_pofe_hidro <- c(NA, diff(log(data$pofe_hidro))) # Difference in pofe_hidro
data$ret_gen_frnc <- c(NA, diff(log(data$gen_frnc)))     # Difference in gen_frnc
data$ret_disp_hidro <- c(NA, diff(log(data$disp_hidro)))     # Difference in gen_frnc

data <- as.data.frame(data)  # Ensure the object is a data frame

# Remove missing values
library(dplyr)
retornos <- na.omit(data[, c("ret_pbolsa", "ret_pofe_hidro", "ret_gen_frnc", "ret_disp_hidro")])


ggplot(data, aes(x = dates, y = ret_pbolsa)) +
  geom_line() +
  scale_x_date('Dates', date_breaks = "1 year") +
  ylab("Log difference Spot Price (pbolsa)") +
  theme(axis.text.x = element_text(angle = 90))

ggplot(data, aes(x = dates, y = ret_pofe_hidro)) +
  geom_line() +
  scale_x_date('Dates', date_breaks = "1 year") +
  ylab("Log difference Hydroelectric Price (pofe_hidro)") +
  theme(axis.text.x = element_text(angle = 90))

ggplot(data, aes(x = dates, y = ret_gen_frnc)) +
  geom_line() +
  scale_x_date('Dates', date_breaks = "1 year") +
  ylab("Log difference NCRES Generation (gen_frnc)") +
  theme(axis.text.x = element_text(angle = 90))

ggplot(data, aes(x = dates, y = ret_disp_hidro)) +
  geom_line() +
  scale_x_date('Dates', date_breaks = "1 year") +
  ylab("Log difference Hydropower Availability (disp_hidro)") +
  theme(axis.text.x = element_text(angle = 90))


# Plot histograms
par(mfrow = c(2, 2))  # Configure the graphics window for multiple plots

# Histogram of log differences in pbolsa
hist(retornos$ret_pbolsa, 
     main = "Spot Price (pbolsa)", 
     col = "blue", 
     xlab = "Log difference", 
     ylab = "Density", 
     freq = FALSE)
curve(dnorm(x, mean = mean(retornos$ret_pbolsa), sd = sd(retornos$ret_pbolsa)), 
      add = TRUE, col = "red")

# Histogram of log differences in pofe_hidro
hist(retornos$ret_pofe_hidro, 
     main = "Hydroelectric Price (pofe_hidro)", 
     col = "blue", 
     xlab = "Log difference", 
     ylab = "Density", 
     freq = FALSE)
curve(dnorm(x, mean = mean(retornos$ret_pofe_hidro), sd = sd(retornos$ret_pofe_hidro)), 
      add = TRUE, col = "red")

# Histogram of log differences in gen_frnc
hist(retornos$ret_gen_frnc, 
     main = "NCRES Generation (gen_frnc)", 
     col = "blue", 
     xlab = "Log difference", 
     ylab = "Density", 
     freq = FALSE)
curve(dnorm(x, mean = mean(retornos$ret_gen_frnc), sd = sd(retornos$ret_gen_frnc)), 
      add = TRUE, col = "red")

# Histogram of log differences in disp_hidro
hist(retornos$ret_disp_hidro, 
     main = "Hydropower Availability (disp_hidro)", 
     col = "blue", 
     xlab = "Log difference", 
     ylab = "Density", 
     freq = FALSE)
curve(dnorm(x, mean = mean(retornos$ret_gen_frnc), sd = sd(retornos$ret_gen_frnc)), 
      add = TRUE, col = "red")

# Load required libraries
library(nortest)

# Normality tests on log differences
# Pearson Chi-square Test: H0: Normality
pearson.test(retornos$ret_pbolsa)        # Log difference of pbolsa
pearson.test(retornos$ret_pofe_hidro)   # Log difference of pofe_hidro
pearson.test(retornos$ret_gen_frnc)     # Log difference of gen_frnc
pearson.test(retornos$ret_disp_hidro)     # Log difference of gen_frnc

# Shapiro-Francia Test
sf.test(retornos$ret_pbolsa)            # Log difference of pbolsa
sf.test(retornos$ret_pofe_hidro)       # Log difference of pofe_hidro
sf.test(retornos$ret_gen_frnc)         # Log difference of gen_frnc
sf.test(retornos$ret_disp_hidro)         # Log difference of gen_frnc

# Shapiro-Wilk Test
shapiro.test(retornos$ret_pbolsa)       # Log difference of pbolsa
shapiro.test(retornos$ret_pofe_hidro)  # Log difference of pofe_hidro
shapiro.test(retornos$ret_gen_frnc)    # Log difference of gen_frnc
shapiro.test(retornos$ret_disp_hidro)    # Log difference of gen_frnc


# ADF and PP tests for log differences
# ADF Test: H0: unit root
adf.test(retornos$ret_pbolsa)        # Log difference of pbolsa
adf.test(retornos$ret_pofe_hidro)   # Log difference of pofe_hidro
adf.test(retornos$ret_gen_frnc)     # Log difference of gen_frnc
adf.test(retornos$ret_disp_hidro)     # Log difference of gen_frnc

# PP Test: H0: unit root
pp.test(retornos$ret_pbolsa)        # Log difference of pbolsa
pp.test(retornos$ret_pofe_hidro)   # Log difference of pofe_hidro
pp.test(retornos$ret_gen_frnc)     # Log difference of gen_frnc
pp.test(retornos$ret_disp_hidro)     # Log difference of gen_frnc

# ACF y PACF: Serial dependence
par(mfrow = c(2, 2))  # Configure the graphics window for multiple plots

# ACF y PACF of log differences in pbolsa
acf(retornos$ret_pbolsa, lag.max = 20, main = "ACF: Spot Price (pbolsa)")
pacf(retornos$ret_pbolsa, lag.max = 20, main = "PACF: Spot Price (pbolsa)")

# ACF y PACF of log differences in pofe_hidro
acf(retornos$ret_pofe_hidro, lag.max = 20, main = "ACF: Hydroelectric Price (pofe_hidro)")
pacf(retornos$ret_pofe_hidro, lag.max = 20, main = "PACF: Hydroelectric Price (pofe_hidro)")

# ACF y PACF of log differences in gen_frnc
acf(retornos$ret_gen_frnc, lag.max = 20, main = "ACF: NCRES Generation (gen_frnc)")
pacf(retornos$ret_gen_frnc, lag.max = 20, main = "PACF: NCRES Generation (gen_frnc)")

# ACF y PACF of log differences in gen_frnc
acf(retornos$ret_disp_hidro, lag.max = 20, main = "ACF: Hydropower Availability (disp_hidro)")
pacf(retornos$ret_disp_hidro, lag.max = 20, main = "PACF: Hydropower Availability (disp_hidro)")



################### ARIMA models ######################################
# Log difference of pbolsa
modelo_pbolsa <- auto.arima(retornos$ret_pbolsa, max.p = 21, max.q = 21, stationary = TRUE, trace = TRUE)
resid_pbolsa <- residuals(modelo_pbolsa)

pearson.test(resid_pbolsa)  # Normality test
resid2_pbolsa <- resid_pbolsa^2  # Squared residuals

ArchTest(resid_pbolsa, lag = 1)  # ARCH test
ArchTest(resid_pbolsa, lag = 2)
ArchTest(resid_pbolsa, lag = 3)
ArchTest(resid_pbolsa, lag = 4)
ArchTest(resid_pbolsa, lag = 5)
ArchTest(resid_pbolsa, lag = 167)

# GARCH specification for pbolsa
modelogarch_pbolsa <- ugarchspec(
  variance.model = list(model = "gjrGARCH", garchOrder = c(1, 1)),
  mean.model = list(armaOrder = c(1, 1), include.mean = TRUE),
  distribution.model = "norm"
)
fit_garch_pbolsa <- ugarchfit(spec = modelogarch_pbolsa, data = retornos$ret_pbolsa)
#summary(fit_garch_pbolsa)
#plot(fit_garch_pbolsa, which = 10)

# Log difference of pofe_hidro
modelo_pofe_hidro <- auto.arima(retornos$ret_pofe_hidro, max.p = 21, max.q = 21, stationary = TRUE, trace = TRUE)
resid_pofe_hidro <- residuals(modelo_pofe_hidro)

pearson.test(resid_pofe_hidro)  # Normality test
resid2_pofe_hidro <- resid_pofe_hidro^2  # Squared residuals

ArchTest(resid_pofe_hidro, lag = 1)  # ARCH test
ArchTest(resid_pofe_hidro, lag = 2)
ArchTest(resid_pofe_hidro, lag = 3)
ArchTest(resid_pofe_hidro, lag = 4)
ArchTest(resid_pofe_hidro, lag = 5)
ArchTest(resid_pofe_hidro, lag = 167)

# GARCH specification for pofe_hidro
modelogarch_pofe_hidro <- ugarchspec(
  variance.model = list(model = "gjrGARCH", garchOrder = c(1, 1)),
  mean.model = list(armaOrder = c(0, 0), include.mean = TRUE),
  distribution.model = "norm"
)
fit_garch_pofe_hidro <- ugarchfit(spec = modelogarch_pofe_hidro, data = retornos$ret_pofe_hidro)
summary(fit_garch_pofe_hidro)
plot(fit_garch_pofe_hidro, which = 10)

# Log difference of gen_frnc
modelo_gen_frnc <- auto.arima(retornos$ret_gen_frnc, max.p = 21, max.q = 21, stationary = TRUE, trace = TRUE)
resid_gen_frnc <- residuals(modelo_gen_frnc)

pearson.test(resid_gen_frnc)  # Normality test
resid2_gen_frnc <- resid_gen_frnc^2  # Squared residuals

ArchTest(resid_gen_frnc, lag = 1)  # ARCH test
ArchTest(resid_gen_frnc, lag = 2)
ArchTest(resid_gen_frnc, lag = 3)
ArchTest(resid_gen_frnc, lag = 4)
ArchTest(resid_gen_frnc, lag = 5)
ArchTest(resid_gen_frnc, lag = 167)

# GARCH specification for gen_frnc

modelogarch_gen_frnc <- ugarchspec(
  variance.model = list(model = "gjrGARCH", garchOrder = c(1, 1)),
  mean.model = list(armaOrder = c(1, 1), include.mean = TRUE),
  distribution.model = "norm"
)
fit_garch_gen_frnc <- ugarchfit(spec = modelogarch_gen_frnc, data = retornos$ret_gen_frnc)
summary(fit_garch_gen_frnc)
plot(fit_garch_gen_frnc, which = 10)


# Log difference of disp_hidro
modelo_disp_hidro <- auto.arima(retornos$ret_disp_hidro, max.p = 21, max.q = 21, stationary = TRUE, trace = TRUE)
resid_disp_hidro <- residuals(modelo_disp_hidro)

pearson.test(resid_disp_hidro)  # Normality test
resid2_gen_frnc <- resid_disp_hidro^2  # Squared residuals

ArchTest(resid_disp_hidro, lag = 1)  # ARCH test
ArchTest(resid_disp_hidro, lag = 2)
ArchTest(resid_disp_hidro, lag = 3)
ArchTest(resid_disp_hidro, lag = 4)
ArchTest(resid_disp_hidro, lag = 5)
ArchTest(resid_disp_hidro, lag = 167)

# GARCH specification for disp_hidro

modelogarch_disp_hidro <- ugarchspec(
  variance.model = list(model = "gjrGARCH", garchOrder = c(1, 1)),
  mean.model = list(armaOrder = c(1, 1), include.mean = TRUE),
  distribution.model = "norm"
)
fit_garch_disp_hidro <- ugarchfit(spec = modelogarch_disp_hidro, data = retornos$ret_disp_hidro)
summary(fit_garch_disp_hidro)
plot(fit_garch_disp_hidro, which = 10)


modelo_pbolsa
modelo_pofe_hidro
modelo_gen_frnc
modelo_disp_hidro

################### Results ######################################
# Summaries of fitted GARCH models
summary(fit_garch_pbolsa)
summary(fit_garch_pofe_hidro)
summary(fit_garch_gen_frnc)
summary(fit_garch_disp_hidro)

#########################Multivariate GARCH model####################################
#Modelo
mspec=multispec(c(modelogarch_pbolsa,modelogarch_pofe_hidro,modelogarch_gen_frnc,modelogarch_disp_hidro))
# Specify the DCC-GARCH model
dccgarchspec <- dccspec(uspec = mspec, dccOrder = c(1, 1), distribution = "mvnorm")
# Prepare multivariate data
mvdata <- cbind(retornos$ret_pbolsa, retornos$ret_pofe_hidro, retornos$ret_gen_frnc,  retornos$ret_disp_hidro)
# Fit the DCC-GARCH model
dccmodel <- dccfit(dccgarchspec, data = mvdata)
# Extract residuals
dccresiduals <- residuals(dccmodel)


# Residuals for pbolsa
residuales_pbolsa <- coredata(dccresiduals[, 1])
residdcc_pbolsa <- ts(residuales_pbolsa)

data_resid_pbolsa <- data.frame()  # Create an empty data frame
data_resid_pbolsa <- data.frame(
  Fecha = data$dates[-1],  # Dates (excluding the first observation due to differencing)
  Asset_1 = residdcc_pbolsa
)

data_resid_pbolsa$Asset_1 <- data.frame("Fecha" = data$dates[-1], residdcc_pbolsa)


ggplot(data_resid_pbolsa, aes(Fecha, residdcc_pbolsa)) +
  geom_line() +
  scale_x_date('Dates', date_breaks = "1 year") +
  ylab("Residuals ret_pbolsa") +
  theme(axis.text.x = element_text(angle = 90))

# Dynamic correlations
rcorr_pbolsa_pofe <- rcor(dccmodel)[1, 2, ]
rcorr_pbolsa_pofe_ts <- ts(rcorr_pbolsa_pofe, start = c(2018, 1), frequency = 365)
plot(rcorr_pbolsa_pofe_ts, type = 'l', main = "Dynamic Correlation: pbolsa - pofe_hidro")

rcorr_pbolsa_gen <- rcor(dccmodel)[1, 3, ]
rcorr_pbolsa_gen_ts <- ts(rcorr_pbolsa_gen, start = c(2018, 1), frequency = 365)
plot(rcorr_pbolsa_gen_ts, type = 'l', main = "Dynamic Correlation: pbolsa - gen_frnc")

rcorr_pbolsa_disp <- rcor(dccmodel)[1, 4, ]
rcorr_pbolsa_disp_ts <- ts(rcorr_pbolsa_disp, start = c(2018, 1), frequency = 365)
plot(rcorr_pbolsa_disp_ts, type = 'l', main = "Dynamic Correlation: pbolsa - disp_hidro")

rcorr_pofe_gen <- rcor(dccmodel)[2, 3, ]
rcorr_pofe_gen_ts <- ts(rcorr_pofe_gen, start = c(2018, 1), frequency = 365)
plot(rcorr_pofe_gen_ts, type = 'l', main = "Dynamic Correlation: pofe_hidro - gen_frnc")

rcorr_pofe_disp <- rcor(dccmodel)[2, 4, ]
rcorr_pofe_disp_ts <- ts(rcorr_pofe_disp, start = c(2018, 1), frequency = 365)
plot(rcorr_pofe_disp_ts, type = 'l', main = "Dynamic Correlation: pofe_hidro - disp_hidro")

rcorr_gen_disp <- rcor(dccmodel)[3, 4, ]
rcorr_gen_disp_ts <- ts(rcorr_gen_disp, start = c(2018, 1), frequency = 365)
plot(rcorr_gen_disp_ts, type = 'l', main = "Dynamic Correlation: gen_frnc - disp_hidro")

par(mfrow = c(2, 2)) 
plot(rcorr_pbolsa_pofe_ts, type = 'l', main = "Spot Price - Hydroelectric Price")
plot(rcorr_pbolsa_gen_ts, type = 'l', main = "Spot Price - NCRES Generation")
plot(rcorr_pbolsa_disp_ts, type = 'l', main = "Spot Price - Hydropower Availability")
plot(rcorr_gen_disp_ts, type = 'l', main = "NCRES Generation - Hydropower Availability")

# Q matrix (dynamic conditional correlation)
Q_pbolsa_pofe_hidro <- rcor(dccmodel, type = 'Q')[1, 2, ]
Q_pbolsa_pofe_hidro_ts <- ts(Q_pbolsa_pofe_hidro, start = c(2018, 1), frequency = 365)

Q_pbolsa_gen_frnc <- rcor(dccmodel, type = 'Q')[1, 3, ]
Q_pbolsa_gen_frnc_ts <- ts(Q_pbolsa_gen_frnc, start = c(2018, 1), frequency = 365)

Q_pbolsa_gen_disp <- rcor(dccmodel, type = 'Q')[1, 4, ]
Q_pbolsa_gen_disp_ts <- ts(Q_pbolsa_gen_disp, start = c(2018, 1), frequency = 365)

Q_pofe_hidro_gen_frnc <- rcor(dccmodel, type = 'Q')[2, 3, ]
Q_pofe_hidro_gen_frnc_ts <- ts(Q_pofe_hidro_gen_frnc, start = c(2018, 1), frequency = 365)

Q_pofe_hidro_disp <- rcor(dccmodel, type = 'Q')[2, 4, ]
Q_pofe_hidro_disp_ts <- ts(Q_pofe_hidro_disp, start = c(2018, 1), frequency = 365)

Q_gen_frnc_disp <- rcor(dccmodel, type = 'Q')[3, 4, ]
Q_gen_frnc_disp_ts <- ts(Q_gen_frnc_disp, start = c(2018, 1), frequency = 365)


#Variances

# Conditional variances
var_pbolsa <- rcov(dccmodel)[1, 1, ]
var_pbolsa_ts <- ts(var_pbolsa, start = c(2018, 1), frequency = 365)

var_pofe_hidro <- rcov(dccmodel)[2, 2, ]
var_pofe_hidro_ts <- ts(var_pofe_hidro, start = c(2018, 1), frequency = 365)

var_gen_frnc <- rcov(dccmodel)[3, 3, ]
var_gen_frnc_ts <- ts(var_gen_frnc, start = c(2018, 1), frequency = 365)

var_disp <- rcov(dccmodel)[4, 4, ]
var_disp_ts <- ts(var_disp, start = c(2018, 1), frequency = 365)

# Variance plots
par(mfrow = c(2, 2)) 
plot(var_pbolsa_ts, type = "l", main = "Spot Price")
plot(var_pofe_hidro_ts, type = "l", main = "Hydroelectric Price")
plot(var_gen_frnc_ts, type = "l", main = "NCRES Generation")
plot(var_disp_ts, type = "l", main = "Hydropower Availability")



##############################Impulse response functions############################
###############################Variances with a shock


#Check the lambda parameters here: 
dccmodel@mfit$matcoef

#These values were entered manually
#lambda1 <- dccmodel@mfit$matcoef["DCC1", "Estimate"]
#lambda2 <- dccmodel@mfit$matcoef["DCC2", "Estimate"]
# Joint parameters
lambda1 <- 2.239439e-02  # [Joint]dcca1
lambda2 <- 8.480560e-01  # [Joint]dccb1

Qt <- rcor(dccmodel, type = 'Q')[,,1672]
Rvirf <- rcor(dccmodel)[,,1672]
Qbar <- dccmodel@mfit[["Qbar"]]
H <- rcov(dccmodel)[,,1672]
stdresid_t <- dccmodel@mfit[["stdresid"]][1672,]
h_0 <- diag(H)

#omegas <- dccmodel@mfit$matcoef[grep("omega", rownames(dccmodel@mfit$matcoef)), "Estimate"]
#alphas <- dccmodel@mfit$matcoef[grep("alpha1", rownames(dccmodel@mfit$matcoef)), "Estimate"]
#betas <- dccmodel@mfit$matcoef[grep("beta1", rownames(dccmodel@mfit$matcoef)), "Estimate"]
#gammas <- dccmodel@mfit$matcoef[grep("gamma1", rownames(dccmodel@mfit$matcoef)), "Estimate"]


# Variable-specific parameters
omegas <- c(1.760698e-04, 1.284553e-05, 1.310996e-05, 1.548492e-04)  # For variables 1, 2, and 3
alphas <- c(1.110550e-01, 9.462685e-02, 9.638979e-03, 5.299352e-04)  # ARCH
betas  <- c(8.709988e-01, 9.395569e-01, 9.521968e-01, 7.123579e-01)   # GARCH
gammas <- c(3.389234e-02, -7.036743e-02, 7.432826e-02, 1.722692e-01)   # Gamma (only some variables have this parameter)

# Initialize objects for four variables
d=c(0, 0, 0, 0)
Dvirf <- sqrt(diag(diag(H)))  # Diagonal matrix of initial standard deviations
Qvirf <- matrix(c(0), nrow = 4, ncol = 4)  # Initial 4x4 Q matrix
nperiodos <- 60  # Number of simulation periods
arreglo <- array(c(0), dim = c(4, 4, nperiodos))  # Array to store results
choque <- 1.5  # Initial shock magnitude

#Simulation
for (n in 1:nperiodos) {
  if(n==1) {
    stdresid_virf=stdresid_t%*%t(stdresid_t)  
  } else {  
    if (n==2){
      stdresid_virf=matrix(c(choque),nrow=4,ncol=4)
    } else {
      stdresid_virf=matrix(c(0),nrow=4,ncol=4)
    }
  }
  
  if (n==1) {
    d=c(1,1,1,0)
  } else {
    if (n==2) {
      d=c(1,1,1,1)
    } else {
      d=c(0,0,0,0)
    }
  }
  
  for (i in 1:4) {
    for (j in 1:4) {
      if (n==1 | n==2) {
        Qvirf[i,j]=(1-lambda1-lambda2)*Qbar[i,j]+lambda1*stdresid_virf[i,j]+lambda2*Qt[i,j]
      } else {
        Qvirf[i,j]=(1-lambda1-lambda2)*Qbar[i,j]+(lambda1+lambda2)*Qt[i,j]
      }    
    }
  }
  Rvirf=Qvirf
  Rvirf[1,1]=Rvirf[2,2]=Rvirf[3,3]=Rvirf[4,4]=1
  
  if (n==1 | n==2) {
    h_virf=omegas+alphas*diag(stdresid_virf)*h_0+betas*h_0+gammas*d*diag(stdresid_virf)*h_0  
  } else {
    h_virf=omegas+(alphas+betas)*h_0 
  }
  
  Dvirf=diag(sqrt(h_virf))
  Hvirf=Dvirf%*%Rvirf%*%Dvirf
  
  h_0=h_virf
  Qt=Qvirf
  arreglo[ , ,n]=Hvirf
}


hvar1c <- arreglo[1, 1, ]  # Conditional variance for the first variable
hvar2c <- arreglo[2, 2, ]  # Conditional variance for the second variable
hvar3c <- arreglo[3, 3, ]  # Conditional variance for the third variable
hvar4c <- arreglo[4, 4, ]  # Conditional variance for the third variable

##################################Variances without a shock
# Coefficients manually specified from the output of dccmodel@mfit$matcoef

##################################Variances without a shock
lambda1 <- 2.239439e-02  # [Joint]dcca1
lambda2 <- 8.480560e-01  # [Joint]dccb1

Qt <- rcor(dccmodel, type = 'Q')[,,1672]
Rvirf <- rcor(dccmodel)[,,1672]
Qbar <- dccmodel@mfit[["Qbar"]]
H <- rcov(dccmodel)[,,1672]
stdresid_t <- dccmodel@mfit[["stdresid"]][1672,]
h_0 <- diag(H)

# Variable-specific parameters
omegas <- c(1.760698e-04, 1.284553e-05, 1.310996e-05, 1.548492e-04)  # For variables 1, 2, and 3
alphas <- c(1.110550e-01, 9.462685e-02, 9.638979e-03, 5.299352e-04)  # ARCH
betas  <- c(8.709988e-01, 9.395569e-01, 9.521968e-01, 7.123579e-01)   # GARCH
gammas <- c(3.389234e-02, -7.036743e-02, 7.432826e-02, 1.722692e-01)   # Gamma (only some variables have this parameter)

# Initialize objects for four variables
d=c(0, 0, 0, 0)
Dvirf <- sqrt(diag(diag(H)))  # Diagonal matrix of initial standard deviations
Qvirf <- matrix(c(0), nrow = 4, ncol = 4)  # Initial 4x4 Q matrix
arreglo0=array(c(0),dim = c(4,4,nperiodos))

for (n in 1:nperiodos) {
  if(n==1) {
    stdresid_virf=stdresid_t%*%t(stdresid_t)  
  } else {  
    stdresid_virf=matrix(c(0),nrow=4,ncol=4)
  }
  
  if (n==1) {
    d=c(1,1,1,0)
  } else {
    d=c(0,0,0,0)
  }
  
  for (i in 1:4) {
    for (j in 1:4) {
      if (n==1) {
        Qvirf[i,j]=(1-lambda1-lambda2)*Qbar[i,j]+lambda1*stdresid_virf[i,j]+lambda2*Qt[i,j]
      } else {
        Qvirf[i,j]=(1-lambda1-lambda2)*Qbar[i,j]+(lambda1+lambda2)*Qt[i,j]
      } 
    }
  }
  
  
  if (n==1) {
    h_virf=omegas+alphas*diag(stdresid_virf)*h_0+betas*h_0+gammas*d*diag(stdresid_virf)*h_0  
  } else {
    h_virf=omegas+(alphas+betas)*h_0 
  }
  
  Rvirf=Qvirf
  Rvirf[1,1]=Rvirf[2,2]=Rvirf[3,3]=Rvirf[4,4]=1
  Dvirf=diag(sqrt(h_virf))
  Hvirf=Dvirf%*%Rvirf%*%Dvirf
  
  h_0=h_virf
  Qt=Qvirf
  arreglo0[ , ,n]=Hvirf
}

# Extract simulated variances for each variable
hvar1 <- arreglo0[1, 1, ]  # Variance for the first variable
hvar2 <- arreglo0[2, 2, ]  # Variance for the second variable
hvar3 <- arreglo0[3, 3, ]  # Variance for the third variable
hvar4 <- arreglo0[4, 4, ]  # Variance for the fourth variable


# Calculate adjusted impulse responses for four variables
virfvar1 <- (hvar1c - hvar1) / hvar1  # Impulse response for the first variable
virfvar2 <- (hvar2c - hvar2) / hvar2  # Impulse response for the second variable
virfvar3 <- (hvar3c - hvar3) / hvar3  # Impulse response for the third variable
virfvar4 <- (hvar4c - hvar4) / hvar4  # Impulse response for the fourth variable

# Plot results for each variable
par(mfrow = c(2, 2))
plot(virfvar1, type = 'l', xlab = "Time horizon", ylab = "pbolsa", main = "IRF: Spot Price")
plot(virfvar2, type = 'l', xlab = "Time horizon", ylab = "pofe_hidro", main = "IRF: Hydroelectric Price")
plot(virfvar3, type = 'l', xlab = "Time horizon", ylab = "gen_frnc", main = "IRF: NCRES Generation")
plot(virfvar4, type = 'l', xlab = "Time horizon", ylab = "disp_hidro", main = "IRF: Hydropower Availability")

