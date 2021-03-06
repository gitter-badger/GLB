#encoding:utf-8
require "nokogiri"
require "#{Rails.root}/app/helpers/entries_helper"
include EntriesHelper
namespace :db do
  task :import_xml => :environment do
    parsed = 0
    total = 0
    not_parsing = 0
    Entry.transaction do 
      Dir.glob('gesamt/*.xml') do |file|
        # do work on files ending in .rb in the desired directory
        entry = Nokogiri::XML(open(file))
        main_text_array = []
        total += 1
        begin
          entry.xpath("//informaltable/following-sibling::para").each do |para|
            if para.children.length > 0
              main_text_array.push(para.children[0].text)
            end
          end
          main_text_array.shift
          #uebersetzung
          main_text = main_text_array.join("<br />")
        rescue
          log = open("error_main_text.log", "a")
          log.puts file + "\n"
          log.close
        end

        file.slice!(file.length - 3..file.length - 1)
        file.slice!(0..6)
        #page_reference
        page_reference = file + "doc"

        #parameters
        FIELDS = {"Verfasser/in         (Namenskürzel)" => :namenskuerzel, "Kennzahl des Lemmas  (z.B. 1304:1)" => :kennzahl, "Spaltenzahl (z.B. 15)" => :spaltenzahl, "Japanische Umschrift" => :japanische_umschrift, "Kanji" => :kanji, "Pali" => :pali, "Sanskrit " => :sanskrit, "Chinesisch" => :chinesisch, "Tibetisch " => :tibetisch, "Koreanisch " => :koreanisch, "Weitere Sprachen " => :weitere_sprachen, "Alternative japanische Lesungen" => :alternative_japanische_lesungen, "Schreibvarianten (Kanji + Lesungen) " => :schreibvarianten, "Dt. Übersetzung " => :deutsche_uebersetzung, "Art des Lemmas  [Ziffer eingeben]  (1 Person, 2 Tempel, 3 Werk, 4 Fachtermini, 5 geographische Bezeichnung, 6 Ereignis)" => :lemma_art, "Jahreszahlen (westl. Zeitrechnung) " => :jahreszahlen, "Quellen" => :quellen, "Literatur        (m/w)" => :literatur, "Eigene Ergänzungen" => :eigene_ergaenzungen, "Ergänzungen der Quellenangaben" => :quellen_ergaenzungen, "Ergänzungen der Literaturangaben        (m/w)" => :literatur_ergaenzungen}
        hash = Hash.new
        paras = entry.xpath("//tgroup//para")
        new_entry = Entry.new
        new_entry.user = User.first
        new_entry.page_reference = page_reference
        nils = []
        LEMMAART = ["Person", "Tempel", "Werk", "Fachtermini", "Geographische Bezeichnung", "Ereignis"]

        begin
          #0 - 5 bis titel des Lemmas, data in odd
          (0..5).each do |num|
            if paras[num].children.length > 0 && num % 2 == 1
              if FIELDS[paras[num - 1].children[0].text]
                hash[FIELDS[paras[num - 1].children[0].text]] = paras[num].children[0].text
              else
                nils.push(paras[num].children[0].text)
              end
            end
          end
          new_entry.update_attributes(hash)
          #7 - 28 bis weitere Angaben, data in even
          (7..28).each do |num|
            if paras[num].children.length > 0 && num % 2 == 0
              if FIELDS[paras[num - 1].children[0].text]
                hash[FIELDS[paras[num - 1].children[0].text]] = paras[num].children[0].text
              else
                nils.push(paras[num].children[0].text)
              end
            end
          end
          new_entry.update_attributes(hash)
          #30 - 33 bis Übersetzung, data in odd
          (30..33).each do |num|
            if paras[num].children.length > 0 && num % 2 == 1
              if FIELDS[paras[num - 1].children[0].text]
                hash[FIELDS[paras[num - 1].children[0].text]] = paras[num].children[0].text
              else
                nils.push(paras[num].children[0].text)
              end
            end
          end
          new_entry.update_attributes(hash)
          #35 - 44 data in even
          (35..44).each do |num|
            if paras[num].children.length > 0 && num % 2 == 0
              if FIELDS[paras[num - 1].children[0].text]
                hash[FIELDS[paras[num - 1].children[0].text]] = paras[num].children[0].text
              else
                nils.push(paras[num].children[0].text)
              end
            end
          end
          new_entry.update_attributes(hash)

          new_entry.kennzahl = new_entry.kennzahl.split(":").map{|num| num.to_i }.join(":")
          new_entry.uebersetzung = main_text
          if new_entry.lemma_art
            new_entry.lemma_art = LEMMAART[new_entry.lemma_art.to_i - 1]
          end

          new_entry.save
          if nils.length > 0
            not_parsing_entry = []
            entry.xpath("//para").each{|p| not_parsing_entry.push(p)}
            new_entry.uebersetzung = not_parsing_entry.join("<br />")
            new_entry.save
          end
          puts new_entry.japanische_umschrift + " parsed!"
          parsed += 1
        rescue Exception => e
          not_parsing_entry = []
          entry.xpath("//para").each{|p| not_parsing_entry.push(p)}
          if new_entry.lemma_art
            new_entry.lemma_art = LEMMAART[new_entry.lemma_art.to_i - 1]
          end
          new_entry.uebersetzung = not_parsing_entry.join("<br />")
          new_entry.save
          log = open("error_paras.log", "a+")
          log.puts file + "\n"
          log.puts e.to_s + "\n"
          log.puts hash.to_s + "\n"
          log.puts paras.to_s + "\n"
          log.puts "-------------------------------------------"
          log.close
          not_parsing += 1
        end
        puts "total: " + total.to_s
        puts "parsed: " + parsed.to_s
        puts "not_parsing: " + not_parsing.to_s
      end
    end
  end
end

