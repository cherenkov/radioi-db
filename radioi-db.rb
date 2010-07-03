#!/usr/local/bin/ruby -Ku
require 'rubygems'
require 'mechanize'
require 'kconv'
require 'date'
require 'sqlite3'


def getNOAData(year, month, day, hh)
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

  agent.page.encoding = "utf-8" #このタイミングとtoutf8が必要。

  agent.page.search('//tr[td[font[span[@name="riTime"]]]]').each do |e|
    time = e.at('span[@name="riTime"]').inner_text.strip.split(/:/)
    hour = time[0].to_i
    min = time[1].to_i
    date = Time.mktime(year, month, day, hour, min, 9).to_i
    date2 = Time.at(date).to_s
    title = e.at('span[@name="riTitle"]').inner_text.toutf8.strip #gsubで全角も削除対象にしたほうがいいかも
    artist = e.at('span[@name="riArtist"]').inner_text.toutf8.strip

    new_item = {:date => date, :date2 => date2, :title => title, :artist => artist}
    sql = "insert into NOAData values (:date, :date2, :title, :artist)"
    $db.execute(sql, new_item)

    p "#{date2},#{title},#{artist}"


  end

  #db.close #この場所間違ってる。必要ない？

end




db_name = 'radioi_NOAData.db'


unless test(?e, db_name) then

SQL=<<EOS
create table NOAData (
  date    integer,
  date2   text,
  title   text,
  artist  text
);
EOS

  $db = SQLite3::Database.new(db_name)
  $db.execute(SQL)
else
  $db = SQLite3::Database.new(db_name)
end



def bt(sd, ed)
  df = "%Y %m/%d"
  start_date = Date.strptime(sd, df)
  end_date = Date.strptime(ed, df)
  (start_date..end_date).each do |d|
    year = d.year
    month = d.month
    day = d.day

    #隠し設定？ 時間を"0"にすると0-10時、"1"は11-20時、"3"は無し
    #for hour in 0..23 do
    for hour in 13..14 do
      hour = hour.to_s
      hour = hour.length == 1 ? "0#{hour}" : hour
      getNOAData(year, month, day, hour)
    end

  end
end


#bt(db, "2010 7/3","2010 7/4")とすると7/3 0:00～7/4 23:59まで
#7/3 13に日本語あり
bt("2010 7/3","2010 7/3")

