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
  class Instance < Asset
    def local_init
      @asset_type = 'instance'
    end

    def id
      strip_identity_domain(asset_data['name'])
    end

    def full_name
      asset_data['name']
    end

    def ip_address
      asset_data['ip']
    end

    def image
      asset_data['imagelist']
    end

    def shape
      asset_data['shape']
    end

    def hostname
      asset_data['hostname']

    end

    def label
      asset_data['label']
    end

    def state
      asset_data['state']
    end
    alias status state

    def vcable_id
      asset_data['vcable_id']
    end
    
    def sshkeys
      asset_data['sshkeys']
    end

    def public_ip_addresses
      client.ip_associations.find_by_vcable(vcable_id).map(&:ip_address)
    end

    def networking
      asset_data['networking']['eth0']['nat']
    end

    def account
      asset_data['account']
    end

    def storage_volume_name
      asset_data['storage_attachments'][0]['storage_volume_name']
    end

    def orchestration
      orchestration = asset_data['attributes']['nimbula_orchestration']
      return if orchestration.nil?

      strip_identity_domain(orchestration)
    end

    def orchestration_with_domain
      orchestration = asset_data['attributes']['nimbula_orchestration']
      return if orchestration.nil?
    orchestration
    end

    def delete
      raise 'Unable to delete instance, instance is part of orchestration ' \
        "#{orchestration} - delete the orchestration instead" unless orchestration.nil?

      client.asset_delete(asset_type, id)
    end
  end
end
