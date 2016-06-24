module Cryptopro
  module Update
    class CAList
      def self.parse(output_folder)
        xml = File.open("#{output_folder}/DownloadTSL?schemaVersion=0") { |f| Nokogiri::XML(f) }
        array_of_crl_links = []
        array_of_certificate_strings = []
        cas = xml.xpath('//УдостоверяющийЦентр')
        cas.each do |ca|
          if ca.xpath('СтатусАккредитации/Статус').text == 'Действует'
            ca.xpath('.//ДанныеСертификата').each do |cert_body_node|
              if Time.parse(cert_body_node.xpath('ПериодДействияДо').text) > DateTime.now
                array_of_certificate_strings << cert_body_node.xpath('Данные').text
              end
            end
            ca.xpath('.//АдресаСписковОтзыва/Адрес').each do |crl_link_node|
              array_of_crl_links << crl_link_node.text
            end
          end
        end

        crl_list_file = File.new("#{output_folder}/crl_list.txt", 'w')
        array_of_crl_links.each do |link|
          crl_list_file.puts link
        end
        crl_list_file.close

        FileUtils::mkdir_p("#{output_folder}/root_certificates")

        array_of_certificate_strings.each_with_index do |cert_string, index|
          File.open("#{output_folder}/root_certificates/#{index}.cer", 'w'){ |file| file.write(Cryptopro::Base.add_container_to_certificate(cert_string)) }
        end
      end
    end
  end
end