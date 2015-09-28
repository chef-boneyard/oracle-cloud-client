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
  class DummyAssets < Assets
    def local_init
      @asset_type  = 'dummy'
      @asset_klass = OracleCloud::DummyAsset
    end
  end

  class DummyAsset < Asset
    def local_init
      @asset_type  = 'dummy'
    end
  end
end

describe OracleCloud::Assets do
  let(:client) do
    OracleCloud::Client.new(
      username:        'myuser',
      password:        'mypassword',
      api_url:         'https://cloud.oracle.local',
      identity_domain: 'testdomain'
    )
  end

  let(:assets)      { OracleCloud::DummyAssets.new(client) }

  let(:asset_ids_by_container) do
    {
      'container1' => [ 'asset1', 'asset2' ],
      'container2' => [ 'asset3' ]
    }
  end

  before do
    allow(client).to receive(:authenticate!)
    allow(client).to receive(:directory)
    allow(client).to receive(:asset_get)
  end

  describe '#initialize' do
    let(:assets) { OracleCloud::Assets.allocate}

    it 'calls the initialization and validation methods' do
      expect(assets).to receive(:local_init)
      expect(assets).to receive(:validate!)

      assets.send(:initialize, client)
    end
  end

  describe '#validate' do
    it 'raises an exception if asset_type is not set' do
      allow(assets).to receive(:asset_type).and_return(nil)
      expect { assets.validate! }.to raise_error(RuntimeError)
    end

    it 'raises an exception if asset_klass is not set' do
      allow(assets).to receive(:asset_klass).and_return(nil)
      expect { assets.validate! }.to raise_error(RuntimeError)
    end
  end

  describe '#all' do
    let(:asset1) { double('asset1') }
    let(:asset2) { double('asset2') }
    let(:asset3) { double('asset3') }

    before do
      allow(assets).to receive(:all_asset_ids_by_container).and_return(asset_ids_by_container)
    end

    it 'returns an array of assets' do
      expect(OracleCloud::DummyAsset).to receive(:new).with(client, 'container1/asset1').and_return(asset1)
      expect(OracleCloud::DummyAsset).to receive(:new).with(client, 'container1/asset2').and_return(asset2)
      expect(OracleCloud::DummyAsset).to receive(:new).with(client, 'container2/asset3').and_return(asset3)
      expect(assets.all).to eq([ asset1, asset2, asset3 ])
    end
  end

  describe '#containers' do
    it 'fetches the base directory' do
      expect(assets).to receive(:directory).with('')
      assets.containers
    end
  end

  describe '#ids_from_results' do
    let(:results) { { 'result' => [ 'container1/asset1', 'container1/asset2', 'container1/asset3' ] } }
    it 'returns an array of asset IDs' do
      expect(assets.ids_from_results(results)).to eq(%w(asset1 asset2 asset3))
    end
  end

  describe '#all_asset_ids_by_container' do
    let(:containers) { asset_ids_by_container.keys }
    it 'resturns a hash of asset IDs by container' do
      allow(assets).to receive(:containers).and_return(containers)
      allow(assets).to receive(:asset_ids_for_container).with('container1').and_return(%w(asset1 asset2))
      allow(assets).to receive(:asset_ids_for_container).with('container2').and_return(%w(asset3))
      expect(assets.all_asset_ids_by_container).to eq(asset_ids_by_container)
    end
  end

  describe '#asset_ids_for_container' do
    it 'fetches the directory for a container' do
      expect(assets).to receive(:directory).with('container1')
      assets.asset_ids_for_container('container1')
    end
  end

  describe '#create' do
    let(:create_opts)    { {} }
    let(:create_payload) { { 'foo' => 'bar' } }
    let(:response)       { { 'name' => '/Compute-testdomain/container1/asset1' } }
    let(:asset)          { double('asset') }

    before do
      allow(client).to receive(:identity_domain).and_return('testdomain')
      allow(client).to receive(:http_post).and_return(response)
      allow(assets).to receive(:create_request_payload).and_return(create_payload)
      allow(OracleCloud::DummyAsset).to receive(:new)
    end

    it 'validates the creation options' do
      expect(assets).to receive(:validate_create_options!)
      assets.create(create_opts)
    end

    it 'performs an HTTP POST with the payload' do
      expect(client).to receive(:http_post).with('/dummy/', create_payload.to_json)
      assets.create(create_opts)
    end

    it 'strips the identity domain from the name in the response' do
      expect(assets).to receive(:strip_identity_domain!).with('/Compute-testdomain/container1/asset1')
      assets.create(create_opts)
    end

    it 'creates a new asset instance and returns it' do
      expect(OracleCloud::DummyAsset).to receive(:new).with(client, 'container1/asset1').and_return(asset)
      expect(assets.create(create_opts)).to eq(asset)
    end
  end

  describe '#create_request_payload' do
    it 'raises an exception when the method is not defined' do
      expect { assets.create_request_payload }.to raise_error(NoMethodError)
    end
  end

  describe '#strip_identity_domain!' do
    it 'removes the Compute-blah from the name' do
      allow(client).to receive(:identity_domain).and_return('testdomain')
      expect(assets.strip_identity_domain!('/Compute-testdomain/foo')).to eq('foo')
    end
  end
end
