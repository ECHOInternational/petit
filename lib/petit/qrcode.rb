require 'rqrcode'
module Petit
  #  This class contains a single class method used to create QR
  #   code strings to be returned with the JSON payload.
  #   using a class like this makes it easy to override the tool used
  #   for generating the QR code.
  class QRcode
    def self.generate(url)
      qrcode = RQRCode::QRCode.new(url)
      qrcode.as_svg(offset: 0, color: '000', shape_rendering: 'crispEdges', module_size: 11)
    end
  end
end
