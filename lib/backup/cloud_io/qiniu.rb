# encoding: utf-8
require 'backup/cloud_io/base'
require 'qiniu-rs'

module Backup
  module CloudIO
    class Qiniu < Base
      class Error < Backup::Error; end

      MAX_FILE_SIZE       = 1024**3 * 5   # 5 GiB

      attr_reader :access_key_id, :secret_access_key, :bucket

      def initialize(options = {})
        super

        @access_key_id      = options[:access_key_id]
        @secret_access_key  = options[:secret_access_key]
        @bucket             = options[:bucket]

        ::Qiniu::RS.establish_connection!(
          :access_key => @access_key_id,
          :secret_key => @secret_access_key
        )
      end

      # The Syncer may call this method in multiple threads.
      # However, #objects is always called prior to multithreading.
      def upload(src, dest)
        put_object(src, dest)
      end

      # Returns all objects in the bucket with the given prefix.
      #
      # - #get_bucket returns a max of 1000 objects per request.
      # - Returns objects in alphabetical order.
      # - If marker is given, only objects after the marker are in the response.
      def objects(prefix)
        objects = []
        resp = nil
        prefix = prefix.chomp('/')

        while resp.nil? || resp[1]['marker']
          # a hack: bucket list api is not implemented in Qiniu gem
          # but exists. here we use the api manually
          url = "http://rsf.qbox.me/list?bucket=#{bucket}&prefix=#{prefix}"
          url += "&marker=#{resp[1]['marker']}" if resp && resp[1]['marker']
          with_retries("GET '#{ bucket }/#{ prefix }/*'") do
            resp = ::Qiniu::RS::Auth.request url
          end
          resp[1]['items'].each do |obj_data|
            objects << Object.new(self, obj_data)
          end
        end

        objects
      end

      # Used by Object to fetch metadata if needed.
      def head_object(object)
        resp = nil
        with_retries("HEAD '#{ bucket }/#{ object.key }'") do
          resp = connection.head_object(bucket, object.key)
        end
        resp
      end

      # Delete object(s) from the bucket.
      #
      # - Called by the Storage (with objects) and the Syncer (with keys)
      # - Deletes 1000 objects per request.
      # - Missing objects will be ignored.
      def delete(objects_or_keys)
        keys = Array(objects_or_keys).dup
        keys.map!(&:key) if keys.first.is_a?(Object)

        with_retries('DELETE Multiple Objects') do
          unless ::Qiniu::RS.batch_delete(bucket, keys)
            raise Error, "Failed to delete keys in bucket #{bucket}."
          end
        end
      end

      private

      def put_object(src, dest)
        with_retries("PUT '#{ bucket }.qiniudn.com/#{ dest }'") do
          token = ::Qiniu::RS.generate_upload_token(:scope => bucket)
          ::Qiniu::RS.upload_file(
            :uptoken => token,
            :file => src,
            :bucket => bucket,
            :key => dest
          )
        end
      end

      class Object
        attr_reader :key, :etag, :put_time, :size, :mime, :customer

        def initialize(cloud_io, data)
          @cloud_io = cloud_io
          @key  = data['key']
          @put_time = data['time']
          @etag = data['hash']
          @size = data['fsize']
          @mime = data['mimeType']
          @customer = data['customer']
        end

        private

        def metadata
          @metadata ||= @cloud_io.head_object(self).headers
        end

      end

    end
  end
end
