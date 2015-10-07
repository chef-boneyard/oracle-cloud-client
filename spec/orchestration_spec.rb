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

describe OracleCloud::Orchestration do
  let(:client) do
    OracleCloud::Client.new(
      username:        'myuser',
      password:        'mypassword',
      api_url:         'https://cloud.oracle.local',
      identity_domain: 'testdomain'
    )
  end

  let(:orchestration) { described_class.new(client, 'orchestrationpath') }

  let(:asset_data) do
    {
      'status' => 'test_status',
      'description' => 'test_description',
      'objects' => [
        {
          'instances' => [
            {
              'state' => 'stopped',
              'name' => 'instance1'
            },
            {
              'state' => 'started',
              'name' => 'instance2'
            },
            {
              'name' => 'instance3'
            }
          ]
        }
      ]
    }
  end

  before do
    allow(client).to receive(:authenticate!)
    allow(client).to receive(:single_item)
    allow(orchestration).to receive(:asset_data).and_return(asset_data)
    allow(orchestration).to receive(:refresh)
    allow(orchestration).to receive(:name_with_container).and_return('container/name')
  end

  it 'should be a subclass of Asset' do
    expect(orchestration).to be_a(OracleCloud::Asset)
  end

  describe '#status' do
    it 'returns the correct status' do
      expect(orchestration.status).to eq('test_status')
    end
  end

  describe '#description' do
    it 'returns the correct description' do
      expect(orchestration.description).to eq('test_description')
    end
  end

  describe '#start' do
    it 'calls HTTP PUT with a start action and refreshes the asset data' do
      expect(client).to receive(:asset_put).with('orchestration', 'container/name?action=START')
      expect(orchestration).to receive(:refresh)
      orchestration.start
    end
  end

  describe '#stop' do
    it 'calls HTTP PUT with a stop action and refreshes the asset data' do
      expect(client).to receive(:asset_put).with('orchestration', 'container/name?action=STOP')
      expect(orchestration).to receive(:refresh)
      orchestration.stop
    end
  end

  describe '#delete' do
    it 'calls HTTP DELETE' do
      expect(client).to receive(:asset_delete).with('orchestration', 'container/name')
      orchestration.delete
    end
  end

  describe '#launch_plan' do
    context 'when no oplans exist' do
      it 'returns nil' do
        allow(orchestration).to receive(:asset_data).and_return({})
        expect(orchestration.launch_plan).to eq(nil)
      end
    end

    context 'when oplans exist but a launch_plan does not' do
      let(:asset_data) do
        {
          'oplans' => [
            {
              'obj_type' => 'not_a_launch_plan'
            }
          ]
        }
      end

      it 'returns nil' do
        allow(orchestration).to receive(:asset_data).and_return(asset_data)
        expect(orchestration.launch_plan).to eq(nil)
      end
    end

    context 'when a launch plan exists' do
      let(:asset_data) do
        {
          'oplans' => [
            {
              'obj_type' => 'launchplan',
              'test_key' => 'correct'
            },
            {
              'obj_type' => 'some_other_plan',
              'test_key' => 'not the droid you are looking for'
            }
          ]
        }
      end

      it 'returns the launch plan object' do
        allow(orchestration).to receive(:asset_data).and_return(asset_data)
        expect(orchestration.launch_plan['obj_type']).to eq('launchplan')
        expect(orchestration.launch_plan['test_key']).to eq('correct')
      end
    end
  end

  describe '#instance_records' do
    context 'when no launch plan exists' do
      it 'returns an empty array' do
        allow(orchestration).to receive(:launch_plan).and_return(nil)
        expect(orchestration.instance_records).to eq([])
      end
    end

    context 'when a launch plan exists but has no objects' do
      let(:launch_plan) { {} }
      it 'returns an empty array' do
        allow(orchestration).to receive(:launch_plan).and_return(launch_plan)
        expect(orchestration.instance_records).to eq([])
      end
    end

    context 'when launch plan objects exists but have no instances' do
      let(:launch_plan) { { 'objects' => [ { 'some_key' => 'some_value' } ] } }
      it 'returns an empty array' do
        allow(orchestration).to receive(:launch_plan).and_return(launch_plan)
        expect(orchestration.instance_records).to eq([])
      end
    end

    context 'when instances exists but do not have a state key' do
      let(:instance) { { 'name' => 'instance_name' } }
      let(:launch_plan) do
        {
          'objects' => [
            {
              'instances' => [ instance ]
            }
          ]
        }
      end

      it 'returns an empty array' do
        allow(orchestration).to receive(:launch_plan).and_return(launch_plan)
        expect(orchestration.instance_records).to eq([])
      end
    end

    context 'when instances exists with state keys' do
      let(:instance1) { { 'name' => 'instance1', 'state' => 'started' } }
      let(:instance2) { { 'name' => 'instance2', 'state' => 'started' } }
      let(:launch_plan) do
        {
          'objects' => [
            {
              'instances' => [ instance1, instance2 ]
            }
          ]
        }
      end

      it 'returns an array of instances' do
        allow(orchestration).to receive(:launch_plan).and_return(launch_plan)
        expect(orchestration.instance_records).to eq([ instance1, instance2 ])
      end
    end
  end

  describe '#instances' do
    context 'when no instances are available' do
      it 'returns an empty array' do
        allow(orchestration).to receive(:instance_records).and_return(nil)
        expect(orchestration.instances).to eq([])
      end
    end

    context 'when instances are available' do
      let(:instance1)     { { 'name' => 'instance1', 'state' => 'started' } }
      let(:instance2)     { { 'name' => 'instance2', 'state' => 'started' } }
      let(:instance_obj1) { double('instance_obj1') }
      let(:instance_obj2) { double('instance_obj2') }
      let(:instances)     { double('instances') }

      it 'returns an array of Instance objects' do
        allow(client).to receive(:instances).and_return(instances)
        allow(instances).to receive(:by_name).with('instance1').and_return(instance_obj1)
        allow(instances).to receive(:by_name).with('instance2').and_return(instance_obj2)
        allow(orchestration).to receive(:instance_records).and_return([ instance1, instance2 ])

        expect(orchestration.instances).to eq([ instance_obj1, instance_obj2 ])
      end
    end
  end

  describe '#instance_count' do
    it 'returns the correct count' do
      allow(orchestration).to receive(:instance_records).and_return([ 1, 2, 3, 4, 5 ])
      expect(orchestration.instance_count).to eq(5)
    end
  end
end
