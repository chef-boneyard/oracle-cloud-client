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

require 'securerandom'

module OracleCloud
  class Orchestrations < Assets
    def local_init
      @asset_type  = 'orchestration'
      @asset_klass = OracleCloud::Orchestration
    end

    def validate_create_options!
      raise ArgumentError, 'instances option must be an array of instance requests to create' unless create_opts[:instances].respond_to?(:each)
      raise ArgumentError, 'orchestration description is required' unless create_opts[:description]

      create_opts[:name] = SecureRandom.uuid unless create_opts[:name]
      create_opts[:launch_plan_label] = 'launch_plan' unless create_opts[:launch_plan_label]
    end

    def create_request_payload
      {
        'name' => "#{client.compute_identity_domain}/#{client.username}/#{create_opts[:name]}",
        'relationships' => [],
        'account' => "#{client.compute_identity_domain}/default",
        'description' => create_opts[:description],
        'schedule' => { 'start_time' => nil, 'stop_time' => nil },
        'uri' => nil,
        'oplans' => [
          {
            'status' => 'unknown',
            'info' => {},
            'obj_type' => 'launchplan',
            'ha_policy' => 'active',
            'label' => create_opts[:launch_plan_label],
            'objects' => [
              {
                'instances' => create_opts[:instances].map(&:to_h)
              }
            ]
          }
        ]
      }
    end
  end
end
