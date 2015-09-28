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

module OracleCloud
  class DummyAsset < Asset
    def local_init
      @asset_type = 'dummy'
    end
  end
end

describe OracleCloud::Asset do
  let(:client) do
    OracleCloud::Client.new(
      username:        'myuser',
      password:        'mypassword',
      api_url:         'https://cloud.oracle.local',
      identity_domain: 'testdomain'
    )
  end

  let(:container)  { 'testcontainer' }
  let(:asset_id)   { 'asset123' }
  let(:asset_type) { 'dummy' }
  let(:asset_path) { "#{container}/#{asset_id}" }
  let(:asset_data) { { 'id' => asset_id, 'name' => asset_path } }
  let(:asset)      { OracleCloud::DummyAsset.new(client, asset_path) }

  before do
    allow(client).to receive(:authenticate!)
    allow(client).to receive(:single_item)
    allow(asset).to receive(:asset_data).and_return(asset_data)
  end

  describe '#initialize' do
    let(:asset)      { OracleCloud::Asset.allocate}

    it 'calls the initialization and validation methods' do
      expect(asset).to receive(:local_init)
      expect(asset).to receive(:validate!)
      expect(asset).to receive(:fetch)

      asset.send(:initialize, client, asset_path)
    end

    it 'parses the container properly' do
      allow(asset).to receive(:validate!)
      asset.send(:initialize, client, asset_path)
      expect(asset.container).to eq(container)
    end
  end

  describe '#validate!' do
    it 'raises an error when no asset_type is set' do
      allow(asset).to receive(:asset_type).and_return(nil)
      expect { asset.validate! }.to raise_error(RuntimeError)
    end
  end

  describe '#fetch' do
    it 'calls client.single_item to fetch the asset data' do
      expect(client).to receive(:single_item).with(asset_type, asset_path)
      asset.fetch
    end
  end

  describe '#id' do
    it 'returns the correct asset ID from the asset name' do
      expect(asset.id).to eq(asset_id)
    end
  end

  describe '#name_with_container' do
    it 'returns the asset ID with the container prepended' do
      expect(asset.name_with_container).to eq('testcontainer/asset123')
    end
  end

  describe '#full_name' do
    it 'returns the fully-qualified asset name' do
      expect(asset.full_name).to eq('/Compute-testdomain/testcontainer/asset123')
    end
  end
end
