module Cryptopro
  module Update
    class Actions
      def self.download(array_of_links, output_folder)

        array_of_links.each do |link|
          link.gsub!("\n", '')
        end

        pwd = Dir.pwd

        FileUtils::mkdir_p("#{output_folder}/")
        Dir.chdir("#{output_folder}/")

        Curl::Multi.download(
            array_of_links,
            {connect_timeout: 15, ssl_verify_peer: false, follow_location: true, max_redirects: 5, timeout: 20},
            {max_connects: 100, pipeline: 1}
        )

        Dir.chdir(pwd)

      end

      def self.install(file_folder, store, args = '')

        files = Dir["#{file_folder}/*"]

        Cocaine::CommandLine.path = %w(/opt/cprocsp/bin/amd64 /opt/cprocsp/bin/ia32 /opt/cprocsp/bin)

        logger_path = Rails ? "#{Rails.root}/log/cryptopro_installation.log" : 'log/cryptopro_installation.log'
        logger = Logger.new(logger_path)

        line = Cocaine::CommandLine.new(
           'certmgr', '-inst :args -store :store -file :file',
           logger: logger
        )

        files.each do |file|

          begin
            line.run(args: args, store: store, file: file)

          rescue Cocaine::ExitStatusError => e
            # TODO add method that returns description to those errors, as error codes are not that useful
            logger.error "#{file} ErrorCode:#{e.message[/\[ErrorCode: ([0-9x]+)\]/, 1]}"

          end
        end



      end
    end
  end
end