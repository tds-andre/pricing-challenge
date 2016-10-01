###################################################################################################
library(RMySQL)
library(vars)
library(forecast)
db = dbConnect(MySQL(), user='root', password='root', dbname='b2w2', host='localhost')
###################################################################################################
# BOXES & HISTOGRAMS

sales = fetch(dbSendQuery(db, "select * from sales"),n=-1)

prices = list()
prods = sort(unique(sales$product))
i = 1

par(mfrow=c(3,3))
for(product in prods){
  prices[[i]] = sales[sales$product==product,5:5]  
  hist(prices[[i]], main=product, freq=FALSE)
  i = i + 1
}  

par(mfrow=c(1,1))
boxplot(prices)

###################################################################################################
# SCATTERS

daily = fetch(dbSendQuery(db, "select product,volume,price from daily_summary"),n=-1)

par(mfrow=c(3,3))
for(product in prods){
  sub = daily[daily$product==product,2:3]
  plot(sub$volume,sub$price,main=product, sub=NULL, xlab=NULL, ylab=NULL)
  lm = lm(sub$volume~sub$price)
  abline(lm, col="red")
}
###################################################################################################
# ACFs & CCFs

par(mfrow=c(1,1))

prices  = fetch(dbSendQuery(db, "select * from sales_and_prices where product = 'P2' and competitor = 'C1' order by price_at"),n=-1)
prices2  = fetch(dbSendQuery(db, "select min(min_price) as min, avg(avg_price) as avg, max(max_price) as max, my_base_price, volume from sales_and_prices where product = 'P2' group by price_at order by price_at"),n=-1)
volumes = fetch(dbSendQuery(db, "select * from daily_summary where product = 'P2'"),n=-1)

ccf(prices$volume, prices$avg_price, main ='Volume x C1 Price Cross Correlation')
ccf(prices$volume, prices$my_base_price, main ='Volume xPrice Cross Correlation')
acf(prices$volume, main='Volume Autocorrelation', lag = 100)
acf(prices$my_base_price, main='Price Autocorrelation', lag = 100)

plot(prices$my_base_price, prices$min_price)
plot(prices$my_base_price, prices$avg_price)
plot(prices$my_base_price, prices$max_price)

plot(prices2$my_base_price, prices2$min)
plot(prices2$my_base_price, prices2$max)
plot(prices2$my_base_price, prices2$avg)

plot(prices2$min, prices$volume)
plot(prices2$volume, prices2$max)
plot(prices2$volume, prices2$avg)
