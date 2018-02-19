# Planner
Plan which meeting room to take

## Installation

* Clone this repository

* And then execute:

    `$ bundle`

* Run `rspec`

## Usage

Run `./bin/demo` to get a preview of the response from library.

You can create rooms and meetings in the console.
```
room_a = Room.new('Prenzlauer Berg')
room_b = Room.new('Schonhauser Allee')
rooms = [ room_a, room_b ]
```

Schedule meetings with:

`Scheduler.schedule(rooms, Meeting.new('All Hands meeting', 60))`

Check them out with:

`room_a.meetings`


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/adware.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
