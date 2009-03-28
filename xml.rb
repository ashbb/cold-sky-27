# xml.rb
class XML
  def initialize
    @xml = ''
  end
  
  attr_reader :xml
  
  def content text
    @xml << text.to_s
    nil
  end
  
  def tag tagname, attributes = {}
    @xml << "<#{tagname}"
    
    attributes.each{|a, v| @xml << " #{a}='#{v}'"}
    
    if block_given?
      @xml << '>'
      cont = yield
      (@xml << cont.to_s) if cont
      @xml << "</#{tagname}>"
    else
      @xml << '/>'
    end
    nil
  end
  
  alias method_missing tag
  
  def self.generate &blk
    o = XML.new
    o.instance_eval &blk
    o.xml
  end
end
 