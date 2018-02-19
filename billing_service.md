# Components

### Core App
Deals with users and their payment options and plans. Delegates payment related requests to the Payment service.

### Payment Service
The service accepts payment requests through an HTTP API and notifies the core App about payment events(success, failure, renewal, etc) with the help of callbacks. It also hosts a database that contains information about start/end of payment, amount paid, etc. This makes it possible to query for payments from a user. Additionally, it runs a scheduler under the hood to deal with renewals.

### External Payment Providers
The Payment service calls external payment providers on behalf of the main app. These providers are possibly accessed through a gem like Stripe or Braintree and given callbacks of the Payment service.

### Billing app/module
 The billing system can be built either into the main app or as a separate app. It can query the payment service for a list of payments and the main app for User specific information.

### Coupon Code Database
A Redis based database that manages a list of valid coupon codes and expires them accordingly.


# Core App

The following data structures depict tables in the database of the Core App

#### Plans

| plan_type | price | currency |
| ------ | ------ | ------ |
| weekly | 20 | euro |
| yearly | 200 | USD |

#### Payment Options

Details are specific to payment options and are stored as a JSON blob serialized in a way that is simple to send to the API.

| type | details |
| ------ | ------ |
| credit_card | {number: xxx, pin: xxx} |
| paypal | {account_id: xxx, token: xxx} |


#### Subscription

| status | plan_id | user_id | created_at |
| ------ | ------ | ------ | ------ |
| requested/revoked/active/rejected | 20 | 1 | timestamp |


A wrapper over this model encapsulates its interactions with the Payments Service API. After the coupon codes have been applied, it builds a request and passes it on to the payment service. The API request looks like:

```
HEADER: token: xxx
BODY
{
  subscription_id: 1
  callback_url: 'http://core-app/api/1/update_subscription'
  duration:
    - '1m'
    - '1y'
    - '1w'
  request_type:
    :request
    :revoke
    :expire
  payment_provider:
    :paypal
    :sepa
  payment_options: {}
  amount: 20
  currency: 'euros'
}
```


# Payment Service

The Payments Service interacts with specific providers and handles callbacks that come from external payment providers. Depending on whether the payment is successful or rejected, it makes a callback to the Core App. The Core app can make requests for revoking and removing payments as well.

It also runs a scheduler for checking if a payment has expired. It has a database that consists of a Payment model which looks like

| status | subscription_id | begins_at | expires_at | amount | provider | callback_url |
| ------ | ------ | ------ | ------ | ------ | ------ | ------- |
| processing | 1 | timestamp | timestamp | 20 | paypal | http://callbak/1 |


The `subscription_id` references Subscription in the Core App

Providers can be
```
:paypal
:sepa
:credit card
```

Statuses can be
```
:processing
:active
:rejected
:expired
```

We can leverage the flexibility to handle some corner cases as well. For example, if a user with an active subscription changes his payment method or his payment plan,  we can make a request to the Payment Service to expire the current payment and create a new one. We can have the control about which service handles dealing with expirations and renewing subscriptions. We can either program the Payment service to make a request to the external payment gateway as soon as the timer expires or we can ask it to make a callback to our core app  after which the main app can decide what to do.

The payment service makes requests to the callback URL of the core app with a JSON that looks like

```
{
  subscription_id: 1,
  status: [:ok, :error],
  errros: [{}]
}
```

It also has an API that can list all the payment requests for a given subscription


```
GET /payment-service/payments/1

[
  {
    subscription_id: 1,
    amount: 0,
    status: :rejected,
    begins_at: 2018-02-20,
    expires_at: 2018-03-21,
  },
  {
    subscription_id: 2,
    amount: 200,
    status: :active,
    begins_at: 2018-02-20,
    expires_at: 2018-03-21,
  }
]
```

## Use Cases

##### User activates a monthly plan of 20 euros.
  - The core app makes a request to the Payment API.
  - The Payment service creates a record in its database with the callback url of the core app
  - The service makes a request to the third party provider with payment options.
  - External Service Providers run a callback to the Payment service.
  - The Payment service changes the status of the Payment record in the database. If the payment is rejected, it changes the amount to zero.
  - The Payment API makes a callback request to the Core App with the status of the payment.
  - The Core App receives the callback and updates its state accordingly.


##### The Payment is revoked by the user

   - The core app makes a new request to the Payment API with `{ request_type: :revoked }`
   - The Payment service makes a request to external payment provider
   - As soon as it receives a confirmation, it changes its status to expired and the amount to 0.
   - It makes a callback to the Core App notifying the change.

##### User's monthly subscription has just expired.
 - The Payment service scheduler  detects if any Payment record is due to expire looking at the expires_at field.
- As soon as any Payment record expires, it can either try to renew the subscription itself or make a callback to the Core App.
- If a payment is to be renewed, a new payment record is created and the state of the old one is listed as expired.

##### User changes his payment method.
- The Core App makes two requests to the Payment API. The first one is to expire the current payment record and the other one to create a new one. If a payment is expired, the scheduler never operates on it.


## Billing System

The basic idea is to leverage this Payment service for billing calculations. The payment service contains details about each transaction. It holds the amount, start and end date and status for each record. Whether we decide to build the billing into core or outside it, we can get the user information and subscription from core app and individual payment details from the payment app.

With the id of each subscription, the billing app/module can make a request to the payment service

`https://payment-service/api/subscription_ids?=[1,2,3]`

The Payment service is going to return a JSON with details about payments from corresponding subscriptions. If you remember, it looks like
```
[{
    subscription_id: 1,
    amount: 0,
    status: :rejected,
    begins_at: 2018-02-20.19.20,
    expires_at: 2018-03-21.19.20,
  },
  ...
]
```
We can leverage this information to prepare a simple invoice , that looks like:

| from | to | amount | Paid with | Status |
| ------ | ------ | ------ | ------ | ------ |
| 2018-02-30 | 2018-03-30  | 100 $ | Paypal | --- |
| 2018-02-30 | 2018-03-30  | 0 $ | SEPA | Rejected |

We can also perform additional calculations if necessary.


## After Thoughts

The model presented above is conceptually designed to separate responsibilities. Because a core app usually needs to only deal with creating/revoking subscription and checking if the subscription is active, getting the payment related stuff out of the core could be a good idea for long term maintainence.

However, for a simple app with limited use cases, it might even be too much to delve into a separate service that operates via callbacks. The model also comes with the additional hassle of making sure that the data always reaches back to the callback endpoints which could be hard to guarantee without properly monitored infrastructure.
