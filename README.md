SolidusKlarna
=============

[![CircleCI](https://circleci.com/gh/hefan/solidus_klarna.svg?style=svg)](https://circleci.com/gh/hefan/solidus_klarna)

Extends Solidus for supporting Payments via Klarna Direct Bank Transfer. An appropriate Merchant Account is required to use it.

See also https://integration.sofort.com/integrationCenter-eng-DE/content/view/full/2513/


Installation
------------

Add solidus_klarna to your Gemfile:

```ruby
gem 'solidus_klarna', github: 'hefan/solidus_klarna'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g solidus_klarna:install
```

Setup
-----

Navigate to Solidus Backend/Settings/Payments and add a new payment method with Provider "Spree::PaymentMethod::Klarna".
Enter the Configuration key from your klarna merchant account. It should have the form
USER_ID:PROJECT_ID:API_KEY

The default server url should work.
You may use a reference prefix and/or suffix if you like to add something before or after the order number used as reference for klarna.

Turn on the test mode in your Klarna merchant backend to do testing.
Solidus Settings->Stores->Site URL needs to be a valid Url for using Klarna Transactions.

Klarna does only support Euro currency.


License
-------
released under the New BSD License
