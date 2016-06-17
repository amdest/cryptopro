module Cryptopro
  class Signature < Cryptopro::Base
    MESSAGE_FILE_NAME = 'message.txt'
    # Должен называться как файл с сообщением, только расширение .sgn
    SIGNATURE_FILE_NAME = 'message.txt.sgn'

    # Options: message, signature, certificate
    def self.verify(options)
      raise 'Message required' if options[:message].blank?
      raise 'Signature required' if options[:signature].blank?
      raise 'Certificate required' if options[:certificate].blank?

      # Для работы с cryptcp требуется, чтобы сообщение, полпись и сертификат были в виде файлов
      # Создаётся временная уникальная папка для каждой проверки
      tmp_dir = create_temp_dir
      create_temp_files(tmp_dir, options)
      execute(tmp_dir)
    end

    private

    def self.create_temp_files(tmp_dir, options)
      # Создать файл сообщения
      create_temp_file(tmp_dir, MESSAGE_FILE_NAME, options[:message])
      # Создать файл подписи
      create_temp_file(tmp_dir, SIGNATURE_FILE_NAME, options[:signature])
      # Создать файл сертификата
      certificate_with_container = add_container_to_certificate(options[:certificate])
      create_temp_file(tmp_dir, CERTIFICATE_FILE_NAME, certificate_with_container)
    end

    # Обсуждение формата использования: http://www.cryptopro.ru/forum2/Default.aspx?g=posts&t=1516
    # Пример вызова утилиты cryptcp:
    # cryptcp -vsignf -dir /home/user/signs -f certificate.cer message.txt
    # /home/user/signs -- папка с подписью, имя которой соответствуют имени сообщения, но с расширением .sgn
    def self.execute(dir)
      Cocaine::CommandLine.path = %w(/opt/cprocsp/bin/amd64 /opt/cprocsp/bin/ia32 /opt/cprocsp/bin)
      line = Cocaine::CommandLine.new('cryptcp', "-vsignf -errchain -dir #{dir} -f #{dir}/#{CERTIFICATE_FILE_NAME} #{dir}/#{MESSAGE_FILE_NAME}")
      begin
        line.run
        return true, 'Подпись прошла успешно'
      rescue Cocaine::ExitStatusError => e
        message = case e.message[/\[ErrorCode: 0x([0-9x]+)\]/, 1]
                    when '20000132'
                      'Данный сертификат не может применяться для этой операции'
                    when '20000133'
                      'Цепочка сертификатов не проверена'
                    when '200001F6'
                      'Неизвестный алгоритм подписи'
                    when '200001F9'
                      'Подпись не верна'
                    when '20000259'
                      'Неизвестный алгоритм шифрования'
                    else
                      "Неизвестная ошибка, код: #{e.message[/\[ErrorCode: 0x([0-9x]+)\]/, 1]}"
                  end
        return false, message
      rescue Cocaine::CommandNotFoundError => e
        raise 'Command cryptcp was not found'
      end
    end

  end
end
