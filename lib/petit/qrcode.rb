require 'rqrcode'
module Petit
	class QRcode
		def self.generate(url)
			qrcode = RQRCode::QRCode.new(url)
			qrcode.as_svg(offset: 0, color: '000', shape_rendering: 'crispEdges', module_size: 11)
		end
	end
end