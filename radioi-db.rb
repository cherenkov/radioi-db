#!/usr/local/bin/ruby -Ku
require 'rubygems'
require 'mechanize'
require 'kconv'
#require 'date'
require 'sqlite3'




def getNOAData(db, year, month, day, hh)
  agent = Mechanize.new
  agent.get('http://www.radio-i.co.jp/NOAView/cgi-bin/NOAData.Now?id=0469')
  agent.page.form_with(:name => 'form1'){|f|
    f.field_with(:name => 'year').value = year
    f.field_with(:name => 'month').value = month
    f.field_with(:name => 'day').value = day
    f.field_with(:name => 'hh').value = hh
    f.field_with(:name => 'artist').value = ''
    f.field_with(:name => 'music').value = ''
    f.click_button
  }



  agent.page.search('//tr[td[font[span[@name="riTime"]]]]').each do |e|
    time = e.at('span[@name="riTime"]').inner_text.strip.split(/:/) #strip!を使うとエラー
    hour = time[0].to_i
    min = time[1].to_i
    title = e.at('span[@name="riTitle"]').inner_text.strip.toutf8 #gsubで全角も削除対象にしたほうがいいかも
    artist = e.at('span[@name="riArtist"]').inner_text.strip.toutf8


    
    #hash = {
    #  :date => Time.mktime(year, month, day, hour, min, 9).to_i,
    #  :title => title,
    #  :artist => artist
    #}
    #p JsonBuilder.new.build(hash)


    date = Time.mktime(year, month, day, hour, min, 9).to_i
    p "#{date},#{title},#{artist}"

    p date2 = Time.at(date).to_s #sqlに入れるときはto_sを忘れずに
    
    new_item = {:date2 => date2, :date => date, :title => title, :artist => artist}
    sql = "insert into tbl_test values (:date2, :date, :title, :artist)"
    db.execute(sql, new_item)



  end
  
  db.close
  
end




db_name = 'test.db'


unless test(?e, db_name) then

SQL=<<EOS
create table tbl_test (
  date2   text,
  date    integer,
  title   text,
  artist  text
);
EOS

  db = SQLite3::Database.new(db_name)
  db.execute(SQL)

else
  db = SQLite3::Database.new(db_name)

end

getNOAData(db, 2010, 7, 1, '09') #時刻を"0"にすると0-10時、"1"は11-20時、"3"は無し

