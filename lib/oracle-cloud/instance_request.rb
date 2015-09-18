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
    attr_reader :client
    def initialize(client, opts)
      @client    = client
      @shape     = opts[:shape]
      @label     = opts[:label]
      @imagelist = opts[:imagelist]
      @name      = client.compute_identity_domain + '/' + client.username + '/' + opts[:name]

      validate_options!(opts)
    end

    def validate_options!(opts)
      raise "The following required options are missing: #{missing_required_options.join(', ')}" if
        missing_required_options

      raise "#{@shape} is not a valid shape" unless client.shapes.exist?(@shape)
      raise "#{@imagelist} is not a valid imagelist" unless client.imagelists.exist?(@imagelist)
    end

    def missing_required_options(opts)
      [ :name, :shape, :image ].each_with_object([]) do |opt, memo|
        memo << opt unless opts[opt]
      end
    end
  end
end
