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
    attr_reader :asset_type, :client

    def initialize(client)
      @client = client

      local_init
      validate!
    end

    def local_init
      # this should be redefined in each Assets subclass with things like
      # the @asset_type to use in API calls
    end

    def validate!
      raise "#{self.class} did not define an asset_type variable" if asset_type.nil?
    end

    def containers
      directory(asset_type, '')
    end

    def ids_from_results(results)
      results['result'].map { |x| x.split('/')[-1] }
    end

    def all_assets_by_container
      containers.each_with_object({}) do |container, memo|
        memo[container] = assets_for_container(container)
      end
    end

    def assets_for_container(container)
      directory(asset_type, container)
    end

    def directory(type, path)
      ids_from_results(client.directory(type, path))
    end

    def create(opts)
      validate_create_options!(opts)
      call_create
    end

    def validate_create_options!(opts)
      # this should be redefined in each Assets subclass with any validation
      # of creation options that should be done prior to creation
    end

    def call_create
      client.http_post(asset_type, create_request_payload)
    end
  end
end
