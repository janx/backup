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
        opts = { :prefix => prefix + '/' }

        while resp.nil? || resp.body['IsTruncated']
          opts.merge!(:marker => objects.last.key) unless objects.empty?
          with_retries("GET '#{ bucket }/#{ prefix }/*'") do
            resp = connection.get_bucket(bucket, opts)
          end
          resp.body['Contents'].each do |obj_data|
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

        opts = { :quiet => true } # only report Errors in DeleteResult
        until keys.empty?
          _keys = keys.slice!(0, 1000)
          with_retries('DELETE Multiple Objects') do
            resp = connection.delete_multiple_objects(bucket, _keys, opts)
            unless resp.body['DeleteResult'].empty?
              errors = resp.body['DeleteResult'].map do |result|
                error = result['Error']
                "Failed to delete: #{ error['Key'] }\n" +
                "Reason: #{ error['Code'] }: #{ error['Message'] }"
              end.join("\n")
              raise Error, "The server returned the following:\n#{ errors }"
            end
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
        attr_reader :key, :etag, :storage_class

        def initialize(cloud_io, data)
          @cloud_io = cloud_io
          @key  = data['Key']
          @etag = data['ETag']
          @storage_class = data['StorageClass']
        end

        private

        def metadata
          @metadata ||= @cloud_io.head_object(self).headers
        end
      end

    end
  end
end
