# Oracle Cloud API Client

`oracle-cloud` is a RubyGem for interacting with the Oracle Cloud REST API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'oraclecloud'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install oraclecloud

## Usage

First, load in the gem.

```ruby
require 'oraclecloud'
=> true
```

Then, set up your client object.

```ruby
client = OracleCloud::Client.new(username: 'user@domain.io', password: 'supersecret', identity_domain: 'mydomain', api_url: 'https://some-api-endpoint.compute.us6.oraclecloud.com')
=> #<OracleCloud::Client:0x000000034c0df8 ... >
```

### Instances

To list all instances:

```ruby
client.instances.all
=> [#<OracleCloud::Instance:0x007fd6e4080710
  @asset_data=
...
```

Once you have an instance, you can get additional information about it:

```ruby

instance.hostname
=> "c799e7.compute-mydomain.oraclecloud.internal."

instance.ip_address
=> "10.1.1.1"

instance.public_ip_addresses
=> ["1.2.3.4"]

instance.shape
=> "oc1m"

instance.state
=> "running"

instance.vcable_id
=> "/Compute-mydomain/user@domain.io/7a46361a-4e69-41ec-bf4f-84d22a2eeab0"

instance.image
=> "/oracle/public/oel_6.6_20GB_x11_RD"
```

### Creating Instances

To create an instance, you must create an orchestration which controls that instance.  An orchestration can start multiple instances.

First, build an instance request for each instance you wish to start:

```ruby
instance1 = client.instance_request(shape: 'oc1m', imagelist: '/oracle/public/oel_6.6_20GB_x11_RD', name: 'test1', sshkeys: ["/path/to/sshkey"], public_ip: :pool)
=> #<OracleCloud::InstanceRequest:0x007fdf0d286880 ...>
```

See the Shapes and Imagelists sections for help on determining your shape and imagelist options.

Then, build an orchestration:

```ruby
orchestration = client.orchestrations.create(name: 'test1', description: 'my first orchestration', instances: [ instance1 ])
=> #<OracleCloud::Orchestration:0x007fdf0a342880
```

You will see that the orchestration is not yet started, so go ahead and start it!

```ruby
o.status
=> "stopped"

o.start
=> {"relationships"=>[],
 "status"=>"starting",
...
```

You can refresh the orchestration status.  Once it's started, your instances should be available.

```ruby
orchestration.refresh && orchestration.status
=> "starting"

orchestration.refresh && orchestration.status
=> "ready"

instance = orchestration.instances.first
=> #<OracleCloud::Instance:0x007fff0b478aa8 ...>

instance.state
=> "running"

instance.public_ip_addresses
=> ["1.2.3.4"]
```

### Shapes

You can list all available shapes using the `client.shapes.all` method:

```ruby
client.shapes.all
=> [#<OracleCloud::Shape:0x007f823b9cb5e8
  @shape_data=
   {"nds_iops_limit"=>0,
    "ram"=>122880,
    "cpus"=>16.0,
    "uri"=>"https://some-api-endpoint.compute.us6.oraclecloud.com/shape/oc4m",
    "io"=>800,
    "name"=>"oc4m"}>,
 #<OracleCloud::Shape:0x007f823b9cb5c0
  @shape_data=
   {"nds_iops_limit"=>0,
    "ram"=>122880,
    "cpus"=>32.0,
    "uri"=>"https://some-api-endpoint.compute.us6.oraclecloud.com/shape/oc7",
    "io"=>1000,
    "name"=>"oc7"}>,
...
```

This returns an array of OracleCloud::Shape objects which you can interrogate as needed:

```ruby
client.shapes.all.map { |shape| shape.name }.sort
=> ["oc1m", "oc2m", "oc3", "oc3m", "oc4", "oc4m", "oc5", "oc5m", "oc6", "oc7"]
```

### Imagelists

You can list all available imagelists using the `client.imagelists.all` method:

```ruby
client.imagelists.all
=> [#<OracleCloud::ImageList:0x007f823ed69b48
  @imagelist_data=
   {"default"=>1,
    "description"=>"\"OEL 6.4 20 GB image\"",
    "entries"=>
     [{"attributes"=>{},
       "version"=>1,
       "machineimages"=>["/oracle/public/oel_6.4_20GB_x11_RD"],
       "uri"=>
...
```

This returns an array of OracleCloud::ImageList objects which you can interrogateas needed:

```ruby
client.imagelists.all.map { |imagelist| imagelist.name }.sort
=> ["/oracle/public/oel_6.4_20GB_x11_RD", "/oracle/public/oel_6.4_5GB_RD", "/oracle/public/oel_6.6_20GB_x11_RD"]
```

## License and Authors

Author:: Chef Partner Engineering (<partnereng@chef.io>)

Copyright:: Copyright (c) 2015 Chef Software, Inc.

License:: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the License at

```
http://www.apache.org/licenses/LICENSE-2.0
```

Unless required by applicable law or agreed to in writing, software distributed under the
License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied. See the License for the specific language governing permissions
and limitations under the License.

## Contributing

1. Fork it ( https://github.com/chef-partners/oracle-cloud-client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
