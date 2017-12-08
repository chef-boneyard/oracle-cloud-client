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
  class Orchestration < Asset
    def local_init
      @version = client.orchestration_version
      if @version == 2
        @asset_type = 'platform/v1/orchestration'
      else
        @asset_type = 'orchestration'
      end
    end

    def status
      asset_data['status']
    end

    def description
      asset_data['description']
    end

    def start
      return if %w(starting ready active).include?(status)

      client.asset_put(asset_type, "#{name_with_container}?action=START")
      refresh
    end

    def stop
      return if status == 'stopped'

      client.asset_put(asset_type, "#{name_with_container}?action=STOP")
      refresh
    end

    def delete
      client.asset_delete(asset_type, name_with_container)
    end

    def launch_plan
      return if asset_data['oplans'].nil?

      asset_data['oplans'].find { |x| x['obj_type'] == 'launchplan' }
    end

  # The difference between this and all_instance_records, is that this
  # returns a list of lists, whereas the other returns a single list
  def instance_records
    if @version==1
      return [] if launch_plan.nil? || launch_plan['objects'].nil?

      instance_object = launch_plan['objects'].select { |x| x.respond_to?(:key?) && x.key?('instances') }
      return [] if instance_object.nil?

      instances =[]
      instance_object.each do |instance| 
          instances << instance['instances'].select { |x| x.key?('state') }
      end
      instances
    else
      instances=[]
      asset_data['objects'].each do |o|
        if o['type']=='Instance' and o['template'].key?('state')
          instances <<  [o['health']['object']]
        end
      end
      instances
    end
  end

  def instances
    return [] if instance_records.nil?
    instances =[]
    instance_records.each do |instance| 
      instance = instance.map { |x| client.instances.by_name(x['name']) }
      instances <<  instance[0]
    end
      instances
  end

    def all_instance_records
      if @version == 1
        return [] if launch_plan.nil? || launch_plan['objects'].nil?
        instance_object = launch_plan['objects'].find { |x| x.respond_to?(:key?) && x.key?('instances') }
        return [] if instance_object.nil?
        instance_object['instances'].select { |x| x.key?('label') }
      else
        instances=[]
        asset_data['objects'].each do |o|
          if o['type']=='Instance' and o['template'].key?('label')
            instances << o['template']
          end
        end
        instances
      end
    end



    def instance_count
      instance_records.count
    end

    def error?
      status == 'error'
    end

    def errors
      return [] unless launch_plan.key?('info') && launch_plan['info'].key?('errors')

      launch_plan['info']['errors'].values
    end
  end
end
