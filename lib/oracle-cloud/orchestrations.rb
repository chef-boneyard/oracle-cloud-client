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
  class Orchestrations < Assets
    def local_init
      @asset_type = 'orchestration'
    end

    def all #TODO
      all_assets_by_container.each_with_object([]) do |(container, instance_names), memo|
        instance_names.each do |instance_name|
          id   = instance_id_by_name(container, instance_name)
          path = "#{container}/#{instance_name}/#{id}"
          memo << OracleCloud::Instance.new(client, path)
        end
      end
    end

    def validate_create_options!(opts)
      raise 'instances option must be an array of instance requests to create' unless opts[:instances].respond_to?(:each)
      raise 'orchestration name is required' unless opts[:name]
      raise 'orchestration description is required' unless opts[:description]

      opts[:launch_plan_label] = 'launch_plan' unless opts[:launch_plan_label]
    end

    def create_request_payload
      {
        'name' => client.compute_identity_domain + '/' + client.username + '/' + opts[:name],
        'relationships' => [],
        'account' => client.compute_identity_domain + '/default',
        'description' => opts[:description],
        'schedule' => { 'start_time' => nil, 'stop_time' => nil },
        'uri' => nil,
        'oplans' => [
          {
            'status' => 'unknown',
            'info' => {},
            'obj_type' => 'launchplan',
            'ha_policy' => 'active',
            'label' => opts[:launch_plan_label],
            'objects' => [
              {
                'instances' => opts[:instances]
              }
            ]
          }
        ]
      }
    end
  end
end
