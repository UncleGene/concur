target, html, md = *ARGV

target ||= 'merged.html'
html ||= 'clean.html'
md ||= 'notes.md'


h = File.read html
m = File.read md

notes = m.split(/\n\n----\n\n/, -1)
sections = h.scan(/<section.*?>(.*?)<\/section/m).flatten

raise "#{notes.size} notes for #{sections.size} sections" if notes.size != sections.size


File.open(target, "w") do |f|
  sn = 0
  h.lines.each do |l|
    f.write l
    if l =~ /<section/
      f.write "\n<aside class=\"notes\" data-markdown>\n"
      f.write notes[sn]
      sn += 1
      f.write "\n</aside>\n"
    end  
  end
end

