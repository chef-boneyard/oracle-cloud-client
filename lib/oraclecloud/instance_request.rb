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
  class InstanceRequest
    attr_reader :client, :opts, :name, :shape, :imagelist, :public_ip, :label, :sshkeys , :storage_volume_name , :storage_volumes, :bootable_volumes,:boot_order , :volumes ,:seclists,:dns
    def initialize(client, opts)
      @client    = client
      @opts      = opts

      @name      = opts[:name]
      @shape     = opts[:shape]
      @imagelist = opts[:imagelist]
      @public_ip = opts[:public_ip]
      @dns = opts[:dns]
      opts[:boot_order].nil? ? @boot_order = nil : @boot_order =opts[:boot_order] #can be empty
      @label     = opts.fetch(:label, @name)
      @sshkeys   = opts.fetch(:sshkeys, [])
      #@storage_volumes=opts[:storage_volumes]
      #@bootable_volumes=opts[:bootable_volumes]
      @volumes =  opts[:volumes] #can be empty 
      @seclists =  opts[:seclists] #can be empty 
      

      validate_options!
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
      "/#{client.full_identity_domain}/#{client.username}/#{name}"
    end

    def nat
      return unless public_ip
      (public_ip == :pool) ? 'ippool:/oracle/public/ippool' : "ipreservation:#{public_ip}"
    end

    # FIXME: update this to support multiple NICs
    def networking
      networking = {}
      networking['eth0'] = {}
      networking['eth0']['nat'] = nat unless nat.nil?
      networking['eth0']['dns'] = dns unless dns.nil?
      networking['eth0']['seclists'] = seclists unless seclists.nil?

      networking
    end

    def to_h
     to_h_all.delete_if { |key, value| value.nil? || value.empty?}
       #"storage_attachments": [],
       #"boot_order": [null]
    end

     def to_h_all
      {
        'shape'      => shape,
        'label'      => label,
        'imagelist'  => imagelist,
        'name'       => full_name,
        'sshkeys'    => sshkeys,
        'networking' => networking,
        'storage_attachments'=> storage_attachment,
        'boot_order' => boot_order,
        'seclists' =>seclists
      }
    end


    def storage_attachment
      arry =[]
      volumes.each do |key,bvolume|
        arry << to_sh(key,bvolume)
        end
      arry
    end
    
    def to_sh(key,bvolume)
      {
        'volume'      => bvolume,
        'index'      => key.to_i
      }
    end

  end
end
