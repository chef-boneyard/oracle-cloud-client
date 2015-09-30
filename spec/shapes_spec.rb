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

describe OracleCloud::Shapes do
  let(:client) do
    OracleCloud::Client.new(
      username:        'myuser',
      password:        'mypassword',
      api_url:         'https://cloud.oracle.local',
      identity_domain: 'testdomain'
    )
  end

  let(:shapes) { described_class.new(client) }
  let(:shape1) { double('shape1', name: 'shape1') }
  let(:shape2) { double('shape2', name: 'shape2') }

  describe '#all' do
    let(:response) { { 'result' => %w(shape1 shape2) } }
    it 'returns an array of Shape objects' do
      expect(client).to receive(:http_get).with(:single, '/shape/').and_return(response)
      expect(OracleCloud::Shape).to receive(:new).with('shape1').and_return(shape1)
      expect(OracleCloud::Shape).to receive(:new).with('shape2').and_return(shape2)

      expect(shapes.all).to eq([ shape1, shape2 ])
    end
  end

  describe '#exist?' do
    context 'when the shape exists' do
      it 'returns true' do
        allow(shapes).to receive(:all).and_return([ shape1, shape2 ])
        expect(shapes.exist?('shape1')).to eq(true)
      end
    end

    context 'when the shape does not exists' do
      it 'returns false' do
        allow(shapes).to receive(:all).and_return([ shape1, shape2 ])
        expect(shapes.exist?('shape999')).to eq(false)
      end
    end
  end
end
