![Railspress](https://truesoft.ro/railspress/railspress-logo.png)

> Shows WordPress posts in a Ruby on Rails application.

Ever wanted to have a CMS using Ruby on Rails? With Railspress you can have of all 
advantages of WordPress editing pages and posts, but you can display them in a Rails 
layout.

## Features

- Displays the pages, posts and menus from a WordPress site using the rails layouts
- Works for multi-language sites also
- Configure additional options using the same WordPress table
- 4 custom shortcodes:
  - `ts_revisions` - shows the page revisions for website visitors
  - `ts_childpages` - displays links of the child pages into the parent page
  - `ts_customposts` - displays links of the custom post types into a page
  - `ts_fileexplorer` - displays a directory with its files and direct subdirectories
- set a prefix for all articles e.g. `config.posts_permalink_prefix = 'news'`

## Usage
How to use the engine

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'railspress'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install railspress
```

In database.yml add an entry with the table prefix used in WordPress:

```
  prefix: wp
```

Add an initializer

### Dependencies

```ruby
gem 'shortcode'
gem 'will_paginate', '~> 3.1.1'
```

## Contributing

Contribution directions go here.

## Sponsors

Support this project:

[![PayPal](https://www.paypalobjects.com/webstatic/en_US/i/buttons/pp-acceptance-medium.png)](https://paypal.me/ibogdank/10eur)

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
