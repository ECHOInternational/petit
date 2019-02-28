require 'rqrcode'
module Petit
  # This class contains a single class method used to create QR
  # code strings to be returned with the JSON payload.
  # Using a class like this makes it easy to override the tool used
  # for generating the QR code.
  class QRcode
    # Generates a string representation of an SVG QR code for the supplied url
    #
    # @param url [String] the url for which to generate the qr code
    # @return [String] a string representation of a SVG QR code
    def self.generate(url)
      qrcode = RQRCode::QRCode.new(url)
      qrcode.as_svg(offset: 0, color: '000', shape_rendering: 'crispEdges', module_size: 11)
    end
  end
end
