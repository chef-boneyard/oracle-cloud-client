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

describe OracleCloud::InstanceRequest do
  let(:client) do
    OracleCloud::Client.new(
      username:        'myuser',
      password:        'mypassword',
      api_url:         'https://cloud.oracle.local',
      identity_domain: 'testdomain'
    )
  end

  let(:request) do
    OracleCloud::InstanceRequest.new(
      client,
      name: 'test_name',
      shape: 'test_shape',
      imagelist: 'test_imagelist',
      public_ip: :pool,
      label: 'test_label',
      sshkeys: [ 'test_sshkey' ]
    )
  end

  let(:shapes)     { double('shapes') }
  let(:imagelists) { double('imagelists') }
  before do
    allow(client).to receive(:authenticate!)
    allow(client).to receive(:shapes).and_return(shapes)
    allow(client).to receive(:imagelists).and_return(imagelists)
    allow(shapes).to receive(:exist?).and_return(true)
    allow(imagelists).to receive(:exist?).and_return(true)
  end

  describe '#initialize' do
    let(:request) { OracleCloud::InstanceRequest.allocate }

    it 'validates the options' do
      expect(request).to receive(:validate_options!)
      request.send(:initialize, client, {})
    end
  end

  describe '#validate_options!' do
    it 'raises an exception if any required options are missing' do
      allow(request).to receive(:missing_required_options).and_return([ 'missing_opt' ])
      expect { request.validate_options! }.to raise_error(ArgumentError)
    end

    it 'raises an exception if the shape is not valid' do
      allow(shapes).to receive(:exist?).with('test_shape').and_return(false)
      expect { request.validate_options! }.to raise_error(ArgumentError)
    end

    it 'raises an exception if the imagelist is not valid' do
      allow(imagelists).to receive(:exist?).with('test_imagelist').and_return(false)
      expect { request.validate_options! }.to raise_error(ArgumentError)
    end

    context 'when the ssh_keys parameter is not an array of keys' do
      let(:request) do
        OracleCloud::InstanceRequest.new(
          client,
          name: 'test_name',
          shape: 'test_shape',
          imagelist: 'test_imagelist',
          public_ip: :pool,
          label: 'test_label',
          sshkeys: 'test_sshkey'
        )
      end

      it 'raises an exception' do
        expect { request.validate_options! }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#missing_required_options' do
    context 'when name is missing' do
      let(:opts) { { shape: 'test_shape', imagelist: 'test_imagelist' } }
      it 'returns an array containing name' do
        allow(request).to receive(:opts).and_return(opts)
        expect(request.missing_required_options).to eq([ :name ])
      end
    end

    context 'when shape is missing' do
      let(:opts) { { name: 'test_name', imagelist: 'test_imagelist' } }
      it 'returns an array containing shape' do
        allow(request).to receive(:opts).and_return(opts)
        expect(request.missing_required_options).to eq([ :shape ])
      end
    end

    context 'when imagelist is missing' do
      let(:opts) { { name: 'test_name', shape: 'test_shape' } }
      it 'returns an array containing imagelist' do
        allow(request).to receive(:opts).and_return(opts)
        expect(request.missing_required_options).to eq([ :imagelist ])
      end
    end

    context 'when more than one option is missing' do
      let(:opts) { { name: 'test_name' } }
      it 'returns an array containing the missing options' do
        allow(request).to receive(:opts).and_return(opts)
        expect(request.missing_required_options).to eq(%i[shape imagelist])
      end
    end
  end

  describe '#full_name' do
    it 'returns a properly concatenated string for the name in public cloud' do
      allow(client).to receive(:full_identity_domain).and_return('Compute-testdomain')
      allow(client).to receive(:username).and_return('myuser')
      expect(request.full_name).to eq('Compute-testdomain/myuser/test_name')
    end
  end

  describe '#nat' do
    context 'when no public IP is specified' do
      it 'returns nil' do
        allow(request).to receive(:public_ip).and_return(nil)
        expect(request.nat).to eq(nil)
      end
    end

    context 'when pool is specified' do
      it 'returns the oracle public IP pool path' do
        allow(request).to receive(:public_ip).and_return(:pool)
        expect(request.nat).to eq('ippool:/oracle/public/ippool')
      end
    end

    context 'when a reservation is provided' do
      it 'returns the ipreservation name' do
        allow(request).to receive(:public_ip).and_return('some_reservation')
        expect(request.nat).to eq('ipreservation:some_reservation')
      end
    end
  end

  describe '#networking' do
    context 'when nat is nil' do
      it 'returns a hash containing no nat info' do
        allow(request).to receive(:nat).and_return(nil)
        expect(request.networking['eth0'].key?('nat')).to eq(false)
      end
    end

    context 'when nat is not nil' do
      it 'returns a hash containing nat info' do
        allow(request).to receive(:nat).and_return('nat_info')
        expect(request.networking['eth0']['nat']).to eq('nat_info')
      end
    end
  end

  describe '#to_h' do
    it 'returns a hash containing the correct info' do
      allow(request).to receive(:networking).and_return('test_networking')
      allow(request).to receive(:full_name).and_return('test_fullname')

      expect(request.to_h['shape']).to eq('test_shape')
      expect(request.to_h['label']).to eq('test_label')
      expect(request.to_h['imagelist']).to eq('test_imagelist')
      expect(request.to_h['name']).to eq('test_fullname')
      expect(request.to_h['sshkeys']).to eq([ 'test_sshkey' ])
      expect(request.to_h['networking']).to eq('test_networking')
    end
  end
end
