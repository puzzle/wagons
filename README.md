# Here Be Wagons

[![Build Status](https://github.com/codez/wagons/actions/workflows/build.yml/badge.svg)](https://github.com/codez/wagons/actions/workflows/build.yml)
[![Code Climate](https://api.codeclimate.com/v1/badges/32a0d860544681cf718c/maintainability)](https://codeclimate.com/github/codez/wagons/maintainability)

Wagons are extensions to your application train running on Rails. You can see them as plugins that
extend the behavior of your specific Rails application. This framework makes it easy to create and
manage them.

First of all, wagons are basically [Rails Engines](http://api.rubyonrails.org/classes/Rails/Engine.html),
so make sure you are familiar with them. Wagons provide a handful of additions so your wagon
engines actually know your application.

Wagons differ from engines in a few points:

- Wagons extend your application, engines extend Rails.
- Wagon migrations are kept separately from your application's migrations to enable easy addition and removal of wagons.
- When developing and testing, wagons use the main application instead of a dummy application.

## Setup

As always, add this declaration to your application's Gemfile:

    gem 'wagons'

Now you are ready for your first wagon. Generate it with

    rails generate wagon [name]

This creates the structure of your wagon in `vendor/wagons/[name]`. In there, you find the file `lib/[name]/wagon.rb`,
which defines the `Rails::Engine` and includes the `Wagon` module. Here, you may also extend your application
classes in a `config.to_prepare` block.

In order to load wagons with the application, an entry in the `Gemfile` would be sufficient.
To keep things flexible, wagons come with an additional file `Wagonfile`. Generate one for development purposes with:

    rake wagon:file

This will include all wagons found in `vendor/wagons` in development mode.
Do not check `Wagonfile` into source control. In your deployments, you might want to have different entries in there.

Once your wagon is ready to ship, a gem can be built with `rake build`. The name of a wagon gem must always start
with the application name, followed with an underscore and the actual name of the wagon. In production, you may
simply install the wagon gem and explicitly add a declaration to your `Wagonfile`.

If your wagon contains migrations and probably seed data, update your database with

    rake wagon:setup WAGON=[name]

Leave off the `WAGON` parameter to setup all wagons in your `Wagonfile`. This should not interfere with wagons that are
already set up. Migrations are only run if they are not loaded yet, as usual.

## Extending your application with a wagon

Ruby and Rails provide all the magic required to extend your application from within a wagon.

To add new models, controllers or views, simply create them in the `app` directory of your wagon, as you would in a regular engine.

To extend existing models and controllers, you may create modules with the required functionality.
Include them into your application classes in a `config.to_prepare` block in `lib/[wagon_name]/wagon.rb`.

To extend views, wagons provides a simple view helper that looks for partials in all view paths. Any template that
might be extended by a wagon can include a call like this:

    <%= render_extensions :details %>

Any partials living in an equally named subfolder as the calling template and starting with the given key are rendered at this place.

## Wagon dependencies

Wagons may depend on each other and/or have certain requirements on their load order. To make sure something
is loaded before the current wagon, add a `require '[app_name]_[other_wagon]'` on top of the
`lib/[app_name]_[current_wagon].rb` file. For development dependencies, there is an extra `require_optional`
method that will not raise a `LoadError` if the dependency is not found.

To control that the main application actually supports a certain wagon, an application version may be defined
so wagons can define a requirement. The application version can be set in an initializer. Create it with:

    rake wagon:app_version

Besides setting the version, this initializer will check all loaded wagons for their application requirement
and raise errors if one is not met. In `lib/[wagon_name]/wagon.rb` the requirement may be defined, e.g.:

    app_requirement '>= 1.0'

The syntax follows the Ruby gem version and requirements.

## Seed Data

Wagons integrates [Seed Fu](https://github.com/mbleigh/seed-fu) for seed data. All seed data from the application
is also available in wagon tests, as long as no fixture files overwrite the corresponding tables.

Wagons may come with their own seed data as well. Simply put it into `db/fixtures[/environment]`. To allow for
an automatic removal of wagons, [Seed Fu-ndo](https://github.com/codez/seed-fu-ndo) is able to record
seed file instructions and destroy all entries that exist in the database. Just make sure that you only use
the `seed` and `seed_once` methods in these files, or the unseed may not work correctly.

## Beware

There are a few other things that work differently with wagons:

### Schema & Migrations

Wagons are extensions to your application that may vary between various installations. Wagon tables are added
and removed as wagons are installed or uninstalled. After you have added a wagon's gem to your production
`Wagonfile`, run `rake wagon:setup` to run the migrations and load the seed data. Before you remove them
from `Wagonfile`, run `rake wagon:remove WAGON=to_remove` to eliminate the artifacts from the database first.

In this way, the `schema.rb` file must only contain the tables of the application, not of all wagons.
When you have migrations for your main application and wagons loaded, the schema will not be dumped on
`db:migrate`. You need to either remove the wagons or reset the database before the schema may be dumped.
This is (currently) the cost for having arbitrary pluggable application extensions.

### Tests

Wagons use your application for tests. This is also true for your application's test database. To get the
correct setup, `app:db:test:prepare` is extended to run the migration of the current wagon and all its
dependencies, as well as their seed data. Once the database is set up, single tests may be run with
the usual `ruby -I test test/my_test.rb` command.

The `test_helper.rb` of the main application is included in all wagon tests. Any additions in
this file are available in wagon tests as well. The only thing wagons need to do is reseting the
fixture path to the wagon's test fixtures.

RSpec works fine with wagons as well. Simply put the heading lines found in `test_helper.rb` into your
`spec_helper.rb`.

### Gem Bundling

Bundler manages application dependencies, with a stress on application. Because wagons live
inside your application during development, the app's `Gemfile` is included in each wagon's `Gemfile`.
However, Bundler still keeps a separate `Gemfile.lock` for each wagon, so you have to make sure to keep
these up to date when you change your main application gems. The gem versions for the wagons should be
the same as for the application. `rake wagon:bundle:update` is here to help you exactly with that.
We recommend to NOT check in the Wagon's `Gemfile.lock` file into source control.

Unfortunately, adding wagon gems to the `Wagonfile` in production also breaks with Bundler's approach
of locking down application gems. Because of that, the `--deployment` option cannot be used
with wagons. If you install your gems from `vendor/cache` into `vendor/bundle` or so,
you still get most of the benefits of using Bundler, including the guarantee for the very same gem
versions as used in development.

Contributions to this or any other issues are very welcome.
