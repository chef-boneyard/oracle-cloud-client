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

describe OracleCloud::Orchestrations do
  let(:client) do
    OracleCloud::Client.new(
      username:        'myuser',
      password:        'mypassword',
      api_url:         'https://cloud.oracle.local',
      identity_domain: 'testdomain'
    )
  end

  let(:orchestrations) { described_class.new(client) }
  let(:instance1)      { { 'name' => 'instance1' } }
  let(:instance2)      { { 'name' => 'instance2' } }
  let(:create_opts) do
    {
      name: 'test_name',
      launch_plan_label: 'test_label',
      description: 'test_description',
      instances: [ instance1, instance2 ]
    }
  end

  before do
    allow(orchestrations).to receive(:create_opts).and_return(create_opts)
  end

  it 'should be a subclass of Assets' do
    expect(orchestrations).to be_a(OracleCloud::Assets)
  end

  describe '#validate_create_options!' do
    let(:create_opts) do
      {
        name: 'test_name',
        launch_plan_label: 'test_label',
        description: 'test_description',
        instances: [ { 'name' => 'instance1'}, { 'name' => 'instance2' } ]
      }
    end

    context 'when instances is not an array' do
      it 'raises an exception' do
        create_opts[:instances] = 'whoops'
        allow(orchestrations).to receive(:create_opts).and_return(create_opts)
        expect { orchestrations.validate_create_options! }.to raise_error(ArgumentError)
      end
    end

    context 'when a description is not provided' do
      it 'raises an exception' do
        create_opts[:description] = nil
        allow(orchestrations).to receive(:create_opts).and_return(create_opts)
        expect { orchestrations.validate_create_options! }.to raise_error(ArgumentError)
      end
    end

    context 'when a name is not provided' do
      it 'auto-generates a name using a UUID' do
        create_opts[:name] = nil
        allow(orchestrations).to receive(:create_opts).and_return(create_opts)
        expect(SecureRandom).to receive(:uuid).and_return('some_uuid')

        orchestrations.validate_create_options!
        expect(create_opts[:name]).to eq('some_uuid')
      end
    end

    context 'when a launch plan label is not provided' do
      it 'defaults to launch_plan' do
        create_opts[:launch_plan_label] = nil
        allow(orchestrations).to receive(:create_opts).and_return(create_opts)

        orchestrations.validate_create_options!
        expect(create_opts[:launch_plan_label]).to eq('launch_plan')
      end
    end
  end

  describe '#create_request_payload' do
    it 'has a correct name' do
      allow(client).to receive(:compute_identity_domain).and_return('Compute-testdomain')
      allow(client).to receive(:username).and_return('myuser')
      expect(orchestrations.create_request_payload['name']).to eq('Compute-testdomain/myuser/test_name')
    end

    it 'has a correct account' do
      allow(client).to receive(:compute_identity_domain).and_return('Compute-testdomain')
      expect(orchestrations.create_request_payload['account']).to eq('Compute-testdomain/default')
    end

    it 'has correct instances' do
      expect(orchestrations.create_request_payload['oplans']
        .first['objects'].first['instances']).to eq([ instance1, instance2 ])
    end
  end
end
