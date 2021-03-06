require 'prawn'

module PdfHelper

  CONTAINS_LIST_PATTERN = /^\* .*/m
  CONTAINS_NON_LIST_PATTERN = /^[^\*].*/m 

  def wikinize_for_pdf(description, pdf)
    split_text_in_simple_and_lists(description).each { |simple_or_list| 
      if simple_or_list =~ CONTAINS_LIST_PATTERN
        split_list_string(simple_or_list).each do |list_item| 
          pdf.text "#{Prawn::Text::NBSP*3}\u2022"
          pdf.move_up pdf.font_size
          pdf.indent 20 do
            pdf.text wikinize_for_pdf_simple_string(list_item), :align => :justify, :inline_format => true 
          end
        end
      else
        pdf.text wikinize_for_pdf_simple_string(simple_or_list), :align => :justify, :inline_format => true 
      end
    }
  end

  def split_text_in_simple_and_lists(text)
    result = []
    while !text.nil? && text =~ CONTAINS_LIST_PATTERN   #list found
      result << $` if not $`.empty? #non-list part before list
      text = $&  #remainder
      text =~ CONTAINS_NON_LIST_PATTERN #non-list found (or not) in remainder
      result << ($` || text) #this is the list part
      text = $&   #remainder (possibly nil)
    end
    result << text unless text.nil? 
    result
  end

  def wikinize_for_pdf_simple_string( text )
    return "" unless text and not text.empty?
    text = text.gsub(/(^|[^\[])(#{URI::regexp(['http','https'])})/, '\1<u>\2</u>') #simple links
    text = text.gsub(/\[\[(#{URI::regexp(['http','https'])}) /, '<u>\1</u> ([[') #links with name part 1
    text = text.gsub(/\[\[([^\]]*)\]\]/, '\1)') #links  with name part 2

    text = text.gsub( /(^|\W)\*([^*\n]*)\*(\W|$)/, '\1<b>\2</b>\3' ) #bold
    text = text.gsub( /(^|\W)_([^_\n]*)_(\W|$)/, '\1<i>\2</i>\3' )   #italic
  end

  def split_list_string(list_string)
    list_string.scan(/^\* .*/).collect {|l| l[2,l.length] } 
  end

end 
