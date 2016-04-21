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
      @asset_type = 'orchestration'
    end

    def status
      asset_data['status']
    end

    def account
      asset_data['account']
    end

    def description
      asset_data['description']
    end

    def start
      return if %w(starting ready).include?(status)

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

    def instance_records
      return [] if launch_plan.nil? || launch_plan['objects'].nil?

      instance_object = launch_plan['objects'].find { |x| x.respond_to?(:key?) && x.key?('instances') }
      return [] if instance_object.nil?

      instance_object['instances'].select { |x| x.key?('state') }
    end

    def all_instance_records
      return [] if launch_plan.nil? || launch_plan['objects'].nil?

      instance_object = launch_plan['objects'].find { |x| x.respond_to?(:key?) && x.key?('instances') }
      return [] if instance_object.nil?

      instance_object['instances'].select { |x| x.key?('label') }
    end

    def instances
      return [] if instance_records.nil?
      instance_records.map { |x| client.instances.by_name(x['name']) }
    end


    #def instance(name)
    #  return [] if all_instance_records.nil?
     # all_instance_records.select { |x| x.key?('name') && x.value?(name) }
    #end

    def instance(name)
      return [] if all_instance_records.nil?
      all_instance_record = Hash.new

      all_instance_records.each do |all_instance_record|
        #an orchestration can have instances with same names
        #in which case we will be returning an array as below : 
        #instances << all_instance_record    if all_instance_record['name']==name 

        #instead we will assume that instances have unique names
        #so we will always return one instance
        if all_instance_record['name']==name 
              return all_instance_record    
        #the record returned can be either an array or hashmap depending on the status of the orchestration
        #if the orchestration(and hence the instance) is in stopped state - then the instance details are returned as
            #{"networking"=>{"eth0"=>{"nat"=>"ipreservation:/Compute.........}
        #if the orchestration(and hence the instance) is in running state - then the instance details are returned as
            #[{"networking"=>{"eth0"=>{"nat"=>"ipreservation:/Compute.........}] unless the instance name also contains the 
            #id (i.e)oracle_ccloud_13/7934d0dd-7e2e-45ce-af0f-56d615a5548b
        end
    end
    end


     def instances_name
      return [] if all_instance_records.nil?
      all_instance_records.map { |x| x['name'] }
    end

    def instance_name(name)
      return [] if all_instance_records.nil?
      instance(name)['name']
    end

    def instances_label
      return [] if all_instance_records.nil?
      all_instance_records.map { |x| x['label'] }
    end

    def instance_label(name)
      return [] if all_instance_records.nil?
      instance(name)['label']
    end

     def instances_boot_order
      return [] if all_instance_records.nil?
      all_instance_records.map { |x| x['boot_order'] }
    end

    def instance_boot_order(name)
      return [] if all_instance_records.nil?
      instance(name)['boot_order'][0] #there can be only one boot order
    end

    def instances_shape
      return [] if all_instance_records.nil?
      all_instance_records.map { |x| x['shape']}
    end

    def instance_shape(name)
      return [] if all_instance_records.nil?
      instance(name)['shape']
    end

    def instances_imagelist
      return [] if all_instance_records.nil?
      all_instance_records.map { |x| x['imagelist'] }
    end

     def instance_imagelist(name)
      return [] if all_instance_records.nil?
      instance(name)['imagelist']
    end

    def instances_sshkeys
      return [] if all_instance_records.nil?
      all_instance_records.map { |x| x['sshkeys'] }
    end


    def instance_sshkeys(name) #array => ["/Compute-usoracle66248/s.ramaswamy@limepoint.com/mac"]
      return [] if all_instance_records.nil?
      instance(name)['sshkeys']
    end

    def instances_storage_attachments
      return [] if all_instance_records.nil?
      all_instance_records.map { |x| x['storage_attachments'] }
    end

    def instance_storage_attachments(name) #array => [{"volume"=>"/Compute-usoracle66248/s.ramaswamy@limepoint.com/test_instance_oracle_public_oel_6.6_20GB_x11_RD_sv", "index"=>1}]
      return [] if all_instance_records.nil?
      instance(name)['storage_attachments']
    end

    def instance_storage_attachments_name(name)
      return [] if all_instance_records.nil?
      ins = instance_storage_attachments(name)
      puts "ins = #{ins}"
      ins[0]['volume'] #TODO - handle mulitple volumes
    end

    def instances_networking
      return [] if all_instance_records.nil?
      all_instance_records.map { |x| x['networking'] }
    end

    def instance_networking(name) #hash => {"eth0"=>{"nat"=>"ipreservation:/Compute-usoracle66248/s.ramaswamy@limepoint.com/test_instance_oracle_public_oel_6.6_20GB_x11_RD_ir"}}
      return [] if all_instance_records.nil?
      instance(name)['networking']
    end

     def instance_networking_name(name)
      return [] if all_instance_records.nil?
      instance_networking(name)['eth0']['nat'] #TODO - better way to get the details?
    end




    def get(name)
      return [] if instance_records.nil?

      instance_records.map { |x| client.instances.by_name(x['name']) }
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
