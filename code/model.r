###################################################################################################
library(RMySQL)
library(vars)
library(forecast)
db = dbConnect(MySQL(), user='root', password='root', dbname='b2w2', host='localhost')
###################################################################################################

# CLUSTERING
volumes  = fetch(dbSendQuery(db, "select * from m1_tocluster order by date"),n=-1)[,2:10]
scaled = scale(volumes)
par(mfrow=c(1,1))
wcss = list()
for (i in 1:15) 
  wcss[[i]] = sum(kmeans(scaled, centers=i)$withinss)
plot(1:15, wcss, type="b", xlab="Number of Clusters", ylab="Within groups sum of squares")
km = kmeans(p2$volume, centers=6)
plot(volumes$p7_volume, volumes$p2_volume)
ccf(volumes$p2_volume, volumes$p2_volume)

# REGRESSION
p2  = fetch(dbSendQuery(db, "select * from m1 where product = 'P2' and summary_day in (select date from m1_tocluster) order by summary_day"),n=-1)
p2$day_of_week = factor(p2$day_of_week)
p2$is_weekend = factor(p2$is_weekend)
p2$month = factor(p2$month)
p2$is_parent_holiday = factor(p2$is_parent_holiday)
p2 = data.frame(p2, cluster = factor(km$cluster))
p2lm = lm(p2$volume~p2$price + p2$cluster + p2$comp_min_price + p2$volume_lag1)# + p2$comp_min_price + p2$volume_lag1 + p2$volume_lag2 + p2$volume_lag3 + p2$volume_lag4 + p2$price_lag1 + p2$price_lag2 + p2$price_lag3 + p2$price_lag4 + p2$price_lag5 + p2$volume_lag5)
p2r= data.frame(p2 , fitted = fitted (p2lm) , residual = resid(p2lm))

# EVALUATION
mae = mean(abs(p2r$residual))
m = mean(p2r$volume)
mae
mae/m

hist(p2r$residual)
summary(p2r$residual)

p2nm = rwf(p2$volume)
p2mm = meanf(p2$volume)
accuracy(p2mm)
accuracy(p2nm)
accuracy(p2lm)

write.table(p2r, file = "p2r.csv", sep = ";", row.names = FALSE)