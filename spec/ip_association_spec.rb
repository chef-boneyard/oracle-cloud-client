# frozen_string_literal: true

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

describe OracleCloud::IPAssociation do
  let(:client) do
    OracleCloud::Client.new(
      username:        'myuser',
      password:        'mypassword',
      api_url:         'https://cloud.oracle.local',
      identity_domain: 'testdomain'
    )
  end

  let(:ipassociation) { described_class.new(client, 'ipassociationpath') }

  let(:asset_data) do
    {
      'ip'          => '1.2.3.4',
      'vcable'      => 'test_vcable_id',
      'reservation' => 'test_container/test_reservation_id'
    }
  end

  before do
    allow(client).to receive(:authenticate!)
    allow(client).to receive(:single_item)
    allow(ipassociation).to receive(:asset_data).and_return(asset_data)
  end

  it 'should be a subclass of Asset' do
    expect(ipassociation).to be_a(OracleCloud::Asset)
  end

  it 'returns the correct IP address' do
    expect(ipassociation.ip_address).to eq('1.2.3.4')
  end

  it 'returns the correct vcable ID' do
    expect(ipassociation.vcable_id).to eq('test_vcable_id')
  end

  it 'returns the correct reservation ID' do
    expect(ipassociation.reservation_id).to eq('test_reservation_id')
  end
end
