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
  class Asset
    attr_reader :asset_data, :asset_type, :client, :container

    def initialize(client, path)
      @client     = client
      @asset_data = nil
      @container  = path.split('/').first

      local_init
      validate!

      fetch(path)
    end

    def local_init
      # this should be redefined in each Assets subclass with things like
      # the @asset_type to use in API calls
    end

    def validate!
      raise "#{self.class} did not define an asset_type variable" if asset_type.nil?
    end

    def fetch(path)
      @asset_data = client.single_item(asset_type, path)
    end
  end
end
