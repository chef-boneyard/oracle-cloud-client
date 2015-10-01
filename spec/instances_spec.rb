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
require 'spec_helper'

describe OracleCloud::Instances do
  let(:client) do
    OracleCloud::Client.new(
      username:        'myuser',
      password:        'mypassword',
      api_url:         'https://cloud.oracle.local',
      identity_domain: 'testdomain'
    )
  end

  let(:instances) { described_class.new(client) }

  it 'should be a subclass of Assets' do
    expect(instances).to be_a(OracleCloud::Assets)
  end

  describe '#instance_id_by_name' do
    it 'calls the directory and returns the id' do
      expect(instances).to receive(:directory).with('test_container/test_name').and_return(['id'])
      expect(instances.instance_id_by_name('test_container', 'test_name')).to eq('id')
    end
  end

  describe '#all' do
    let(:all_instances) do
      {
        'container1' => %w(instance1 instance2),
        'container2' => %w(instance3 instance4)
      }
    end

    let(:instance1) { double('instance1') }
    let(:instance2) { double('instance2') }
    let(:instance3) { double('instance3') }
    let(:instance4) { double('instance4') }

    it 'returns an array of instance objects' do
      allow(instances).to receive(:all_asset_ids_by_container).and_return(all_instances)
      allow(instances).to receive(:instance_id_by_name).with('container1', 'instance1').and_return('id1')
      allow(instances).to receive(:instance_id_by_name).with('container1', 'instance2').and_return('id2')
      allow(instances).to receive(:instance_id_by_name).with('container2', 'instance3').and_return('id3')
      allow(instances).to receive(:instance_id_by_name).with('container2', 'instance4').and_return('id4')

      expect(OracleCloud::Instance).to receive(:new).with(client, 'container1/instance1/id1').and_return(instance1)
      expect(OracleCloud::Instance).to receive(:new).with(client, 'container1/instance2/id2').and_return(instance2)
      expect(OracleCloud::Instance).to receive(:new).with(client, 'container2/instance3/id3').and_return(instance3)
      expect(OracleCloud::Instance).to receive(:new).with(client, 'container2/instance4/id4').and_return(instance4)

      expect(instances.all).to eq([ instance1, instance2, instance3, instance4 ])
    end
  end
end
