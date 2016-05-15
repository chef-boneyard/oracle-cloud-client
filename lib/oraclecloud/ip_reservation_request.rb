#
# Author:: Chef Partner Engineering (<partnereng@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module OracleCloud
  class IpReservationRequest
  attr_reader :client, :opts, :name, :parentpool, :permanent, :size, :bootable
    
  def initialize(client, opts)
    @client    = client
    @opts      = opts

    @name      = opts[:name]
    @parentpool = opts[:parentpool]
    @permanent  =  opts[:permanent] 
  end


   def delete(path)
    client.http_delete(path)
  end

  def validate_options!
    raise ArgumentError, "The following required options are missing: #{missing_required_options.join(', ')}" unless
      missing_required_options.empty?

    raise ArgumentError, "#{shape} is not a valid shape" unless client.shapes.exist?(shape)
    raise ArgumentError, "#{imagelist} is not a valid imagelist" unless client.imagelists.exist?(imagelist)
    raise ArgumentError, 'sshkeys must be an array of key names' unless sshkeys.respond_to?(:each)
  end

  def missing_required_options
    [ :name, :shape, :imagelist ].each_with_object([]) do |opt, memo|
      memo << opt unless opts[opt]
    end
  end

  def full_name
    "#{client.full_identity_domain}/#{client.username}/#{name}"
  end


  def asjson
    to_h.delete_if { |key, value| value.nil? }.to_json
  end


  def to_h
    {
      'name'       => name,
      'parentpool'    => parentpool,
      'permanent' => permanent
    }
  end


  def post
    path=''
    path.concat("ip/reservation/")
    OracleCloud::IPReservation.new(client.http_post(path,asjson))
  end


  def put(name)
    path=''
    path.concat("ip/reservation"+name)
    OracleCloud::IPReservation.new(client.http_put(path,asjson))
  end


  def get(path)
    OracleCloud::IPReservation.new(client.http_get(:single,path))
  end

  def delete(path)
    client.http_delete(path)
  end

  end
end
