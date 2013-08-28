source, html, md = *ARGV

source ||= 'merged.html'
html ||= 'clean.html'
md ||= 'notes.md'


src = File.read(source)

sections = src.scan(/<section.*?>(.*?)<\/section/m).flatten

File.open(md, 'w').write sections.map{ |s| 
  m = s.match(/aside.*?>(.*)<\/aside/m) 
  ((m && m[1]) || '').strip
}.join("\n\n----\n\n") 

File.open(html, 'w').write src.gsub(/\s+<aside.*?>.*?<\/aside.*?>/m, '')

