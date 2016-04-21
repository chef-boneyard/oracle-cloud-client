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
  class StorageVolumeRequest
    attr_reader :client, :opts, :name, :properties, :imagelist, :size, :bootable , :size
    def initialize(client, opts)
      @client    = client
      @opts      = opts

      @name      = opts[:name]
      @size     =  opts[:size]
      @properties = '/oracle/public/storage/default'
      @imagelist = opts[:imagelist]
      @imagelist ? @bootable = true : @bootable = false  
    end

    def local_init
      @asset_type = 'storage/volume'
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

    def nat
      return unless public_ip
      (public_ip == :pool) ? 'ippool:/oracle/public/ippool' : "ipreservation:#{public_ip}"
    end

    def networking
      networking = {}
      networking['eth0'] = {}
      networking['eth0']['nat'] = nat unless nat.nil?

      networking
    end

    def asjson
      storage_input_map = to_h
      storage_input_map.delete('imagelist') if storage_input_map['imagelist']==nil || storage_input_map['imagelist'].empty?
      storage_input_map.to_json
    end

    def delete(path)
      client.http_delete(path)
    end


    def properties_as_array
       {
        'properties'=> [@properties]
      }
    end

    def to_h
      {
        'name'       => name,
        'size'      => size,
        'properties'    => [@properties],
        'bootable' => bootable,
        'imagelist'  => imagelist
      }
    end


    def post
      path=''
      path.concat("storage/volume/")
      client.http_post(path,asjson)
    end

      def get(path)
      client.http_get(:single,path)
    end
  end
end
