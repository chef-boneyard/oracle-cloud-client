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

describe OracleCloud::ImageLists do
  let(:client) do
    OracleCloud::Client.new(
      username:        'myuser',
      password:        'mypassword',
      api_url:         'https://cloud.oracle.local',
      identity_domain: 'testdomain'
    )
  end

  let(:imagelists) { described_class.new(client) }

  describe '#all' do
    it 'returns a concatenated array of public and private imagelists' do
      allow(imagelists).to receive(:public_imagelists).and_return([ 1, 2 ])
      allow(imagelists).to receive(:private_imagelists).and_return([ 3, 4 ])
      expect(imagelists.all).to eq([ 1, 2, 3, 4 ])
    end
  end

  describe '#public_imagelists' do
    let(:response) { { 'result' => %w[imagelist1 imagelist2] } }
    let(:imagelist1) { double('imagelist1', name: 'imagelist1') }
    let(:imagelist2) { double('imagelist2', name: 'imagelist2') }

    before do
      allow(client).to receive(:http_get).with(:single, '/imagelist/oracle/public/').and_return(response)
      allow(OracleCloud::ImageList).to receive(:new).with('imagelist1').and_return(imagelist1)
      allow(OracleCloud::ImageList).to receive(:new).with('imagelist2').and_return(imagelist2)
    end

    it 'http_gets the list of public images' do
      expect(client).to receive(:http_get).with(:single, '/imagelist/oracle/public/')
      imagelists.public_imagelists
    end

    it 'returns an array of imagelist instances' do
      expect(imagelists.public_imagelists).to eq([ imagelist1, imagelist2 ])
    end
  end

  describe '#private_imagelists' do
    it 'returns an empty array until it is fully implemented' do
      expect(imagelists.private_imagelists).to eq([])
    end
  end

  describe '#exist?' do
    let(:imagelist1) { double('imagelist1', name: 'imagelist1') }
    let(:imagelist2) { double('imagelist2', name: 'imagelist2') }

    before do
      allow(imagelists).to receive(:all).and_return([ imagelist1, imagelist2 ])
    end

    context 'when an existing imagelist name is provided' do
      it 'returns true' do
        expect(imagelists.exist?('imagelist1')).to eq(true)
      end
    end

    context 'when an imagelist name is provided that does not exist' do
      it 'returns false' do
        expect(imagelists.exist?('imagelist999')).to eq(false)
      end
    end
  end
end
