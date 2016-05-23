module Cryptopro
  module Update
    class CRL
      def self.execute(array_of_links, output_folder)
        self.download(array_of_links, output_folder)
        self.install(output_folder)
      end

      private

      def self.download(array_of_links, output_folder)

        # Reprocess received array of emails into a temporary file that we feed to wget.
        temp_file = Tempfile.new('crls')
        array_of_links.each{ |link| temp_file.puts link }
        temp_file.rewind

        # We're using wget to download all necessary (with modification date newer than what we have) crls.
        logger = Logger.new('log/crl_download.log')
        line = Cocaine::CommandLine.new(
            'wget', '-i :temp_file -N -P :output_folder',
            logger: logger
        )

        begin
          line.run(temp_file: temp_file.path, output_folder: output_folder)


        # Here we're scanning error for lines like:
        # wget: unable to resolve host address ‘seor7ytlqehrtbkhsdfgodhkghsdpogsdf.com’
        rescue Cocaine::ExitStatusError => e
          e.message.scan(/wget: ([a-z0-9’‘ .]+)/i).each do |error|
            logger.error error
          end

        # As we're good guys, we're cleaning after ourselves.
        ensure
          temp_file.close
          temp_file.unlink
        end
      end

      def self.install(output_folder)

        # First of all we're getting path to crl files and checking if they are of a fresh version.
        crl_files = Dir["#{output_folder}/*"]
        crl_files = crl_files.select{ |file| File.ctime(file).today? }

        # CryptoPro CSP creates bin folder with subfolder dependant on system's architecture, so we're making sure
        # we're going to use current one.
        Cocaine::CommandLine.path = %w(/opt/cprocsp/bin/amd64 /opt/cprocsp/bin/ia32)

        # We're using part of a CryptoPro CSP toolkit: certmgr, to install all our crls to mCA store, which is the
        # default one for crls and we're going to send any errors we encounter to a log file.
        logger = Logger.new('log/crl_installation.log')
        line = Cocaine::CommandLine.new(
            'certmgr', '-inst -crl -store mCA -file :file',
            logger: logger
        )

        crl_files.each do |file|
          begin
            line.run(file: "#{Dir.pwd}/#{file}")

          # CryptoPro provides really long and verbose error messages, but the only thing of use in those is actual
          # error code, which we're scanning for and writing to log file.
          rescue Cocaine::ExitStatusError => e
            logger.error "#{file} ErrorCode:#{e.message[/\[ErrorCode: ([0-9x]+)\]/, 1]}"
          end
        end
      end

    end
  end
end