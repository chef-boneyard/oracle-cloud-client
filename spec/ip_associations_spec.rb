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

describe OracleCloud::IPAssociations do
  let(:client) do
    OracleCloud::Client.new(
      username:        'myuser',
      password:        'mypassword',
      api_url:         'https://cloud.oracle.local',
      identity_domain: 'testdomain'
    )
  end

  let(:ipassociations) { described_class.new(client) }
  let(:ipa1)           { double('ipa1', vcable_id: 'vcable1') }
  let(:ipa2)           { double('ipa2', vcable_id: 'vcable1') }
  let(:ipa3)           { double('ipa3', vcable_id: 'vcable2') }

  it 'should be a subclass of Assets' do
    expect(ipassociations).to be_a(OracleCloud::Assets)
  end

  it 'returns all associations for a vcable' do
    allow(ipassociations).to receive(:all).and_return([ ipa1, ipa2, ipa3 ])
    expect(ipassociations.find_by_vcable('vcable1')).to eq([ ipa1, ipa2 ])
  end
end
