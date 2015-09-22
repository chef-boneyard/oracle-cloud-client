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
  class Instances < Assets
    def local_init
      @asset_type  = 'instance'
      @asset_klass = OracleCloud::Instance
    end

    def instance_id_by_name(container, name)
      directory(asset_type, "#{container}/#{name}").first
    end

    def all
      all_assets_by_container.each_with_object([]) do |(container, instance_names), memo|
        instance_names.each do |instance_name|
          id   = instance_id_by_name(container, instance_name)
          path = "#{container}/#{instance_name}/#{id}"
          memo << OracleCloud::Instance.new(client, path)
        end
      end
    end
  end
end
