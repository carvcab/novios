with open(r'C:\Users\diego\Documents\Nueva carpeta\iphone app\Novios\Services\ChatService.swift', 'r') as f:
    content = f.read()

old = 'let msgId = "\(myUid)_\(Date().timeIntervalSince1970)"'
new = 'let msgId = "\(myUid)_\(Int(Date().timeIntervalSince1970 * 1000))"'
content = content.replace(old, new)

with open(r'C:\Users\diego\Documents\Nueva carpeta\iphone app\Novios\Services\ChatService.swift', 'w') as f:
    f.write(content)

count = content.count(new)
print(f'Replaced {count} occurrences of msgId pattern')
