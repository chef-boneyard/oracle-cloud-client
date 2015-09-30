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

describe OracleCloud::Instance do
  let(:client) do
    OracleCloud::Client.new(
      username:        'myuser',
      password:        'mypassword',
      api_url:         'https://cloud.oracle.local',
      identity_domain: 'testdomain'
    )
  end

  let(:instance) { described_class.new(client, 'instancepath') }

  let(:asset_data) do
    {
      'ip'        => '1.2.3.4',
      'imagelist' => 'test_image',
      'shape'     => 'test_shape',
      'hostname'  => 'test_hostname',
      'state'     => 'test_state',
      'vcable_id' => 'test_vcable_id'
    }
  end

  before do
    allow(client).to receive(:authenticate!)
    allow(client).to receive(:single_item)
    allow(instance).to receive(:asset_data).and_return(asset_data)
  end

  it 'should be a subclass of Asset' do
    expect(instance).to be_a(OracleCloud::Asset)
  end

  it 'returns the correct IP address' do
    expect(instance.ip_address).to eq('1.2.3.4')
  end

  it 'returns the correct image' do
    expect(instance.image).to eq('test_image')
  end

  it 'returns the correct shape' do
    expect(instance.shape).to eq('test_shape')
  end

  it 'returns the correct hostname' do
    expect(instance.hostname).to eq('test_hostname')
  end

  it 'returns the correct state' do
    expect(instance.state).to eq('test_state')
  end

  it 'returns the correct vcable ID' do
    expect(instance.vcable_id).to eq('test_vcable_id')
  end

  let(:ip1)             { double('ip1', ip_address: '1.1.1.1') }
  let(:ip2)             { double('ip2', ip_address: '2.2.2.2') }
  let(:ip_associations) { [ ip1, ip2 ] }
  let(:client_ipa)      { double('ip_associations') }
  it 'returns a list of public IP addresses' do
    allow(instance).to receive(:vcable_id).and_return('cable123')
    allow(client).to receive(:ip_associations).and_return(client_ipa)
    allow(client_ipa).to receive(:find_by_vcable).with('cable123').and_return(ip_associations)
    expect(instance.public_ip_addresses).to eq([ '1.1.1.1', '2.2.2.2' ])
  end
end
