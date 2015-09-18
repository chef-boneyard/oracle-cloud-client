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
  class IPAssociations < Assets
    def local_init
      @asset_type = 'ip/association'
    end

    def all
      all_assets_by_container.each_with_object([]) do |(container, association_names), memo|
        association_names.each do |association_name|
          memo << OracleCloud::IPAssociation.new(client, "#{container}/#{association_name}")
        end
      end
    end

    def find_by_vcable(vcable_id)
      all.select { |x| x.vcable_id == vcable_id }
    end
  end
end
