#!/usr/local/bin/ruby -Ku
require 'rubygems'
require 'mechanize'
require 'kconv'
require 'date'
require 'sqlite3'
require 'nkf'



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



  agent.page.search('//tr[td[font[span[@name="riTime"]]]]').each do |e|
    time = e.at('span[@name="riTime"]').inner_text.strip.split(/:/) #strip!を使うとエラー
    hour = time[0].to_i
    min = time[1].to_i
    title = e.at('span[@name="riTitle"]').inner_text.strip #gsubで全角も削除対象にしたほうがいいかも
    artist = e.at('span[@name="riArtist"]').inner_text.strip


    date = Time.mktime(year, month, day, hour, min, 9).to_i
    p "#{date},#{title},#{artist}"
    
    
    #p title = NKF::nkf( '-Sem0', title )
    #p title = NKF::nkf( '-e', title )
    #p title = title.kconv(Kconv::UTF8,Kconv::SJIS)
    #p title = title.kconv(Kconv::EUC,Kconv::SJIS)
    #p title = title.toeuc
    #p title = NKF::nkf('-Se', title)

    p date2 = Time.at(date).to_s #sqlに入れるときはto_s
    
    new_item = {:date2 => date2, :date => date, :title => title, :artist => artist}
    sql = "insert into tbl_test values (:date2, :date, :title, :artist)"
    $db.execute(sql, new_item)



  end
  
  #db.close #この場所間違ってる
  
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

  $db = SQLite3::Database.new(db_name)
  $db.execute(SQL)

else
  $db = SQLite3::Database.new(db_name)

end





def bt(sd, ed)
  df = "%Y %m/%d" #"2010 7/3" のフォーマットで
  start_date = Date.strptime(sd, df)
  end_date = Date.strptime(ed, df)
  (start_date..end_date).each do |d|
    year = d.year
    month = d.month
    day = d.day

    for hour in 0..23 do #隠し設定？ 時間を"0"にすると0-10時、"1"は11-20時、"3"は無し
      hour = hour.to_s
      hour = hour.length == 1 ? "0#{hour}" : hour
      getNOAData(year, month, day, hour)
    end

  end
end

bt("2010 7/4","2010 7/4") #bt(db, "2010 7/3","2010 7/4")とすると7/3 0:00～7/4 23:59まで
