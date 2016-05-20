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
  class Assets
    attr_reader :asset_klass, :asset_type, :client
    attr_accessor :create_opts

    def initialize(client)
      @client = client
      @create_opts = {}

      local_init
      validate!
    end

    def local_init
      # this should be redefined in each Assets subclass with things like
      # the @asset_type to use in API calls
    end

    def validate!
      raise "#{self.class} did not define an asset_type variable" if asset_type.nil?
      raise "#{self.class} did not define an asset_klass variable" if asset_klass.nil?
    end

    def all
      all_asset_ids_by_container.each_with_object([]) do |(container, asset_names), memo|
        asset_names.each do |asset_name|
          memo << @asset_klass.new(client, "#{container}/#{asset_name}")
        end
      end
    end

    def containers
      directory('')
    end

    def ids_from_results(results)
      results['result'].map { |x| x.split('/').last }
    end

    def all_asset_ids_by_container
      containers.each_with_object({}) do |container, memo|
        memo[container] = asset_ids_for_container(container)
      end
    end

    def asset_ids_for_container(container)
      directory(container)
    end

    def by_name(name)
      @asset_klass.new(client, strip_identity_domain(name))
    end

    def directory(path)
      ids_from_results(client.directory(asset_type, path))
    end

    def create(opts)
      @create_opts = opts

      validate_create_options!
      response = client.http_post("/#{asset_type}/", create_request_payload.to_json)
      name     = strip_identity_domain(response['name'])
      @asset_klass.new(client, name)
    end

    def update(opts)
      path = opts[:path]
      payload  = opts[:payload]
      response = client.http_put("/#{asset_type}#{path}", payload.to_json)
      name     = strip_identity_domain(response['name'])
      @asset_klass.new(client, name)
    end

    def create_request_payload
      # this should be defined in each Assets subclass with a formatted
      # payload used to create the Asset
      raise NoMethodError, "#{self.class} does not define create_request_payload"
    end

    def validate_create_options!
      # this should be redefined in each Assets subclass with any validation
      # of creation options that should be done prior to creation
    end

    def strip_identity_domain(name)
      name.gsub("/Compute-#{client.identity_domain}/", '')
    end
  end
end
