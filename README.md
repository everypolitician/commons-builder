# Commons::Builder

[![Build Status](https://travis-ci.org/everypolitician/commons-builder.svg?branch=master)](https://travis-ci.org/everypolitician/commons-builder) [![codecov](https://codecov.io/gh/everypolitician/commons-builder/branch/master/graph/badge.svg)](https://codecov.io/gh/everypolitician/commons-builder)

This gem contains the build scripts for Democratic Commons repositories.

## Installation

Add this line to your Democratic Commons repository's Gemfile:

```ruby
gem 'commons-builder'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install commons-builder

## Usage

### Starting a new Democratic Commons repository

In an empty repository, create `config.json` a bit like this one:

```json
{
  "languages": [
    "it",
    "en"
  ],
  "country_wikidata_id": "Q38"
}
```

If you have additional administrative areas for which you want to include
legislatures and executives, then add a `additional_admin_area_ids` key:

```json
{
  "languages": [
    "it",
    "en"
  ],
  "country_wikidata_id": "Q38",
  "additional_admin_area_ids: [
    "Q1234",
    "Q1235"
  ]
}
```

If the regional administrative admin areas you want aren't FLACSen, use
`regional_admin_area_type_id` to specify the Wikidata ID of the superclass you
want to use.

Create the directory structure and `index.json` files in each, each containing
an empty array to be populated later:

```bash
mkdir -p boundaries executive legislative
for d in boundaries executive legislative ; do
    if [ ! -e $d/index.json ] ; then
        echo -e "[\n\n]" > $d/index.json
    fi
done
```


### Creating or refreshing the branch indexes

In the Democratic Commons repository you should run:

    $ bundle exec generate_legislative_index | tee legislative/index-warnings.txt
    $ bundle exec generate_executive_index | tee executive/index-warnings.txt

Caveats:

* There's sometimes a disconnect between cities and the administrative areas
  covered by their mayors. For example, the Mayor of London is associated with
  Greater London, so won't be picked up to be automatically included in
  `executive/index.json`, but the entry can still be maintained by hand. As a
  workaround, you could explicitly add the appropriate admin areas as explained
  above.

TODO: Explain `boundaries/index.json`


### Refreshing data from Wikidata

In the Democratic Commons repository you should run:

    $ bundle exec build update
    $ bundle exec build build | tee build_output.txt

... to build the output files.

You ought to commit changes after each of these commands separately.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/everypolitician/commons-builder. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Commons::Builder project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/everypolitician/commons-builder/blob/master/CODE_OF_CONDUCT.md).
