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
  class SecurityListRequest
attr_reader :client, :opts, :name, :description, :outbound_cidr_policy,:policy

def initialize(client, opts)
  @client    = client
  @opts      = opts

  @name      = opts[:name]
  @outbound_cidr_policy = opts[:outbound_cidr_policy]
  @policy = opts[:policy]
  @description     =  opts[:description]
end

def full_name
  "#{client.full_identity_domain}/#{client.username}/#{name}"
end

def asjson
  to_h.delete_if { |key, value| value.nil? }.to_json
end

def to_h
  {
    'name'       => name,
    'outbound_cidr_policy'      => outbound_cidr_policy,
    'policy'  => policy,
    'description'       => description
  }
end

def put(name)
  path=''
  path.concat("seclist"+name)
  OracleCloud::SecurityList.new(client.http_put(path,asjson))
end

def post
  path=''
  path.concat("seclist/")
  OracleCloud::SecurityList.new(client.http_post(path,asjson))
end

def get(path)
  OracleCloud::SecurityList.new(client.http_get(:single,path))
end


def delete(path)
    client.http_delete(path)
end

end
end
