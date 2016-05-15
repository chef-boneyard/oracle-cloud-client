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
  class StorageAttachmentRequest
  attr_reader :client, :opts, :storage_volume_name, :instance_name, :index
  
  def initialize(client, opts)
    @client    = client
    @opts      = opts
    @storage_volume_name      = opts[:storage_volume_name]
    @instance_name     =  opts[:instance_name]
    @index = opts[:index]

  end

  def full_name
    "#{client.full_identity_domain}/#{client.username}/#{name}"
  end



  def asjson
    storage_input_map = to_h
    storage_input_map.delete_if { |key, value| value.nil? }
    storage_input_map.to_json
  end

  def delete(path)
    client.http_delete(path)
  end


  def to_h
    {
      'storage_volume_name'       => storage_volume_name,
      'instance_name'      => instance_name,
      'index'  => index
    }
  end

  def put(name)
    path=''
    path.concat("storage/attachment"+name)
    OracleCloud::StorageAttachment.new(client.http_put(path,asjson))
  end

  def post
    path=''
    path.concat("storage/attachment/")
    OracleCloud::StorageAttachment.new(client.http_post(path,asjson))
  end

  def get(path)
    OracleCloud::StorageAttachment.new(client.http_get(:single,path))
  end

  def delete(path)
    client.http_delete(path)
  end
    
  end
end
