# encoding: utf-8
require 'backup/cloud_io/qiniu'

module Backup
  module Storage
    class Qiniu < Base
      class Error < Backup::Error; end

      ##
      # Qiniu Credentials
      attr_accessor :access_key_id, :secret_access_key

      ##
      # Qiniu bucket name
      attr_accessor :bucket

      ##
      # Number of times to retry failed operations.
      #
      # Default: 10
      attr_accessor :max_retries

      ##
      # Time in seconds to pause before each retry.
      #
      # Default: 30
      attr_accessor :retry_waitsec

      def initialize(model, storage_id = nil)
        super

        @max_retries    ||= 10
        @retry_waitsec  ||= 30
        @path           ||= 'backups'
        path.sub!(/^\//, '')

        check_configuration
      end

      private

      def cloud_io
        @cloud_io ||= CloudIO::Qiniu.new(
          :access_key_id      => access_key_id,
          :secret_access_key  => secret_access_key,
          :bucket             => bucket,
          :max_retries        => max_retries,
          :retry_waitsec      => retry_waitsec
        )
      end

      def transfer!
        package.filenames.each do |filename|
          src = File.join(Config.tmp_path, filename)
          dest = File.join(remote_path, filename)
          Logger.info "Storing '#{ bucket }/#{ dest }'..."
          cloud_io.upload(src, dest)
        end
      end

      # Called by the Cycler.
      # Any error raised will be logged as a warning.
      def remove!(package)
        Logger.info "Removing backup package dated #{ package.time }..."

        remote_path = remote_path_for(package)
        objects = cloud_io.objects(remote_path)

        raise Error, "Package at '#{ remote_path }' not found" if objects.empty?

        cloud_io.delete(objects)
      end

      def check_configuration
        required = %w{ access_key_id secret_access_key bucket }
        raise Error, <<-EOS if required.map {|name| send(name) }.any?(&:nil?)
          Configuration Error
          #{ required.map {|name| "##{ name }"}.join(', ') } are all required
        EOS
      end

    end
  end
end
