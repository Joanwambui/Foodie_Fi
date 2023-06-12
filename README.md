# Foodie_Fi
Analysis of Foodie-Fi’s subscription style digital data and study of key business metrics on customer journey, payments, and business performances using SQL.
Danny and his friends launched a new startup Foodie-Fi 🥑 and started selling monthly and annual subscriptions, giving their customers unlimited on-demand access to exclusive food videos from around the world.

This case study focuses on using subscription style digital data to answer important business questions on customer journey, payments, and business performances.
There two tables in the database: 
Table 1: plans

There are 5 customer plans.
Trial— Customer sign up to an initial 7 day free trial and will automatically continue with the pro monthly subscription plan unless they cancel, downgrade to basic or upgrade to an annual pro plan at any point during the trial.
Basic plan — Customers have limited access and can only stream their videos and is only available monthly at $9.90.
Pro plan — Customers have no watch time limits and are able to download videos for offline viewing. Pro plans start at $19.90 a month or $199 for an annual subscription.

Table 2: subscriptions

Customer subscriptions show the exact date where their specific plan_id starts.

If customers downgrade from a pro plan or cancel their subscription — the higher plan will remain in place until the period is over — the start_date in the subscriptionstable will reflect the date that the actual plan changes.

When customers upgrade their account from a basic plan to a pro or annual pro plan — the higher plan will take effect straightaway.

When customers churn — they will keep their access until the end of their current billing period, but the start_date will be technically the day they decided to cancel their service.
